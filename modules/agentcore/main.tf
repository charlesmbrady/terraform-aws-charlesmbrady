###############################################################################
#### AgentCore Module - Main Configuration
###############################################################################

locals {
  # Use underscores instead of hyphens to comply with AWS naming regex: ^[a-zA-Z][a-zA-Z0-9_]{0,47}$
  agentcore_name = replace("${var.project_name}_${var.agent_name}_${var.environment_tag}", "-", "_")
  
  # Gateway requires hyphen-based naming: ^([0-9a-zA-Z][-]?){1,100}$
  gateway_name = "${var.project_name}-${var.agent_name}-${var.environment_tag}-gateway"
  # ECR repository name must be lowercase and match ECR naming rules
  basic_agent_ecr_name = lower("${var.project_name}-${var.agent_name}-${var.environment_tag}-basic-agent")
}

###############################################################################
#### AgentCore Runtime
###############################################################################

resource "aws_bedrockagentcore_agent_runtime" "main" {
  agent_runtime_name = local.agentcore_name
  role_arn           = aws_iam_role.agentcore_runtime.arn
  description        = var.agent_description

  # Container-based artifact configuration - uses ARM64 image built by CodeBuild
  agent_runtime_artifact {
    container_configuration {
      container_uri = "${aws_ecr_repository.basic_agent.repository_url}:latest"
    }
  }

  # Minimal network configuration (PUBLIC or VPC)
  network_configuration {
    network_mode = "PUBLIC"
  }

  # Pass model + instruction + rag bucket + memory ID to the runtime container/code
  environment_variables = {
    AGENT_INSTRUCTION = var.agent_instruction
    FOUNDATION_MODEL  = var.foundation_model
    RAG_BUCKET        = var.rag_enabled ? local.rag_bucket_effective_name : ""
    MEMORY_ID         = var.enable_memory ? aws_bedrockagentcore_memory.main[0].id : ""
  }

  tags = {
    Name        = local.agentcore_name
    Environment = var.environment_tag
  }
}

###############################################################################
#### AgentCore Runtime Endpoint
###############################################################################

## NOTE: The prior "aws_bedrockagentcore_agent_runtime_endpoint" resource has been removed.
## If endpoints become available/required in the provider schema later, reintroduce accordingly.

###############################################################################
#### AgentCore Gateway
###############################################################################

resource "aws_bedrockagentcore_gateway" "main" {
  name            = local.gateway_name
  protocol_type   = "MCP"     # Valid values: MCP
  authorizer_type = "AWS_IAM" # Using IAM auth (no JWT authorizer block required)
  role_arn        = aws_iam_role.agentcore_runtime.arn

  tags = {
    Name        = local.gateway_name
    Environment = var.environment_tag
  }
}

###############################################################################
#### AgentCore Gateway Tool - Lambda Integration
###############################################################################
# Note: aws_bedrockagentcore_gateway_tool does not exist in the provider.
# Tool integration is handled at invocation time via Lambda permissions.
# The gateway already has IAM role permissions to invoke the Lambda tool.

###############################################################################
#### AgentCore Memory Configuration
###############################################################################

resource "aws_bedrockagentcore_memory" "main" {
  count = var.enable_memory ? 1 : 0

  name                  = "${local.agentcore_name}_memory"
  event_expiry_duration = var.memory_retention_days # Days (7-365)
  description           = "Persistent memory for ${local.agentcore_name}"

  tags = {
    Name        = "${local.agentcore_name}_memory"
    Environment = var.environment_tag
  }
}

###############################################################################
#### DIY RAG Lightweight Embeddings Storage (S3)
###############################################################################

locals {
  # S3 bucket naming must be lowercase letters, numbers, and hyphens (no underscores, no uppercase).
  # Derive a base from agentcore_name by replacing underscores with hyphens and lowercasing.
  agentcore_bucket_base     = lower(replace(local.agentcore_name, "_", "-"))
  rag_bucket_effective_name = var.rag_bucket_name != "" ? lower(replace(var.rag_bucket_name, "_", "-")) : "${local.agentcore_bucket_base}-rag-embeddings"
}

resource "aws_s3_bucket" "rag_embeddings" {
  count         = var.rag_enabled ? 1 : 0
  bucket        = local.rag_bucket_effective_name
  force_destroy = true

  tags = {
    Name        = local.rag_bucket_effective_name
    Purpose     = "DIY-RAG-Embeddings"
    Environment = var.environment_tag
  }
}

