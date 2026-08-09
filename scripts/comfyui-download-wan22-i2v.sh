#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <instance-id> [region]"
  exit 1
fi

INSTANCE_ID="$1"
REGION="${2:-us-east-1}"

# Wan 2.2 14B fp8 I2V model set (ComfyUI official template). ~35GB total.
CMD_ID=$(aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --region "$REGION" \
  --document-name AWS-RunShellScript \
  --comment "Download Wan 2.2 I2V models" \
  --parameters '{"executionTimeout":["7200"],"commands":[
    "cd /opt/ComfyUI/models",
    "sudo -u ubuntu mkdir -p diffusion_models text_encoders vae loras",
    "sudo -u ubuntu wget -c -q -O diffusion_models/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors",
    "sudo -u ubuntu wget -c -q -O diffusion_models/wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors",
    "sudo -u ubuntu wget -c -q -O text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors",
    "sudo -u ubuntu wget -c -q -O vae/wan_2.1_vae.safetensors https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors",
    "sudo -u ubuntu wget -c -q -O loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors",
    "sudo -u ubuntu wget -c -q -O loras/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors",
    "ls -lh diffusion_models text_encoders vae loras",
    "df -h /"
  ]}' \
  --output text --query 'Command.CommandId')

echo "SSM command: $CMD_ID"
echo "Downloading ~35GB on the instance. This can take 10-30 minutes..."

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
