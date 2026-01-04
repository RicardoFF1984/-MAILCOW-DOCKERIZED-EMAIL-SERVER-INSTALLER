#!/bin/bash

#───────────────────────────────────────────────────────────────
# ROOT MODE CONFIRMATION
#───────────────────────────────────────────────────────────────

printf "This script must be run as ROOT.\n"
printf "Are you currently running as root? (y/n): "
read answer

if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
    printf "\nPlease switch to root mode using:\n"
    printf "   sudo -i\n\n"
    printf "Exiting script so you can re-run it as root.\n"
    exit 1
fi

printf "Root mode confirmed. Continuing...\n\n"


###############################################################################
#                   MAILCOW DOCKERIZED EMAIL SERVER INSTALLER
#                        Ubuntu Server 24.04 LTS Edition
#
#  This script installs and configures:
#    • Docker + Docker Compose
#    • Mailcow (full email stack: SMTP, IMAP, POP3, Webmail, Antivirus, Spam)
#
#  It is intentionally simple and educational.
#  Every step includes clear explanations so even beginners understand
#  what is happening and why it is required.
#
#  REQUIREMENTS BEFORE RUNNING:
#    • Fresh Ubuntu Server 24.04 installation
#    • Minimum 6 GB RAM (8 GB+ recommended)
#    • Minimum 40 GB disk space
#    • A domain with DNS A + MX records pointing to this server
#    • Ports 25, 80, 443, 587, 993, 995 must be open
#
###############################################################################

printf "\n"
printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
printf "        UBUNTU 24.04 – MAILCOW EMAIL SERVER INSTALLER\n"
printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"
printf "This script will automatically install Docker, Docker Compose,\n"
printf "and the full Mailcow email server stack.\n\n"
printf "Sit back and relax — each step will be explained clearly.\n\n"

###############################################################################
# STEP 1 — Update the system
###############################################################################
printf "[1/8] Updating system packages...\n"
# Updates the package list and installs the latest security patches
apt update -y && apt upgrade -y
printf "✓ System updated.\n\n"

###############################################################################
# STEP 2 — Install required dependencies
###############################################################################
printf "[2/8] Installing required packages...\n"
printf "   These tools allow the system to download, verify, and run Docker.\n"

apt install -y \
    curl \                    # Used to download files from the internet
    git \                     # Required to clone the Mailcow repository
    apt-transport-https \     # Allows APT to use HTTPS sources
    ca-certificates \         # Ensures secure package downloads
    gnupg2 \                  # Used to verify package signatures
    software-properties-common # Provides add-apt-repository and other tools

printf "✓ Dependencies installed.\n\n"

###############################################################################
# STEP 3 — Add Docker repository and GPG key
###############################################################################
printf "[3/8] Adding Docker security key...\n"
# Downloads Docker's official GPG key and stores it securely
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
printf "✓ Docker GPG key added.\n"

printf "[3/8] Adding Docker repository...\n"
# Adds Docker's official repository to APT sources
echo "deb [arch=$(dpkg --print-architecture) \
signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
| tee /etc/apt/sources.list.d/docker.list

apt update -y
printf "✓ Docker repository added.\n\n"

###############################################################################
# STEP 4 — Install Docker Engine
###############################################################################
printf "[4/8] Installing Docker Engine...\n"
# Installs Docker CE (Community Edition) and its components
apt install -y docker-ce docker-ce-cli containerd.io
printf "✓ Docker installed and running.\n\n"

###############################################################################
# STEP 5 — Install Docker Compose
###############################################################################
printf "[5/8] Installing Docker Compose...\n"
printf "   Docker Compose is required to run Mailcow's multi-container setup.\n"

# Downloads the latest stable Docker Compose binary
curl -L \
"https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-$(uname -s)-$(uname -m)" \
-o /usr/local/bin/docker-compose

# Makes the binary executable
chmod +x /usr/local/bin/docker-compose
printf "✓ Docker Compose installed.\n\n"

###############################################################################
# STEP 6 — Download Mailcow
###############################################################################
printf "[6/8] Downloading Mailcow...\n"
# Mailcow is installed in /opt (standard for server applications)
cd /opt

# Clones the official Mailcow repository
git clone https://github.com/mailcow/mailcow-dockerized
cd mailcow-dockerized

printf "✓ Mailcow repository cloned.\n\n"

###############################################################################
# STEP 7 — Generate Mailcow configuration
###############################################################################
printf "[7/8] Installing jq (required for config generator)...\n"
# jq is required by Mailcow's configuration script
apt install -y jq

printf "Before continuing, please choose the correct TIMEZONE for your server.\n"
printf "This ensures correct email timestamps, logs, DKIM signing times, and scheduling.\n\n"

printf "Common timezone examples:\n"
printf "  • Europe/Lisbon      → Portugal mainland\n"
printf "  • Europe/London      → UK / Ireland\n"
printf "  • Europe/Madrid      → Spain\n"
printf "  • Europe/Paris       → France\n"
printf "  • America/New_York   → US East Coast\n"
printf "  • America/Los_Angeles→ US West Coast\n"
printf "  • UTC                → Universal Coordinated Time (neutral)\n\n"

printf "Mailcow will ask you to type your timezone manually.\n"
printf "If you are in Portugal, use:  Europe/Lisbon\n\n"

printf "Press Enter to continue to the Mailcow configuration wizard...\n"
read -r

# Launches Mailcow's interactive configuration generator
./generate_config.sh


printf "✓ Configuration generated.\n\n"

###############################################################################
# STEP 8 — Pull and start Mailcow containers
###############################################################################
printf "[8/8] Pulling Mailcow Docker images...\n"
# Downloads all required Mailcow container images
docker-compose pull
printf "✓ Images downloaded.\n"

printf "Starting Mailcow services...\n"
# Starts the entire Mailcow stack in the background
docker-compose up -d
printf "✓ Mailcow is now running.\n\n"

###############################################################################
# COMPLETION MESSAGE
###############################################################################
printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
printf "                 MAILCOW INSTALLATION COMPLETE\n"
printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"

printf "You can now access your Mailcow admin panel at:\n"
printf "   → https://YOUR-MAIL-SERVER\n\n"

printf "Default admin login:\n"
printf "   Username: admin\n"
printf "   Password: moohoo\n\n"

printf "IMPORTANT:\n"
printf "   • Update DNS (A, MX, SPF, DKIM, DMARC)\n"
printf "   • Open ports: 25, 80, 443, 587, 993, 995\n"
printf "   • Change the default admin password immediately\n\n"

printf "Mailcow is fully deployed. Enjoy your new email server!\n"
