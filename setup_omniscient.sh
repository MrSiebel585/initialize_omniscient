#!/bin/bash

# Omniscient Framework Installer (Config-driven)


set -e
CONFIG_FILE="/opt/omniscient/omniscient.conf"

########################################
# Function: Parse INI-style config file
########################################
parse_conf() {
    section=$1
    key=$2
    result=$(awk -F '=' -v section="[$section]" -v key="$key" '
        $0 == section {found=1; next}
        /^\[/ {found=0}
        found && $1 ~ key {gsub(/[ \t\r\n]+/, "", $2); print $2; exit}
    ' "$CONFIG_FILE")
    if [[ -z "$result" ]]; then
        echo "[!] Missing config for [$section] $key" >&2
        exit 1
    fi
    echo "$result"
}

##################################
# Load Configuration Values
##################################
ROOT_DIR=$(parse_conf core framework_root)
VENV_DIR=$(parse_conf core venv_path)
USER_HOME_BASE=$(parse_conf core user_home_base)
DEFAULT_USER=$(parse_conf core default_user)
INSTALL_LOG=$(parse_conf logs install_log)
PYTHON_VERSION=$(parse_conf python version)
PYTHON_PACKAGES=$(parse_conf python packages)
DIR_STRUCTURE=$(parse_conf dirs structure | tr ',' '\n')

DEFAULT_HOME="$USER_HOME_BASE/$DEFAULT_USER"
BASHRC_TEMPLATE="$ROOT_DIR/.bashrc"
PROFILE_TEMPLATE="$ROOT_DIR/.bash_profile"

##################################
# Directory & Home Setup
##################################
create_directories() {
    echo "[+] Creating Omniscient directory structure..."
    mkdir -p "$ROOT_DIR"
    for dir in $DIR_STRUCTURE; do
        mkdir -p "$ROOT_DIR/$dir"
    done
    mkdir -p "$DEFAULT_HOME"
}

setup_home_structure() {
    echo "[+] Creating Omniscient user home layout..."
    for folder in downloads scripts logs osint profile scraped text research docs audio video images; do
        mkdir -p "$DEFAULT_HOME/$folder"
    done

    cp "$BASHRC_TEMPLATE" "$DEFAULT_HOME/.bashrc" 2>/dev/null || true
    cp "$PROFILE_TEMPLATE" "$DEFAULT_HOME/.bash_profile" 2>/dev/null || true
}

setup_bash_aliases() {
    echo "[+] Appending Omniscient aliases to .bashrc..."
    if ! grep -q "Omniscient Aliases" "$DEFAULT_HOME/.bashrc"; then
        cat <<EOF >> "$DEFAULT_HOME/.bashrc"

# ── Omniscient Aliases ─────────────
alias arm='sudo chmod +x'
alias implement='sudo apt install'
alias dropoff='sudo apt remove'
alias blowoff='sudo apt autoremove'
cd $ROOT_DIR
source $VENV_DIR/bin/activate
EOF
    fi
}

##################################
# Python Environment Setup
##################################
install_python_env() {
    echo "[+] Setting up Python virtual environment..."
    sudo apt update
    sudo apt install -y "$PYTHON_VERSION" "$PYTHON_VERSION"-pip "$PYTHON_VERSION"-venv

    "$PYTHON_VERSION" -m venv "$VENV_DIR"
    source "$VENV_DIR/bin/activate"
    pip install --upgrade pip

    for pkg in ${PYTHON_PACKAGES//,/ }; do
        pip install "$pkg"
    done
}

##################################
# Validate or Create Core Files
##################################
validate_core_files() {
    echo "[+] Validating or generating missing core files..."
    declare -A files=(
        [omniscient.conf]="default_omniscient_conf"
        [omniscientctl]="default_omniscientctl"
        [rsysai.py]="default_rsysai"
    )

    for file in "${!files[@]}"; do
        path="$ROOT_DIR/$file"
        if [[ ! -f "$path" ]]; then
            echo "[!] Missing $file — generating default..."
            ${files[$file]} > "$path"
            chmod +x "$path"
        fi
    done
}

##################################
# Default File Templates
##################################
default_omniscient_conf() {
    cat <<EOF
[core]
framework_root = /opt/omniscient
venv_path = /opt/omniscient/venv
user_home_base = /opt/omniscient/home
default_user = $DEFAULT_USER

[python]
version = python3
packages = openai,huggingface_hub,streamlit,ollama

[dirs]
structure = ai,backups,bin,conf,osint,forensics,compiled,scripts,logs,crons,envs,dockers,sql,web,templates,init,home,archives,profile,scraped,research,text,audio,video,images,docs

[logs]
install_log = /opt/omniscient/installers.log
EOF
}

default_omniscientctl() {
    cat <<EOF
#!/bin/bash
echo "[+] OmniscientCTL - Command Line Engine Loaded"
EOF
}

default_rsysai() {
    cat <<EOF
#!/usr/bin/env python3
print("[+] RsysAI Log Processor Placeholder")
EOF
}

##################################
# Log Install Event
##################################
log_install() {
    echo "[+] Logging installation to $INSTALL_LOG"
    echo "Installed Omniscient on $(date)" >> "$INSTALL_LOG"
}

##################################
# Main Execution Flow
##################################
main() {
    create_directories
    setup_home_structure
    setup_bash_aliases
    install_python_env
    validate_core_files
    log_install

    echo "[✓] Omniscient installation completed successfully."
    echo "🔧 Activate with: source $VENV_DIR/bin/activate"
    echo "📁 User Home: $DEFAULT_HOME"
    echo "📜 Install Log: $INSTALL_LOG"
}

main "$@"
