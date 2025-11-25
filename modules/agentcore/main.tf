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

  # Pass model + instruction + rag bucket to the runtime container/code
  environment_variables = {
    AGENT_INSTRUCTION = var.agent_instruction
    FOUNDATION_MODEL  = var.foundation_model
    RAG_BUCKET        = var.rag_enabled ? local.rag_bucket_effective_name : ""
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
        pre_build:
          commands:
            - echo Logging in to Amazon ECR...
            - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
        build:
          commands:
            - echo Build started on `date`
            - echo Building the Docker image for basic agent ARM64...

            # Step 1.1: Create requirements.txt
            - |
              cat > requirements.txt << 'EOF'
              strands-agents
              boto3
              bedrock-agentcore
              EOF

            # Step 1.2: Create my_agent.py (enhanced version with proper input handling & debug logs)
            - |
              cat > my_agent.py << 'EOF'
              import os, sys, traceback, json, time
              from strands import Agent
              from bedrock_agentcore.runtime import BedrockAgentCoreApp

              app = BedrockAgentCoreApp()

              def _log(msg: str):
                # Simple structured-ish logging; CloudWatch will capture stdout
                print(json.dumps({"level": "DEBUG", "msg": msg, "ts": time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())}))
                sys.stdout.flush()

              SYSTEM_PROMPT = os.getenv("AGENT_INSTRUCTION", "You are a helpful assistant. Respond clearly and concisely.")

              CAPABILITIES_TEXT = (
                "I can help you with: \n"
                "• Product technical specifications (laptops, smartphones, headphones, monitors)\n"
                "• Return policy details by product category\n"
                "Ask: 'product info <type>' or 'return policy <category>' to begin."
              )

              def create_basic_agent() -> Agent:
                return Agent(system_prompt=SYSTEM_PROMPT, name="BasicAgent")

              def handle_structured_query(query: str) -> str:
                ql = query.lower().strip()
                if ql.startswith("product info"):
                  parts = ql.split()
                  if len(parts) >= 3:
                    product = parts[-1]
                    return f"(stub) Product info for {product}: specs forthcoming."
                  return "Please specify a product type, e.g. 'product info laptops'."
                if ql.startswith("return policy"):
                  parts = ql.split()
                  if len(parts) >= 3:
                    cat = parts[-1]
                    return f"(stub) Return policy for {cat}: details forthcoming."
                  return "Please specify a category, e.g. 'return policy smartphones'."
                if "help" in ql or "what can" in ql:
                  return CAPABILITIES_TEXT
                return "General query received. Ask 'help' to see capabilities."

              @app.entrypoint
              async def invoke(payload=None):
                start = time.time()
                try:
                  _log(f"Raw payload: {payload}")
                  query = ""
                  if isinstance(payload, dict):
                    query = (
                      payload.get("input") or
                      payload.get("prompt") or
                      payload.get("inputText") or
                      payload.get("text") or
                      payload.get("message") or
                      payload.get("query") or ""
                    )
                  elif isinstance(payload, str):
                    query = payload
                  query = query or "What can you help me with?"
                  _log(f"Extracted query: {query}")

                  # Lightweight intent routing before LLM
                  routed = handle_structured_query(query)
                  _log(f"Routed response (pre-LLM): {routed}")

                  # LLM augmentation (optional); keep short to control cost
                  agent = create_basic_agent()
                  llm_response = agent(f"User asked: {query}\nContext hint: {routed}\nRespond helpfully.")
                  text = llm_response.message['content'][0]['text']
                  _log(f"LLM raw response: {text}")

                  elapsed = round(time.time() - start, 3)
                  return {"status": "success", "response": text, "elapsed_sec": elapsed}
                except Exception as e:
                  _log(f"ERROR: {e}\n{traceback.format_exc()}")
                  return {"status": "error", "error": str(e)}

              if __name__ == "__main__":
                _log("Starting app server on port 8080")
                app.run()
              EOF

            # Step 1.3: Create Dockerfile
            - |
              cat > Dockerfile << 'EOF'
              FROM public.ecr.aws/docker/library/python:3.11-slim
              WORKDIR /app

              COPY requirements.txt requirements.txt
              RUN pip install --no-cache-dir -r requirements.txt && \
                  pip install --no-cache-dir aws-opentelemetry-distro>=0.10.1

              ENV AWS_REGION=$AWS_DEFAULT_REGION
              ENV AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION

              # Create non-root user
              RUN useradd -m -u 1000 bedrock_agentcore
              USER bedrock_agentcore

              EXPOSE 8080
              EXPOSE 8000

              COPY . .

              CMD ["opentelemetry-instrument", "python", "-m", "my_agent"]
              EOF

            # Step 1.4: Build the image
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

