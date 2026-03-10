#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <instance-id> [region]"
  exit 1
fi

INSTANCE_ID="$1"
REGION="${2:-us-east-1}"

aws ec2 stop-instances \
  --instance-ids "$INSTANCE_ID" \
  --region "$REGION" \
  --output table

aws ec2 wait instance-stopped \
  --instance-ids "$INSTANCE_ID" \
  --region "$REGION"

echo "Instance is stopped."
