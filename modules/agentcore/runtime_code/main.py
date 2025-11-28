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
    from bedrock_agentcore.memory import MemoryClient
    from strands import Agent
    from strands.models import BedrockModel
    from strands.tools import tool
    from memory_hook_provider import MemoryHook

    print("[startup] Imported bedrock_agentcore + strands + memory successfully")
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
MEMORY_ID = os.environ.get("MEMORY_ID", "")  # From Terraform memory resource

# System prompt - Portfolio-focused conversational agent
SYSTEM_PROMPT = f"""You are Charles Brady's AI portfolio assistant. Your role is to have natural, engaging conversations about Charles's professional work, technical expertise, and projects.

## About Charles Brady

Charles is a full-stack software engineer and cloud architect with deep expertise in:

**Core Technologies:**
- AWS Cloud Architecture (Lambda, API Gateway, DynamoDB, S3, Cognito, CloudFront, Bedrock)
- Infrastructure as Code (Terraform)
- TypeScript/JavaScript (React, Node.js, Express)
- Python (AI/ML, backend services)
- Real-time 3D graphics and computer vision

**Key Projects:**

1. **Charlava.com** - Full-stack AWS platform
   - Serverless architecture with Lambda + API Gateway
   - Cognito authentication with custom UI
   - DynamoDB data layer
   - CloudFront CDN distribution
   - Nx monorepo with shared libraries

2. **CB-Common Platform** - Enterprise monorepo
   - Shared TypeScript libraries and services
   - API services with Express
   - React applications with Material-UI
   - Jest testing framework
   - CI/CD pipelines

3. **AgentCore Integration** - AI Agent Runtime (this system!)
   - AWS Bedrock integration
   - Conversational AI with memory
   - Custom tool development
   - Container-based deployment

4. **JamCam** - Real-time motion tracking
   - 3D pose estimation
   - Computer vision pipelines
   - Real-time rendering

5. **Guitar Normal Guy** - AI-powered image processing
   - YOLO object detection
   - Composite image generation
   - Node.js backend

## Conversation Guidelines

- Be conversational and natural - you're representing Charles professionally
- Provide specific technical details when asked
- Explain architectural decisions and trade-offs
- Reference actual code, tools, and technologies from the projects
- If you don't know something specific, acknowledge it honestly
- Use conversation history to maintain context across turns
- Ask clarifying questions when needed

## Available Information

{AGENT_INSTRUCTION}

Remember: You're having a professional conversation, not just answering queries. Build rapport, reference previous discussion points, and provide insights into Charles's technical approach and problem-solving style.
"""

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
def get_project_details(project_name: str) -> str:
    """
    Get detailed information about one of Charles's projects including architecture,
    technologies used, and key features.

    Args:
        project_name: Name of the project (e.g., 'charlava', 'cb-common', 'jamcam', 'guitar-normal-guy', 'agentcore')

    Returns:
        Detailed project information including tech stack and architecture
    """
    projects = {
        "charlava": {
            "description": "Full-stack AWS serverless platform for content delivery and user management",
            "architecture": "Serverless microservices on AWS",
            "tech_stack": [
                "AWS Lambda (Node.js/TypeScript)",
                "API Gateway with custom domain",
                "DynamoDB for data persistence",
                "Cognito for authentication",
                "CloudFront CDN",
                "S3 for static hosting",
                "Terraform for IaC",
            ],
            "features": [
                "Custom Cognito UI with branded login",
                "RESTful API services",
                "JWT-based authorization",
                "Python training pipelines for ML",
                "Nx monorepo structure",
            ],
            "highlights": "Demonstrates full AWS stack proficiency with infrastructure as code, serverless patterns, and production-ready security.",
        },
        "cb-common": {
            "description": "Enterprise-grade monorepo platform with shared libraries and applications",
            "architecture": "Nx monorepo with modular libraries and apps",
            "tech_stack": [
                "TypeScript/JavaScript",
                "React with Material-UI",
                "Express.js APIs",
                "Jest for testing",
                "AWS Lambda deployment",
                "Nx build system",
            ],
            "features": [
                "Shared UI components (@cb-common/ui-react-auth)",
                "API services with middleware",
                "AgentCore integration",
                "AI Chat interface",
                "Reusable Lambda utilities",
            ],
            "highlights": "Shows architectural skills in creating scalable, maintainable codebases with code reuse and separation of concerns.",
        },
        "jamcam": {
            "description": "Real-time 3D motion tracking and pose estimation application",
            "architecture": "Computer vision pipeline with 3D rendering",
            "tech_stack": [
                "Python computer vision",
                "Real-time pose estimation",
                "3D graphics rendering",
                "Model training pipelines",
            ],
            "features": [
                "Real-time motion capture",
                "3D skeleton tracking",
                "Custom ML model training",
                "Performance-optimized rendering",
            ],
            "highlights": "Demonstrates computer vision expertise and real-time processing capabilities.",
        },
        "guitar-normal-guy": {
            "description": "AI-powered image processing service for composite image generation",
            "architecture": "Node.js backend with YOLO integration",
            "tech_stack": [
                "Node.js/Express",
                "YOLO object detection",
                "Python ML models",
                "Image processing pipelines",
            ],
            "features": [
                "Object detection and segmentation",
                "Automated composite generation",
                "REST API for image processing",
                "ML model integration",
            ],
            "highlights": "Combines traditional backend development with modern AI/ML capabilities.",
        },
        "agentcore": {
            "description": "AWS Bedrock AgentCore runtime with conversational AI and memory",
            "architecture": "Container-based agent runtime on AWS Bedrock",
            "tech_stack": [
                "AWS Bedrock AgentCore",
                "Python with strands framework",
                "Docker containers (ARM64)",
                "CodeBuild for CI/CD",
                "Memory API for conversation persistence",
            ],
            "features": [
                "Conversational AI with memory",
                "Custom tool development",
                "Session management",
                "Cognito-protected Lambda integration",
                "Memory hooks for context retention",
            ],
            "highlights": "Cutting-edge AI agent implementation showcasing AWS Bedrock expertise and conversational AI development.",
        },
    }

    project_key = project_name.lower().replace("-", "").replace("_", "")
    project = projects.get(project_key)

    if not project:
        available = ", ".join(projects.keys())
        return f"I don't have detailed information about '{project_name}'. Available projects: {available}. Would you like to know about any of these?"

    tech_list = "\n  - ".join(project["tech_stack"])
    features_list = "\n  - ".join(project["features"])

    return f"""**{project_name.upper()} Project**

{project['description']}

**Architecture:** {project['architecture']}

**Technology Stack:**
  - {tech_list}

**Key Features:**
  - {features_list}

**Highlights:** {project['highlights']}
"""


