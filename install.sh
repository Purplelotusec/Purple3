#!/bin/bash

# PurpleLotus Installation Script
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
echo -e "${GREEN}Supply Chain Security - Local Installation${NC}"
echo ""

# Installation directory
INSTALL_DIR="$HOME/purplelotus"
PROJECT_NAME="Purple3"
PROJECT_DIR="$INSTALL_DIR/$PROJECT_NAME"

echo -e "${BLUE}[1/6]${NC} Checking system requirements..."

# Check for required tools
command -v git >/dev/null 2>&1 || { echo -e "${RED}Error: git is not installed.${NC} Please install git first."; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo -e "${RED}Error: python3 is not installed.${NC} Please install Python 3.8+ first."; exit 1; }

echo -e "${GREEN}✓ System requirements satisfied${NC}"

# Check Python version
PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
echo -e "  Python version: ${PYTHON_VERSION}"

echo ""
echo -e "${BLUE}[2/6]${NC} Setting up installation directory..."

# Create installation directory if it doesn't exist
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Create project directory
if [ -d "$PROJECT_DIR" ]; then
    echo -e "${YELLOW}Project directory already exists. Updating files...${NC}"
    cd "$PROJECT_DIR"
else
    echo -e "Creating project directory..."
    mkdir -p "$PROJECT_DIR"
    cd "$PROJECT_DIR"
fi

# Download files from purplelotus.space
echo -e "Downloading files from purplelotus.space..."

# Download main HTML files
curl -fsSL https://purplelotus.space/index.html -o index.html || {
    echo -e "${RED}Error: Could not download from purplelotus.space${NC}"
    echo -e "Please ensure the site is accessible."
    exit 1
}

curl -fsSL https://purplelotus.space/style.css -o style.css 2>/dev/null || true
curl -fsSL https://purplelotus.space/blogs.html -o blogs.html 2>/dev/null || true
curl -fsSL https://purplelotus.space/threat-feed.html -o threat-feed.html 2>/dev/null || true

# Download Python scripts
curl -fsSL https://purplelotus.space/fetch_attacks.py -o fetch_attacks.py 2>/dev/null || true
curl -fsSL https://purplelotus.space/fetch_incident_digest.py -o fetch_incident_digest.py 2>/dev/null || true
curl -fsSL https://purplelotus.space/requirements.txt -o requirements.txt 2>/dev/null || true

# Download assets
curl -fsSL https://purplelotus.space/PurpleBanner.jpg -o PurpleBanner.jpg 2>/dev/null || true

# Create necessary directories
mkdir -p data blog

echo -e "${GREEN}✓ Files downloaded${NC}"

echo -e "${GREEN}✓ Project directory ready${NC}"
echo ""

echo -e "${BLUE}[3/6]${NC} Installing Python dependencies..."

# Check if pip3 is installed, if not try to install it
if ! command -v pip3 >/dev/null 2>&1; then
    echo -e "${YELLOW}pip3 not found. Attempting to install...${NC}"

    # Detect OS and install pip3
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command -v apt-get >/dev/null 2>&1; then
            # Debian/Ubuntu
            echo -e "Installing pip3 using apt-get..."
            sudo apt-get update -qq && sudo apt-get install -y python3-pip -qq
        elif command -v yum >/dev/null 2>&1; then
            # CentOS/RHEL/Fedora
            echo -e "Installing pip3 using yum..."
            sudo yum install -y python3-pip -q
        elif command -v dnf >/dev/null 2>&1; then
            # Fedora (newer)
            echo -e "Installing pip3 using dnf..."
            sudo dnf install -y python3-pip -q
        elif command -v pacman >/dev/null 2>&1; then
            # Arch Linux
            echo -e "Installing pip3 using pacman..."
            sudo pacman -S --noconfirm python-pip
        else
            echo -e "${YELLOW}! Could not detect package manager. Trying ensurepip...${NC}"
            python3 -m ensurepip --upgrade 2>/dev/null || {
                echo -e "${RED}Error: Could not install pip3.${NC}"
                echo -e "Please install pip3 manually and run this script again."
                exit 1
            }
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        echo -e "Installing pip3 using ensurepip..."
        python3 -m ensurepip --upgrade 2>/dev/null || {
            echo -e "${YELLOW}Trying with homebrew...${NC}"
            if command -v brew >/dev/null 2>&1; then
                brew install python3
            else
                echo -e "${RED}Error: Could not install pip3.${NC}"
                echo -e "Please install pip3 manually: python3 -m ensurepip --upgrade"
                exit 1
            fi
        }
    else
        # Try ensurepip as fallback
        echo -e "Trying to install pip3 using ensurepip..."
        python3 -m ensurepip --upgrade 2>/dev/null || {
            echo -e "${RED}Error: Could not install pip3.${NC}"
            echo -e "Please install pip3 manually and run this script again."
            exit 1
        }
    fi

    # Verify pip3 installation
    if command -v pip3 >/dev/null 2>&1; then
        echo -e "${GREEN}✓ pip3 installed successfully${NC}"
    else
        echo -e "${RED}Error: pip3 installation failed.${NC}"
        echo -e "Please install pip3 manually and run this script again."
        exit 1
    fi
