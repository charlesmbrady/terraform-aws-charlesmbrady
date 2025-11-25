"""
AgentCore Runtime Entrypoint - Production Code
Simplified layout: all third-party dependencies can live under `vendored/`.
We manually extend sys.path so the runtime zip can stay clean.
"""

import os
import sys
import traceback
import boto3

# Inject vendored directory (if present) into sys.path early
_BASE_DIR = os.path.dirname(__file__)
_VENDORED = os.path.join(_BASE_DIR, "vendored")
if os.path.isdir(_VENDORED) and _VENDORED not in sys.path:
    sys.path.insert(0, _VENDORED)
    print(f"[startup] Added vendored path: {_VENDORED}")

print("[startup] Beginning runtime import sequence")
try:
    from bedrock_agentcore.runtime import BedrockAgentCoreApp
    from strands import Agent
    from strands.models import BedrockModel
    from strands.tools import tool

    print("[startup] Imported bedrock_agentcore + strands successfully")
except Exception as import_err:
    print(f"[startup-error] Import failure: {import_err}\n{traceback.format_exc()}")

    # Fallback minimal shim so container still responds; tools disabled
    class BedrockAgentCoreApp:
        def entrypoint(self, fn):
            self._fn = fn
            return fn

        def run(self):
            print("[fallback] Running minimal app server")

        def __call__(self, *args, **kwargs):
            return self._fn(*args, **kwargs)

    class Agent:
        def __init__(self, **kwargs):
            self.kwargs = kwargs

        def __call__(self, prompt):
            return {"message": {"content": [{"text": f"(fallback) Echo: {prompt}"}]}}

    def tool(fn):
        return fn


# Get AWS region from session (fallback to environment or us-east-1 to avoid None)
_session_region = boto3.session.Session().region_name
REGION = (
    _session_region
    or os.environ.get("AWS_REGION")
    or os.environ.get("AWS_DEFAULT_REGION")
    or "us-east-1"
)
if _session_region is None:
    print(f"[startup] Session region was None; using fallback REGION={REGION}")

# Read configuration from environment variables (set by Terraform)
MODEL_ID = os.environ.get(
    "FOUNDATION_MODEL", "anthropic.claude-3-5-sonnet-20240620-v1:0"
)
AGENT_INSTRUCTION = os.environ.get("AGENT_INSTRUCTION", "You are a helpful assistant.")
RAG_BUCKET = os.environ.get("RAG_BUCKET", "")

# System prompt from environment or default
SYSTEM_PROMPT = AGENT_INSTRUCTION

# Initialize Bedrock model (guard if strands import failed)
try:
    model = BedrockModel(model_id=MODEL_ID, region_name=REGION)
    print(f"[startup] Initialized BedrockModel {MODEL_ID} region {REGION}")
except Exception as model_err:
    print(f"[startup-error] Model init failed: {model_err}\n{traceback.format_exc()}")
    model = None

# Initialize the AgentCore Runtime App
app = BedrockAgentCoreApp()
print("[startup] App initialized")
print(f"[startup] ✓ Runtime ready - Model: {MODEL_ID}, Region: {REGION}")


# ============================================================================
# TOOLS - Define your agent's capabilities
# ============================================================================


@tool
def get_product_info(product_type: str) -> str:
    """
    Get detailed technical specifications and information for electronics products.

    Args:
        product_type: Electronics product type (e.g., 'laptops', 'smartphones', 'headphones', 'monitors')
    Returns:
        Formatted product information including warranty, features, and policies
    """
    products = {
        "laptops": {
            "warranty": "1-year manufacturer warranty + optional extended coverage",
            "specs": "Intel/AMD processors, 8-32GB RAM, SSD storage, various display sizes",
            "features": "Backlit keyboards, USB-C/Thunderbolt, Wi-Fi 6, Bluetooth 5.0",
            "compatibility": "Windows 11, macOS, Linux support varies by model",
            "support": "Technical support and driver updates included",
        },
        "smartphones": {
            "warranty": "1-year manufacturer warranty",
            "specs": "5G/4G connectivity, 128GB-1TB storage, multiple camera systems",
            "features": "Wireless charging, water resistance, biometric security",
            "compatibility": "iOS/Android, carrier unlocked options available",
            "support": "Software updates and technical support included",
        },
        "headphones": {
            "warranty": "1-year manufacturer warranty",
            "specs": "Wired/wireless options, noise cancellation, 20Hz-20kHz frequency",
            "features": "Active noise cancellation, touch controls, voice assistant",
            "compatibility": "Bluetooth 5.0+, 3.5mm jack, USB-C charging",
            "support": "Firmware updates via companion app",
        },
        "monitors": {
            "warranty": "3-year manufacturer warranty",
            "specs": "4K/1440p/1080p resolutions, IPS/OLED panels, various sizes",
            "features": "HDR support, high refresh rates, adjustable stands",
            "compatibility": "HDMI, DisplayPort, USB-C inputs",
            "support": "Color calibration and technical support",
        },
    }
    product = products.get(product_type.lower())
    if not product:
        return f"Technical specifications for {product_type} not available. Please contact our technical support team for detailed product information and compatibility requirements."

    return (
        f"Technical Information - {product_type.title()}:\n\n"
        f"• Warranty: {product['warranty']}\n"
        f"• Specifications: {product['specs']}\n"
        f"• Key Features: {product['features']}\n"
        f"• Compatibility: {product['compatibility']}\n"
        f"• Support: {product['support']}"
    )