@tool
def get_technical_expertise(area: str) -> str:
    """
    Get information about Charles's expertise in a specific technical area.

    Args:
        area: Technical domain (e.g., 'aws', 'terraform', 'typescript', 'python', 'ai', 'frontend', 'backend')

    Returns:
        Details about experience and capabilities in that area
    """
    expertise = {
        "aws": {
            "level": "Advanced",
            "services": [
                "Lambda (serverless functions)",
                "API Gateway (REST APIs)",
                "DynamoDB (NoSQL database)",
                "S3 (object storage)",
                "Cognito (authentication/authorization)",
                "CloudFront (CDN)",
                "Bedrock (AI/ML)",
                "CodeBuild (CI/CD)",
                "ECR (container registry)",
                "IAM (security/permissions)",
            ],
            "experience": "Production deployments with infrastructure as code (Terraform), serverless architectures, security best practices, and cost optimization.",
        },
        "terraform": {
            "level": "Advanced",
            "capabilities": [
                "Multi-environment deployments",
                "Custom module development",
                "State management",
                "Complex dependency orchestration",
                "AWS provider expertise",
                "Security and compliance patterns",
            ],
            "experience": "Extensive Terraform modules for AWS infrastructure including networking, compute, serverless, AI services, and complete application stacks.",
        },
        "typescript": {
            "level": "Advanced",
            "areas": [
                "React applications",
                "Node.js backend services",
                "Express.js APIs",
                "Type-safe architectures",
                "Nx monorepo tooling",
                "Jest testing",
            ],
            "experience": "Full-stack TypeScript development with emphasis on type safety, maintainability, and modern development practices.",
        },
        "python": {
            "level": "Advanced",
            "areas": [
                "AI/ML pipelines",
                "Computer vision (OpenCV, YOLO)",
                "Backend services",
                "AWS Lambda functions",
                "Data processing",
                "Agent development (strands, bedrock-agentcore)",
            ],
            "experience": "Production Python for AI/ML workflows, serverless functions, and computer vision applications.",
        },
        "ai": {
            "level": "Intermediate to Advanced",
            "capabilities": [
                "AWS Bedrock integration",
                "Conversational AI agents",
                "Computer vision (pose estimation, object detection)",
                "ML model training and deployment",
                "Agent memory and tool development",
                "Prompt engineering",
            ],
            "experience": "Building production AI systems with AWS Bedrock, custom agent development, and computer vision applications.",
        },
        "frontend": {
            "level": "Advanced",
            "technologies": [
                "React with hooks",
                "Material-UI component library",
                "TypeScript",
                "Responsive design",
                "State management",
                "API integration",
            ],
            "experience": "Modern React applications with focus on user experience, accessibility, and maintainable component architectures.",
        },
        "backend": {
            "level": "Advanced",
            "technologies": [
                "Node.js/Express",
                "AWS Lambda",
                "RESTful API design",
                "Authentication/Authorization",
                "Database design (DynamoDB, SQL)",
                "Microservices architecture",
            ],
            "experience": "Production backend services with serverless and traditional architectures, emphasizing scalability and security.",
        },
    }

    area_key = area.lower().replace(" ", "").replace("-", "")
    info = expertise.get(area_key)

    if not info:
        available = ", ".join(expertise.keys())
        return f"I can discuss expertise in: {available}. Which area interests you?"

    details_key = (
        "services"
        if "services" in info
        else (
            "capabilities"
            if "capabilities" in info
            else "areas" if "areas" in info else "technologies"
        )
    )
    details_list = "\n  - ".join(info.get(details_key, []))

    return f"""**{area.upper()} Expertise**

**Level:** {info['level']}

**{details_key.title()}:**
  - {details_list}

**Experience:** {info['experience']}
"""


