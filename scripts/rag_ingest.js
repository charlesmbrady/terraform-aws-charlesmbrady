#!/usr/bin/env node
/**
 * DIY RAG Ingestion Script
 * ---------------------------------
 * Reads markdown files from a source directory, chunks them, generates embeddings
 * using Amazon Bedrock Titan Embed Text V2, and uploads a single consolidated
 * embeddings JSON file to the configured S3 bucket.
 *
 * Requirements:
 *   npm install @aws-sdk/client-bedrock-runtime @aws-sdk/client-s3 @aws-sdk/client-ssm gray-matter glob
 *   AWS credentials with bedrock:InvokeModel, s3:PutObject, ssm:GetParameter
 *
 * Usage:
 *   node rag_ingest.js --source ./docs --bucket my-rag-bucket
 *   OR rely on SSM parameter (if bucket omitted): /<project>/<env>/agentcore/rag/bucket-name
 */

import {
  BedrockRuntimeClient,
  InvokeModelCommand,
} from "@aws-sdk/client-bedrock-runtime";
import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import { SSMClient, GetParameterCommand } from "@aws-sdk/client-ssm";
import fs from "fs";
import path from "path";
import matter from "gray-matter";
import glob from "glob";

const REGION = process.env.AWS_REGION || "us-east-1";
const EMBEDDING_MODEL =
  process.env.RAG_EMBED_MODEL || "amazon.titan-embed-text-v2:0";
const MAX_CHUNK_TOKENS = parseInt(
  process.env.RAG_MAX_CHUNK_TOKENS || "800",
  10
);
const CHUNK_OVERLAP_TOKENS = parseInt(
  process.env.RAG_CHUNK_OVERLAP_TOKENS || "80",
  10
);
const OUTPUT_KEY = process.env.RAG_OUTPUT_KEY || "embeddings/embeddings.json";
const SSM_BUCKET_PARAM =
  process.env.RAG_SSM_PARAM || "/charlesmbrady/Test/agentcore/rag/bucket-name";

function parseArgs() {
  const args = process.argv.slice(2);
  const out = {};
  for (let i = 0; i < args.length; i++) {
    if (args[i] === "--source") out.source = args[++i];
    else if (args[i] === "--bucket") out.bucket = args[++i];
  }
  return out;
}

function simpleTokenizer(text) {
  // Very naive tokenization by whitespace; adjust if needed.
  return text.split(/\s+/).filter(Boolean);
}

function chunkText(text) {
  const tokens = simpleTokenizer(text);
  const chunks = [];
  let start = 0;
  while (start < tokens.length) {
    const end = Math.min(start + MAX_CHUNK_TOKENS, tokens.length);
    const chunkTokens = tokens.slice(start, end);
    chunks.push(chunkTokens.join(" "));
    start = end - CHUNK_OVERLAP_TOKENS; // overlap
    if (start < 0) start = 0;
    if (start >= tokens.length) break;
  }
  return chunks;
}

async function getBucketNameIfMissing(providedBucket) {
  if (providedBucket) return providedBucket;
  const ssm = new SSMClient({ region: REGION });
  const param = await ssm.send(
    new GetParameterCommand({ Name: SSM_BUCKET_PARAM })
  );
  return param.Parameter.Value;
}

async function embedChunk(client, text) {
  const payload = {
    inputText: text,
  };
  const command = new InvokeModelCommand({
    modelId: EMBEDDING_MODEL,
    contentType: "application/json",
    accept: "application/json",
    body: Buffer.from(JSON.stringify(payload)),
  });
  const response = await client.send(command);
  const bodyStr = Buffer.from(response.body).toString();
  const parsed = JSON.parse(bodyStr);
  // Titan returns embedding in embedding field; adjust if model changes.
  return parsed.embedding;
}

async function main() {
  const { source, bucket: bucketArg } = parseArgs();
  if (!source) {
    console.error("Missing --source directory of markdown files");
    process.exit(1);
  }
  const absSource = path.resolve(source);
  if (!fs.existsSync(absSource)) {
    console.error("Source directory does not exist:", absSource);
    process.exit(1);
  }

  const bucket = await getBucketNameIfMissing(bucketArg);
  console.log("Using embeddings bucket:", bucket);

  const files = glob.sync("**/*.md", { cwd: absSource });
  if (files.length === 0) {
    console.warn("No markdown files found. Exiting.");
    process.exit(0);
  }

  const bedrock = new BedrockRuntimeClient({ region: REGION });
  const s3 = new S3Client({ region: REGION });

  const embeddingsDoc = [];

  for (const rel of files) {
    const fullPath = path.join(absSource, rel);
    const raw = fs.readFileSync(fullPath, "utf-8");
    const { content, data: frontmatter } = matter(raw);

    const chunks = chunkText(content);
    console.log(`File: ${rel} => ${chunks.length} chunks`);

    for (let i = 0; i < chunks.length; i++) {
      const chunk = chunks[i];
      try {
        const embedding = await embedChunk(bedrock, chunk);
        embeddingsDoc.push({
          id: `${rel}#${i}`,
          file: rel,
          chunk_index: i,
          text: chunk,
          metadata: frontmatter || {},
          embedding,
        });
      } catch (err) {
        console.error("Embedding failed for chunk", rel, i, err);
      }
    }
  }

  const body = JSON.stringify({
    model: EMBEDDING_MODEL,
    generated_at: new Date().toISOString(),
    chunk_count: embeddingsDoc.length,
    items: embeddingsDoc,
  });

  await s3.send(
    new PutObjectCommand({
      Bucket: bucket,
      Key: OUTPUT_KEY,
      Body: body,
      ContentType: "application/json",
    })
  );

  console.log("Uploaded embeddings file:", `${bucket}/${OUTPUT_KEY}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
