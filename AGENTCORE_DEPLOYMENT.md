# AgentCore Deployment Guide

## Overview

This guide provides instructions for deploying Amazon Bedrock AgentCore infrastructure using OpenTofu/Terraform.

**✅ Fully Automated Deployment**  
All AgentCore resources are managed via Terraform/OpenTofu using native AWS provider resources. No manual AWS Console steps required!

## What Gets Created

The Terraform configuration creates:

1. **AgentCore Runtime** (`aws_bedrockagentcore_agent_runtime`)

   - Foundation model: Claude 3.5 Sonnet
   - Custom instructions for your platform
   - Enhanced prompt configuration with inference parameters (temperature, top_p, top_k, max_length)
   - IAM role for execution
   - Session timeout configuration

2. **Runtime Endpoint** (`aws_bedrockagentcore_runtime_endpoint`)

   - Qualifier: `DEFAULT`
   - Endpoint URL for invocations

3. **AgentCore Gateway** (`aws_bedrockagentcore_gateway`)

   - Routes requests to runtime
   - Integrates with Lambda tools

4. **Gateway Tool Integration** (`aws_bedrockagentcore_gateway_tool`)

   - Lambda function: `charlesmbrady_api_services_Test`
   - Tool name and description

5. **Memory Configuration** (`aws_bedrockagentcore_memory`)

   - DynamoDB storage for conversation history
   - 30-day retention policy

6. **DIY RAG Embeddings (Optional)** (S3 + JSON)

- S3 bucket storing precomputed embeddings JSON
- Titan Embed Text v2 used only at ingestion time
- Zero always-on vector infra cost

7. **Supporting Infrastructure**

- IAM role with Bedrock/Lambda/DynamoDB permissions
- DynamoDB table for conversation memory
- SSM parameters for runtime configuration
- CloudWatch log group

---

## Prerequisites

### 1. OpenTofu/Terraform Installed

```bash
tofu --version
# or
terraform --version
```

### 2. AWS CLI Configured

```bash
aws sts get-caller-identity
```

### 3. Bedrock Model Access Enabled

Ensure you have access to the foundation model in your AWS account:

- Model: `anthropic.claude-3-5-sonnet-20240620-v1:0`
- Region: `us-east-1` (or your configured region)
- Enable via AWS Console → Bedrock → Model Access

---

## Deployment Steps

### Step 1: Review Configuration (Optional)

The default configuration should work for most use cases. If you want to customize:

Edit `environments/test/main.tf` and add these variables to the `module "main"` block:

```terraform
module "main" {
  # ... existing configuration ...

  # Optional AgentCore customization
  agentcore_agent_name              = "my-custom-assistant"  # default: "assistant"
  agentcore_agent_description       = "Custom description here"
  agentcore_agent_instruction       = "Custom instructions here"
  agentcore_foundation_model        = "anthropic.claude-3-5-sonnet-20240620-v1:0"
  agentcore_enable_memory           = true
  agentcore_memory_retention_days   = 30

  # DIY RAG (optional lightweight retrieval)
  agentcore_rag_enabled     = true
  agentcore_rag_bucket_name = "" # leave blank to auto-generate bucket name
}
```

### Step 2: Deploy with OpenTofu/Terraform

```bash
cd environments/test

# Initialize (if first time)
tofu init
# or: terraform init

# Review what will be created
tofu plan

# Apply the configuration
tofu apply
```

### Step 3: Capture Outputs

After successful apply, capture these values for your application:

```bash
# Get all AgentCore outputs
tofu output | grep agentcore

# Key outputs for Lambda integration:
tofu output agentcore_runtime_id        # Use this to invoke the agent
tofu output agentcore_endpoint_url      # Endpoint URL
tofu output agentcore_gateway_id        # Gateway ID
```

**Example outputs**:

```text
agentcore_runtime_id     = "ABC123XYZ"
agentcore_endpoint_url   = "https://bedrock-agent-runtime.us-east-1.amazonaws.com/..."
agentcore_gateway_id     = "GATEWAY789"
agentcore_runtime_arn    = "arn:aws:bedrock:us-east-1:632785536297:agent/ABC123XYZ"
```

````

---

## Lambda Integration

Your existing `charlesmbrady_api_services_Test` Lambda can now invoke the AgentCore runtime.

### Reading Configuration from SSM

The Lambda already has permissions to read SSM parameters. Use these parameters:

