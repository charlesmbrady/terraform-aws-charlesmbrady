# AgentCore Deployment and Testing Guide

## Issue Identified

Your agent is not responding to the actual user input. This is because:

1. **The payload extraction might be failing** - The code now checks for multiple payload field names
2. **Debug logging was insufficient** - Added comprehensive logging to see what's happening
3. **Response format was inconsistent** - Now all paths return `{"status": "...", "response": "..."}`

## Changes Made

### Enhanced Payload Extraction (main.py)
```python
# Now checks for: input, prompt, inputText, text, message, query
# Also handles string payloads directly
```

### Debug Logging Added
- Logs full payload structure
- Logs payload type
- Logs extracted user input
- Logs system prompt
- Logs agent response details

### Consistent Response Format
All responses now return:
```json
{
  "status": "success" or "error",
  "response": "actual response text"
}
```

## Deployment Steps

### Step 1: Check Current State

```bash
cd /Users/charlesbrady/Desktop/Charlava_25/terraform-aws-charlesmbrady

# Get the CodeBuild project name (adjust project_name and environment as needed)
# Format: {project_name}-assistant-{environment}-basic-agent-build
# Example: charlesmbrady-assistant-Test-basic-agent-build

# List CodeBuild projects to find yours
aws codebuild list-projects --region us-east-1
```

### Step 2: Trigger Build

```bash
# Replace with your actual project name from step 1
PROJECT_NAME="charlesmbrady-assistant-Test-basic-agent-build"

# Start the build
aws codebuild start-build --project-name "$PROJECT_NAME" --region us-east-1
```

### Step 3: Monitor Build

```bash
# Get the build ID from the previous command output or list builds
aws codebuild list-builds-for-project --project-name "$PROJECT_NAME" --region us-east-1

# Watch build status (replace BUILD_ID)
aws codebuild batch-get-builds --ids <BUILD_ID> --region us-east-1
```

### Step 4: Verify ECR Image

```bash
# List images in the ECR repository
# Format: {project_name}-assistant-{environment}-basic-agent
REPO_NAME="charlesmbrady-assistant-test-basic-agent"

aws ecr describe-images --repository-name "$REPO_NAME" --region us-east-1
```

### Step 5: Update AgentCore Runtime (if needed)

The runtime should automatically use the `:latest` tag, but if you need to force an update:

```bash
# Run terraform apply to ensure runtime picks up new image
terraform apply -target=module.agentcore.aws_bedrockagentcore_agent_runtime.main
```

## Testing

### Test in AWS Console

1. Go to AWS Bedrock Console → AgentCore
2. Find your agent runtime (name format: `{project}_assistant_{environment}`)
3. Open the Test/Sandbox view
4. Send this payload:

```json
{
  "input": "What can you help me with?",
  "user_id": "12345",
  "context": {
    "timezone": "Asia/Tokyo",
    "language": "en"
  }
}
```

### Check CloudWatch Logs

```bash
# Find log groups
aws logs describe-log-groups --log-group-name-prefix "/aws/bedrock-agentcore" --region us-east-1

# Get recent logs (replace LOG_GROUP_NAME)
aws logs tail "/aws/bedrock-agentcore/runtimes/<runtime-id>-<name>/runtime-logs" --follow --region us-east-1
```

Look for the debug output:
```
[DEBUG] Full payload: ...
[DEBUG] Payload type: ...
[DEBUG] Extracted user_input: 'What can you help me with?'
[DEBUG] About to invoke agent with input: 'What can you help me with?'
[DEBUG] System prompt: 'You are a helpful assistant...'
```

## Expected Behavior After Fix

**Input:**
```json
{
  "input": "What can you help me with?"
}
```

**Expected Output:**
```json
{
  "status": "success",
  "response": "I can help you with information about electronics products! Specifically, I can provide:\n\n1. **Product Information** - Get detailed technical specifications for laptops, smartphones, headphones, and monitors\n2. **Return Policies** - Learn about return windows, conditions, and processes for different product categories\n\nFeel free to ask me about product details or return policies for any electronics category!"
}
```

## Troubleshooting

### If agent still doesn't respond correctly:

1. **Check CloudWatch logs** - Look for the `[DEBUG]` lines to see what payload is being received
2. **Verify the correct runtime** - Make sure you're testing the right AgentCore runtime
3. **Check system prompt** - The debug logs show what system prompt is active
4. **Try direct Lambda invocation** - The runtime can be invoked directly via AWS SDK

### Common Issues:

- **Wrong runtime being tested**: Check the runtime name matches what Terraform created
- **Image not updated**: Verify CodeBuild completed and ECR has new image with recent timestamp
- **Permissions issue**: Check IAM role has Bedrock model access
- **Model not available**: Verify the foundation model ID is correct and you have access

## Quick Test Script

Save this as `test_agent.sh`:

```bash
#!/bin/bash

# Configuration
RUNTIME_NAME="charlesmbrady_assistant_Test"  # Adjust as needed
REGION="us-east-1"

# Test payload
PAYLOAD='{
  "input": "What can you help me with?",
  "user_id": "12345"
}'

echo "Testing AgentCore Runtime: $RUNTIME_NAME"
echo "Payload: $PAYLOAD"
echo ""

# Note: Direct invocation might require AWS CLI v2 or SDK
# This is a placeholder - actual invocation method depends on AWS CLI support
echo "Use AWS Console Sandbox for now, or implement via boto3"
```

## Next Steps

1. Deploy the updated code (Steps 1-5 above)
2. Test in AWS Console Sandbox
3. Check CloudWatch logs to verify debug output
4. Share the logs if issue persists

The debug logging will tell us exactly what's happening!
