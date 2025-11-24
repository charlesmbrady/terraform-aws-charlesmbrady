#!/bin/bash
# Force recreate the AgentCore runtime when it's stuck in UPDATE_FAILED state

set -e

cd "$(dirname "$0")/../../.."

echo "🔄 Forcing AgentCore runtime recreation..."
echo ""

echo "Step 1: Destroying failed runtime..."
terraform destroy -target='module.agentcore.aws_bedrockagentcore_agent_runtime.main' -auto-approve

echo ""
echo "Step 2: Recreating runtime with current code..."
terraform apply -auto-approve

echo ""
echo "✅ Runtime recreated successfully!"
echo ""
echo "Now test in the Agent Sandbox with:"
echo '{"input": "Hello, are you working?"}'
