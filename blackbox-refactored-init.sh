#!/bin/bash

# Colors
END="\e[0m"
Red="\e[31m"
Green="\e[32m"
BoldGreen="\e[1;32m"
Yellow="\e[33m"
Cyan="\e[36m"
White="\e[37m"

# Check if running as root
check_root() {
  if [ "$EUID" -ne 0 ]; then
    echo -e "${Red}Please run as root${END}"
    exit 1
  fi
}

# Print banner
print_banner() {
  echo -e "${Red}
 █████╗ ██████╗ ███████╗███████╗███╗   ██╗ █████╗ ██╗
██╔══██╗██╔══██╗██╔════╝██╔════╝████╗  ██║██╔══██╗██║
███████║██████╔╝███████╗█████╗  ██╔██╗ ██║███████║██║
██╔══██║██╔══██╗╚════██║██╔══╝  ██║╚██╗██║██╔══██║██║
██║  ██║██║  ██║███████║███████╗██║ ╚████║██║  ██║███████╗
╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝ v2
${END}
IS NOW EXECUTING FOR OMNISCIENT INITIALIZATION AND IMPLEMENTATION...
"
}

# Create Arsenal directory and cd into it
prepare_arsenal_dir() {
  mkdir -p Arsenal
  cd Arsenal || exit 1
}

# Helper function to check if a command exists
command_exists() {
  command -v "$1" &> /dev/null
}

# Helper function to install a package via apt-get if not installed
install_package() {
  local pkg=$1
  local cmd=$2
  if ! command_exists "$cmd"; then
    echo "Installing $pkg..."
    apt-get install -y "$pkg" &> /dev/null
    if command_exists "$cmd"; then
      echo "$pkg installed successfully."
    else
      echo -e "${Red}Failed to install $pkg.${END}"
    fi
  else
    echo -e "${Green}$pkg is already installed.${END}"
  fi
}

# Install Go language if not installed
install_go() {
  if ! command_exists go; then
    echo "Go is not installed. Installing Go 1.20.1..."
    apt-get remove -y golang-go &> /dev/null
    rm -rf /usr/local/go &> /dev/null
    wget https://go.dev/dl/go1.20.1.linux-amd64.tar.gz &> /dev/null
    tar -xvf go1.20.1.linux-amd64.tar.gz &> /dev/null
    mv go /usr/local
    # Setup environment variables
    echo "export GOPATH=\$HOME/go" >> /etc/profile
    echo "export PATH=\$PATH:/usr/local/go/bin" >> /etc/profile
    echo "export PATH=\$PATH:\$GOPATH/bin" >> /etc/profile
    source /etc/profile
    echo "Go installed."
  else
    echo -e "${Cyan}Go is already installed: $(go version)${END}"
  fi
}

# Install system requirements
install_system_requirements() {
  install_go
  install_package build-essential make
  install_package git git
  install_package ruby ruby
  install_package rustc rustc
  install_package python3 python3
  install_package python3-pip pip3
  install_package apache2 apache2
  install_package php php
}

# Optional PHP installation instructions
php_install_instructions() {
  echo "If PHP errors occur, run the following commands:"
  echo "sudo apt install software-properties-common"
  echo "sudo add-apt-repository ppa:ondrej/php"
  echo "sudo apt update"
  echo "sudo apt install php8.0 libapache2-mod-php8.0"
  echo "sudo systemctl restart apache2"
  echo
  echo "To configure Apache with PHP-FPM:"
  echo "sudo apt update"
  echo "sudo apt install php8.0-fpm libapache2-mod-fcgid"
  echo "sudo a2enmod proxy_fcgi setenvif"
  echo "sudo a2enconf php8.0-fpm"
  echo "sudo systemctl restart apache2"
}

# Install PHP with user prompt
install_php() {
  read -rp "Press Enter to continue with PHP installation, or 'N' to skip: " input
  if [[ "$input" == "" ]]; then
    echo "Continuing with PHP8+ installation..."
    apt-get install -y software-properties-common
    add-apt-repository -y ppa:ondrej/php
    apt-get update
    apt-get install -y php8.0 libapache2-mod-php8.0
    systemctl restart apache2
    apt-get install -y php8.0-fpm libapache2-mod-fcgid
    a2enmod proxy_fcgi setenvif
    a2enconf php8.0-fpm
    systemctl restart apache2
  else
    echo "Skipping PHP installation. Continuing with the rest of the script..."
    echo "Installing MariaDB server..."
    apt-get install -y mariadb-server
    mysql_secure_installation
    # Assuming lamp_implementation is a script to source
    if [ -f lamp_implementation ]; then
      source lamp_implementation
      echo "Sourced lamp_implementation for LAMP testing..."
    fi
    systemctl restart apache2
    systemctl status apache2
  fi
}

