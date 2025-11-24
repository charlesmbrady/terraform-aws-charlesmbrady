# AgentCore Runtime Code - Summary

## What You Now Have

✅ **Production-ready runtime code** in `runtime_code/`:

- `main.py`: Full Strands Agent with tools (get_product_info, get_return_policy)
- `requirements.txt`: All dependencies (bedrock-agentcore, strands-agents, boto3, etc.)
- `package.sh`: Script to zip and prepare for deployment
- `README.md`: Detailed technical documentation
- `RUNTIME_DEPLOYMENT.md`: Step-by-step deployment guide

## What Runtime Code Actually Does

Based on the workshop (lab4_runtime.py), runtime code is **your agent application wrapped in an HTTP server** that:

1. **Receives HTTP requests** at `/invocations` endpoint

   - Payload: `{"prompt": "user question"}`
   - Headers: `Authorization: Bearer <jwt-token>`

2. **Extracts environment variables** from Terraform:

   - `FOUNDATION_MODEL`: Which Bedrock model to use
   - `AGENT_INSTRUCTION`: System prompt
   - `RAG_BUCKET`: S3 bucket for embeddings

3. **Invokes your Strands Agent**:

   - Creates agent with model + tools + system prompt
   - Processes user query
   - Returns text response

4. **Handles health checks** at `/ping` endpoint

5. **Logs to CloudWatch** for observability

## How It Works with Terraform

```
Terraform creates:           AgentCore does:
┌─────────────────────┐     ┌──────────────────────┐
│ Runtime resource    │────▶│ Creates CodeBuild    │
│ IAM role            │     │ Pulls code from S3   │
│ S3 code reference   │     │ Builds Docker image  │
│ Environment vars    │     │ Pushes to ECR        │
└─────────────────────┘     │ Deploys containers   │
                            │ Auto-scales 0→N      │
                            └──────────────────────┘
                                      │
                                      ▼
                            Your agent handles requests!
```

## What the Workshop Shows

The workshop demonstrates the complete journey:

### Lab 1: Local Prototype

- Basic Strands Agent
- Tools: get_product_info, get_return_policy, web_search
- Runs on your laptop

### Lab 2: Add Memory

- AgentCore Memory for conversation history
- Semantic + preference strategies
- Persists across sessions

### Lab 3: Add Gateway

- AgentCore Gateway for shared tools
- MCP protocol integration
- JWT authentication
- Centralized tool management

### Lab 4: Deploy to Production ⭐ (This is what we're building)

- **Runtime code** (main.py with BedrockAgentCoreApp)
- Containerized deployment
- Auto-scaling
- CloudWatch observability
- Production-ready

### Lab 5: Add Frontend

- Streamlit web UI
- User authentication
- Real-time streaming
- Session management

## Your Current Runtime Code

Your `main.py` is a **simplified version of Lab 4** that:

✅ Uses BedrockAgentCoreApp framework
✅ Has @app.entrypoint decorator
✅ Reads environment variables from Terraform
✅ Invokes Bedrock via Strands Agent
✅ Includes two core tools
✅ Logs to CloudWatch
✅ Returns text responses

⚠️ Does NOT yet include:

- Memory integration (can add later)
- Gateway/MCP integration (can add later)
- Web search tool (requires external API)

## How to Deploy

See `RUNTIME_DEPLOYMENT.md` for full steps. Quick version:

```bash
# 1. Package
cd modules/agentcore/runtime_code
./package.sh

# 2. Upload to S3
aws s3 mb s3://my-agentcore-artifacts
aws s3 cp ../runtime_code.zip s3://my-agentcore-artifacts/agent-runtime/code.zip

# 3. Configure Terraform
# In Terraform Cloud workspace or terraform.tfvars:
agent_runtime_code_bucket = "my-agentcore-artifacts"
agent_runtime_code_prefix = "agent-runtime/code.zip"

# 4. Deploy
terraform apply
```

## What Happens During Deployment

