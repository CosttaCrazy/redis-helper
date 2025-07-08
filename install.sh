#!/bin/bash

# Redis Helper Installation Script
# Licensed under GPLv3

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
INSTALL_DIR="/opt/redis-helper"
BIN_DIR="/usr/local/bin"
CONFIG_DIR="$HOME/.redis-helper"
GITHUB_REPO="https://github.com/CosttaCrazy/redis-helper"

# Functions
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Check if running as root for system-wide installation
check_permissions() {
    if [[ $EUID -eq 0 ]]; then
        log "Installing system-wide (all users)"
        INSTALL_DIR="/opt/redis-helper"
        BIN_DIR="/usr/local/bin"
    else
        log "Installing for current user only"
        INSTALL_DIR="$HOME/.local/share/redis-helper"
        BIN_DIR="$HOME/.local/bin"
        mkdir -p "$BIN_DIR"
    fi
}

# Check dependencies
check_dependencies() {
    log "Checking dependencies..."
    
    local missing_deps=()
    
    # Check for required commands
    for cmd in bash redis-cli bc; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    # Check for optional commands
    for cmd in gzip curl wget; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            warn "Optional dependency missing: $cmd"
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        error "Missing required dependencies: ${missing_deps[*]}"
    fi
    
    log "All required dependencies found"
}

# Download or copy files
install_files() {
    log "Installing Redis Helper files..."
    
    # Create installation directory
    mkdir -p "$INSTALL_DIR"
    
    # If we're in the source directory, copy files
    if [[ -f "redis-helper.sh" ]]; then
        log "Copying files from source directory..."
        cp -r . "$INSTALL_DIR/"
    else
        # Download from GitHub
        log "Downloading from GitHub..."
        if command -v git >/dev/null 2>&1; then
            git clone "$GITHUB_REPO" "$INSTALL_DIR"
        elif command -v curl >/dev/null 2>&1; then
            curl -L "$GITHUB_REPO/archive/main.tar.gz" | tar -xz -C "$INSTALL_DIR" --strip-components=1
        elif command -v wget >/dev/null 2>&1; then
            wget -O- "$GITHUB_REPO/archive/main.tar.gz" | tar -xz -C "$INSTALL_DIR" --strip-components=1
        else
            error "No download method available (git, curl, or wget required)"
        fi
    fi
    
    # Make scripts executable
    chmod +x "$INSTALL_DIR/redis-helper.sh"
    [[ -f "$INSTALL_DIR/install.sh" ]] && chmod +x "$INSTALL_DIR/install.sh"
    
    # Create necessary directories
    mkdir -p "$INSTALL_DIR"/{config,logs,backups,metrics,lib}
    
    log "Files installed to $INSTALL_DIR"
}

# Create symlink
create_symlink() {
    log "Creating symlink..."
    
    # Remove existing symlink if it exists
    [[ -L "$BIN_DIR/redis-helper" ]] && rm "$BIN_DIR/redis-helper"
    
    # Create new symlink
    ln -s "$INSTALL_DIR/redis-helper.sh" "$BIN_DIR/redis-helper"
    
    log "Symlink created: $BIN_DIR/redis-helper -> $INSTALL_DIR/redis-helper.sh"
}

# Setup user configuration
setup_user_config() {
    log "Setting up user configuration..."
    
    # Create user config directory
    mkdir -p "$CONFIG_DIR"
    
    # Copy default config if it doesn't exist
    if [[ ! -f "$CONFIG_DIR/redis-helper.conf" ]]; then
        if [[ -f "$INSTALL_DIR/config/redis-helper.conf" ]]; then
            cp "$INSTALL_DIR/config/redis-helper.conf" "$CONFIG_DIR/"
        fi
        log "Default configuration created at $CONFIG_DIR/redis-helper.conf"
    else
        log "Existing configuration found at $CONFIG_DIR/redis-helper.conf"
    fi
    
    # Create user directories
    mkdir -p "$CONFIG_DIR"/{logs,backups,metrics}
}

