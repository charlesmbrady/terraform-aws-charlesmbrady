"""
AgentCore Runtime - Ultra-Minimal Working Version
Only uses guaranteed pre-installed packages
"""

import os
import json

print("[startup] Python runtime started")

# Try importing bedrock_agentcore - confirmed to work from previous test
from bedrock_agentcore.runtime import BedrockAgentCoreApp
print("[startup] ✓ bedrock_agentcore imported")

app = BedrockAgentCoreApp()
print("[startup] ✓ App initialized")

# Read config
MODEL_ID = os.environ.get("FOUNDATION_MODEL", "anthropic.claude-3-5-sonnet-20240620-v1:0")
AGENT_INSTRUCTION = os.environ.get("AGENT_INSTRUCTION", "You are a helpful assistant.")
RAG_BUCKET = os.environ.get("RAG_BUCKET", "")

print(f"[startup] Config loaded - Model: {MODEL_ID[:50]}...")


@app.entrypoint
async def invoke(payload, context=None):
    """
    Minimal working handler - will add Strands agent incrementally
    """
    user_input = payload.get("input") or payload.get("prompt", "")
    
    print(f"[invoke] Received: {user_input[:100]}")
    
    # For now, just echo back with config info
    response = {
        "message": f"AgentCore runtime is working! You said: {user_input}",
        "model": MODEL_ID,
        "instruction": AGENT_INSTRUCTION[:100],
        "status": "ready_for_strands_integration"
    }
    
    return json.dumps(response, indent=2)


if __name__ == "__main__":
    print("[startup] Starting server")
    app.run()
