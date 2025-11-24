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
echo "📝 Copying main.py..."
cp "$SCRIPT_DIR/main.py" "$BUILD_DIR/"

# Install dependencies
echo "📚 Installing Python dependencies..."
echo "   This may take a minute..."

# Create a minimal requirements file (excluding packages that are pre-installed)
cat > "$BUILD_DIR/requirements_build.txt" << EOF
# Only install packages NOT pre-installed in AgentCore runtime
# bedrock-agentcore and bedrock-agentcore-runtime are already there
# strands packages - try to install if available
boto3>=1.40.0
pyyaml
EOF

# Try to install strands if available (may fail if not public)
echo ""
echo "⚠️  Note: Some packages may not be publicly available"
pip install -r "$BUILD_DIR/requirements_build.txt" -t "$BUILD_DIR" --upgrade || true

# Try strands separately (may be in a private repo)
echo ""
echo "Attempting to install strands packages..."
pip install strands-agents -t "$BUILD_DIR" 2>/dev/null || echo "   ℹ️  strands-agents not available (will use runtime version)"
pip install strands-agents-tools -t "$BUILD_DIR" 2>/dev/null || echo "   ℹ️  strands-agents-tools not available (will use runtime version)"

# Clean up build artifacts
echo ""
echo "🧹 Cleaning build artifacts..."
find "$BUILD_DIR" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find "$BUILD_DIR" -type d -name "*.dist-info" -exec rm -rf {} + 2>/dev/null || true
find "$BUILD_DIR" -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
find "$BUILD_DIR" -type f -name "*.pyc" -delete 2>/dev/null || true
rm -f "$BUILD_DIR/requirements_build.txt"

# Create deployment package
echo ""
echo "🗜️  Creating deployment package..."
cd "$BUILD_DIR"
zip -r "$ZIP_FILE" . -q

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
