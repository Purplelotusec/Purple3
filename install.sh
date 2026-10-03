#!/bin/bash

# Osprey CLI Installation Script
# Download and install: curl -fsSL https://purplelotus.space/install.sh | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Banner
echo -e "${PURPLE}"
cat << "EOF"
 ____                   _      _           _
|  _ \ _   _ _ __ _ __ | | ___| |    ___ | |_ _   _ ___
| |_) | | | | '__| '_ \| |/ _ \ |   / _ \| __| | | / __|
|  __/| |_| | |  | |_) | |  __/ |__| (_) | |_| |_| \__ \
|_|    \__,_|_|  | .__/|_|\___|_____\___/ \__|\__,_|___/
                 |_|
EOF
echo -e "${NC}"
echo -e "${GREEN}Installing Osprey CLI - Supply Chain Security Tool${NC}"
echo ""

# Installation directory
INSTALL_DIR="$HOME/.purplelotus"
OSPREY_DIR="$INSTALL_DIR/osprey"

echo -e "${BLUE}[1/5]${NC} Checking system requirements..."

# Check for required tools
if ! command -v git >/dev/null 2>&1; then
    echo -e "${RED}Error: git is not installed.${NC}"
    echo -e "Please install git first."
    exit 1
fi

if ! command -v node >/dev/null 2>&1; then
    echo -e "${RED}Error: Node.js is not installed.${NC}"
    echo -e "Please install Node.js (v14 or higher) first."
    echo -e "Visit: https://nodejs.org/"
    exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
    echo -e "${RED}Error: npm is not installed.${NC}"
    echo -e "Please install npm first (usually comes with Node.js)."
    exit 1
fi

echo -e "${GREEN}✓ System requirements satisfied${NC}"

# Check versions
NODE_VERSION=$(node --version 2>&1)
NPM_VERSION=$(npm --version 2>&1)
echo -e "  Node.js: ${NODE_VERSION}"
echo -e "  npm: ${NPM_VERSION}"

echo ""
echo -e "${BLUE}[2/5]${NC} Setting up installation directory..."

# Create installation directory if it doesn't exist
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Clone or update Osprey repository
if [ -d "$OSPREY_DIR" ]; then
    echo -e "${YELLOW}Osprey directory already exists. Updating...${NC}"
    cd "$OSPREY_DIR"
    git pull origin main || git pull origin master || {
        echo -e "${YELLOW}Could not pull updates. Using existing version.${NC}"
    }
else
    echo -e "Cloning Osprey from GitHub..."
    git clone https://github.com/Purplelotusec/Osprey.git "$OSPREY_DIR" || {
        echo -e "${RED}Error: Could not clone Osprey repository.${NC}"
        echo -e "Please check your internet connection and try again."
        exit 1
    }
    cd "$OSPREY_DIR"
fi

echo -e "${GREEN}✓ Osprey repository ready${NC}"
echo ""

echo -e "${BLUE}[3/5]${NC} Installing dependencies..."

# Install npm dependencies
npm install || {
    echo -e "${RED}Error: npm install failed.${NC}"
    echo -e "Please check the error messages above."
    exit 1
}

echo -e "${GREEN}✓ Dependencies installed${NC}"
echo ""

echo -e "${BLUE}[4/5]${NC} Linking Osprey CLI globally..."

# Link the CLI tool globally
npm link || {
    echo -e "${YELLOW}Warning: npm link failed. Trying with sudo...${NC}"
    sudo npm link || {
        echo -e "${RED}Error: Could not link Osprey CLI globally.${NC}"
        echo -e "You may need to run with sudo or configure npm properly."
        exit 1
    }
}

echo -e "${GREEN}✓ Osprey CLI linked globally${NC}"
echo ""

echo -e "${BLUE}[5/5]${NC} Verifying installation..."

# Verify the CLI is accessible
if command -v osprey >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Osprey CLI is ready!${NC}"
elif command -v cra >/dev/null 2>&1; then
    echo -e "${GREEN}✓ CRA CLI is ready!${NC}"
else
    echo -e "${YELLOW}Warning: CLI command not found in PATH.${NC}"
    echo -e "You may need to restart your terminal or add npm global bin to PATH."
fi

echo ""
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "Osprey CLI installed at: ${BLUE}$OSPREY_DIR${NC}"
echo ""
echo -e "${YELLOW}Quick Start:${NC}"
echo -e "  ${GREEN}osprey --help${NC}      # Show all available commands"
echo -e "  ${GREEN}cra --help${NC}         # Alternative command (if osprey is the CRA tool)"
echo ""
echo -e "${YELLOW}Example Usage:${NC}"
echo -e "  ${GREEN}osprey scan${NC}        # Scan current project"
echo -e "  ${GREEN}osprey init${NC}        # Initialize configuration"
echo ""
echo -e "${YELLOW}Update Osprey:${NC}"
echo -e "  Run this installer again to update to the latest version"
echo ""
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Need help?${NC} Visit: ${GREEN}https://purplelotus.space${NC}"
echo -e "${BLUE}Report issues:${NC} ${GREEN}https://github.com/Purplelotusec/Osprey/issues${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
