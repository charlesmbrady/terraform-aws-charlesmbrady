# ComfyUI EC2 Runbook

This runbook is for the current test ComfyUI host managed by Terraform in this repo.

## Current Instance

- Instance ID: ``
- Region: `us-east-1`
- State: `running`
- Instance type: `g6e.4xlarge`
- Public IP: ``
- Availability Zone: `us-east-1d`
- SSM status: `Online`
- OS: `Ubuntu`

## Architecture Notes

- ComfyUI is running on a single GPU EC2 host.
- Access is intended to go through AWS Systems Manager port forwarding, not direct public web ingress.
- `comfyui_allow_web_ui = false`, so use the tunnel instead of the public IP for the UI.
- Parsec is currently disabled.
- ClawdBot has been removed from this setup.
- The root volume is configured with `delete_on_termination = true`, so a Terraform destroy should remove the instance disk.

## What To Do Now

1. Open the ComfyUI tunnel from your laptop.
2. Open the UI in your browser.
3. If you need models, shell into the box and download them directly onto the EC2 volume.
4. Run a small workflow first to confirm the service is healthy before loading large video models.

## Quick Start

From the repo root:

```bash
cd /Users/charlesbrady/Desktop/Charlava_25/terraform-aws-charlesmbrady
./scripts/comfyui-tunnel.sh i-05e2e566261d8269f us-east-1
```

Then open:

```text
http://localhost:8188
```

Keep that terminal open while you use ComfyUI.

## Open An SSM Shell

```bash
aws ssm start-session --target i-05e2e566261d8269f --region us-east-1
```

If that hangs at `Starting session`, verify the Session Manager plugin is installed locally and that the instance is still `Online` in SSM.

## Start And Stop The Instance

Start:

```bash
cd /Users/charlesbrady/Desktop/Charlava_25/terraform-aws-charlesmbrady
./scripts/comfyui-start.sh i-05e2e566261d8269f us-east-1
```

Stop:

```bash
cd /Users/charlesbrady/Desktop/Charlava_25/terraform-aws-charlesmbrady
./scripts/comfyui-stop.sh i-05e2e566261d8269f us-east-1
```

Direct AWS CLI equivalents:

```bash
aws ec2 start-instances --instance-ids i-05e2e566261d8269f --region us-east-1
aws ec2 stop-instances --instance-ids i-05e2e566261d8269f --region us-east-1
```

## Check Instance Status

EC2 state:

```bash
aws ec2 describe-instances \
  --instance-ids i-05e2e566261d8269f \
  --region us-east-1 \
  --query 'Reservations[0].Instances[0].[State.Name,InstanceType,PublicIpAddress,Placement.AvailabilityZone]' \
  --output table
```

SSM status:

```bash
aws ssm describe-instance-information \
  --region us-east-1 \
  --filters Key=InstanceIds,Values=i-05e2e566261d8269f \
  --query 'InstanceInformationList[0].[PingStatus,PlatformName,AgentVersion]' \
  --output table
```

## Check ComfyUI Service

Open an SSM shell first, then use:

```bash
sudo systemctl status comfyui --no-pager
```

Recent logs:

```bash
sudo journalctl -u comfyui -n 200 --no-pager
```

Live logs:

```bash
sudo journalctl -u comfyui -f
```

Restart the service:

```bash
sudo systemctl restart comfyui
```

## GPU And System Checks

GPU health:

```bash
nvidia-smi
```

Watch GPU usage:

```bash
watch -n 2 nvidia-smi
```

Disk space:

```bash
df -h
```

Memory:

```bash
free -h
```

## Important Paths On The Instance

- ComfyUI repo: `/opt/ComfyUI`
- Python virtualenv: `/opt/ComfyUI/.venv`
- ComfyUI models: `/opt/ComfyUI/models`

Useful model subdirectories often include:

