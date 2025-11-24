#!/bin/bash
# Build runtime package with vendored dependencies

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
ZIP_FILE="$SCRIPT_DIR/../runtime_code.zip"

echo "🧹 Cleaning previous build..."
rm -rf "$BUILD_DIR"
rm -f "$ZIP_FILE"

echo "📦 Creating build directory..."
mkdir -p "$BUILD_DIR"

echo "📝 Copying source files..."
cp "$SCRIPT_DIR/main.py" "$BUILD_DIR/"
cp "$SCRIPT_DIR/requirements.txt" "$BUILD_DIR/"

echo "📚 Installing dependencies to build directory..."
pip install -r "$SCRIPT_DIR/requirements.txt" -t "$BUILD_DIR" --upgrade

echo "🗜️  Creating deployment package..."
cd "$BUILD_DIR"
zip -r "$ZIP_FILE" . -x "*.pyc" -x "*__pycache__*" -x "*.dist-info*"

echo "✅ Package created: $ZIP_FILE"
echo "📊 Package size: $(du -h "$ZIP_FILE" | cut -f1)"
echo ""
echo "To upload to S3 (run from terraform root):"
echo "  aws s3 cp modules/agentcore/runtime_code.zip s3://\$(terraform output -raw agentcore_runtime_code_bucket_name)/agent-runtime/code.zip"
echo ""
echo "Or just run: terraform apply"
