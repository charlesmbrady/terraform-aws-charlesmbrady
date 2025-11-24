#!/bin/bash
# Manual deployment script for AgentCore runtime with vendored dependencies
# Run this from your local machine to build and deploy the full agent

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
ZIP_FILE="$SCRIPT_DIR/runtime_code_full.zip"

echo "🏗️  Building AgentCore Runtime with Dependencies"
echo "================================================"
echo ""

# Clean previous build
echo "🧹 Cleaning previous build..."
rm -rf "$BUILD_DIR"
rm -f "$ZIP_FILE"

# Create build directory
echo "📦 Creating build directory..."
mkdir -p "$BUILD_DIR"

# Copy main code (the full version with strands)
echo "📝 Copying main.py to build root..."
cp "$SCRIPT_DIR/main.py" "$BUILD_DIR/main.py"

# Install dependencies
echo "📚 Installing Python dependencies for ARM64..."
echo "   This may take a minute..."

# Install core dependencies for ARM64/aarch64 platform
echo "   Installing bedrock-agentcore..."
pip install bedrock-agentcore==0.1.7 \
  -t "$BUILD_DIR" \
  --platform manylinux2014_aarch64 \
  --only-binary=:all: \
  --python-version 312 \
  --upgrade \
  --quiet 2>/dev/null || echo "   ⚠️  bedrock-agentcore failed (may need manual install)"

echo "   Installing strands packages..."
pip install strands-agents strands-agents-tools \
  -t "$BUILD_DIR" \
  --platform manylinux2014_aarch64 \
  --only-binary=:all: \
  --python-version 312 \
  --quiet 2>/dev/null || echo "   ⚠️  strands packages failed (may need manual install)"

echo "   Installing boto3, pyyaml..."
pip install boto3>=1.40.0 pyyaml \
  -t "$BUILD_DIR" \
  --platform manylinux2014_aarch64 \
  --only-binary=:all: \
  --python-version 312 \
  --upgrade \
  --quiet || true

# Clean up build artifacts
echo ""
echo "🧹 Cleaning build artifacts..."
cd "$BUILD_DIR"
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -type d -name "*.dist-info" -exec rm -rf {} + 2>/dev/null || true
find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
find . -type f -name "*.pyc" -delete 2>/dev/null || true

# Create deployment package FROM INSIDE build directory
echo ""
echo "🗜️  Creating deployment package..."
zip -r "$ZIP_FILE" . -q

cd "$SCRIPT_DIR"

echo ""
echo "📋 Verifying zip contents..."
unzip -l "$ZIP_FILE" | head -20

cd "$SCRIPT_DIR"

echo ""
echo "✅ Package created successfully!"
echo "📊 Package size: $(du -h "$ZIP_FILE" | cut -f1)"
echo ""
echo "📤 To deploy to AWS:"
echo ""
echo "1. Get the bucket name:"
echo "   cd ../../.."
echo "   BUCKET=\$(terraform output -raw agentcore_runtime_code_bucket_name)"
echo ""
echo "2. Upload the package:"
echo "   aws s3 cp modules/agentcore/runtime_code/runtime_code_full.zip s3://\$BUCKET/agent-runtime/code.zip"
echo ""
echo "3. Terraform will detect the change on next apply:"
echo "   terraform apply"
echo ""
echo "Or run this one-liner from terraform root:"
echo "   aws s3 cp modules/agentcore/runtime_code/runtime_code_full.zip s3://\$(terraform output -raw agentcore_runtime_code_bucket_name)/agent-runtime/code.zip && terraform apply"