- `/opt/ComfyUI/models/checkpoints`
- `/opt/ComfyUI/models/vae`
- `/opt/ComfyUI/models/loras`
- `/opt/ComfyUI/models/controlnet`
- `/opt/ComfyUI/models/clip_vision`
- `/opt/ComfyUI/models/upscale_models`

## Download Models Directly To EC2

Download models from the instance, not through your laptop, so you avoid local disk churn and keep the files on EBS.

Example:

```bash
cd /opt/ComfyUI/models/checkpoints
wget -c "PASTE_MODEL_URL_HERE"
```

With `curl`:

```bash
cd /opt/ComfyUI/models/checkpoints
curl -L "PASTE_MODEL_URL_HERE" -o model.safetensors
```

Hugging Face example:

```bash
cd /opt/ComfyUI/models/checkpoints
wget -c "https://huggingface.co/<org>/<repo>/resolve/main/<file>"
```

If a source needs authentication, use a token in the shell session rather than downloading locally first.

## Update ComfyUI

```bash
aws ssm start-session --target i-05e2e566261d8269f --region us-east-1
```

Then on the box:

```bash
cd /opt/ComfyUI
git pull
/opt/ComfyUI/.venv/bin/pip install -r requirements.txt
sudo systemctl restart comfyui
```

## If The Tunnel Fails

Retry the tunnel:

```bash
cd /Users/charlesbrady/Desktop/Charlava_25/terraform-aws-charlesmbrady
./scripts/comfyui-tunnel.sh i-05e2e566261d8269f us-east-1
```

Common causes:

- the instance is stopped
- SSM is not yet `Online`
- the Session Manager plugin is missing locally
- the `comfyui` service is down on the instance

## If ComfyUI Loads But Generations Fail

Start with these checks:

```bash
sudo journalctl -u comfyui -n 200 --no-pager
nvidia-smi
free -h
df -h
```

Typical causes:

- model or workflow needs more VRAM than available
- model files are incomplete or in the wrong folder
- a custom node dependency is missing
- the service needs a restart after a large update

## Terraform Operations

Apply test environment:

```bash
cd /Users/charlesbrady/Desktop/Charlava_25/terraform-aws-charlesmbrady
terraform -chdir=environments/test plan
terraform -chdir=environments/test apply
```

Destroy test environment:

```bash
cd /Users/charlesbrady/Desktop/Charlava_25/terraform-aws-charlesmbrady
terraform -chdir=environments/test destroy
```

Current Terraform settings for this host are in:

- `environments/test/main.tf`
- `comfyui_gpu_ec2.tf`

## Cost Notes

- Stopping the instance saves EC2 compute cost.
- Stopping the instance does not remove EBS storage cost.
- Terraform destroy is what removes the host and, with the current config, its root volume.

## Session Cleanup

List active SSM sessions:

```bash
aws ssm describe-sessions --state Active --region us-east-1 --output table
```

Terminate a stuck session:

```bash
aws ssm terminate-session --session-id PASTE_SESSION_ID --region us-east-1
```

## Recommended First Workflow

1. Open the tunnel.
2. Confirm the UI loads.
3. Run a small text-to-image workflow first.
4. Download one larger model only after the basic workflow succeeds.
5. Watch `nvidia-smi` and `journalctl` during the first heavier run.

## Handy Copy/Paste Block

```bash
cd /Users/charlesbrady/Desktop/Charlava_25/terraform-aws-charlesmbrady

# tunnel to ComfyUI
./scripts/comfyui-tunnel.sh i-05e2e566261d8269f us-east-1

# open SSM shell
aws ssm start-session --target i-05e2e566261d8269f --region us-east-1

# stop when idle
./scripts/comfyui-stop.sh i-05e2e566261d8269f us-east-1

# start again later
./scripts/comfyui-start.sh i-05e2e566261d8269f us-east-1

# check service logs from an SSM shell
sudo journalctl -u comfyui -n 200 --no-pager

# check GPU from an SSM shell
nvidia-smi
```
