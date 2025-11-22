# AgentCore Knowledge Base & Enhanced Prompts - Implementation Summary

## Overview

Added comprehensive knowledge base support and enhanced prompt configuration to the AgentCore Terraform module, matching the AWS workshop "Amazon Bedrock AgentCore End-to-End" architecture.

## What Was Added

````terraform
3. Sync data sources to index content
4. Test retrieval: `aws bedrock-agent-runtime retrieve --knowledge-base-id <KB_ID> --retrieval-query "test"`
# AgentCore DIY RAG & Enhanced Prompts - Implementation Summary

## Overview

The previous managed Knowledge Base (OpenSearch Serverless + Bedrock KB) has been removed to eliminate high baseline costs. It is replaced by a lightweight Retrieval Augmented Generation (RAG) pattern using:

- S3 bucket storing a single `embeddings.json`
- Titan Embed Text v2 at ingestion and query time only
- Simple cosine similarity inside Lambda

Enhanced prompt configuration remains unchanged.

## Current Capabilities

1. Agent runtime with inference parameter overrides
2. Memory (DynamoDB) for conversation persistence
3. Lambda tool integration via Gateway
4. DIY RAG optional enablement (`agentcore_rag_enabled`)
5. SSM parameters for runtime & bucket references

## Prompt Configuration (Unchanged)

```terraform
prompt_override_configuration {
  prompt_configurations {
    prompt_type = "ORCHESTRATION"
    inference_configuration {
      temperature = 0.7
      top_p       = 0.9
      top_k       = 250
      max_length  = 2048
    }
  }
}
````

## DIY RAG Variables

Added module & root variables:

- `agentcore_rag_enabled` (bool)
- `agentcore_rag_bucket_name` (optional override; auto-generated if blank)

## RAG Ingestion Flow

1. Author markdown docs (`./docs` or chosen folder)
2. Run ingestion script to chunk & embed

```bash
npm install @aws-sdk/client-bedrock-runtime @aws-sdk/client-s3 @aws-sdk/client-ssm gray-matter glob
node scripts/rag_ingest.js --source ./docs
```

3. Script uploads `embeddings/embeddings.json` to S3 bucket
4. Lambda loads JSON (first request) → caches in memory → performs similarity
5. Top-k chunk texts appended to agent input

## Lambda Retrieval Outline

Pseudo-flow:

```javascript
// 1. Load cached embeddings (global scope)
// 2. Embed user query via Titan
// 3. Cosine similarity across vectors
// 4. Select top K
// 5. Concatenate chunk texts into agent invocation inputText
```

See `AGENTCORE_QUICK_REF.md` for full example snippet.

## Cost Comparison

| Approach                | Baseline    | Monthly (Small Corpus) |
| ----------------------- | ----------- | ---------------------- |
| Managed KB (OpenSearch) | High (OCUs) | $60-100+               |
| DIY RAG (S3 + Titan)    | Near-zero   | $10-30 (total stack)   |

Savings derive from removing persistent OpenSearch OCUs.

## Removed Components

- OpenSearch Serverless collection
- Bedrock Knowledge Base resource
- KB SSM parameter & outputs
- KB IAM statements

## Updated Files

1. `modules/agentcore/main.tf` – Added S3 bucket + removed KB resources
2. `modules/agentcore/variables.tf` – Removed KB vars, added RAG vars
3. `modules/agentcore/iam.tf` – Removed KB/OpenSearch policy, added S3 read permissions
4. `modules/agentcore/outputs.tf` – Removed KB outputs, added `rag_bucket_name`
5. `agentcore.tf` – Passed new RAG vars to module
6. `variables.tf` – Added `agentcore_rag_enabled`, `agentcore_rag_bucket_name`
7. `outputs.tf` – Added `agentcore_rag_bucket_name`
8. `scripts/rag_ingest.js` – New ingestion script
9. `AGENTCORE_DEPLOYMENT.md` – Replaced KB section with DIY RAG

## Minimal Configuration (No RAG)

```terraform
agentcore_rag_enabled = false
```

## Enable DIY RAG

```terraform
agentcore_rag_enabled     = true
agentcore_rag_bucket_name = "" # auto-generate
```

## Migration Notes

All former KB outputs/parameters removed; downstream code referencing them must switch to:

- Runtime invocation unchanged
- Retrieval now performed manually before invoking AgentCore

## Next Steps

1. Populate docs directory with source markdown
2. Run ingestion script
3. Add similarity retrieval code to Lambda
4. Monitor S3 & Titan usage (CloudWatch / Cost Explorer)
5. Tune chunk size & top-k for relevance/performance

## Support & References

- `AGENTCORE_DEPLOYMENT.md` – Full deployment guide
- `AGENTCORE_QUICK_REF.md` – RAG ingestion + Lambda snippets
- AWS Bedrock Runtime (Titan embeddings & Claude model)

**Last Updated**: November 22, 2025
