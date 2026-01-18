#!/bin/bash
# ============================================================================
# Enterprise Cloud Platform (ECP) - Claude Code Session Start Hook
# ============================================================================
# Purpose:      Install Terraform and Terragrunt for Claude Code on the Web
# Repository:   enterprise-cloud-platform-wp-avd
# Environment:  Remote sessions only (Claude Code on the Web)
# ============================================================================

set -euo pipefail

# Only run in remote environments (Claude Code on the Web)
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
    exit 0
fi

# Minimum required versions
TERRAFORM_MIN_VERSION="1.9.0"
TERRAGRUNT_VERSION="0.72.6"

# ============================================================================
# Helper Functions
# ============================================================================

log_info() {
    echo "[INFO] $1"
}

log_success() {
    echo "[SUCCESS] $1"
}

version_gte() {
    # Returns 0 if $1 >= $2
    [ "$(printf '%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]
}

# ============================================================================
# Terraform Installation
# ============================================================================

install_terraform() {
    log_info "Checking Terraform installation..."

    if command -v terraform &> /dev/null; then
        current_version=$(terraform version -json 2>/dev/null | grep -o '"terraform_version":"[^"]*"' | cut -d'"' -f4 || terraform version | head -1 | grep -oP 'v\K[0-9.]+')
        if version_gte "$current_version" "$TERRAFORM_MIN_VERSION"; then
            log_success "Terraform $current_version is already installed (>= $TERRAFORM_MIN_VERSION)"
            return 0
        fi
        log_info "Terraform $current_version found, but need >= $TERRAFORM_MIN_VERSION. Upgrading..."
    fi

    log_info "Installing Terraform..."

    # Install prerequisites
    sudo apt-get update -qq
    sudo apt-get install -y -qq gnupg software-properties-common curl

    # Add HashiCorp GPG key
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg 2>/dev/null || true

    # Add HashiCorp repository
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null

    # Install Terraform
    sudo apt-get update -qq
    sudo apt-get install -y -qq terraform

    log_success "Terraform $(terraform version -json | grep -o '"terraform_version":"[^"]*"' | cut -d'"' -f4) installed successfully"
}

# ============================================================================
# Terragrunt Installation
# ============================================================================

install_terragrunt() {
    log_info "Checking Terragrunt installation..."

    if command -v terragrunt &> /dev/null; then
        current_version=$(terragrunt --version 2>/dev/null | grep -oP 'v\K[0-9.]+' || echo "0.0.0")
        if version_gte "$current_version" "$TERRAGRUNT_VERSION"; then
            log_success "Terragrunt $current_version is already installed (>= $TERRAGRUNT_VERSION)"
            return 0
        fi
        log_info "Terragrunt $current_version found, but need >= $TERRAGRUNT_VERSION. Upgrading..."
    fi

    log_info "Installing Terragrunt v${TERRAGRUNT_VERSION}..."

    # Determine architecture
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)  ARCH="amd64" ;;
        aarch64) ARCH="arm64" ;;
        *)       echo "Unsupported architecture: $ARCH"; exit 1 ;;
    esac

    # Download and install Terragrunt from GitHub releases
    TERRAGRUNT_URL="https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_${ARCH}"

    curl -fsSL "$TERRAGRUNT_URL" -o /tmp/terragrunt
    chmod +x /tmp/terragrunt
    sudo mv /tmp/terragrunt /usr/local/bin/terragrunt

    log_success "Terragrunt v${TERRAGRUNT_VERSION} installed successfully"
}

# ============================================================================
# Main Execution
# ============================================================================

log_info "Starting Claude Code session bootstrap for ECP AVD Workload Pattern..."

install_terraform
install_terragrunt

log_info "Verifying installations..."
echo "  Terraform:  $(terraform version -json | grep -o '"terraform_version":"[^"]*"' | cut -d'"' -f4)"
echo "  Terragrunt: $(terragrunt --version | grep -oP 'v[0-9.]+' | head -1)"

log_success "Session bootstrap completed successfully!"
