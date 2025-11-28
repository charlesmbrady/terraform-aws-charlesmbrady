# AgentCore Module

AWS Bedrock AgentCore conversational AI runtime with persistent memory, custom tools, and container-based deployment.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [Module Structure](#module-structure)
- [Configuration](#configuration)
- [Agent Capabilities](#agent-capabilities)
- [Deployment](#deployment)
- [Testing](#testing)
- [Monitoring & Logs](#monitoring--logs)
- [Customization](#customization)
- [Troubleshooting](#troubleshooting)
- [Resources Created](#resources-created)
- [Cost Estimates](#cost-estimates)

---

## Overview

This Terraform module deploys a production-ready AWS Bedrock AgentCore agent with:

- **Container-Based Runtime**: ARM64 Docker image built by CodeBuild, stored in ECR
- **Conversational Memory**: Persistent conversation history using Bedrock AgentCore Memory API
- **Custom Tools**: Portfolio-focused tools for discussing projects and technical expertise
- **MCP Gateway**: Model Context Protocol with IAM authentication
- **Portfolio Assistant**: Natural language agent representing Charles Brady's professional work

### Key Features

✅ Persistent memory across conversation sessions  
✅ Custom tools (`get_project_details`, `get_technical_expertise`)  
✅ Automated CodeBuild pipeline for container images  
✅ CloudWatch logging with structured debug output  
✅ IAM-based security with least-privilege policies  
✅ Fully infrastructure-as-code deployment

---

## Architecture

```
Frontend (React AI Chat)
    ↓
Lambda API Service (Cognito-protected)
    ↓
AgentCore Gateway (MCP + IAM Auth)
    ↓
AgentCore Runtime (Docker Container)
    ├── main.py (Agent logic with memory hooks)
    ├── memory_hook_provider.py (Conversation persistence)
    └── Bedrock Foundation Model (Claude 3.5 Sonnet)
    ↓
Memory API (Stores/retrieves conversation history)
    ↓
Response (with session tracking)
```

**Data Flow**:

1. User sends message via React frontend
2. Lambda service invokes AgentCore runtime (passes `sessionId`, `actorId`)
3. Runtime loads conversation history from Memory API
4. Agent processes request with context from previous turns
5. Response generated and saved to memory
6. Frontend receives response with session tracking

---

## Quick Start

### 1. Deploy Infrastructure

```bash
cd /Users/charlesbrady/Desktop/Charlava_25/terraform-aws-charlesmbrady/environments/test

# Initialize Terraform (first time only)
terraform init

# Review changes
terraform plan

# Deploy
terraform apply
```

### 2. Trigger Container Build

After Terraform deploys, manually trigger the CodeBuild project to build the Docker image:

```bash
aws codebuild start-build \
  --project-name charlesmbrady-assistant-Test-basic-agent-build \
  --region us-east-1

# Monitor build progress
aws codebuild batch-get-builds \
  --ids $(aws codebuild list-builds-for-project \
    --project-name charlesmbrady-assistant-Test-basic-agent-build \
    --query 'ids[0]' --output text) \
  --query 'builds[0].buildStatus'
```

Build takes ~5-10 minutes. Once complete, the image is pushed to ECR automatically.

### 3. Update Runtime (If Needed)

If you change the runtime code and rebuild, update the runtime to pull the new image:

```bash
# From Terraform directory
terraform apply -target=module.agentcore.aws_bedrockagentcore_agent_runtime.main
```

### 4. Test the Agent

**Via AWS Console**:

1. Navigate to Bedrock → AgentCore → Runtimes
2. Select `charlesmbrady_assistant_Test`
3. Test tab → Enter prompt: `"Tell me about Charles's AWS expertise"`

**Via Frontend**:

- Access the React AI Chat at your deployed frontend URL
- Start a conversation - memory will persist across messages

---

## Module Structure

```
modules/agentcore/
├── README.md                    # This file - comprehensive guide
├── main.tf                      # Core resources + CodeBuild buildspec
├── iam.tf                       # IAM roles and policies (includes Memory API permissions)
├── dynamodb.tf                  # DynamoDB table for legacy memory (deprecated)
├── variables.tf                 # Input variables
├── outputs.tf                   # Module outputs
├── versions.tf                  # Provider requirements
└── runtime_code/
    ├── main.py                  # Production runtime code (reference - buildspec is source of truth)
    ├── memory_hook_provider.py  # Memory persistence hooks (reference)
    ├── requirements.txt         # Python dependencies
    ├── build_package.sh         # (Not used - for Lambda-style deployment)
    └── rebuild_vendored.sh      # (Not used - CodeBuild handles deps)
```

**Important**: The actual runtime code is **embedded in `main.tf` buildspec** (lines ~300-520). The `runtime_code/` directory files are **reference implementations**. CodeBuild generates files from the buildspec during Docker image builds.

---

## Configuration

### Variables

Configure in your environment's `terraform.tfvars` or `main.tf`:

| Variable                | Description                  | Default                                     | Required |
| ----------------------- | ---------------------------- | ------------------------------------------- | -------- |
| `project_name`          | Project identifier           | `"charlesmbrady"`                           | Yes      |
| `agent_name`            | Agent name                   | `"assistant"`                               | Yes      |
| `environment_tag`       | Environment (Test/Prod)      | `"Test"`                                    | Yes      |
| `agent_instruction`     | System prompt for agent      | `"You are a helpful assistant..."`          | No       |
| `foundation_model`      | Bedrock model ID             | `anthropic.claude-3-5-sonnet-20240620-v1:0` | No       |
| `enable_memory`         | Enable conversation memory   | `true`                                      | No       |
| `memory_retention_days` | Days to retain history       | `30`                                        | No       |
| `rag_enabled`           | Enable RAG embeddings bucket | `true`                                      | No       |
| `tool_lambda_arn`       | Lambda ARN for tools         | (Lambda ARN)                                | Yes      |

### Environment Variables (Set by Runtime)

These are automatically configured by Terraform and passed to the Docker container:

- `AGENT_INSTRUCTION`: System prompt
- `FOUNDATION_MODEL`: Bedrock model ID
- `RAG_BUCKET`: S3 bucket for RAG (if enabled)
- `MEMORY_ID`: Memory resource ID (if enabled)
- `AWS_REGION`: AWS region

---

## Agent Capabilities

### Current Tools

#### 1. `get_project_details(project_name: str)`

Returns detailed information about Charles's projects:

- **charlava**: Serverless AWS platform
- **cb-common**: Enterprise Nx monorepo
- **agentcore**: AI agent runtime (this system!)
- **jamcam**: Real-time 3D motion tracking
- **guitar-normal-guy**: AI image processing

#### 2. `get_technical_expertise(area: str)`

Returns expertise information by technical domain:

- **aws**: Advanced (Lambda, API Gateway, DynamoDB, Bedrock, etc.)
- **terraform**: Advanced (Multi-environment, modules, state management)
- **typescript**: Advanced (React, Node.js, Express, Nx)
- **python**: Advanced (AI/ML, computer vision, serverless)
- **ai**: Intermediate-Advanced (Bedrock, agents, computer vision)

### Conversation Memory

The agent maintains conversation context using AWS Bedrock AgentCore Memory API:

- **Session-based**: Each `sessionId` maintains separate conversation thread
- **Actor-based**: Each `actorId` has personalized memory
- **Persistent**: Survives runtime restarts and redeployments
- **Configurable**: 7-365 day retention (default: 30 days)

**Example flow**:

```
User: "Tell me about Charles's AWS expertise"
Agent: [Responds with AWS details]

User: "Which project uses those services?"
Agent: [References Charlava/CB-Common from memory context - knows "those services" = AWS]

User: "What's the tech stack?"
Agent: [Provides details for the previously mentioned project]
```

---## Deployment

### Initial Deployment

```bash
# 1. Navigate to environment directory
cd /Users/charlesbrady/Desktop/Charlava_25/terraform-aws-charlesmbrady/environments/test

# 2. Initialize Terraform
terraform init

# 3. Deploy infrastructure
terraform apply

# 4. Trigger CodeBuild to create Docker image
aws codebuild start-build \
  --project-name charlesmbrady-assistant-Test-basic-agent-build \
  --region us-east-1
```

### Updating Agent Code

When you modify the runtime logic or tools:

#### Option 1: Update Buildspec in main.tf (Recommended)

1. Edit `modules/agentcore/main.tf`
2. Find the buildspec section (lines ~300-520)
3. Modify the embedded Python code in the heredoc
4. Apply changes:

```bash
terraform apply -target=module.agentcore.aws_codebuild_project.basic_agent_image
aws codebuild start-build \
  --project-name charlesmbrady-assistant-Test-basic-agent-build \
  --region us-east-1
# Wait for build to complete (~5-10 min)
terraform apply -target=module.agentcore.aws_bedrockagentcore_agent_runtime.main
```

#### Option 2: Update Reference Files

For easier editing, update `runtime_code/main.py` and `runtime_code/memory_hook_provider.py`, then manually sync changes to the buildspec in `main.tf`.

**Note**: The buildspec is the source of truth - `runtime_code/` files are references only.

### Updating IAM Permissions

If you add new tools that require AWS service access:

```bash
# Edit modules/agentcore/iam.tf
# Add new policy statements
terraform apply -target=module.agentcore.aws_iam_policy.agentcore_runtime
```

---

## Testing

### AWS Console Testing

1. Navigate to **Bedrock → AgentCore → Runtimes**
2. Click on `charlesmbrady_assistant_Test`
3. Go to **Test** tab
4. Send test payload:

```json
{
  "input": "Tell me about Charles's AWS expertise",
  "sessionId": "test-session-123",
  "actorId": "test-user"
}
```

**Expected Response**:

```json
{
  "status": "success",
  "response": "Charles has advanced AWS expertise including...",
  "sessionId": "test-session-123",
  "actorId": "test-user",
  "memoryEnabled": true
}
```

### Frontend Integration Testing

The React AI Chat component (`cb-common/apps/apps/src/app/subapps/AIChat`) integrates with the agent:

```typescript
// Sends request via Lambda API
const response = await invokeAgent({
  body: {
    prompt: userMessage,
    sessionId: currentSessionId,
  },
});
```

Test conversation flow:

1. Send message: "What projects has Charles built?"
2. Follow-up: "Tell me more about the first one" ← Should remember context
3. New session: Clear chat → Memory resets

---

## Monitoring & Logs

### CloudWatch Logs

**Location**: `/aws/bedrock-agentcore/runtimes/<runtime-id>*/runtime-logs`

**Log Format**:

```
[startup] Beginning runtime import sequence
[startup] Imported bedrock_agentcore + strands + memory successfully
[startup] ✓ Runtime ready - Model: anthropic.claude-3-5-sonnet-20240620-v1:0, Region: us-east-1
[invoke] Raw payload type: <class 'dict'>
[invoke] Session: test-session-123, Actor: test-user
[invoke] User input: Tell me about Charles's AWS expertise...
[MemoryHook] Loading history for session test-session-123
[MemoryHook] Loaded 4 messages
[invoke] Agent created with memory hooks
[invoke] Response generated: Charles has advanced AWS expertise...
[MemoryHook] Saving assistant message
```

### Viewing Logs

```bash
# List log groups
aws logs describe-log-groups \
  --log-group-name-prefix "/aws/bedrock-agentcore/runtimes/" \
  --region us-east-1

# Tail logs
aws logs tail /aws/bedrock-agentcore/runtimes/<runtime-id>/runtime-logs \
  --follow --region us-east-1
```

### Common Log Patterns

**Successful invocation**:

- `[startup] ✓ Runtime ready`
- `[invoke] Agent created with memory hooks`
- `[invoke] Response generated`
- `[MemoryHook] Saved ... message`

**Memory errors**:

- `[MemoryHook] Load error: AccessDeniedException` → Check IAM permissions
- `[MemoryHook] Save error` → Check Memory API permissions

**Model errors**:

- `Anthropic model access not enabled` → Submit use case form in Bedrock console
- `AWS Marketplace permissions missing` → Update IAM role with marketplace permissions

---

## Customization

### Adding New Tools

Edit the buildspec in `main.tf` (or `runtime_code/main.py` as reference):

```python
@tool
def get_contact_info(contact_type: str) -> str:
    """Get Charles's contact information"""
    contacts = {
        "email": "charles@example.com",
        "linkedin": "linkedin.com/in/charlesbrady",
        "github": "github.com/charlesmbrady"
    }
    return contacts.get(contact_type.lower(), "Contact type not found")

# Register in invoke function
tools = [
    get_project_details,
    get_technical_expertise,
    get_contact_info  # Add new tool
]
```

### Modifying System Prompt

Update the `SYSTEM_PROMPT` variable in the buildspec:

```python
SYSTEM_PROMPT = f"""You are Charles Brady's AI portfolio assistant...

[Modify persona, tone, capabilities here]

{AGENT_INSTRUCTION}
"""
```

### Changing Model

Update Terraform variable:

```hcl
# In environments/test/terraform.tfvars or module call
agentcore_foundation_model = "amazon.titan-text-premier-v1:0"
```

Or use environment variable override:

```bash
terraform apply -var="agentcore_foundation_model=amazon.titan-text-premier-v1:0"
```

---

## Troubleshooting

### Permission Errors in Logs

**Symptom**:

```
[MemoryHook] Load error: AccessDeniedException ... bedrock-agentcore:ListEvents
```

**Solution**:

```bash
# Verify IAM policy includes Memory API permissions
terraform apply -target=module.agentcore.aws_iam_policy.agentcore_runtime
```

### Agent Returns "Invalid HTTP request"

**Symptom**: Warning in logs but no response

**Cause**: Payload format mismatch or health check probe

**Solution**: Check logs for `[invoke] Raw payload` - should show dict with `input`, `sessionId`, `actorId`

### Memory Not Persisting

**Symptoms**:

- Agent doesn't remember previous messages
- `memoryEnabled: false` in response
- No `[MemoryHook]` logs

**Checks**:

1. Verify `enable_memory = true` in Terraform
2. Check `MEMORY_ID` environment variable is set: `terraform output agentcore_memory_id`
3. Review IAM permissions for Memory API

### CodeBuild Fails

**Symptom**: Build status = FAILED

**Solution**:

```bash
# View build logs
aws codebuild batch-get-builds \
  --ids <build-id> \
  --query 'builds[0].logs.deepLink'

# Common issues:
# - Python syntax errors in buildspec heredoc
# - Missing dependencies in requirements.txt
# - Docker build failures (check Dockerfile in buildspec)
```

### Runtime Not Updating After Rebuild

**Symptom**: Old behavior persists after CodeBuild completes

**Solution**: Force runtime to pull new image:

```bash
terraform apply -target=module.agentcore.aws_bedrockagentcore_agent_runtime.main
```

---

## Resources Created

| Resource                                  | Type              | Purpose                                                   |
| ----------------------------------------- | ----------------- | --------------------------------------------------------- |
| `aws_bedrockagentcore_agent_runtime.main` | AgentCore Runtime | Hosts the conversational AI agent                         |
| `aws_bedrockagentcore_gateway.main`       | MCP Gateway       | Routes requests with IAM auth                             |
| `aws_bedrockagentcore_memory.main`        | Memory Store      | Persistent conversation history (optional)                |
| `aws_codebuild_project.basic_agent_image` | CodeBuild Project | Builds Docker image for runtime                           |
| `aws_ecr_repository.basic_agent`          | ECR Repository    | Stores container images                                   |
| `aws_iam_role.agentcore_runtime`          | IAM Role          | Runtime execution role with Memory API permissions        |
| `aws_iam_role.codebuild_role`             | IAM Role          | CodeBuild execution role                                  |
| `aws_dynamodb_table.agentcore_memory`     | DynamoDB Table    | Legacy memory storage (deprecated in favor of Memory API) |
| `aws_s3_bucket.rag_embeddings`            | S3 Bucket         | RAG embeddings storage (optional)                         |

---

## Cost Estimates

**Monthly costs (us-east-1, Test environment, moderate usage)**:

| Service                       | Cost                    | Notes                                                         |
| ----------------------------- | ----------------------- | ------------------------------------------------------------- |
| **Bedrock Model Invocations** | $10-50                  | Claude 3.5 Sonnet: ~$3/1K input tokens, ~$15/1K output tokens |
| **AgentCore Memory API**      | $0-2                    | $0.10/1M events stored + retrieval                            |
| **CodeBuild**                 | $0.05-0.20              | $0.005/min build time (only during builds)                    |
| **ECR Storage**               | $0.10-0.25              | ~$0.10/GB/month (~500MB image)                                |
| **DynamoDB**                  | $0-1                    | On-demand pricing (minimal usage)                             |
| **CloudWatch Logs**           | $0.50-2                 | Depends on log volume                                         |
| **S3 (RAG bucket)**           | $0-0.50                 | If enabled, minimal storage costs                             |
| **Lambda Invocations**        | Covered by existing API | N/A                                                           |

**Total**: **$12-60/month** (primarily Bedrock token usage)

**Cost Optimization**:

- Use cheaper models for development (e.g., `amazon.titan-text-lite-v1`)
- Reduce memory retention period
- Implement response caching for common queries
- Monitor token usage with CloudWatch metrics

---

## References

- [AWS Bedrock AgentCore Documentation](https://docs.aws.amazon.com/bedrock/latest/userguide/agents-agentcore.html)
- [Bedrock AgentCore Memory API](https://docs.aws.amazon.com/bedrock/latest/userguide/memory-api.html)
- [Strands Agent Framework](https://github.com/aws-samples/strands-agents)
- [AWS Bedrock Pricing](https://aws.amazon.com/bedrock/pricing/)

---

**Last Updated**: November 28, 2025  
**Terraform Version**: >= 1.0  
**AWS Provider Version**: >= 5.0

## TODO

# DIY RAG integration with S3 + Titan embeddings

Example how this could work.

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

This stack replaces the managed Knowledge Base with a cost-efficient S3 + JSON approach.

### Why This Approach?

- Eliminates OpenSearch Serverless baseline OCUs (> $170/mo)
- Simple to reason about, easy to extend
- Ideal for very small corpora and low query volume

## Enhanced Prompt Configuration

The agent runtime includes enhanced prompt configuration with inference parameters:

- **Temperature**: 0.7 (balanced creativity vs determinism)
- **Top P**: 0.9 (nucleus sampling)
- **Top K**: 250 (token diversity)
- **Max Length**: 2048 tokens (response length limit)
- **Session Timeout**: 600 seconds (10 minutes)

These can be customized by modifying `modules/agentcore/main.tf`:

```terraform
prompt_override_configuration {
  prompt_configurations {
    prompt_type = "ORCHESTRATION"

    inference_configuration {
      temperature = 0.7   # Adjust 0.0-1.0
      top_p       = 0.9   # Adjust 0.0-1.0
      top_k       = 250   # Adjust 1-500
      max_length  = 2048  # Token limit
    }
  }
}
```

---

No managed Knowledge Base / OpenSearch layer.

DIY RAG avoids OpenSearch Serverless OCU baseline by using ephemeral in-memory similarity over a tiny corpus.

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

### References

https://github.com/aws/bedrock-agentcore-starter-toolkit/blob/main/src/bedrock_agentcore_starter_toolkit/utils/runtime/config.py

https://github.com/awslabs/amazon-bedrock-agentcore-samples/blob/main/01-tutorials/07-AgentCore-E2E/lab-04-agentcore-runtime.ipynb

https://www.workshops.aws/?tag=AgentCore

https://github.com/awslabs/amazon-bedrock-agentcore-samples/tree/main/02-use-cases/customer-support-assistant