resource "aws_s3_bucket_public_access_block" "rag_embeddings" {
  count                   = var.rag_enabled ? 1 : 0
  bucket                  = aws_s3_bucket.rag_embeddings[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_ssm_parameter" "rag_bucket_name" {
  count       = var.rag_enabled ? 1 : 0
  name        = "/${var.project_name}/${var.environment_tag}/agentcore/rag/bucket-name"
  description = "S3 bucket name storing DIY RAG embeddings JSON"
  type        = "String"
  value       = aws_s3_bucket.rag_embeddings[0].bucket

  tags = {
    Name        = "agentcore-rag-bucket-name"
    Environment = var.environment_tag
  }
}

###############################################################################
#### NOTE: SSM parameters for runtime/gateway ID/ARN removed
###############################################################################
# The provider does not export runtime or gateway id/arn attributes. References
# to those attributes caused Terraform errors. These SSM parameters are removed
# to ensure a successful apply without unsupported attribute lookups.


###############################################################################
#### CloudWatch Log Group for AgentCore
###############################################################################

## NOTE: Do not pre-create a custom CloudWatch log group. The service creates
## log groups under /aws/bedrock-agentcore/runtimes/ automatically. Pre-creating
## a mismatched path (e.g. /aws/bedrock/agentcore/...) leads to confusion when
## logs appear empty. Retaining no manual log group ensures correct automatic
## log stream generation.

###############################################################################
#### Basic Agent ECR Repository (for container-based runtime)
###############################################################################

resource "aws_ecr_repository" "basic_agent" {
  name                 = local.basic_agent_ecr_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${local.basic_agent_ecr_name}-repository"
    Environment = var.environment_tag
    Module      = "ECR"
  }
}

