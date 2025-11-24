#!/bin/bash
# Package and upload runtime code to S3

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNTIME_DIR="$SCRIPT_DIR"
ZIP_FILE="$SCRIPT_DIR/../runtime_code.zip"

echo "📦 Packaging runtime code..."
cd "$RUNTIME_DIR"

# Remove old zip if exists
rm -f "$ZIP_FILE"

# Create zip with runtime code
zip -r "$ZIP_FILE" . -x "*.sh" -x "README.md" -x ".DS_Store"

echo "✅ Created: $ZIP_FILE"
echo ""
echo "To upload to S3:"
echo "  aws s3 cp $ZIP_FILE s3://YOUR_BUCKET/agent-runtime/code.zip"
echo ""
echo "Then update Terraform variables:"
echo "  agent_runtime_code_bucket = \"YOUR_BUCKET\""
echo "  agent_runtime_code_prefix = \"agent-runtime/code.zip\""
