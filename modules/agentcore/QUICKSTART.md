# 🚀 Quick Start: Deploy Your AgentCore Runtime

## TL;DR

```bash
# 1. Package runtime code
cd modules/agentcore/runtime_code
chmod +x package.sh && ./package.sh

# 2. Create S3 bucket and upload
aws s3 mb s3://my-agentcore-code
aws s3 cp ../runtime_code.zip s3://my-agentcore-code/agent-runtime/code.zip

# 3. Configure Terraform Cloud workspace variable
# Set: agent_runtime_code_bucket = "my-agentcore-code"

# 4. Deploy
cd ../../..
terraform apply
```

## What You're Deploying

A production Bedrock agent with:

- ✅ Claude 3.5 Sonnet model
- ✅ Two customer support tools (product info, return policy)
- ✅ Auto-scaling runtime (0→N instances)
- ✅ CloudWatch logging
- ✅ HTTP invocation endpoint
- ✅ Fully managed by AWS

## Files Created

```
modules/agentcore/
├── runtime_code/
│   ├── main.py              ← Your agent application
│   ├── requirements.txt     ← Python dependencies
│   ├── package.sh          ← Packaging script
│   └── README.md           ← Technical docs
├── RUNTIME_DEPLOYMENT.md   ← Detailed deployment guide
└── RUNTIME_CODE_EXPLAINED.md ← What it all means
```

## Need Help?

- **Deployment steps**: See `RUNTIME_DEPLOYMENT.md`
- **Understanding runtime code**: See `RUNTIME_CODE_EXPLAINED.md`
- **Technical details**: See `runtime_code/README.md`
- **Workshop examples**: See `lab-04-agentcore-runtime.ipynb`

## After Deployment

Test your agent:

```python
# Python SDK example
from bedrock_agentcore_starter_toolkit import Runtime

runtime = Runtime()
response = runtime.invoke({
    "prompt": "What laptops do you have?"
})
print(response)
```

Monitor in AWS Console:

- CloudWatch → Log groups → `/aws/bedrock/agentcore/{name}`
- CloudWatch → GenAI Observability → Bedrock AgentCore

## Next Steps

1. Test basic deployment ✅
2. Add more tools (edit `main.py`)
3. Enable Memory (`enable_memory = true`)
4. Deploy Gateway (future)
5. Build frontend UI (lab 5)

Ready? Start with step 1 above! 🎯