###############################################################################
#### CodeBuild Project - Build ARM64 Basic Agent Image
###############################################################################

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "codebuild_role" {
  name = "${var.project_name}-${var.agent_name}-${var.environment_tag}-codebuild-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "codebuild.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  inline_policy {
    name = "CodeBuildPolicy"
    policy = jsonencode({
      Version   = "2012-10-17"
      Statement = [
        {
          Sid    = "CloudWatchLogs"
          Effect = "Allow"
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
          ]
          Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/*"
        },
        {
          Sid    = "ECRAccess"
          Effect = "Allow"
          Action = [
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:GetAuthorizationToken",
            "ecr:PutImage",
            "ecr:InitiateLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:CompleteLayerUpload",
          ]
          Resource = [
            aws_ecr_repository.basic_agent.arn,
            "*",
          ]
        },
      ]
    })
  }

  tags = {
    Name        = "${var.project_name}-${var.agent_name}-${var.environment_tag}-codebuild-role"
    Environment = var.environment_tag
    Module      = "IAM"
  }
}

resource "aws_codebuild_project" "basic_agent_image" {
  name        = "${var.project_name}-${var.agent_name}-${var.environment_tag}-basic-agent-build"
  description = "Build basic agent Docker image for ${var.project_name}-${var.agent_name}-${var.environment_tag}"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    type            = "ARM_CONTAINER"
    compute_type    = "BUILD_GENERAL1_LARGE"
    image           = "aws/codebuild/amazonlinux2-aarch64-standard:3.0"
    privileged_mode = true

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = data.aws_region.current.name
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = aws_ecr_repository.basic_agent.name
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }
  }

  source {
    type      = "NO_SOURCE"
    buildspec = <<-EOT
      version: 0.2
      phases:
        install:
          commands:
            - echo Installing dependencies...
            - yum install -y git
        pre_build:
          commands:
            - echo Logging in to Amazon ECR...
            - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
            
            # Download runtime code from module (assumes this module is in a git repo or accessible path)
            # For now, we'll fetch from the Terraform module path by cloning or copying
            # Alternative: Store runtime_code in S3 and download here
            - echo Preparing runtime code...
            
        build:
          commands:
            - echo Build started on `date`
            - echo Building the Docker image for AgentCore runtime ARM64...

            # Create requirements.txt
            - |
              cat > requirements.txt << 'EOF'
              strands-agents
              boto3
              bedrock-agentcore
              aws-opentelemetry-distro>=0.10.1
              EOF

            # Create main.py from your actual runtime code
            # Note: This embeds your updated main.py with memory support
            - |
              cat > main.py << 'MAINPY'
              """
              AgentCore Runtime Entrypoint - Portfolio Assistant with Memory
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
                  print(f"[startup-error] Import failure: {import_err}")
                  traceback.print_exc()

              # Get AWS region
              _session_region = boto3.session.Session().region_name
              REGION = _session_region or os.environ.get("AWS_REGION") or os.environ.get("AWS_DEFAULT_REGION") or "us-east-1"

              # Read configuration from environment
              MODEL_ID = os.environ.get("FOUNDATION_MODEL", "anthropic.claude-3-5-sonnet-20240620-v1:0")
              AGENT_INSTRUCTION = os.environ.get("AGENT_INSTRUCTION", "You are a helpful assistant.")
              RAG_BUCKET = os.environ.get("RAG_BUCKET", "")
              MEMORY_ID = os.environ.get("MEMORY_ID", "")

              # Portfolio-focused system prompt
              SYSTEM_PROMPT = f"""You are Charles Brady's AI portfolio assistant. Your role is to have natural, engaging conversations about Charles's professional work, technical expertise, and projects.

              ## About Charles Brady
              Charles is a full-stack software engineer and cloud architect with expertise in AWS, Terraform, TypeScript/JavaScript, Python, and AI/ML.

              Key projects include:
              - Charlava.com: Serverless AWS platform
              - CB-Common: Enterprise monorepo with shared libraries
              - AgentCore: AI agent runtime with conversational memory
              - JamCam: Real-time 3D motion tracking
              - Guitar Normal Guy: AI-powered image processing

              Be conversational, provide technical details, and use conversation history to maintain context.

              {AGENT_INSTRUCTION}
              """

              # Initialize model
              try:
                  model = BedrockModel(model_id=MODEL_ID, region_name=REGION)
                  print(f"[startup] Initialized BedrockModel {MODEL_ID} region {REGION}")
              except Exception as model_err:
                  print(f"[startup-error] Model init failed: {model_err}")
                  model = None

              # Initialize the AgentCore Runtime App
              app = BedrockAgentCoreApp()
              print(f"[startup] Runtime ready - Model: {MODEL_ID}, Region: {REGION}, Memory: {MEMORY_ID or 'disabled'}")

              # Tools
              @tool
              def get_project_details(project_name: str) -> str:
                  """Get detailed information about Charles's projects"""
                  projects = {
                      "charlava": "Full-stack AWS serverless platform with Lambda, API Gateway, DynamoDB, Cognito, CloudFront",
                      "cb-common": "Enterprise Nx monorepo with shared TypeScript libraries, React apps, Express APIs",
                      "agentcore": "AWS Bedrock agent runtime with conversational AI and persistent memory",
                      "jamcam": "Real-time 3D motion tracking with computer vision",
                      "guitar-normal-guy": "AI-powered image processing with YOLO object detection"
                  }
                  return projects.get(project_name.lower(), f"Project '{project_name}' not found. Available: {', '.join(projects.keys())}")

              @tool
              def get_technical_expertise(area: str) -> str:
                  """Get information about Charles's technical expertise"""
                  expertise = {
                      "aws": "Advanced - Lambda, API Gateway, DynamoDB, S3, Cognito, CloudFront, Bedrock, IAM",
                      "terraform": "Advanced - Multi-environment deployments, custom modules, AWS provider",
                      "typescript": "Advanced - React, Node.js, Express, type-safe architectures, Nx monorepo",
                      "python": "Advanced - AI/ML, computer vision, backend services, AWS Lambda",
                      "ai": "Intermediate-Advanced - Bedrock, conversational agents, computer vision, ML pipelines"
                  }
                  return expertise.get(area.lower(), f"Area '{area}' not found. Available: {', '.join(expertise.keys())}")

              @app.entrypoint
              async def invoke(payload, context=None):
                  """AgentCore entrypoint with memory support"""
                  # Extract input and session context
                  user_input = payload.get("input") or payload.get("prompt", "")
                  if not user_input and isinstance(payload, str):
                      user_input = payload
                  if not user_input and isinstance(payload, dict):
                      user_input = payload.get("inputText") or payload.get("text") or payload.get("message") or payload.get("query") or ""

                  session_id = payload.get("sessionId", "default-session")
                  actor_id = payload.get("actorId", "anonymous")

                  print(f"[invoke] Session: {session_id}, Actor: {actor_id}, Input: {user_input[:100]}...")

                  try:
                      tools = [get_project_details, get_technical_expertise]

                      if model is None:
                          return {"status": "error", "response": "Model not initialized", "sessionId": session_id}

                      # Initialize memory if configured
                      memory_hook = None
                      if MEMORY_ID:
                          try:
                              print(f"[invoke] Initializing memory with ID={MEMORY_ID}")
                              memory_client = MemoryClient()
                              memory_hook = MemoryHook(
                                  memory_client=memory_client,
                                  memory_id=MEMORY_ID,
                                  actor_id=actor_id,
                                  session_id=session_id,
                              )
                              print("[invoke] Memory hook initialized")
                          except Exception as mem_err:
                              print(f"[invoke] Memory init failed: {mem_err}")

                      # Create agent
                      agent_kwargs = {"model": model, "tools": tools, "system_prompt": SYSTEM_PROMPT}
                      if memory_hook:
                          agent_kwargs["hooks"] = [memory_hook]
                      agent = Agent(**agent_kwargs)

                      # Invoke
                      response = agent(user_input)
                      response_text = response.message["content"][0]["text"]
                      
                      return {
                          "status": "success",
                          "response": response_text,
                          "sessionId": session_id,
                          "actorId": actor_id,
                          "memoryEnabled": bool(memory_hook)
                      }

                  except Exception as e:
                      print(f"[invoke] ERROR: {e}")
                      traceback.print_exc()
                      return {"status": "error", "response": str(e), "sessionId": session_id}

              if __name__ == "__main__":
                  app.run()
              MAINPY

            # Create memory_hook_provider.py
            - |
              cat > memory_hook_provider.py << 'MEMORYHOOK'
              from bedrock_agentcore.memory import MemoryClient
              from strands.hooks.events import AgentInitializedEvent, MessageAddedEvent
              from strands.hooks.registry import HookProvider, HookRegistry
              import copy

              class MemoryHook(HookProvider):
                  def __init__(self, memory_client: MemoryClient, memory_id: str, actor_id: str, session_id: str):
                      self.memory_client = memory_client
                      self.memory_id = memory_id
                      self.actor_id = actor_id
                      self.session_id = session_id
                      print(f"[MemoryHook] Init - memory={memory_id}, actor={actor_id}, session={session_id}")

                  def on_agent_initialized(self, event: AgentInitializedEvent):
                      try:
                          print(f"[MemoryHook] Loading history for session {self.session_id}")
                          recent_turns = self.memory_client.get_last_k_turns(
                              memory_id=self.memory_id,
                              actor_id=self.actor_id,
                              session_id=self.session_id,
                              k=5
                          )
                          if not recent_turns:
                              print("[MemoryHook] No previous history")
                              return
                          context_messages = []
                          for turn in recent_turns:
                              for message in turn["messages"]:
                                  role = "assistant" if message["role"] == "assistant" else "user"
                                  content = message["content"]["text"]
                                  context_messages.append({"role": role, "content": [{"text": content}]})
                          print(f"[MemoryHook] Loaded {len(context_messages)} messages")
                          event.agent.messages = context_messages
                      except Exception as e:
                          print(f"[MemoryHook] Load error: {e}")

                  def on_message_added(self, event: MessageAddedEvent):
                      messages = copy.deepcopy(event.agent.messages)
                      try:
                          if messages[-1]["role"] not in ["user", "assistant"]:
                              return
                          if "text" not in messages[-1]["content"][0]:
                              return
                          message_text = messages[-1]["content"][0]["text"]
                          message_role = messages[-1]["role"]
                          print(f"[MemoryHook] Saving {message_role} message")
                          self.memory_client.save_conversation(
                              memory_id=self.memory_id,
                              actor_id=self.actor_id,
                              session_id=self.session_id,
                              messages=[(message_text, message_role)]
                          )
                      except Exception as e:
                          print(f"[MemoryHook] Save error: {e}")

                  def register_hooks(self, registry: HookRegistry):
                      registry.add_callback(MessageAddedEvent, self.on_message_added)
                      registry.add_callback(AgentInitializedEvent, self.on_agent_initialized)
              MEMORYHOOK

            # Create Dockerfile
            - |
              cat > Dockerfile << 'EOF'
              FROM public.ecr.aws/docker/library/python:3.11-slim
              WORKDIR /app

              COPY requirements.txt requirements.txt
              RUN pip install --no-cache-dir -r requirements.txt

              ENV AWS_REGION=$AWS_DEFAULT_REGION
              ENV AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION

              RUN useradd -m -u 1000 bedrock_agentcore
              USER bedrock_agentcore

              EXPOSE 8080
              EXPOSE 8000

              COPY main.py memory_hook_provider.py ./

              CMD ["opentelemetry-instrument", "python", "main.py"]
              EOF

            # Build the image
            - echo Building ARM64 image...
            - docker build -t $IMAGE_REPO_NAME:$IMAGE_TAG .
            - docker tag $IMAGE_REPO_NAME:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG

        post_build:
          commands:
            - echo Build completed on `date`
            - echo Pushing the Docker image...
            - docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG
            - echo ARM64 Docker image pushed successfully
      EOT
  }

  tags = {
    Name        = "${var.project_name}-${var.agent_name}-${var.environment_tag}-basic-build"
    Environment = var.environment_tag
    Module      = "CodeBuild"
  }
}

