"""
Basic AgentCore runtime without strands or opentelemetry.
Directly calls the Bedrock foundation model using boto3 bedrock-runtime.
Keeps dependencies minimal to avoid ARM64 wheel issues.
"""

import os
import json
import traceback

print("[basic-startup] Starting basic agent runtime")

# Attempt to import BedrockAgentCoreApp; provide fallback if unavailable
try:
    from bedrock_agentcore.runtime import BedrockAgentCoreApp
    HAVE_AGENTCORE = True
    print("[basic-startup] Imported bedrock_agentcore.runtime")
except Exception as e:
    HAVE_AGENTCORE = False
    print(f"[basic-startup] bedrock_agentcore import failed: {e}\n{traceback.format_exc()}")
    class BedrockAgentCoreApp:
        def entrypoint(self, fn):
            self._fn = fn
            return fn
        def run(self):
            print("[basic-startup] Fallback app running (no HTTP server needed)")
        def __call__(self, *args, **kwargs):
            return self._fn(*args, **kwargs)

app = BedrockAgentCoreApp()

# Config from environment
MODEL_ID = os.environ.get("FOUNDATION_MODEL", "anthropic.claude-3-5-sonnet-20240620-v1:0")
SYSTEM_PROMPT = os.environ.get("AGENT_INSTRUCTION", "You are a helpful assistant.")
RAG_BUCKET = os.environ.get("RAG_BUCKET", "")

print(f"[basic-startup] Model: {MODEL_ID}")
print(f"[basic-startup] Instruction length: {len(SYSTEM_PROMPT)}")
print(f"[basic-startup] RAG Bucket: {RAG_BUCKET or 'none'}")

# Resolve region
import boto3
session = boto3.session.Session()
REGION = session.region_name or os.environ.get("AWS_REGION") or os.environ.get("AWS_DEFAULT_REGION") or "us-east-1"
print(f"[basic-startup] Using region: {REGION}")

bedrock_runtime = boto3.client("bedrock-runtime", region_name=REGION)

def invoke_bedrock_claude(model_id: str, prompt: str) -> str:
    """Invoke a Bedrock text model (Anthropic Claude) in the simplest way."""
    if not prompt.strip():
        return "(No input provided)"
    body = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 512,
        "messages": [
            {"role": "system", "content": [{"type": "text", "text": SYSTEM_PROMPT}]},
            {"role": "user", "content": [{"type": "text", "text": prompt}]}
        ]
    }
    try:
        resp = bedrock_runtime.invoke_model(
            modelId=model_id,
            body=json.dumps(body),
            accept="application/json",
            contentType="application/json",
        )
        payload = resp.get("body")
        if hasattr(payload, "read"):
            payload = payload.read()
        data = json.loads(payload)
        content_blocks = data.get("output", {}).get("message", {}).get("content", [])
        parts = []
        for block in content_blocks:
            if block.get("type") == "text":
                parts.append(block.get("text", ""))
        return "".join(parts) or "(Empty response)"
    except Exception as e:
        print(f"[basic-error] Bedrock invocation failed: {e}\n{traceback.format_exc()}")
        return f"Error invoking model: {e}"

@app.entrypoint
def invoke(payload, context=None):
    """Basic entrypoint compatible with AgentCore HTTP invocation."""
    try:
        user_input = ""
        if isinstance(payload, dict):
            user_input = payload.get("input") or payload.get("prompt", "") or ""
        else:
            user_input = str(payload)
        print(f"[basic-invoke] Received input len={len(user_input)}")
        model_response = invoke_bedrock_claude(MODEL_ID, user_input)
        result = {
            "model_id": MODEL_ID,
            "region": REGION,
            "input": user_input,
            "response": model_response,
            "rag_bucket": RAG_BUCKET or None,
            "agent_mode": "basic",
        }
        return json.dumps(result, indent=2)
    except Exception as e:
        print(f"[basic-invoke-error] {e}\n{traceback.format_exc()}")
        return json.dumps({"error": str(e)}, indent=2)

if __name__ == "__main__":
    print("[basic-startup] Running app server")
    app.run()
