# AgentCore Runtime Deployment Guide

## Quick Start

Your runtime code is ready in `runtime_code/`. Follow these steps to deploy:

### 1. Package Runtime Code

```bash
cd modules/agentcore/runtime_code
chmod +x package.sh
./package.sh
```

This creates `runtime_code.zip` with your agent application.

### 2. Create S3 Bucket for Runtime Artifacts

```bash
# Create bucket (or use existing)
aws s3 mb s3://YOUR-AGENTCORE-ARTIFACTS

# Upload runtime code
aws s3 cp ../runtime_code.zip s3://YOUR-AGENTCORE-ARTIFACTS/agent-runtime/code.zip
```

### 3. Configure Terraform Variables

Update your Terraform Cloud workspace variables or create `terraform.tfvars`:

```hcl
# Required: Point to your S3 runtime code
agent_runtime_code_bucket = "YOUR-AGENTCORE-ARTIFACTS"
agent_runtime_code_prefix = "agent-runtime/code.zip"

# Optional: Customize agent behavior
foundation_model     = "anthropic.claude-3-5-sonnet-20240620-v1:0"
agent_instruction    = "You are a helpful customer support assistant."
agent_description    = "Customer support agent for charlesmbrady.com"

# Optional: Enable DIY RAG
rag_enabled         = true
rag_bucket_name     = ""  # Auto-generated if empty
```

### 4. Deploy via Terraform

```bash
cd ../..  # Back to terraform root
terraform init -upgrade
terraform plan
terraform apply
```

## What Happens During Deployment

1. **Terraform creates**:
   - AgentCore Runtime resource
   - IAM execution role
   - DynamoDB table (if memory enabled)
   - S3 bucket (if RAG enabled)
   - CloudWatch log group

2. **AgentCore automatically**:
   - Creates CodeBuild project
   - Pulls your code from S3
   - Builds Docker container
   - Pushes to ECR
   - Deploys scalable runtime
   - Configures health checks

3. **You get**:
   - Fully managed HTTP endpoint
   - Auto-scaling (0 to N instances)
   - CloudWatch observability
   - Session management
   - Production-ready agent

## Runtime Code Architecture

```
runtime_code/
├── main.py              # Entrypoint with @app.entrypoint
├── requirements.txt     # Python dependencies
├── package.sh          # Packaging script
└── README.md           # Detailed documentation
```

### main.py Structure

```python
from bedrock_agentcore.runtime import BedrockAgentCoreApp
from strands import Agent

app = BedrockAgentCoreApp()

@app.entrypoint
async def invoke(payload, context=None):
    user_input = payload.get("prompt", "")
    # Your agent logic here
    agent = Agent(model=model, tools=tools, system_prompt=prompt)
    response = agent(user_input)
    return response.message["content"][0]["text"]

if __name__ == "__main__":
    app.run()  # Starts HTTP server on port 8080
```

## Environment Variables

Terraform passes these to your runtime container:

- `FOUNDATION_MODEL`: Bedrock model ID
- `AGENT_INSTRUCTION`: System prompt
- `RAG_BUCKET`: S3 bucket for embeddings (if enabled)
- `AWS_REGION`: Auto-set by AgentCore
- `AWS_DEFAULT_REGION`: Auto-set by AgentCore

Access in code: `os.environ.get("FOUNDATION_MODEL")`

## Testing Locally

Before deploying, test locally:

```bash
cd runtime_code
pip install -r requirements.txt

export FOUNDATION_MODEL="anthropic.claude-3-5-sonnet-20240620-v1:0"
export AGENT_INSTRUCTION="You are helpful"
export RAG_BUCKET="my-rag-bucket"

python main.py
```

In another terminal:

```bash
curl -X POST http://localhost:8080/invocations \
  -H "Content-Type: application/json" \
  -d '{"prompt": "What laptops do you have?"}'
```

## Updating Runtime Code

To update your deployed agent:

1. Edit `runtime_code/main.py`
2. Re-package: `./package.sh`
3. Upload to S3: `aws s3 cp ../runtime_code.zip s3://YOUR-BUCKET/agent-runtime/code.zip`
4. Update runtime: `terraform apply` (triggers rebuild)

Or use Terraform variables to force update:

```hcl
# In variables or .tfvars
agent_runtime_code_version = "v2"  # Increment to trigger rebuild
```

## Adding More Tools

Edit `main.py` to add tools:

```python
@tool
def check_order_status(order_id: str) -> str:
    """Check the status of a customer order."""
    # Your logic here
    return f"Order {order_id} status: Shipped"

# Add to agent
tools = [
    get_product_info,
    get_return_policy,
    check_order_status,  # New tool
]
```

## Integrating Memory (Future)

To add conversation memory:

1. Set `enable_memory = true` in Terraform
2. Update `main.py` to use memory hooks:

```python
from bedrock_agentcore.memory import MemoryClient

memory_id = os.environ.get("MEMORY_ID")
# Configure memory integration (see lab2_memory.py example)
```

3. Terraform will pass `MEMORY_ID` as environment variable

## Integrating Gateway (Future)

To connect to shared tools via Gateway:

1. Deploy Gateway separately (see lab3 example)
2. Update `main.py` to use MCP client:

```python
from strands.tools.mcp import MCPClient

auth_header = context.request_headers.get("Authorization", "")
gateway_url = os.environ.get("GATEWAY_URL")

mcp_client = MCPClient(lambda: streamablehttp_client(
    url=gateway_url,
    headers={"Authorization": auth_header}
))
```

3. Add gateway tools to agent

## Monitoring

After deployment, monitor via:

- **CloudWatch Logs**: `/aws/bedrock/agentcore/{runtime-name}`
- **CloudWatch Metrics**: AgentCore namespace
- **GenAI Observability**: CloudWatch → GenAI Observability → Bedrock AgentCore

## Troubleshooting

### CodeBuild fails

Check build logs: AWS Console → CodeBuild → Build history

Common issues:

- Missing dependencies in `requirements.txt`
- Python syntax errors in `main.py`
- S3 bucket permissions

### Runtime unhealthy

Check CloudWatch logs for errors:

```bash
aws logs tail /aws/bedrock/agentcore/{runtime-name} --follow
```

### Model invocation fails

Verify:

- Bedrock model access enabled in your account
- IAM role has `bedrock:InvokeModel` permission
- Model ID matches available models

## Cost Optimization

- **Runtime**: Only pay when invoked (no idle charges)
- **Memory**: DynamoDB on-demand pricing
- **RAG**: S3 Standard or Intelligent-Tiering
- **Logs**: Set retention to 7-30 days

## Next Steps

1. Deploy the basic runtime (this guide)
2. Test with sample queries
3. Add Memory integration (optional)
4. Add Gateway integration (optional)
5. Create frontend application (lab 5)

See workshop labs for complete examples:

- `lab-04-agentcore-runtime.ipynb`: Full production deployment
- `lab_helpers/lab4_runtime.py`: Complete runtime with Memory + Gateway
