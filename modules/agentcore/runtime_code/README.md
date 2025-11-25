# AgentCore Runtime Code

This directory contains the Python runtime code deployed by Terraform to AWS Bedrock AgentCore.

## Structure

- **main.py**: Production runtime with Strands Agent framework and tools
- **requirements.txt**: Python dependencies (workshop-aligned versions)
- **rebuild_vendored.sh**: Script to install deps into `vendored/` subdirectory
- **.gitignore**: Excludes vendored packages and build artifacts from git

## How It Works

1. **Terraform** zips this directory using `archive_file` data source
2. **Terraform** uploads zip to S3 runtime code bucket
3. **AgentCore Runtime** pulls code from S3, builds container, and deploys
4. Runtime starts HTTP server listening on port 8080

## Environment Variables (Set by Terraform)

- `FOUNDATION_MODEL`: Bedrock model ID (e.g., `anthropic.claude-3-5-sonnet-20240620-v1:0`)
- `AGENT_INSTRUCTION`: System prompt for the agent
- `RAG_BUCKET`: S3 bucket name for RAG embeddings (if enabled)

## Current Features

✅ Strands Agent with Bedrock model invocation
✅ Two tools: `get_product_info`, `get_return_policy`
✅ CloudWatch logging
✅ Graceful error handling
✅ Support for vendored dependencies

## Deployment Workflow

### Option 1: Let Terraform Handle Everything (Simple)

```bash
# From terraform root
cd /Users/charlesbrady/Desktop/Charlava_25/terraform-aws-charlesmbrady
terraform apply
```

Terraform will automatically:

- Zip runtime_code directory
- Upload to S3
- Trigger AgentCore runtime update

### Option 2: Manual Dependency Install + Override (Advanced)

Use this when you need ARM64-specific wheels or want full control:

```bash
# 1. Install dependencies into vendored/
cd modules/agentcore/runtime_code
chmod +x rebuild_vendored.sh
./rebuild_vendored.sh

# 2. Package everything
zip -r runtime_code.zip main.py vendored -x "*.pyc" "__pycache__/*"

# 3. Upload to S3 (overrides Terraform-managed object)
aws s3 cp runtime_code.zip s3://charlesmbrady-assistant-test-runtime-code/agent-runtime/code.zip

# 4. Force runtime recreation
cd ../../..
terraform taint module.agentcore.aws_bedrockagentcore_agent_runtime.main
terraform apply
```

## Updating the Agent

1. Edit `main.py` (add/modify tools or logic)
2. Run `terraform apply` or use Option 2 workflow above
3. Monitor CloudWatch logs: `/aws/bedrock-agentcore/runtimes/`

## Testing Locally

```bash
pip install -r requirements.txt
export FOUNDATION_MODEL="anthropic.claude-3-5-sonnet-20240620-v1:0"
export AGENT_INSTRUCTION="You are a helpful assistant."
export RAG_BUCKET="your-rag-bucket"
python main.py
```

Then test:

```bash
curl -X POST http://localhost:8080/invocations \
  -H "Content-Type: application/json" \
  -d '{"input": "What laptops do you have?"}'
```

## Adding Tools

Edit `main.py` and add a function decorated with `@tool`:

```python
@tool
def check_order_status(order_id: str) -> str:
    """Check order status by ID."""
    # Your logic here
    return f"Order {order_id}: Shipped"

# Add to tools list in invoke() function
tools = [get_product_info, get_return_policy, check_order_status]
```

Then redeploy with `terraform apply`.

## Troubleshooting

**No CloudWatch logs appearing:**

- Check IAM role has `logs:CreateLogStream` and `logs:PutLogEvents`
- Verify runtime actually started (check AgentCore console)

**Import errors in container:**

- Use `rebuild_vendored.sh` to ensure ARM64-compatible wheels
- Check `requirements.txt` has correct pinned versions

**Runtime fails to update:**

- Use `terraform taint module.agentcore.aws_bedrockagentcore_agent_runtime.main`
- Then `terraform apply` to force recreation

**Region showing as None:**

- Already fixed in main.py with fallback logic
- Container will use AWS_REGION or AWS_DEFAULT_REGION env vars
