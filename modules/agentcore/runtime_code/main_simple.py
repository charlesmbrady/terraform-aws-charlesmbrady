"""
AgentCore Runtime - Ultra-Minimal Working Version
Only uses guaranteed pre-installed packages
"""

import os
import json

print("[MINIMAL-STARTUP] Python runtime started successfully")
print(f"[MINIMAL-STARTUP] Python version: {os.sys.version}")
print(f"[MINIMAL-STARTUP] Current working directory: {os.getcwd()}")
print(f"[MINIMAL-STARTUP] Environment vars: {list(os.environ.keys())}")

# Try importing bedrock_agentcore - this should be pre-installed in the runtime image
try:
    from bedrock_agentcore.runtime import BedrockAgentCoreApp

    print("[MINIMAL-STARTUP] ✓ bedrock_agentcore.runtime imported successfully")
    app = BedrockAgentCoreApp()
except ImportError as e:
    print(f"[MINIMAL-STARTUP] ✗ bedrock_agentcore.runtime import FAILED: {e}")

    # Fallback minimal WSGI/ASGI app
    class MinimalApp:
        def entrypoint(self, fn):
            self._fn = fn
            return fn

        def run(self):
            print("[MINIMAL-STARTUP] Running fallback HTTP server on port 8080")
            import http.server
            import socketserver

            class Handler(http.server.BaseHTTPRequestHandler):
                def do_POST(self):
                    content_length = int(self.headers.get("Content-Length", 0))
                    body = self.rfile.read(content_length).decode("utf-8")

                    try:
                        payload = json.loads(body) if body else {}
                        result = app._fn(payload, None)
                        response = json.dumps({"response": result})
                    except Exception as ex:
                        response = json.dumps({"error": str(ex)})

                    self.send_response(200)
                    self.send_header("Content-Type", "application/json")
                    self.end_headers()
                    self.wfile.write(response.encode("utf-8"))

                def log_message(self, format, *args):
                    print(f"[HTTP] {format % args}")

            with socketserver.TCPServer(("", 8080), Handler) as httpd:
                print("[MINIMAL-STARTUP] Serving at port 8080")
                httpd.serve_forever()

    app = MinimalApp()


@app.entrypoint
def invoke(payload, context=None):
    """
    Minimal echo handler - returns diagnostic info
    """
    print(f"[MINIMAL-INVOKE] Received payload: {payload}")
    print(f"[MINIMAL-INVOKE] Context: {context}")

    user_input = (
        payload.get("prompt", "") if isinstance(payload, dict) else str(payload)
    )
    # Also try 'input' key for Agent Sandbox
    if not user_input and isinstance(payload, dict):
        user_input = payload.get("input", "")

    response = {
        "echo": user_input,
        "status": "minimal runtime working",
        "env_vars": {
            "FOUNDATION_MODEL": os.environ.get("FOUNDATION_MODEL", "not set"),
            "AGENT_INSTRUCTION": os.environ.get("AGENT_INSTRUCTION", "not set"),
            "RAG_BUCKET": os.environ.get("RAG_BUCKET", "not set"),
            "AWS_REGION": os.environ.get("AWS_REGION", "not set"),
        },
        "python_version": os.sys.version,
    }

    response_text = json.dumps(response, indent=2)
    print(f"[MINIMAL-INVOKE] Returning: {response_text}")
    return response_text


if __name__ == "__main__":
    print("[MINIMAL-STARTUP] Starting app.run()")
    app.run()