# Clone and install Go tools
install_go_tools() {
  local tools=(
    "github.com/projectdiscovery/httpx/cmd/httpx@latest"
    "github.com/tomnomnom/httprobe@latest"
    "github.com/OWASP/Amass/v3/...@master"
    "github.com/OJ/gobuster/v3@latest"
    "github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest"
    "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
    "github.com/tomnomnom/assetfinder@latest"
    "github.com/ffuf/ffuf@latest"
    "github.com/tomnomnom/gf@latest"
    "github.com/tomnomnom/meg@latest"
    "github.com/tomnomnom/waybackurls@latest"
    "github.com/LukaSikic/subzy@latest"
    "github.com/projectdiscovery/asnmap/cmd/asnmap@latest"
    "github.com/channyein1337/jsleak@latest"
    "github.com/projectdiscovery/mapcidr/cmd/mapcidr@latest"
    "github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
    "github.com/jaeles-project/gospider@latest"
    "github.com/projectdiscovery/katana/cmd/katana@latest"
    "github.com/projectdiscovery/uncover/cmd/uncover@latest"
    "github.com/hahwul/dalfox/v2@latest"
    "github.com/0xsha/GoLinkFinder@latest"
    "github.com/hakluke/hakrawler@latest"
    "github.com/edoardottt/csprecon/cmd/csprecon@latest"
    "github.com/Josue87/gotator@latest"
    "github.com/j3ssie/osmedeus@latest"
    "github.com/projectdiscovery/shuffledns/cmd/shuffledns@latest"
    "github.com/utkusen/socialhunter@latest"
    "github.com/003random/getJS@latest"
  )

  for tool in "${tools[@]}"; do
    local tool_name
    tool_name=$(basename "$tool" | cut -d@ -f1)
    if ! command_exists "$tool_name"; then
      echo "Installing $tool_name..."
      go install -v "$tool" &> /dev/null
      sudo cp "$HOME/go/bin/$tool_name" /usr/local/bin
      echo "$tool_name has been installed."
    else
      echo "$tool_name is already installed."
    fi
  done
}

# Clone and install Python tools with user prompts
install_python_tools() {
  declare -A python_tools=(
    ["knock"]="https://github.com/guelfoweb/knock.git"
    ["XSStrike"]="https://github.com/s0md3v/XSStrike"
    ["Logsensor"]="https://github.com/Mr-Robert0/Logsensor.git"
    ["Altdns"]="https://github.com/infosec-au/altdns.git"
    ["xnLinkFinder"]="https://github.com/xnl-h4ck3r/xnLinkFinder.git"
    ["ParamSpider"]="https://github.com/devanshbatham/ParamSpider"
    ["NoSQLMap"]="https://github.com/codingo/NoSQLMap.git"
    ["chameleon"]="https://raw.githubusercontent.com/iustin24/chameleon/master/install.sh"
    ["GraphQLmap"]="https://github.com/swisskyrepo/GraphQLmap"
    ["WhatWeb"]="https://github.com/urbanadventurer/WhatWeb.git"
    ["http-request-smuggling"]="https://github.com/anshumanpattnaik/http-request-smuggling.git"
    ["keyfinder"]="https://github.com/momenbasel/keyFinder.git"
    ["goisnt"]="https://github.com/Nhoya/gOSINT.git"
    ["JWT_TOOL"]="https://github.com/ticarpi/jwt_tool"
    ["Arjun"]="https://github.com/s0md3v/Arjun"
    ["Gitleaks"]="https://github.com/zricethezav/gitleaks.git"
  )

  for tool in "${!python_tools[@]}"; do
    read -rp "Do you want to install $tool (Y/n)? " choice
    case "$choice" in
      [Yy]*|"")
        echo "Installing $tool..."
        if [[ "$tool" == "chameleon" ]]; then
          curl -sL "${python_tools[$tool]}" | bash
        else
          git clone "${python_tools[$tool]}"
          cd "$tool" || continue
          if [[ -f "requirements.txt" ]]; then
            pip3 install -r requirements.txt &> /dev/null
          fi
          if [[ "$tool" == "JWT_TOOL" ]]; then
            python3 -m pip install termcolor cprint pycryptodomex requests
            chmod +x jwt_tool.py
          elif [[ "$tool" == "Arjun" ]]; then
            python3 setup.py install
          elif [[ "$tool" == "Gitleaks" ]]; then
            make build
            mv gitleaks /usr/local/bin
          fi
          cd - || continue
        fi
        echo "$tool has been installed."
        ;;
      *)
        echo "Skipping $tool installation."
        ;;
    esac
  done
}

# Install main system framework
install_main_system() {
  echo "Installing Omniscient main system infrastructure..."
  go install github.com/graniet/operative-framework@latest
  echo "Operative Framework installed."
}

# Install Andriller tool
install_andriller() {
  echo "Installing Andriller..."
  pip uninstall -y andriller
  pip install -U andriller
  echo "Running Andriller GUI..."
  python -m andriller
}

# Install Python requirements for /opt tools
install_operations_requirements() {
  for dir in /opt/*/; do
    if [ -f "$dir/requirements.txt" ]; then
      echo "Installing Python packages in $dir..."
      pip install -r "$dir/requirements.txt" --break-system-packages
    fi
  done
}

# Make scripts in /usr/local/bin executable and run them
arm_and_execute_scripts() {
  local script_directory="/usr/local/bin"
  for script in "$script_directory"/*; do
    if [ -f "$script" ]; then
      if [ ! -x "$script" ]; then
        chmod +x "$script"
        echo "Made $script executable."
      fi
      "$script"
    fi
  done
}

# Main function
main() {
  check_root
  print_banner
  prepare_arsenal_dir
  install_system_requirements
  php_install_instructions
  install_php
  install_go_tools
  install_python_tools
  install_main_system
  install_andriller
  install_operations_requirements
  arm_and_execute_scripts
  echo -e "${Green}Installation and setup complete.${END}"
}

main "$@"
