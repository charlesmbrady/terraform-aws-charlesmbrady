###############################################################################
#### On-Demand GPU EC2 for ComfyUI (+ optional Parsec bootstrap)
#### NAT-free approach: launch in a public subnet with a public IP.
###############################################################################

variable "comfyui_ec2_enabled" {
  type        = bool
  description = "Enable provisioning of the ComfyUI GPU EC2 instance."
  default     = false
}

variable "comfyui_instance_name" {
  type        = string
  description = "Name tag for the ComfyUI GPU EC2 instance."
  default     = "comfyui-gpu-host"
}

variable "comfyui_instance_type" {
  type        = string
  description = "GPU instance type for ComfyUI workloads."
  default     = "g4dn.xlarge"
}

variable "comfyui_root_volume_size_gb" {
  type        = number
  description = "Root EBS volume size in GB for models/checkpoints/data."
  default     = 300
}

variable "comfyui_delete_root_on_termination" {
  type        = bool
  description = "Delete the root EBS volume when the EC2 instance is terminated/destroyed."
  default     = true
}

variable "comfyui_subnet_id" {
  type        = string
  description = "Optional subnet ID. Leave blank to auto-select the first subnet in the VPC."
  default     = ""
}

variable "comfyui_ami_ssm_parameter_name" {
  type        = string
  description = "SSM parameter that resolves to a GPU-ready AMI ID."
  default     = "/aws/service/deeplearning/ami/x86_64/base-oss-nvidia-driver-gpu-ubuntu-22.04/latest/ami-id"
}

variable "comfyui_allow_ssh" {
  type        = bool
  description = "Allow SSH ingress to the instance security group."
  default     = false
}

variable "comfyui_allow_web_ui" {
  type        = bool
  description = "Allow direct ingress to ComfyUI web UI (8188)."
  default     = false
}

variable "comfyui_ingress_cidrs" {
  type        = list(string)
  description = "CIDR blocks allowed for inbound access (SSH/UI)."
  default     = []
}

variable "comfyui_public_key" {
  type        = string
  description = "Optional SSH public key material for key pair creation."
  default     = ""
}

variable "comfyui_parsec_install_enabled" {
  type        = bool
  description = "If true, attempts to install Parsec in user_data (best effort)."
  default     = false
}

variable "comfyui_parsec_deb_url" {
  type        = string
  description = "Optional HTTPS URL to a Parsec .deb package. Required if parsec install is enabled."
  default     = ""
}

variable "clawdbot_enabled" {
  type        = bool
  description = "If true, clone and run ClawdBot side-by-side with ComfyUI."
  default     = false
}

variable "clawdbot_git_repo" {
  type        = string
  description = "HTTPS git repository URL for ClawdBot."
  default     = ""
}

variable "clawdbot_git_ref" {
  type        = string
  description = "Git branch/tag/commit for ClawdBot checkout."
  default     = "main"
}

variable "clawdbot_requirements_file" {
  type        = string
  description = "Path (inside ClawdBot repo) to pip requirements file."
  default     = "requirements.txt"
}

variable "clawdbot_start_command" {
  type        = string
  description = "Command to start ClawdBot inside its project directory and venv."
  default     = "python -m uvicorn app.main:app --host 0.0.0.0 --port 3001"
}

variable "clawdbot_port" {
  type        = number
  description = "Port exposed by ClawdBot service."
  default     = 3001
}

variable "clawdbot_allow_public_ingress" {
  type        = bool
  description = "Allow inbound access to ClawdBot port from comfyui_ingress_cidrs."
  default     = false
}