# ============================================================================
# ENTRYPOINT - AgentCore Runtime invocation handler
# ============================================================================


@app.entrypoint
async def invoke(payload, context=None):
    """
    AgentCore Runtime entrypoint function.
    Processes user prompts and returns agent responses with memory persistence.

    Args:
        payload: dict with user input and session context
                 Expected: {"input": "...", "sessionId": "...", "actorId": "..."}
        context: request context (headers, metadata, etc.)

    Returns:
        Agent response with session tracking
    """
    # Extract user input - support multiple payload formats
    user_input = payload.get("input") or payload.get("prompt", "")

    if not user_input and isinstance(payload, str):
        user_input = payload

    if not user_input and isinstance(payload, dict):
        user_input = (
            payload.get("inputText")
            or payload.get("text")
            or payload.get("message")
            or payload.get("query")
            or ""
        )

    # Extract session context for memory
    session_id = payload.get("sessionId", "default-session")
    actor_id = payload.get("actorId", "anonymous")

    # Access request headers
    request_headers = context.request_headers or {} if context else {}
    auth_header = request_headers.get("Authorization", "")

    # Log invocation details
    print(f"[invoke] Session: {session_id}, Actor: {actor_id}")
    print(f"[invoke] User input: {user_input[:100]}...")
    print(f"[invoke] Model: {MODEL_ID}")
    print(f"[invoke] Memory ID: {MEMORY_ID or 'Not configured'}")
    print(f"[DEBUG] Full payload: {payload}")

    try:
        # Define available tools
        tools = [
            get_project_details,
            get_technical_expertise,
        ]

        if model is None:
            print("[invoke] Model unavailable; using fallback")
            return {
                "status": "error",
                "response": "Agent model not initialized. Check CloudWatch logs for import errors.",
                "sessionId": session_id,
                "actorId": actor_id,
            }

        # Initialize memory hook if memory is configured
        memory_hook = None
        if MEMORY_ID:
            try:
                print(f"[invoke] Initializing MemoryClient with memory_id={MEMORY_ID}")
                memory_client = MemoryClient()
                memory_hook = MemoryHook(
                    memory_client=memory_client,
                    memory_id=MEMORY_ID,
                    actor_id=actor_id,
                    session_id=session_id,
                )
                print("[invoke] Memory hook initialized successfully")
            except Exception as mem_err:
                print(f"[invoke] Memory initialization failed: {mem_err}")
                # Continue without memory rather than failing
                memory_hook = None

        # Create the agent with tools and optional memory
        agent_kwargs = {
            "model": model,
            "tools": tools,
            "system_prompt": SYSTEM_PROMPT,
        }

        if memory_hook:
            agent_kwargs["hooks"] = [memory_hook]
            print("[invoke] Agent created with memory hooks")
        else:
            print("[invoke] Agent created without memory (disabled or unavailable)")

        agent = Agent(**agent_kwargs)

        # Invoke the agent
        print(f"[invoke] Invoking agent...")
        response = agent(user_input)
        response_text = response.message["content"][0]["text"]
        print(f"[invoke] Response generated: {response_text[:100]}...")

        return {
            "status": "success",
            "response": response_text,
            "sessionId": session_id,
            "actorId": actor_id,
            "memoryEnabled": bool(memory_hook),
        }

    except Exception as e:
        err_txt = str(e)
        print(f"[invoke] ERROR: {err_txt}")
        print(f"[invoke] Traceback:\n{traceback.format_exc()}")

        # Provide helpful error messages
        if "Model use case details" in err_txt and "Anthropic" in err_txt:
            return {
                "status": "error",
                "response": (
                    "Anthropic model access not enabled. Submit use case form in AWS Bedrock console "
                    "or switch to an approved model (e.g., amazon.titan-text-premier-v1:0)."
                ),
                "sessionId": session_id,
                "actorId": actor_id,
            }

        if "aws-marketplace" in err_txt.lower():
            return {
                "status": "error",
                "response": (
                    "AWS Marketplace permissions missing. IAM role needs marketplace permissions. "
                    "Wait 10 minutes after terraform apply, then retry."
                ),
                "sessionId": session_id,
                "actorId": actor_id,
            }

        return {
            "status": "error",
            "response": f"Error: {err_txt}",
            "sessionId": session_id,
            "actorId": actor_id,
        }


if __name__ == "__main__":
    # Start the HTTP server (listens on port 8080)
    app.run()
