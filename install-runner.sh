#!/bin/bash
set -e

# --- CONFIGURATION (update these) ---
REPO_URL="https://github.com/TheBrist/terraform-daily-project"
GITHUB_TOKEN="ATEAM4MVTQX5KIQC3GYVLEDIFH53O" # ⚠️ Replace securely in production
RUNNER_DIR="/opt/github-runner"
RUNNER_NAME="github-runner"
RUNNER_LABELS="self-hosted,Linux,X64"
WORK_FOLDER="_work"
TERRAFORM_VERSION="1.8.5"  # Or "latest"
NODE_VERSION="18"

# --- Update and install dependencies ---
echo "[*] Installing dependencies..."
sudo apt-get update -y
sudo apt-get install -y curl unzip tar git jq gnupg software-properties-common apt-transport-https ca-certificates lsb-release

# --- Install Node.js ---
echo "[*] Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | sudo -E bash -
sudo apt-get install -y nodejs

# --- Install Terraform ---
echo "[*] Installing Terraform..."
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install -y terraform

# --- Install Google Cloud SDK ---
echo "[*] Installing Google Cloud SDK..."
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt-get update && sudo apt-get install -y google-cloud-sdk

# --- Create runner directory ---
echo "[*] Creating runner directory..."
sudo mkdir -p "$RUNNER_DIR"
sudo chown "$USER":"$USER" "$RUNNER_DIR"
cd "$RUNNER_DIR"

# --- Download GitHub Actions Runner ---
echo "[*] Downloading GitHub Actions runner..."
ARCH=$(uname -m)
if [ "$ARCH" == "x86_64" ]; then
  ARCH="x64"
elif [ "$ARCH" == "aarch64" ]; then
  ARCH="arm64"
fi

RUNNER_LATEST=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r ".tag_name")
RUNNER_URL="https://github.com/actions/runner/releases/download/${RUNNER_LATEST}/actions-runner-linux-${ARCH}-${RUNNER_LATEST:1}.tar.gz"

curl -O -L "$RUNNER_URL"
tar xzf ./actions-runner-linux-${ARCH}-${RUNNER_LATEST:1}.tar.gz

# --- Configure GitHub Runner ---
echo "[*] Configuring runner..."
./config.sh --url "$REPO_URL" --token "$GITHUB_TOKEN" --name "$RUNNER_NAME" --labels "$RUNNER_LABELS" --work "$WORK_FOLDER" --unattended

# --- Install as a service ---
echo "[*] Installing runner as systemd service..."
sudo ./svc.sh install
sudo ./svc.sh start

# --- Done ---
echo "[✓] Setup complete. GitHub Actions runner is now installed and running as a service."
