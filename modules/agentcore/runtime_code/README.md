# AgentCore Runtime Code

This directory contains the runtime code that AgentCore deploys as a containerized service.

## What's Here

- **main.py**: HTTP server entrypoint with `@app.entrypoint` decorator
- **requirements.txt**: Python dependencies for the runtime container

## How It Works

1. **Terraform** uploads this code to S3 (zipped)
2. **AgentCore Runtime** pulls the code from S3
3. **CodeBuild** builds a Docker container with this code
4. **ECR** stores the container image
5. **AgentCore** deploys the container and routes traffic to it

## Current Status

This is a **production-ready runtime** that:

- ✅ Satisfies AgentCore's artifact requirement
- ✅ Responds to `/invocations` and `/ping` endpoints
- ✅ Reads environment variables from Terraform
- ✅ Logs to CloudWatch
- ✅ Invokes Bedrock models via Strands Agent
- ✅ Includes two customer support tools (get_product_info, get_return_policy)
- ⚠️ Memory integration ready but not enabled (requires memory_id)
- ⚠️ Gateway integration ready but not enabled (requires gateway auth)

## To Deploy Your Actual Agent

The runtime code is ready! To deploy:

### Step 1: Package the runtime code

```bash
cd modules/agentcore/runtime_code
./package.sh
```

### Step 2: Upload to S3

Create an S3 bucket (or use existing) and upload:

```bash
aws s3 mb s3://YOUR-AGENTCORE-BUCKET
aws s3 cp ../runtime_code.zip s3://YOUR-AGENTCORE-BUCKET/agent-runtime/code.zip
```

### Step 3: Update Terraform variables

In your Terraform Cloud workspace or `terraform.tfvars`:

```hcl
agent_runtime_code_bucket = "YOUR-AGENTCORE-BUCKET"
agent_runtime_code_prefix = "agent-runtime/code.zip"
```

### Step 4: Deploy via Terraform

```bash
cd ../../..  # Back to terraform root
terraform init -upgrade
terraform apply
```

AgentCore will:

1. Pull your code from S3
2. Build a Docker container with CodeBuild
3. Push to ECR
4. Deploy as a scalable runtime
5. Route traffic to your agent

## Environment Variables

Terraform passes these via `environment_variables` block:
- `FOUNDATION_MODEL`: Model ID (e.g., `anthropic.claude-3-5-sonnet-20240620-v1:0`)
- `AGENT_INSTRUCTION`: System prompt for the agent
- `RAG_BUCKET`: S3 bucket for DIY RAG embeddings

## Testing Locally

You can test the runtime locally before deploying:

```bash
cd runtime_code
pip install -r requirements.txt
export FOUNDATION_MODEL="claude-3-5-sonnet"
export AGENT_INSTRUCTION="You are helpful"
export RAG_BUCKET="my-rag-bucket"
python main.py
```

Then in another terminal:
```bash
curl -X POST http://localhost:8080/invocations \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Hello, are you working?"}'
```

## Production Integration Example

See the workshop lab files for a full example:
- `lab-04-agentcore-runtime.ipynb`: Full integration with Strands + Memory + Gateway
- `lab_helpers/lab4_runtime.py`: Complete production-ready code

The workshop shows how to:
- Connect to AgentCore Gateway for shared tools
- Use AgentCore Memory for conversation history
- Propagate JWT tokens for authentication
- Handle errors gracefully
- Return streaming responses