@tool
def get_return_policy(product_category: str) -> str:
    """
    Get return policy information for a specific product category.

    Args:
        product_category: Electronics category (e.g., 'smartphones', 'laptops', 'accessories')

    Returns:
        Formatted return policy details including timeframes and conditions
    """
    return_policies = {
        "smartphones": {
            "window": "30 days",
            "condition": "Original packaging, no physical damage, factory reset required",
            "process": "Online RMA portal or technical support",
            "refund_time": "5-7 business days after inspection",
            "shipping": "Free return shipping, prepaid label provided",
            "warranty": "1-year manufacturer warranty included",
        },
        "laptops": {
            "window": "30 days",
            "condition": "Original packaging, all accessories, no software modifications",
            "process": "Technical support verification required before return",
            "refund_time": "7-10 business days after inspection",
            "shipping": "Free return shipping with original packaging",
            "warranty": "1-year manufacturer warranty, extended options available",
        },
        "accessories": {
            "window": "30 days",
            "condition": "Unopened packaging preferred, all components included",
            "process": "Online return portal",
            "refund_time": "3-5 business days after receipt",
            "shipping": "Customer pays return shipping under $50",
            "warranty": "90-day manufacturer warranty",
        },
    }

    default_policy = {
        "window": "30 days",
        "condition": "Original condition with all included components",
        "process": "Contact technical support",
        "refund_time": "5-7 business days after inspection",
        "shipping": "Return shipping policies vary",
        "warranty": "Standard manufacturer warranty applies",
    }

    policy = return_policies.get(product_category.lower(), default_policy)
    return (
        f"Return Policy - {product_category.title()}:\n\n"
        f"• Return window: {policy['window']} from delivery\n"
        f"• Condition: {policy['condition']}\n"
        f"• Process: {policy['process']}\n"
        f"• Refund timeline: {policy['refund_time']}\n"
        f"• Shipping: {policy['shipping']}\n"
        f"• Warranty: {policy['warranty']}"
    )


# ============================================================================
# ENTRYPOINT - AgentCore Runtime invocation handler
# ============================================================================


@app.entrypoint
async def invoke(payload, context=None):
    """
    AgentCore Runtime entrypoint function.
    Processes user prompts and returns agent responses.

    Args:
        payload: dict with user input (e.g., {"prompt": "Hello"} or {"input": "Hello"})
        context: request context (headers, metadata, etc.)

    Returns:
        Agent response text
    """
    # Support both 'input' (Agent Sandbox) and 'prompt' (custom invocations)
    user_input = payload.get("input") or payload.get("prompt", "")
    
    # If still empty, check if the entire payload is just a string
    if not user_input and isinstance(payload, str):
        user_input = payload
    
    # Check for nested structures that AWS might send
    if not user_input and isinstance(payload, dict):
        # Try various possible payload structures
        user_input = (
            payload.get("inputText") or 
            payload.get("text") or
            payload.get("message") or
            payload.get("query") or
            ""
        )

    # Access request headers (for future Gateway/Auth integration)
    request_headers = context.request_headers or {} if context else {}
    auth_header = request_headers.get("Authorization", "")

    # Log invocation (visible in CloudWatch)
    print(f"[DEBUG] Full payload: {payload}")
    print(f"[DEBUG] Payload type: {type(payload)}")
    print(f"[DEBUG] Extracted user_input: '{user_input}'")
    print(f"Received prompt: {user_input}")
    print(f"Model: {MODEL_ID}")
    print(f"RAG Bucket: {RAG_BUCKET or 'Not configured'}")
    print(f"Auth header present: {bool(auth_header)}")

    try:
        # Define available tools
        tools = [
            get_product_info,
            get_return_policy,
        ]

        if model is None:
            print("[invoke] Model unavailable; using fallback agent")
            agent = Agent()
            response = agent(user_input)
            return {
                "status": "success",
                "response": response["message"]["content"][0]["text"]
            }

        # Create the agent with tools
        agent = Agent(
            model=model,
            tools=tools,
            system_prompt=SYSTEM_PROMPT,
        )

        # Invoke the agent
        print(f"[DEBUG] About to invoke agent with input: '{user_input}'")
        print(f"[DEBUG] System prompt: '{SYSTEM_PROMPT}'")
        response = agent(user_input)
        print(f"[DEBUG] Agent response type: {type(response)}")
        print(f"[DEBUG] Agent response: {response}")
        response_text = response.message["content"][0]["text"]
        print(f"[DEBUG] Extracted response text: '{response_text}'")
        
        # Return in format expected by AgentCore
        return {
            "status": "success",
            "response": response_text
        }

    except Exception as e:
        err_txt = str(e)
        print(f"Agent invocation error: {err_txt}")
        print(f"[DEBUG] Full traceback:\n{traceback.format_exc()}")
        # Detect Anthropic model gating message and provide clearer guidance
        if "Model use case details" in err_txt and "Anthropic" in err_txt:
            return {
                "status": "error",
                "response": (
                    "Anthropic model access not yet enabled for this account. "
                    "Submit the Anthropic model use case form in the AWS Bedrock console (Model access) "
                    "or switch FOUNDATION_MODEL to an approved model (e.g., amazon.titan-text-premier-v1:0)."
                )
            }
        if (
            "aws-marketplace:ViewSubscriptions" in err_txt
            or "aws-marketplace:Subscribe" in err_txt
        ):
            return {
                "status": "error",
                "response": (
                    "AWS Marketplace permissions missing for Anthropic model access. "
                    "The IAM role needs aws-marketplace:ViewSubscriptions and aws-marketplace:Subscribe. "
                    "Terraform update in progress—wait 10 minutes after terraform apply completes, then retry."
                )
            }
        return {
            "status": "error",
            "response": f"Error processing request: {err_txt}"
        }


if __name__ == "__main__":
    # Start the HTTP server (listens on port 8080)
    app.run()
