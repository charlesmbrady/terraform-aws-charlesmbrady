#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <instance-id> [region] [local-port] [remote-port]"
  exit 1
fi

INSTANCE_ID="$1"
REGION="${2:-us-east-1}"
LOCAL_PORT="${3:-3001}"
REMOTE_PORT="${4:-3001}"

echo "Starting SSM tunnel: localhost:${LOCAL_PORT} -> ${INSTANCE_ID}:${REMOTE_PORT}"
echo "Keep this terminal open, then open http://localhost:${LOCAL_PORT}"

aws ssm start-session \
  --target "$INSTANCE_ID" \
  --region "$REGION" \
  --document-name AWS-StartPortForwardingSession \
  --parameters "portNumber=${REMOTE_PORT},localPortNumber=${LOCAL_PORT}"