```javascript
const { SSMClient, GetParameterCommand } = require("@aws-sdk/client-ssm");
const { BedrockAgentRuntimeClient, InvokeAgentCommand } = require("@aws-sdk/client-bedrock-agent-runtime");

const ssmClient = new SSMClient({ region: process.env.AWS_REGION });
const bedrockClient = new BedrockAgentRuntimeClient({ region: process.env.AWS_REGION });

async function getAgentConfig() {
  const runtimeIdParam = await ssmClient.send(
    new GetParameterCommand({
      Name: "/charlesmbrady/Test/agentcore/runtime-id"
    })
  );
  return {
    runtimeId: runtimeIdParam.Parameter.Value,
  };
}
````

### Invoking the Agent

```javascript
exports.handler = async (event) => {
  try {
    const { runtimeId } = await getAgentConfig();

    const command = new InvokeAgentCommand({
      agentId: runtimeId,
      agentAliasId: "DEFAULT",
      sessionId: event.sessionId || `session-${Date.now()}`,
      inputText: event.message || "Hello",
    });

    const response = await bedrockClient.send(command);

    // Handle streaming response
    let agentResponse = "";
    for await (const chunk of response.completion) {
      if (chunk.chunk && chunk.chunk.bytes) {
        agentResponse += new TextDecoder().decode(chunk.chunk.bytes);
      }
    }

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: agentResponse,
        sessionId: event.sessionId,
      }),
    };
  } catch (error) {
    console.error("AgentCore error:", error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message }),
    };
  }
};
```

### Using Environment Variables (Alternative)

You can also pass the runtime ID as an environment variable to your Lambda.

Update `environments/test/main.tf`:

```terraform
module "main" {
  # ... existing config ...