# Add to PATH if needed
update_path() {
    if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
        warn "$BIN_DIR is not in your PATH"
        
        # Suggest adding to shell profile
        local shell_profile=""
        case "$SHELL" in
            */bash) shell_profile="$HOME/.bashrc" ;;
            */zsh) shell_profile="$HOME/.zshrc" ;;
            */fish) shell_profile="$HOME/.config/fish/config.fish" ;;
            *) shell_profile="$HOME/.profile" ;;
        esac
        
        echo
        echo "To add $BIN_DIR to your PATH, add this line to $shell_profile:"
        echo "export PATH=\"$BIN_DIR:\$PATH\""
        echo
        echo "Then run: source $shell_profile"
    fi
}

# Create desktop entry (Linux only)
create_desktop_entry() {
    if [[ "$OSTYPE" == "linux-gnu"* ]] && command -v xdg-desktop-menu >/dev/null 2>&1; then
        log "Creating desktop entry..."
        
        local desktop_file="$HOME/.local/share/applications/redis-helper.desktop"
        mkdir -p "$(dirname "$desktop_file")"
        
        cat > "$desktop_file" << EOF
[Desktop Entry]
Name=Redis Helper
Comment=Advanced Redis Management Tool
Exec=gnome-terminal -- $BIN_DIR/redis-helper
Icon=database
Terminal=true
Type=Application
Categories=Development;Database;
Keywords=redis;database;monitoring;
EOF
        
        log "Desktop entry created"
    fi
}

# Test installation
test_installation() {
    log "Testing installation..."
    
    if [[ -x "$BIN_DIR/redis-helper" ]]; then
        log "Installation test passed"
        
        # Show version
        "$BIN_DIR/redis-helper" --version
    else
        error "Installation test failed"
    fi
}

# Show completion message
show_completion() {
    echo
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                 Redis Helper Installation Complete!           ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${BLUE}Installation Details:${NC}"
    echo "  • Installation directory: $INSTALL_DIR"
    echo "  • Binary location: $BIN_DIR/redis-helper"
    echo "  • Configuration: $CONFIG_DIR/redis-helper.conf"
    echo
    echo -e "${BLUE}Getting Started:${NC}"
    echo "  1. Run: redis-helper"
    echo "  2. Configure your Redis connection in the settings"
    echo "  3. Explore the features through the interactive menu"
    echo
    echo -e "${BLUE}Documentation:${NC}"
    echo "  • README: $INSTALL_DIR/README.md"
    echo "  • GitHub: $GITHUB_REPO"
    echo
    echo -e "${YELLOW}Note: Make sure Redis is running and accessible before using the tool${NC}"
}

# Uninstall function
uninstall() {
    echo -e "${YELLOW}Uninstalling Redis Helper...${NC}"
    
    # Remove symlink
    [[ -L "$BIN_DIR/redis-helper" ]] && rm "$BIN_DIR/redis-helper"
    
    # Remove installation directory
    if [[ -d "$INSTALL_DIR" ]]; then
        read -p "Remove installation directory $INSTALL_DIR? (y/N): " -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$INSTALL_DIR"
            log "Installation directory removed"
        fi
    fi
    
    # Remove user config (optional)
    if [[ -d "$CONFIG_DIR" ]]; then
        read -p "Remove user configuration and data $CONFIG_DIR? (y/N): " -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$CONFIG_DIR"
            log "User configuration removed"
        fi
    fi
    
    # Remove desktop entry
    [[ -f "$HOME/.local/share/applications/redis-helper.desktop" ]] && \
        rm "$HOME/.local/share/applications/redis-helper.desktop"
    
    log "Redis Helper uninstalled"
}

# Main installation process
main() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                    Redis Helper Installer                     ║${NC}"
    echo -e "${BLUE}║              Advanced Redis Management Tool                   ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    # Parse command line arguments
    case "${1:-install}" in
        "install")
            check_permissions
            check_dependencies
            install_files
            create_symlink
            setup_user_config
            update_path
            create_desktop_entry
            test_installation
            show_completion
            ;;
        "uninstall")
            check_permissions
            uninstall
            ;;
        "update")
            log "Updating Redis Helper..."
            check_permissions
            install_files
            log "Update completed"
            ;;
        "--help"|"-h")
            echo "Redis Helper Installer"
            echo
            echo "Usage: $0 [command]"
            echo
            echo "Commands:"
            echo "  install    - Install Redis Helper (default)"
            echo "  uninstall  - Remove Redis Helper"
            echo "  update     - Update to latest version"
            echo "  --help     - Show this help"
            ;;
        *)
            error "Unknown command: $1. Use --help for usage information."
            ;;
    esac
}

# Run main function
main "$@"
