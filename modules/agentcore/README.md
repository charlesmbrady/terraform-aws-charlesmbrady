# AgentCore Module

AWS Bedrock AgentCore runtime with containerized deployment.

## Overview

This module deploys a Bedrock AgentCore agent runtime using a custom container image:

- **Container**: Built by CodeBuild, stored in ECR
- **Runtime**: Bedrock AgentCore with custom Python agent
- **Gateway**: MCP protocol with IAM auth
- **Memory**: DynamoDB-backed conversation state
- **Tools**: Lambda function integration for extended capabilities

## Architecture

```
User Request
    ↓
AgentCore Gateway (MCP + IAM Auth)
    ↓
AgentCore Runtime (Container: my_agent.py)
    ↓
Bedrock Foundation Model (Claude 3.5 Sonnet)
    ↓
Optional: Tool Lambda (custom actions)
    ↓
Response
```

## Quick Start

### Deploy Infrastructure

```bash
# From root terraform directory
terraform init
terraform apply
```

### Update Agent Code

Agent logic is in `main.tf` buildspec (inline `my_agent.py`). After changes:

```bash
# 1. Apply terraform
terraform apply

# 2. Rebuild container
aws codebuild start-build \
  --project-name "charlesmbrady-assistant-Test-basic-agent-build" \
  --region us-east-1

# 3. Recreate runtime in AWS Console
# Bedrock → AgentCore → Runtimes → Delete → Create new
```

See **[DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)** for detailed instructions.

## Module Structure

```
modules/agentcore/
├── DEPLOYMENT_GUIDE.md      # Complete deployment workflow
├── main.tf                   # Core resources + buildspec
├── iam.tf                    # IAM roles and policies
├── dynamodb.tf               # Memory table
├── variables.tf              # Input variables
├── outputs.tf                # Module outputs
├── versions.tf               # Provider requirements
└── runtime_code/
    └── main.py               # (Not used - code is in buildspec)
```

## Variables

Key variables (defined in root `variables.tf`):

| Variable                      | Description                | Default                                     |
| ----------------------------- | -------------------------- | ------------------------------------------- |
| `agentcore_agent_name`        | Agent runtime name         | `assistant`                                 |
| `agentcore_agent_instruction` | System prompt              | `You are a helpful assistant...`            |
| `agentcore_foundation_model`  | Bedrock model ID           | `anthropic.claude-3-5-sonnet-20240620-v1:0` |
| `agentcore_enable_memory`     | Enable conversation memory | `true`                                      |
| `agentcore_rag_enabled`       | Enable DIY RAG             | `false`                                     |

## Outputs

| Output              | Description                    |
| ------------------- | ------------------------------ |
| `runtime_name`      | AgentCore runtime name         |
| `iam_role_arn`      | Runtime IAM role ARN           |
| `memory_table_name` | DynamoDB table for memory      |
| `rag_bucket_name`   | S3 bucket for RAG (if enabled) |
| `agentcore_name`    | Generated agent name           |

## Agent Capabilities

Current agent supports:

- **Product Information**: Technical specs for electronics (laptops, smartphones, headphones, monitors)
- **Return Policies**: Return windows and conditions by category
- **Help/Capabilities**: Lists what the agent can do

### Customizing Capabilities

Edit `main.tf` → Search for `cat > my_agent.py` → Modify:

```python
# System prompt
SYSTEM_PROMPT = os.getenv("AGENT_INSTRUCTION", "...")

# Capabilities list
CAPABILITIES_TEXT = "I can help you with:\n• Your feature\n..."

# Intent routing
def handle_structured_query(query: str) -> str:
    if "your_keyword" in query.lower():
        return "Your custom response"
```

Then redeploy (terraform → codebuild → recreate runtime).

## CloudWatch Logs

Logs location: `/aws/bedrock-agentcore/runtimes/<runtime-id>-<name>/runtime-logs`

Debug log format:

```json
{"level": "DEBUG", "msg": "Raw payload: {...}", "ts": "..."}
{"level": "DEBUG", "msg": "Extracted query: What can you help me with?", "ts": "..."}
{"level": "DEBUG", "msg": "Routed response (pre-LLM): ...", "ts": "..."}
```

Tail logs:

```bash
aws logs tail "/aws/bedrock-agentcore/runtimes/<runtime-id>/runtime-logs" \
  --follow --region us-east-1
```

## Testing

**AWS Console**:

1. Bedrock → AgentCore → Runtimes → `charlesmbrady_assistant_Test`
2. Test tab
3. Payload: `{"input": "What can you help me with?"}`

**Expected response**:

```json
{
  "status": "success",
  "response": "I can help you with:\n• Product technical specifications...",
  "elapsed_sec": 0.842
}
```

## Resources Created

- `aws_bedrockagentcore_agent_runtime.main` - AgentCore runtime
- `aws_bedrockagentcore_gateway.main` - MCP gateway with IAM auth
- `aws_bedrockagentcore_memory.main` - Memory store (optional)
- `aws_dynamodb_table.agentcore_memory` - Memory persistence
- `aws_codebuild_project.basic_agent_image` - Container builder
- `aws_ecr_repository.basic_agent` - Container registry
- `aws_iam_role.agentcore_runtime` - Runtime execution role
- `aws_s3_bucket.rag_embeddings` - RAG storage (optional)

## Costs

Estimated monthly costs (us-east-1, Test environment):

- **AgentCore Runtime**: $0 (runtime itself is free)
- **Bedrock Model Invocations**: ~$3-15/1K invocations (Claude 3.5 Sonnet)
- **CodeBuild**: $0.005/min build time (~$0.02 per build)
- **ECR Storage**: ~$0.10/GB/month (image ~500MB)
- **DynamoDB**: $0-5 (on-demand, depends on usage)
- **CloudWatch Logs**: ~$0.50-2 (depends on log volume)

**Total**: ~$5-25/month (mostly Bedrock usage)

## Troubleshooting

### Agent returns old behavior after rebuild

**Solution**: You must manually recreate the runtime in AWS Console. The runtime caches the container image.

### Build fails with Python syntax error

**Check**: Review buildspec syntax in `main.tf`. Python code is embedded as heredoc.

### "Invalid HTTP request" warning in logs

**Impact**: Cosmetic only. Occurs during health checks, doesn't affect functionality.

### No debug logs appearing

**Check**:

- Log group path includes correct runtime ID
- Runtime was recreated (not just redeployed)
- Wait 30-60 seconds for logs to appear

## Future Improvements

- [ ] Move buildspec to separate file for better version control
- [ ] Use Git repo source instead of inline buildspec
- [ ] Add automated runtime recreation (Lambda trigger on ECR push)
- [ ] Implement actual tool integrations (product DB, order API)
- [ ] Add integration tests
- [ ] Multi-region deployment option

## References

- [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) - Detailed deployment steps
- [AWS Bedrock AgentCore Docs](https://docs.aws.amazon.com/bedrock/latest/userguide/agents.html)
- [Strands Framework](https://github.com/aws-samples/strands-agents)

## License

See root repository LICENSE.