locals {
  comfyui_effective_subnet_id = var.comfyui_subnet_id != "" ? var.comfyui_subnet_id : try(data.aws_subnets.comfyui_public_vpc_subnets[0].ids[0], null)

  comfyui_user_data = <<-EOT
    #!/usr/bin/env bash
    set -euxo pipefail

    export DEBIAN_FRONTEND=noninteractive

    apt-get update -y
    apt-get install -y \
      git \
      curl \
      wget \
      unzip \
      jq \
      python3 \
      python3-venv \
      python3-pip \
      build-essential \
      ffmpeg \
      libgl1 \
      libglib2.0-0 \
      xorg \
      xfce4 \
      xfce4-goodies

    # Ensure SSM agent is available and started (some images do not enable it by default).
    snap install amazon-ssm-agent --classic || true
    systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service || true
    systemctl restart snap.amazon-ssm-agent.amazon-ssm-agent.service || true
    systemctl enable amazon-ssm-agent || true
    systemctl restart amazon-ssm-agent || true

    # Clone and install ComfyUI under /opt for shared system usage.
    if [ ! -d /opt/ComfyUI ]; then
      git clone https://github.com/comfyanonymous/ComfyUI.git /opt/ComfyUI
    fi

    python3 -m venv /opt/ComfyUI/.venv
    /opt/ComfyUI/.venv/bin/pip install --upgrade pip wheel
    /opt/ComfyUI/.venv/bin/pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124 || true
    /opt/ComfyUI/.venv/bin/pip install -r /opt/ComfyUI/requirements.txt

    mkdir -p /opt/ComfyUI/models
    chown -R ubuntu:ubuntu /opt/ComfyUI

    cat >/etc/systemd/system/comfyui.service <<'SERVICE'
    [Unit]
    Description=ComfyUI Service
    After=network-online.target
    Wants=network-online.target

    [Service]
    Type=simple
    User=ubuntu
    WorkingDirectory=/opt/ComfyUI
    ExecStart=/opt/ComfyUI/.venv/bin/python main.py --listen 0.0.0.0 --port 8188
    Restart=always
    RestartSec=5

    [Install]
    WantedBy=multi-user.target
    SERVICE

    systemctl daemon-reload
    systemctl enable comfyui
    systemctl start comfyui

    # Optional ClawdBot setup on the same host.
    if [ "${var.clawdbot_enabled}" = "true" ] && [ -n "${var.clawdbot_git_repo}" ]; then
      if [ ! -d /opt/ClawdBot ]; then
        git clone "${var.clawdbot_git_repo}" /opt/ClawdBot
      fi

      cd /opt/ClawdBot
      git fetch --all || true
      git checkout "${var.clawdbot_git_ref}" || true

      python3 -m venv /opt/ClawdBot/.venv
      /opt/ClawdBot/.venv/bin/pip install --upgrade pip wheel

      if [ -f "/opt/ClawdBot/${var.clawdbot_requirements_file}" ]; then
        /opt/ClawdBot/.venv/bin/pip install -r "/opt/ClawdBot/${var.clawdbot_requirements_file}"
      fi

      chown -R ubuntu:ubuntu /opt/ClawdBot

      cat >/etc/systemd/system/clawdbot.service <<'SERVICE'
      [Unit]
      Description=ClawdBot Service
      After=network-online.target
      Wants=network-online.target

      [Service]
      Type=simple
      User=ubuntu
      WorkingDirectory=/opt/ClawdBot
      ExecStart=/bin/bash -lc 'source /opt/ClawdBot/.venv/bin/activate && ${var.clawdbot_start_command}'
      Restart=always
      RestartSec=5

      [Install]
      WantedBy=multi-user.target
      SERVICE

      systemctl daemon-reload
      systemctl enable clawdbot
      systemctl start clawdbot
    fi

    # Optional Parsec install hook for cloud-host workflow.
    if [ "${var.comfyui_parsec_install_enabled}" = "true" ] && [ -n "${var.comfyui_parsec_deb_url}" ]; then
      wget -O /tmp/parsec.deb "${var.comfyui_parsec_deb_url}" || true
      dpkg -i /tmp/parsec.deb || apt-get -f install -y || true
    fi
  EOT

  comfyui_tags = merge(
    {
      Name        = "${var.name_prefix}-${var.comfyui_instance_name}"
      Environment = var.environment_tag
      Workload    = "ComfyUI"
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}

data "aws_ssm_parameter" "comfyui_gpu_ami" {
  count = var.comfyui_ec2_enabled ? 1 : 0
  name  = var.comfyui_ami_ssm_parameter_name
}

data "aws_subnets" "comfyui_public_vpc_subnets" {
  count = var.comfyui_ec2_enabled && var.comfyui_subnet_id == "" ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  filter {
    name   = "map-public-ip-on-launch"
    values = ["true"]
  }
}

resource "aws_security_group" "comfyui_host" {
  count       = var.comfyui_ec2_enabled ? 1 : 0
  name        = "${var.name_prefix}-${var.environment_tag}-comfyui-host-sg"
  description = "Security group for ComfyUI GPU host"
  vpc_id      = data.aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.comfyui_allow_ssh && length(var.comfyui_ingress_cidrs) > 0 ? [1] : []
    content {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.comfyui_ingress_cidrs
    }
  }

  dynamic "ingress" {
    for_each = var.comfyui_allow_web_ui && length(var.comfyui_ingress_cidrs) > 0 ? [1] : []
    content {
      description = "ComfyUI"
      from_port   = 8188
      to_port     = 8188
      protocol    = "tcp"
      cidr_blocks = var.comfyui_ingress_cidrs
    }
  }

  dynamic "ingress" {
    for_each = var.clawdbot_allow_public_ingress && length(var.comfyui_ingress_cidrs) > 0 ? [1] : []
    content {
      description = "ClawdBot"
      from_port   = var.clawdbot_port
      to_port     = var.clawdbot_port
      protocol    = "tcp"
      cidr_blocks = var.comfyui_ingress_cidrs
    }
  }

  egress {
    description = "All outbound internet access"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.comfyui_tags
}

resource "aws_iam_role" "comfyui_ec2_role" {
  count = var.comfyui_ec2_enabled ? 1 : 0
  name  = "${var.name_prefix}-${var.environment_tag}-comfyui-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = local.comfyui_tags
}

resource "aws_iam_role_policy_attachment" "comfyui_ssm_core" {
  count      = var.comfyui_ec2_enabled ? 1 : 0
  role       = aws_iam_role.comfyui_ec2_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "comfyui_ec2_profile" {
  count = var.comfyui_ec2_enabled ? 1 : 0
  name  = "${var.name_prefix}-${var.environment_tag}-comfyui-ec2-profile"
  role  = aws_iam_role.comfyui_ec2_role[0].name

  tags = local.comfyui_tags
}

resource "aws_key_pair" "comfyui_key_pair" {
  count      = var.comfyui_ec2_enabled && var.comfyui_public_key != "" ? 1 : 0
  key_name   = "${var.name_prefix}-${var.environment_tag}-comfyui-key"
  public_key = var.comfyui_public_key

  tags = local.comfyui_tags
}

resource "aws_instance" "comfyui_gpu_host" {
  count = var.comfyui_ec2_enabled ? 1 : 0

  ami           = data.aws_ssm_parameter.comfyui_gpu_ami[0].value
  instance_type = var.comfyui_instance_type

  subnet_id                   = local.comfyui_effective_subnet_id
  vpc_security_group_ids      = [aws_security_group.comfyui_host[0].id]
  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.comfyui_ec2_profile[0].name
  key_name             = var.comfyui_public_key != "" ? aws_key_pair.comfyui_key_pair[0].key_name : null

  user_data = local.comfyui_user_data

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_size           = var.comfyui_root_volume_size_gb
    volume_type           = "gp3"
    encrypted             = true
    kms_key_id            = var.kms_key_id
    delete_on_termination = var.comfyui_delete_root_on_termination
    throughput            = 250
    iops                  = 6000
    tags                  = local.comfyui_tags
  }

  lifecycle {
    precondition {
      condition     = local.comfyui_effective_subnet_id != null
      error_message = "No public subnet found. Set var.comfyui_subnet_id to a public subnet ID with internet gateway routing."
    }
  }

  tags = local.comfyui_tags
}

output "comfyui_instance_id" {
  description = "EC2 instance ID for the ComfyUI GPU host"
  value       = try(aws_instance.comfyui_gpu_host[0].id, null)
}

output "comfyui_instance_public_ip" {
  description = "Public IP of the ComfyUI GPU host"
  value       = try(aws_instance.comfyui_gpu_host[0].public_ip, null)
}

output "comfyui_start_instance_command" {
  description = "CLI command to start the ComfyUI host on demand"
  value       = try("aws ec2 start-instances --instance-ids ${aws_instance.comfyui_gpu_host[0].id}", null)
}

output "comfyui_stop_instance_command" {
  description = "CLI command to stop the ComfyUI host when idle"
  value       = try("aws ec2 stop-instances --instance-ids ${aws_instance.comfyui_gpu_host[0].id}", null)
}

output "comfyui_ssm_shell_command" {
  description = "CLI command to open an SSM shell without SSH key management"
  value       = try("aws ssm start-session --target ${aws_instance.comfyui_gpu_host[0].id}", null)
}

output "clawdbot_public_url" {
  description = "ClawdBot URL if public ingress is enabled"
  value       = try("http://${aws_instance.comfyui_gpu_host[0].public_ip}:${var.clawdbot_port}", null)
}