fi

# Install dependencies
if [ -f "requirements.txt" ]; then
    echo -e "Installing Python packages..."
    pip3 install --user -r requirements.txt -q || {
        echo -e "${YELLOW}! Some packages failed to install. Trying without --user flag...${NC}"
        pip3 install -r requirements.txt -q || {
            echo -e "${YELLOW}! Package installation had issues but continuing...${NC}"
        }
    }
    echo -e "${GREEN}✓ Python dependencies installed${NC}"
else
    echo -e "${YELLOW}! requirements.txt not found, skipping Python dependencies${NC}"
fi

echo ""
echo -e "${BLUE}[4/6]${NC} Fetching latest threat feed data..."

# Run the threat feed script if it exists
if [ -f "fetch_attacks.py" ]; then
    python3 fetch_attacks.py 2>/dev/null || {
        echo -e "${YELLOW}! Could not fetch threat feed (may need GitHub token)${NC}"
        echo -e "  You can set GITHUB_TOKEN env var for higher API limits"
    }
else
    echo -e "${YELLOW}! fetch_attacks.py not found${NC}"
fi

echo ""
echo -e "${BLUE}[5/6]${NC} Fetching AI incident digest..."

# Run the incident digest script if it exists
if [ -f "fetch_incident_digest.py" ]; then
    python3 fetch_incident_digest.py 2>/dev/null || {
        echo -e "${YELLOW}! Could not fetch incident digest${NC}"
    }
else
    echo -e "${YELLOW}! fetch_incident_digest.py not found${NC}"
fi

echo ""
echo -e "${BLUE}[6/6]${NC} Setting up local server..."

# Create a simple server launch script
cat > start.sh << 'SERVEREOF'
#!/bin/bash
echo "Starting PurpleLotus local server..."
echo "Access the site at: http://localhost:8000"
echo "Press Ctrl+C to stop the server"
echo ""

# Try different methods to start a local server
if command -v python3 >/dev/null 2>&1; then
    python3 -m http.server 8000
elif command -v python >/dev/null 2>&1; then
    python -m SimpleHTTPServer 8000
else
    echo "Error: Python is not installed. Cannot start server."
    exit 1
fi
SERVEREOF

chmod +x start.sh

echo -e "${GREEN}✓ Setup complete!${NC}"
echo ""
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "Project installed at: ${BLUE}$PROJECT_DIR${NC}"
echo ""
echo -e "${YELLOW}Quick Start:${NC}"
echo -e "  cd $PROJECT_DIR"
echo -e "  ./start.sh"
echo ""
echo -e "${YELLOW}Or manually start the server:${NC}"
echo -e "  python3 -m http.server 8000"
echo ""
echo -e "Then open your browser to: ${GREEN}http://localhost:8000${NC}"
echo ""
echo -e "${YELLOW}Update threat feed data:${NC}"
echo -e "  python3 fetch_attacks.py"
echo -e "  python3 fetch_incident_digest.py"
echo ""
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
