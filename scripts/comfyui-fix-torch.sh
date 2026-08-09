#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <instance-id> [region]"
  exit 1
fi

INSTANCE_ID="$1"
REGION="${2:-us-east-1}"

echo "Stopping comfyui, upgrading torch in the venv, and restarting (runs on the instance via SSM)..."

CMD_ID=$(aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --region "$REGION" \
  --document-name AWS-RunShellScript \
  --comment "Fix torch/comfy-kitchen version mismatch" \
  --parameters 'commands=[
    "systemctl stop comfyui",
    "sudo -u ubuntu -H /opt/ComfyUI/.venv/bin/pip install --upgrade torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128",
    "sudo -u ubuntu /opt/ComfyUI/.venv/bin/python -c \"import torch, comfy_kitchen; print(torch.__version__, torch.version.cuda, torch.cuda.is_available())\"",
    "systemctl start comfyui",
    "sleep 10",
    "systemctl is-active comfyui"
  ]' \
  --output text --query 'Command.CommandId')

echo "SSM command: $CMD_ID"
echo "Waiting (torch wheel is ~800MB, this can take several minutes)..."

aws ssm wait command-executed \
  --command-id "$CMD_ID" \
  --instance-id "$INSTANCE_ID" \
  --region "$REGION" || true

aws ssm get-command-invocation \
  --command-id "$CMD_ID" \
  --instance-id "$INSTANCE_ID" \
  --region "$REGION" \
  --query '{Status:Status,ExitCode:ResponseCode,Stdout:StandardOutputContent,Stderr:StandardErrorContent}' \
  --output json

echo ""
echo "If Status is Success and the last stdout line is 'active', open the tunnel:"
echo "  ./scripts/comfyui-tunnel.sh $INSTANCE_ID $REGION"
