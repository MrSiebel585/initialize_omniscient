#!/bin/bash

# Merged Omniscient Arsenal Installer
# Base: setup_omniscient.sh
# Integrated content from omniscient_arsenal_refactored_final.sh and arsenal_original_metrge.sh
# Author: Automated merge by BLACKBOXAI

set -e

# Configuration file path
CONFIG_FILE="/opt/omniscient/omniscient.conf"

# Function to parse INI-style config file
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

# Load configuration values
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

# Create directory structure
create_directories() {
    echo "[+] Creating Omniscient directory structure..."
    mkdir -p "$ROOT_DIR"
    for dir in $DIR_STRUCTURE; do
        mkdir -p "$ROOT_DIR/$dir"
    done
    mkdir -p "$DEFAULT_HOME"
}

# Setup user home layout
setup_home_structure() {
    echo "[+] Creating Omniscient user home layout..."
    for folder in downloads scripts logs osint profile scraped text research docs audio video images; do
        mkdir -p "$DEFAULT_HOME/$folder"
    done

    cp "$BASHRC_TEMPLATE" "$DEFAULT_HOME/.bashrc" 2>/dev/null || true
    cp "$PROFILE_TEMPLATE" "$DEFAULT_HOME/.bash_profile" 2>/dev/null || true
}

# Append Omniscient aliases to .bashrc
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

# Setup Python virtual environment and install packages
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

# Validate or generate core files if missing
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

# Default file templates
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

# Log installation event
log_install() {
    echo "[+] Logging installation to $INSTALL_LOG"
    echo "Installed Omniscient on $(date)" >> "$INSTALL_LOG"
}

# Check and install system dependencies
install_system_dependencies() {
    echo "[+] Installing system dependencies..."

    # Disable unnecessary services
    sudo systemctl disable plymouth apparmor unattended-upgrades
    sudo systemctl stop plymouth apparmor unattended-upgrades
    sudo systemctl stop tor

    # Install Go if missing
    if ! command -v go &> /dev/null; then
        echo "Go is not installed. Installing Go..."
        wget https://go.dev/dl/go1.20.1.linux-amd64.tar.gz -q
        sudo tar -xvf go1.20.1.linux-amd64.tar.gz -C /usr/local
        echo "export GOPATH=\$HOME/go" >> /etc/profile
        echo "export PATH=\$PATH:/usr/local/go/bin:\$GOPATH/bin" >> /etc/profile
        source /etc/profile
    else
        echo "Go is already installed."
    fi

    # Install Ruby if missing
    if ! command -v ruby &> /dev/null; then
        echo "Installing Ruby..."
        sudo apt-get install ruby-full -y
    else
        echo "Ruby is already installed."
    fi

    # Install Rust if missing
    if ! command -v rustc &> /dev/null; then
        echo "Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    else
        echo "Rust is already installed."
    fi

    # Install Python3 and pip if missing
    if ! command -v python3 &> /dev/null; then
        echo "Installing Python3 and pip..."
        sudo apt-get install python3 python3-pip -y
    else
        echo "Python3 is already installed."
    fi

    # Install Apache if missing
    if ! command -v apache2 &> /dev/null; then
        echo "Installing Apache..."
        sudo apt-get install apache2 -y
    else
        echo "Apache is already installed."
    fi

    # Install PHP if missing
    if ! command -v php &> /dev/null; then
        echo "Installing PHP..."
        sudo apt-get install php -y
    else
        echo "PHP is already installed."
    fi
}

# Setup system aliases
setup_system_aliases() {
    echo "Configuring system aliases..."
    sudo cp -r ~/.bashrc ~/.bashrc.bak
    cat <<EOF >> ~/.bashrc

# Omniscient System Aliases
alias arm='sudo chmod +x'
alias implement='sudo apt install -y'
alias blowoff='sudo apt autoremove'
alias dropoff='sudo apt remove'
alias update='sudo apt update && sudo apt upgrade -y'
alias displayservices='sudo service --status-all'
alias truncatelogs='sudo truncate -s 0 /var/log/syslog'
alias search='sudo apt-cache search'
alias nmapme='sudo nmap -sS localhost'
EOF
    source ~/.bashrc
}