1. Terraform creates `aws_bedrockagentcore_agent_runtime` resource
2. AgentCore sees S3 reference in `agent_runtime_artifact` block
3. AgentCore automatically:

   - Creates CodeBuild project
   - Downloads your code from S3
   - Generates Dockerfile
   - Builds container image
   - Pushes to ECR (auto-created)
   - Deploys as scalable runtime
   - Configures /invocations and /ping endpoints

4. You get a production endpoint that auto-scales!

## Testing After Deployment

```bash
# Get runtime ARN from Terraform outputs
RUNTIME_ARN=$(terraform output -raw agentcore_runtime_arn)

# Invoke via AWS CLI (if no auth required)
aws bedrock-agentcore-runtime invoke-agent-runtime \
  --agent-runtime-id ${RUNTIME_ARN##*/} \
  --input-text "What laptops do you have?" \
  response.txt

cat response.txt
```

Or use the workshop's starter toolkit (Python):

```python
from bedrock_agentcore_starter_toolkit import Runtime

runtime = Runtime()
response = runtime.invoke({"prompt": "What laptops do you have?"})
print(response)
```

## Extending Your Runtime

### Add More Tools

Edit `main.py`, add tool function with `@tool` decorator, include in `tools` list.

### Add Memory

1. Set `enable_memory = true` in Terraform
2. Update `main.py` to import memory hooks (see lab2_memory.py)
3. Pass memory_id via environment variable

### Add Gateway

1. Deploy gateway separately (future enhancement)
2. Update `main.py` to use MCPClient (see lab4_runtime.py full example)
3. Pass gateway URL + auth via environment/headers

### Add Web Search

```python
from ddgs import DDGS

@tool
def web_search(keywords: str) -> str:
    results = DDGS().text(keywords, max_results=5)
    return results

# Add to tools list
tools = [get_product_info, get_return_policy, web_search]
```

Don't forget to add `ddgs` to requirements.txt!

## Comparison: Workshop vs Your Setup

| Aspect        | Workshop (lab4_runtime.py) | Your Runtime (main.py)          |
| ------------- | -------------------------- | ------------------------------- |
| Framework     | BedrockAgentCoreApp ✅     | BedrockAgentCoreApp ✅          |
| Bedrock Model | Claude via Strands ✅      | Claude via Strands ✅           |
| Tools         | 3 local + gateway tools    | 2 local tools ✅                |
| Memory        | AgentCore Memory ✅        | Not yet (ready to add)          |
| Gateway       | MCP client ✅              | Not yet (ready to add)          |
| Auth          | JWT propagation ✅         | Ready (context.request_headers) |
| Config        | SSM parameters             | Environment variables ✅        |
| Deployment    | Manual (workshop)          | Terraform ✅                    |
| Observability | CloudWatch ✅              | CloudWatch ✅                   |

## Key Differences from Workshop

1. **Configuration**: Workshop uses SSM parameter lookups; yours uses env vars from Terraform (cleaner!)
2. **Tools**: Workshop has gateway integration; yours is local-only (simpler for now)
3. **Memory**: Workshop has full memory hooks; yours is ready but not enabled
4. **Deployment**: Workshop uses starter toolkit CLI; yours uses Terraform (IaC!)

## Next Steps

1. ✅ **Deploy basic runtime** (this guide)
2. Test with sample queries
3. Monitor in CloudWatch
4. Optional: Add Memory (enable_memory = true)
5. Optional: Add Gateway (deploy gateway resources)
6. Optional: Add more tools (edit main.py)
7. Build frontend (lab 5 example)

## Questions?

- **"Do I need Memory?"** - No, optional. Adds conversation persistence.
- **"Do I need Gateway?"** - No, optional. Enables shared tools across agents.
- **"Can I use different tools?"** - Yes! Edit main.py, add @tool functions.
- **"How do I update code?"** - Re-package, upload to S3, terraform apply.
- **"What's the cost?"** - Pay per invocation, no idle charges.

## Resources

- Workshop: `lab-04-agentcore-runtime.ipynb`
- Full runtime example: `lab_helpers/lab4_runtime.py`
- Deployment guide: `RUNTIME_DEPLOYMENT.md`
- Runtime code: `runtime_code/`
- AWS Docs: [AgentCore Runtime](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/agents-tools-runtime.html)
