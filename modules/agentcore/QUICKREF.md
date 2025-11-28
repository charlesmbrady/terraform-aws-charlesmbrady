# AgentCore Quick Reference

## 🚀 Deploy New Code Changes

```bash
# 1. Edit code in modules/agentcore/main.tf (search: "cat > my_agent.py")

# 2. Apply terraform
cd /Users/charlesbrady/Desktop/Charlava_25/terraform-aws-charlesmbrady
terraform apply

# 3. Rebuild container
aws codebuild start-build \
  --project-name "charlesmbrady-assistant-Test-basic-agent-build" \
  --region us-east-1

# 4. Wait 3-5 minutes for build to complete

# 5. MANUALLY recreate runtime in AWS Console:
#    Bedrock → AgentCore → Runtimes → Delete charlesmbrady_assistant_Test → Create new
```

## 📝 Edit Agent Code

**File**: `modules/agentcore/main.tf`  
**Search for**: `cat > my_agent.py`

**Key sections**:

- System prompt: `SYSTEM_PROMPT =`
- Capabilities: `CAPABILITIES_TEXT =`
- Intent routing: `def handle_structured_query`

## 🧪 Test Agent

**Console**: AWS → Bedrock → AgentCore → Runtimes → Test tab

**Payload**:

```json
{ "input": "What can you help me with?" }
```

## 📊 View Logs

```bash
# Find log group
aws logs describe-log-groups \
  --log-group-name-prefix "/aws/bedrock-agentcore" \
  --region us-east-1

# Tail logs (replace <runtime-id>)
aws logs tail "/aws/bedrock-agentcore/runtimes/<runtime-id>-charlesmbrady_assistant_Test/runtime-logs" \
  --follow \
  --region us-east-1
```

## 🔍 Check Build Status

```bash
# List recent builds
aws codebuild list-builds-for-project \
  --project-name "charlesmbrady-assistant-Test-basic-agent-build" \
  --region us-east-1 \
  --max-items 1

# Get build details (replace BUILD_ID)
aws codebuild batch-get-builds \
  --ids "charlesmbrady-assistant-Test-basic-agent-build:BUILD_ID" \
  --region us-east-1 \
  --query 'builds[0].buildStatus'
```

## 🐳 Verify ECR Image

```bash
aws ecr describe-images \
  --repository-name "charlesmbrady-assistant-test-basic-agent" \
  --region us-east-1 \
  --query 'imageDetails[0].[imageTags[0],imagePushedAt]' \
  --output table
```

## ⚠️ Common Issues

| Issue                  | Solution                                  |
| ---------------------- | ----------------------------------------- |
| Old behavior persists  | Must recreate runtime in Console (step 5) |
| Build fails            | Check buildspec Python syntax in main.tf  |
| No logs                | Verify runtime ID in log group path       |
| "Invalid HTTP request" | Ignore - cosmetic health check warning    |

## 📚 Documentation

- **[README.md](./README.md)** - Module overview
- **[DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)** - Complete workflow with examples

## 💡 Pro Tips

1. **Always recreate runtime** after image rebuild - it caches the container
2. **Check CloudWatch logs** for debug output with structured JSON
3. **Use terraform plan** before apply to preview changes
4. **Verify ECR timestamp** before recreating runtime
5. **Keep system prompt in variables.tf** for easier changes

## 🎯 One-Liner Deploy

```bash
terraform apply && \
aws codebuild start-build --project-name "charlesmbrady-assistant-Test-basic-agent-build" --region us-east-1 && \
echo "⏳ Wait 5 min, then recreate runtime in AWS Console"
```
