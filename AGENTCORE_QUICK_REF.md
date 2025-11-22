# AgentCore Quick Reference

## Enable DIY RAG (Lightweight Retrieval)

**File**: `environments/test/main.tf`

```terraform
module "main" {
  source = "../../"

  # ... existing config ...

  # Optional lightweight RAG (S3 + embeddings JSON)
  agentcore_rag_enabled     = true
  agentcore_rag_bucket_name = "" # auto-generate if blank
}
```

## Deploy

```bash
cd environments/test
tofu init
tofu plan
tofu apply
```

tofu output -raw agentcore_knowledge_base_id

## RAG Ingestion

```bash
npm install @aws-sdk/client-bedrock-runtime @aws-sdk/client-s3 @aws-sdk/client-ssm gray-matter glob
node scripts/rag_ingest.js --source ./docs

# Optional explicit bucket
node scripts/rag_ingest.js --source ./docs --bucket my-rag-bucket
```

## Configure Inference Parameters

**File**: `modules/agentcore/main.tf`

```terraform
prompt_override_configuration {
  prompt_configurations {
    prompt_type = "ORCHESTRATION"

    inference_configuration {
      temperature = 0.7   # 0.0-1.0 (higher = more creative)
      top_p       = 0.9   # 0.0-1.0 (nucleus sampling)
      top_k       = 250   # 1-500 (token diversity)
      max_length  = 2048  # Max response tokens
    }
  }
}
```

## Lambda Retrieval Outline

```javascript
// Pseudocode inside Lambda handler
// Load embeddings once (global scope cache)
if (!global.embeddings) {
  const s3Data = await s3.getObject({
    Bucket,
    Key: "embeddings/embeddings.json",
  });
  global.embeddings = JSON.parse(await streamToString(s3Data.Body));
}

// Embed query
const embedResp = await bedrockRuntime.invokeModel({
  modelId: "amazon.titan-embed-text-v2:0",
  body: JSON.stringify({ inputText: event.query }),
});
const queryVec = JSON.parse(embedResp.body).embedding;

// Similarity
const scored = global.embeddings
  .map((e) => ({
    score: cosine(queryVec, e.embedding),
    text: e.text,
  }))
  .sort((a, b) => b.score - a.score)
  .slice(0, 3);

// Augment input
const augmented = scored.map((s) => s.text).join("\n---\n");
// Pass augmented context to AgentCore InvokeAgentCommand.
```

## Test Embedding Call (Direct)

```bash
aws bedrock-runtime invoke-model \
  --model-id amazon.titan-embed-text-v2:0 \
  --body '{"inputText":"Sample query"}' \
  --region us-east-1 \
  --content-type application/json
```

## Test Agent (Invocation)

```bash
RUNTIME_ID=$(tofu output -raw agentcore_runtime_id)

aws bedrock-agent-runtime invoke-agent \
  --region us-east-1 \
  --agent-id $RUNTIME_ID \
  --agent-alias-id DEFAULT \
  --session-id test-$(date +%s) \
  --input-text "What features are available?"
```

## Cost Snapshot

| Component            | Driver               | Est. Monthly |
| -------------------- | -------------------- | ------------ |
| AgentCore Runtime    | Tokens & invocations | $5-20        |
| DIY RAG (S3 + Titan) | Storage + embeddings | <$2          |
| Lambda               | Requests             | <$1          |
| DynamoDB             | On-demand            | <$1          |
| CloudWatch Logs      | Storage              | <$5          |
| API Gateway          | Per call             | <$1          |

No persistent vector infra baseline.

## Monitoring

### CloudWatch Logs

```bash
# AgentCore logs
aws logs tail /aws/bedrock/agentcore/charlesmbrady-assistant-Test --follow

# Lambda logs
aws logs tail /aws/lambda/charlesmbrady_api_services_Test --follow
```

### DynamoDB Conversation History

```bash
TABLE_NAME=$(tofu output -raw agentcore_memory_table_name)

aws dynamodb scan \
  --table-name $TABLE_NAME \
  --max-items 10 \
  --region us-east-1
```

## Useful Outputs

```bash
# All AgentCore outputs
tofu output | grep agentcore

# Specific outputs
tofu output -raw agentcore_runtime_id
tofu output -raw agentcore_endpoint_url
tofu output -raw agentcore_gateway_id
tofu output -raw agentcore_memory_table_name
tofu output -raw agentcore_rag_bucket_name
```

## SSM Parameters

The following parameters are automatically created:

- `/charlesmbrady/Test/agentcore/runtime-id`
- `/charlesmbrady/Test/agentcore/runtime-arn`
- `/charlesmbrady/Test/agentcore/endpoint-url`
- `/charlesmbrady/Test/agentcore/gateway-id`
- `/charlesmbrady/Test/agentcore/qualifier`
- `/charlesmbrady/Test/agentcore/rag-bucket-name` (if RAG enabled)

Access from Lambda:

```javascript
const { SSMClient, GetParameterCommand } = require("@aws-sdk/client-ssm");

const ssm = new SSMClient({ region: "us-east-1" });
const param = await ssm.send(
  new GetParameterCommand({
    Name: "/charlesmbrady/Test/agentcore/runtime-id",
  })
);

const runtimeId = param.Parameter.Value;
```

## Troubleshooting

### RAG Retrieval Issues

1. Confirm bucket exists: `tofu output -raw agentcore_rag_bucket_name`
2. Check object path: `aws s3 ls s3://<bucket>/embeddings/`
3. Validate JSON integrity: `aws s3 cp s3://<bucket>/embeddings/embeddings.json - | jq length`
4. Re-run ingestion after doc changes.

## Key Resources

- **Module**: `modules/agentcore/`
- **Root Config**: `agentcore.tf`
- **Variables**: `variables.tf` (search for `agentcore_`)
- **Outputs**: `outputs.tf` (search for `agentcore_`)
- **Documentation**: `AGENTCORE_DEPLOYMENT.md`
- **Summary**: `AGENTCORE_KB_PROMPTS_SUMMARY.md`

## Default Values

```terraform
agentcore_agent_name                       = "assistant"
agentcore_agent_description                = "AI assistant for the charlesmbrady.com platform"
agentcore_agent_instruction                = "You are a helpful assistant..."
agentcore_foundation_model                 = "anthropic.claude-3-5-sonnet-20240620-v1:0"
agentcore_enable_memory                    = true
agentcore_memory_retention_days            = 30
agentcore_rag_enabled                      = false
agentcore_rag_bucket_name                  = ""
```

## Resources Created

### Always Created

1. `aws_bedrockagentcore_agent_runtime.main`
2. `aws_bedrockagentcore_runtime_endpoint.default`
3. `aws_bedrockagentcore_gateway.main`
4. `aws_bedrockagentcore_gateway_tool.lambda_tool`
5. `aws_bedrockagentcore_memory.main` (if `enable_memory = true`)
6. `aws_dynamodb_table.agentcore_memory`
7. `aws_iam_role.agentcore_runtime`
8. `aws_iam_policy.agentcore_runtime`
9. `aws_cloudwatch_log_group.agentcore`
10. 5x `aws_ssm_parameter.*`

### Conditionally Created (DIY RAG)

1. S3 bucket (embeddings storage)
2. RAG bucket name SSM parameter

**Total**: 10-12 resources depending on configuration