# Create desktop icons for /opt scripts
create_desktop_icons() {
    echo "Creating desktop icons for /opt scripts..."
    desktop_dir="$HOME/Desktop"
    mkdir -p "$desktop_dir"
    for file in /opt/*.sh /opt/*.py; do
        name=$(basename "$file" | cut -d. -f1)
        cat <<EOF > "$desktop_dir/$name.desktop"
[Desktop Entry]
Type=Application
Encoding=UTF-8
Name=$name
Comment=
Exec=$file
Icon=
Terminal=true
Categories=Application;Development;
EOF
    done
}

# Install OSINT tools
install_osint_tools() {
    echo "Installing OSINT tools..."

    # List of tools to install with install commands
    declare -A tools=(
        [httpx]="go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest"
        [httprobe]="go install github.com/tomnomnom/httprobe@latest && sudo cp \$HOME/go/bin/httprobe /usr/local/bin"
        [amass]="go install -v github.com/OWASP/Amass/v3/...@master && sudo cp \$HOME/go/bin/amass /usr/local/bin"
        [gobuster]="go install github.com/OJ/gobuster/v3@latest && sudo cp \$HOME/go/bin/gobuster /usr/local/bin"
        [nuclei]="go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest && sudo cp \$HOME/go/bin/nuclei /usr/local/bin"
        [subfinder]="go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest && sudo cp \$HOME/go/bin/subfinder /usr/local/bin"
        [assetfinder]="go install github.com/tomnomnom/assetfinder@latest"
        [ffuf]="go install github.com/ffuf/ffuf@latest && cp \$HOME/go/bin/ffuf /usr/local/bin"
        [gf]="go install github.com/tomnomnom/gf@latest && cp \$HOME/go/bin/gf /usr/local/bin"
        [meg]="go install github.com/tomnomnom/meg@latest && cp \$HOME/go/bin/meg /usr/local/bin"
        [waybackurls]="go install github.com/tomnomnom/waybackurls@latest && cp \$HOME/go/bin/waybackurls /usr/local/bin"
        [subzy]="go install -v github.com/LukaSikic/subzy@latest && sudo cp \$HOME/go/bin/subzy /usr/local/bin"
        [asnmap]="go install github.com/projectdiscovery/asnmap/cmd/asnmap@latest"
        [jsleak]="go install github.com/channyein1337/jsleak@latest"
        [mapcidr]="go install -v github.com/projectdiscovery/mapcidr/cmd/mapcidr@latest"
        [dnsx]="go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest && sudo cp \$HOME/go/bin/dnsx /usr/local/bin"
        [gospider]="go install github.com/jaeles-project/gospider@latest && sudo cp \$HOME/go/bin/gospider /usr/local/bin"
        [wpscan]="gem install wpscan"
        [CRLFuzz]="go install github.com/dwisiswant0/crlfuzz/cmd/crlfuzz@latest && sudo cp \$HOME/go/bin/crlfuzz /usr/local/bin"
        [dontgo403]="git clone https://github.com/devploit/dontgo403 && cd dontgo403 && go get && go build && cd -"
        [katana]="go install github.com/projectdiscovery/katana/cmd/katana@latest && sudo cp \$HOME/go/bin/katana /usr/local/bin"
        [uncover]="go install -v github.com/projectdiscovery/uncover/cmd/uncover@latest && sudo cp \$HOME/go/bin/uncover /usr/local/bin"
        [dalfox]="go install github.com/hahwul/dalfox/v2@latest && cp \$HOME/go/bin/dalfox /usr/local/bin"
        [GoLinkFinder]="go install github.com/0xsha/GoLinkFinder@latest && cp \$HOME/go/bin/GoLinkFinder /usr/local/bin"
        [hakrawler]="go install github.com/hakluke/hakrawler@latest && cp \$HOME/go/bin/hakrawler /usr/local/bin"
        [csprecon]="go install github.com/edoardottt/csprecon/cmd/csprecon@latest"
        [gotator]="go env -w GO111MODULE=\"auto\" && go install github.com/Josue87/gotator@latest"
        [osmedeus]="go install -v github.com/j3ssie/osmedeus@latest"
        [shuffledns]="go install -v github.com/projectdiscovery/shuffledns/cmd/shuffledns@latest"
        [socialhunter]="go install github.com/utkusen/socialhunter@latest"
        [getJS]="go install github.com/003random/getJS@latest"
    )

    for tool in "${!tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            echo "Installing $tool..."
            eval "${tools[$tool]}"
            echo "$tool installation completed."
        else
            echo "$tool is already installed."
        fi
    done
}

# Clone and install additional Python OSINT tools with user prompts
install_python_osint_tools() {
    echo "Installing Python OSINT tools..."

    install_tool() {
        local repo_url=$1
        local description=$2
        local usage=$3
        local install_cmds=$4
        local repo_dir=$(basename "$repo_url" .git)

        echo -e "$repo_dir:\nDescription: $description\nUsage: $usage\nInstalling $repo_dir..."
        git clone "$repo_url" &> /dev/null
        cd "$repo_dir" || exit
        eval "$install_cmds"
        echo "$repo_dir has been installed."
        cd - &> /dev/null || exit
    }

    # List of Python OSINT tools with descriptions and install commands
    declare -a python_tools=(
        "https://github.com/guelfoweb/knock.git|knockpy is a Python tool for subdomain enumeration.|python3 knock.py -t domain.com|pip3 install -r requirements.txt"
        "https://github.com/s0md3v/XSStrike|XSStrike is an advanced XSS detection suite.|python3 xsstrike.py -u http://example.com|pip3 install -r requirements.txt"
        "https://github.com/Mr-Robert0/Logsensor.git|Logsensor monitors and analyzes logs in real-time.|./logsensor.py --config config.yaml|chmod +x logsensor.py install.sh; pip install -r requirements.txt; ./install.sh"
        "https://github.com/infosec-au/altdns.git|Altdns generates permutations of domain names.|python3 altdns -i input.txt -o output.txt -w words.txt|pip3 install -r requirements.txt"
        "https://github.com/xnl-h4ck3r/xnLinkFinder.git|Finds URLs and secrets in JavaScript files.|python3 xnLinkFinder.py -i http://example.com|python3 setup.py install"
        "https://github.com/devanshbatham/ParamSpider|Parameter discovery tool for web apps.|python3 paramspider.py --domain target.com|pip3 install -r requirements.txt"
        "https://github.com/codingo/NoSQLMap.git|Automated NoSQL database exploitation.|python3 nosqlmap.py -u http://example.com|python3 setup.py install /dev/null"
        "https://github.com/momenbasel/keyFinder.git|Finds cryptographic keys in files.|python3 keyfinder.py|"
        "https://github.com/Nhoya/gOSINT|OSINT tool for domain and IP info.|python3 goisnt.py|"
        "https://github.com/ticarpi/jwt_tool|JWT analysis and exploitation toolkit.|python3 jwt_tool.py|python3 -m pip install termcolor cprint pycryptodomex requests; chmod +x jwt_tool.py"
        "https://github.com/s0md3v/Arjun|Parameter discovery suite.|python3 arjun.py -u http://example.com|python3 setup.py install"
        "https://github.com/zricethezav/gitleaks.git|Git repository secret scanner.|gitleaks --repo=<repo_url>|make build; sudo mv gitleaks /usr/local/bin"
    )

    for tool_info in "${python_tools[@]}"; do
        IFS='|' read -r repo_url description usage install_cmds <<< "$tool_info"
        read -p "Do you want to install $(basename "$repo_url" .git)? (Y/n) " choice
        case $choice in
            [Yy]*|"")
                install_tool "$repo_url" "$description" "$usage" "$install_cmds"
                ;;
            *)
                echo "Skipping $(basename "$repo_url" .git)."
                ;;
        esac
    done
}

# Main execution flow
main() {
    create_directories
    setup_home_structure
    setup_bash_aliases
    install_system_dependencies
    setup_system_aliases
    create_desktop_icons
    install_python_env
    install_osint_tools
    install_python_osint_tools
    validate_core_files
    log_install

    echo "[✓] Omniscient Arsenal merged installation completed successfully."
    echo "Activate the environment with: source $VENV_DIR/bin/activate"
    echo "User home directory: $DEFAULT_HOME"
    echo "Installation log: $INSTALL_LOG"
}

main "$@"
