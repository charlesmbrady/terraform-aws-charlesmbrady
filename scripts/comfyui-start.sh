#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <instance-id> [region]"
  exit 1
fi

INSTANCE_ID="$1"
REGION="${2:-us-east-1}"

aws ec2 start-instances \
  --instance-ids "$INSTANCE_ID" \
  --region "$REGION" \
  --output table

aws ec2 wait instance-running \
  --instance-ids "$INSTANCE_ID" \
  --region "$REGION"

PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --region "$REGION" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo "Instance is running. Public IP: $PUBLIC_IP"
echo "If ComfyUI SG ingress is enabled, open: http://$PUBLIC_IP:8188"
