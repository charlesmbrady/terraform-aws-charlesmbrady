#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <instance-id> [region] [local-port] [remote-port]"
  exit 1
fi

INSTANCE_ID="$1"
REGION="${2:-us-east-1}"
LOCAL_PORT="${3:-8188}"
REMOTE_PORT="${4:-8188}"

echo "Checking SSM connectivity for ${INSTANCE_ID} in ${REGION}..."

for _ in {1..30}; do
  PING_STATUS=$(aws ssm describe-instance-information \
    --region "$REGION" \
    --filters "Key=InstanceIds,Values=${INSTANCE_ID}" \
    --query 'InstanceInformationList[0].PingStatus' \
    --output text 2>/dev/null || true)

  if [[ "$PING_STATUS" == "Online" ]]; then
    break
  fi

  sleep 10
done

if [[ "${PING_STATUS:-}" != "Online" ]]; then
  echo "SSM target is not Online yet for instance ${INSTANCE_ID}."
  echo "Common causes:"
  echo "1) SSM agent not running on instance"
  echo "2) Instance has no outbound path to internet/SSM endpoints"
  echo "3) IAM role missing AmazonSSMManagedInstanceCore"
  echo "Try again in a couple of minutes, or check EC2 system logs and route table."
  exit 1
fi

echo "Starting SSM tunnel: localhost:${LOCAL_PORT} -> ${INSTANCE_ID}:${REMOTE_PORT}"
echo "Keep this terminal open, then open http://localhost:${LOCAL_PORT}"

aws ssm start-session \
  --target "$INSTANCE_ID" \
  --region "$REGION" \
  --document-name AWS-StartPortForwardingSession \
  --parameters "portNumber=${REMOTE_PORT},localPortNumber=${LOCAL_PORT}"
