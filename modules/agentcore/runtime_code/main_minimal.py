"""
AgentCore Runtime - Simplified Production Version
Uses only pre-installed runtime dependencies (bedrock_agentcore, strands)
"""

import os
import json

print("[startup] Beginning runtime import sequence")

from bedrock_agentcore.runtime import BedrockAgentCoreApp
from strands import Agent
from strands.models import BedrockModel
from strands.tools import tool

print("[startup] ✓ Imported bedrock_agentcore + strands successfully")

# Get AWS region from session
import boto3

REGION = boto3.session.Session().region_name

# Read configuration from environment variables (set by Terraform)
MODEL_ID = os.environ.get(
    "FOUNDATION_MODEL", "anthropic.claude-3-5-sonnet-20240620-v1:0"
)
AGENT_INSTRUCTION = os.environ.get("AGENT_INSTRUCTION", "You are a helpful assistant.")
RAG_BUCKET = os.environ.get("RAG_BUCKET", "")

print(f"[startup] Model: {MODEL_ID}")
print(f"[startup] Region: {REGION}")
print(f"[startup] RAG Bucket: {RAG_BUCKET or 'Not configured'}")

# Initialize Bedrock model
model = BedrockModel(model_id=MODEL_ID, region_name=REGION)
print(f"[startup] ✓ Initialized BedrockModel")

# Initialize the AgentCore Runtime App
app = BedrockAgentCoreApp()


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

    # Access request headers (for future Gateway/Auth integration)
    request_headers = context.request_headers or {} if context else {}
    auth_header = request_headers.get("Authorization", "")

    # Log invocation (visible in CloudWatch)
    print(f"[invoke] Received input: {user_input}")
    print(f"[invoke] Model: {MODEL_ID}")
    print(f"[invoke] Auth header present: {bool(auth_header)}")

    try:
        # Define available tools
        tools = [
            get_product_info,
            get_return_policy,
        ]

        # Create the agent with tools
        agent = Agent(
            model=model,
            tools=tools,
            system_prompt=AGENT_INSTRUCTION,
        )

        # Invoke the agent
        print("[invoke] Calling agent...")
        response = agent(user_input)
        result = response.message["content"][0]["text"]
        print(f"[invoke] Response length: {len(result)} chars")
        return result

    except Exception as e:
        import traceback

        error_msg = f"Agent invocation error: {str(e)}"
        print(f"[invoke-error] {error_msg}")
        print(f"[invoke-error] Traceback:\n{traceback.format_exc()}")
        return error_msg


if __name__ == "__main__":
    print("[startup] Starting app.run()")
    app.run()