  charlesmbrady_middleware_environment_variables = {
    AGENTCORE_RUNTIME_ID = module.agentcore.runtime_id
  }
}
```

Then in Lambda:

```javascript
const runtimeId = process.env.AGENTCORE_RUNTIME_ID;
```

---

## Frontend Integration

Once Lambda is working, integrate with your React frontend.

### API Call from React

```typescript
// src/services/agentService.ts
export const sendMessageToAgent = async (
  message: string,
  sessionId?: string
) => {
  const response = await fetch(
    "https://api-test.charlesmbrady.com/agent/chat",
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${getCognitoToken()}`,
      },
      body: JSON.stringify({ message, sessionId }),
    }
  );

  return response.json();
};
```

### Chat Component Example

```typescript
// src/components/AgentChat.tsx
import { useState } from "react";
import { sendMessageToAgent } from "../services/agentService";

export const AgentChat = () => {
  const [messages, setMessages] = useState([]);
  const [sessionId, setSessionId] = useState(null);

  const sendMessage = async (text: string) => {
    const response = await sendMessageToAgent(text, sessionId);

    if (!sessionId) {
      setSessionId(response.sessionId);
    }

    setMessages([
      ...messages,
      { role: "user", content: text },
      { role: "assistant", content: response.message },
    ]);
  };

  return <div className="chat-container">{/* Chat UI implementation */}</div>;
};
```

---

## DIY RAG (Lightweight Retrieval Augmentation)

This stack replaces the managed Knowledge Base with a cost-efficient S3 + JSON approach.

### Why This Approach?

- Eliminates OpenSearch Serverless baseline OCUs (> $170/mo)
- Simple to reason about, easy to extend
- Ideal for very small corpora and low query volume

### Components

1. Ingestion script: `scripts/rag_ingest.js`
2. S3 bucket: stores `embeddings/embeddings.json`
3. Lambda: loads file (cached after first call) and performs cosine similarity

### Ingestion Workflow

```bash
# Install deps (if not already)
npm install @aws-sdk/client-bedrock-runtime @aws-sdk/client-s3 @aws-sdk/client-ssm gray-matter glob

# Generate & upload embeddings from markdown in ./docs
node scripts/rag_ingest.js --source ./docs

# Override bucket name (optional)
node scripts/rag_ingest.js --source ./docs --bucket my-custom-rag-bucket
```

### Lambda Retrieval Outline

1. Fetch `embeddings.json` from S3 (store in global variable for reuse)
2. Embed user query with Titan Embed Text v2
3. Compute cosine similarity per chunk
4. Select top `k` chunks (e.g. 3)
5. Concatenate chunk texts into the input sent to AgentCore

Full example provided in `AGENTCORE_QUICK_REF.md`.

### Cost Snapshot

| Component        | Driver             | Est. Monthly |
| ---------------- | ------------------ | ------------ |
| S3 storage       | Few KB JSON        | <$0.01       |
| Titan embeddings | Ingest + per-query | <$1          |
| Lambda execution | Requests           | <$1          |

No persistent vector infra required.

---

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

## Monitoring & Debugging

### CloudWatch Logs

**AgentCore Logs**:

```bash
aws logs tail /aws/bedrock/agentcore/charlesmbrady-assistant-Test --follow
```

**Lambda Logs**:

```bash
aws logs tail /aws/lambda/charlesmbrady_api_services_Test --follow
```

### Testing the Agent Directly

Use AWS CLI to test the agent:

```bash
RUNTIME_ID=$(tofu output -raw agentcore_runtime_id)

aws bedrock-agent-runtime invoke-agent \
  --region us-east-1 \
  --agent-id $RUNTIME_ID \
  --agent-alias-id DEFAULT \
  --session-id test-session-$(date +%s) \
  --input-text "Hello, can you help me?"
```

### Viewing Conversation History

Query the DynamoDB table:

```bash
TABLE_NAME=$(tofu output -raw agentcore_memory_table_name)

aws dynamodb scan \
  --table-name $TABLE_NAME \
  --max-items 10
```

---

## Cost Breakdown

All resources are **serverless** with **pay-per-use** pricing:

| Service              | Pricing Model           | Est. Monthly Cost |
| -------------------- | ----------------------- | ----------------- |
| AgentCore Runtime    | Per invocation + tokens | $5-20             |
| Lambda               | Per request             | <$1               |
| DynamoDB             | On-demand               | <$1               |
| API Gateway          | Per API call            | <$1               |
| CloudWatch Logs      | Storage                 | <$5               |
| DIY RAG (S3 + Titan) | On-demand               | <$2               |
| SSM Parameters       | Free (standard)         | $0                |
| IAM Roles            | Free                    | $0                |

**Total**: ~$10-30/month including DIY RAG

No managed Knowledge Base / OpenSearch layer.

DIY RAG avoids OpenSearch Serverless OCU baseline by using ephemeral in-memory similarity over a tiny corpus.

**No fixed costs**:

- ❌ No EC2 instances
- ❌ No NAT Gateways
- ❌ No RDS databases
- ❌ No provisioned capacity

---

## Troubleshooting

### Error: "Access denied to model"

**Solution**: Enable model access in Bedrock console

```bash
# Check if model is available
aws bedrock list-foundation-models \
  --region us-east-1 \
  --query "modelSummaries[?modelId=='anthropic.claude-3-5-sonnet-20240620-v1:0']"
```

### Error: "Runtime not found" in Lambda

**Solution**: Ensure SSM parameters are created

```bash
aws ssm get-parameter --name "/charlesmbrady/Test/agentcore/runtime-id"
```

### Error: "Lambda invocation failed" from AgentCore

**Solution**: Check IAM role permissions

```bash
# Verify AgentCore role can invoke Lambda
aws iam get-role-policy \
  --role-name charlesmbrady-agentcore-Test \
  --policy-name charlesmbrady-agentcore-Test-policy
```

### Memory not persisting between sessions

**Solution**:

- Verify memory is enabled: Check Terraform outputs
- Check DynamoDB table exists: `aws dynamodb describe-table --table-name charlesmbrady-agentcore-memory-Test`
- Ensure same `sessionId` is used across requests

---

## Updating Configuration

### Changing Agent Instructions

Edit `variables.tf` or pass via `main.tf`:

```terraform
agentcore_agent_instruction = "New custom instructions here"
```

Then apply:

```bash
tofu apply
```

### Changing Foundation Model

```terraform
agentcore_foundation_model = "anthropic.claude-3-opus-20240229-v1:0"
```

**Note**: Ensure you have access to the new model in Bedrock.

### Disabling Memory

```terraform
agentcore_enable_memory = false
```

---

## Destroying Resources

To remove all AgentCore infrastructure:

```bash
cd environments/test
tofu destroy
```

**Warning**: This will delete:

- AgentCore runtime and endpoint
- Gateway and tool configurations
- DynamoDB table (conversation history will be lost)
- SSM parameters
- IAM roles

---

## Production Deployment

When ready to deploy to production:

1. **Create production configuration**:

```bash
cp -r environments/test environments/production
```

2. **Update production variables** in `environments/production/main.tf`

3. **Apply to production**:

```bash
cd environments/production
tofu init
tofu apply
```

4. **Update frontend** to use production API endpoint

---

## Additional Resources

- [AWS Bedrock AgentCore Documentation](https://docs.aws.amazon.com/bedrock/latest/userguide/agents.html)
- [Terraform AWS Provider - BedrockAgentCore](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_agent_runtime)
- [AWS SDK for JavaScript - Bedrock Agent Runtime](https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/clients/client-bedrock-agent-runtime/)

---

**Last Updated**: November 21, 2025
