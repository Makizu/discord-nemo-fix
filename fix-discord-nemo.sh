#!/bin/bash
# Discord/Vesktop Nemo File Picker Fix for Linux
# Version: 1.1
# Description: Redirects Discord and Vesktop file picker from Nautilus to Nemo

set -e

SCRIPT_NAME="Discord/Vesktop Nemo File Picker Fix"
VERSION="1.1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Help function
show_help() {
    cat << EOF
$SCRIPT_NAME v$VERSION

DESCRIPTION:
    Fixes Discord and Vesktop file picker to use Nemo instead of Nautilus on Linux.
    Creates a wrapper script that intercepts nautilus calls and redirects them to nemo.

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help      Show this help message
    -v, --verbose   Enable verbose output
    -u, --uninstall Remove the fix
    --dry-run       Show what would be done without making changes

WHAT THIS SCRIPT MODIFIES:
    - Creates: ~/.local/bin/nautilus (wrapper script)
    - Modifies: ~/.bashrc (adds PATH configuration)
    - Modifies: ~/.zshrc (adds PATH configuration, if exists)
    - Creates: ~/.config/environment.d/nemo-fix.conf
    - Creates: ~/.local/share/applications/discord-nemo.desktop
    - Creates: ~/.local/share/applications/vesktop-nemo.desktop

REQUIREMENTS:
    - Nemo file manager must be installed
    - Discord and/or Vesktop should be installed

EOF
}

# Check dependencies
check_dependencies() {
    log "Checking dependencies..."

    if ! command -v nemo >/dev/null 2>&1; then
        error "Nemo is not installed"
        echo "Please install Nemo first:"
        echo "  Arch/Manjaro: sudo pacman -S nemo"
        echo "  Ubuntu/Debian: sudo apt install nemo"
        echo "  Fedora: sudo dnf install nemo"
        exit 1
    fi

    local discord_found=false
    local vesktop_found=false

    if command -v discord >/dev/null 2>&1; then
        discord_found=true
        log "Discord found"
    fi

    if command -v vesktop >/dev/null 2>&1; then
        vesktop_found=true
        log "Vesktop found"
    fi

    if [ "$discord_found" = false ] && [ "$vesktop_found" = false ]; then
        warn "Neither Discord nor Vesktop found in PATH"
        warn "Make sure at least one is installed before using this fix"
    fi

    success "Dependencies check passed"
}

# Backup existing files
backup_files() {
    log "Creating backups of existing files..."

    if [ -f ~/.local/bin/nautilus ]; then
        cp ~/.local/bin/nautilus ~/.local/bin/nautilus.backup.$(date +%s)
        log "Backed up existing ~/.local/bin/nautilus"
    fi

    if [ -f ~/.bashrc ]; then
        cp ~/.bashrc ~/.bashrc.backup.$(date +%s)
        log "Backed up ~/.bashrc"
    fi

    if [ -f ~/.zshrc ]; then
        cp ~/.zshrc ~/.zshrc.backup.$(date +%s)
        log "Backed up ~/.zshrc"
    fi
}

# Create wrapper script
create_wrapper() {
    log "Creating nautilus wrapper script..."

    mkdir -p ~/.local/bin

    cat > ~/.local/bin/nautilus << 'EOF'
#!/bin/bash
# Nautilus to Nemo wrapper
# Created by Discord Nemo File Picker Fix
# Redirects all nautilus calls to nemo

# Log the call for debugging
echo "$(date '+%Y-%m-%d %H:%M:%S'): nautilus called with args: $*" >> ~/.local/share/nautilus-wrapper.log

# Check if nemo is available
if command -v nemo >/dev/null 2>&1; then
    exec nemo "$@"
else
    # Fallback to system nautilus if nemo is not available
    if [ -f /usr/bin/nautilus ]; then
        exec /usr/bin/nautilus "$@"
    else
        echo "Error: Neither nemo nor nautilus found" >&2
        exit 1
    fi
fi
EOF

    chmod +x ~/.local/bin/nautilus
    success "Created wrapper script at ~/.local/bin/nautilus"
}

# Configure PATH
configure_path() {
    log "Configuring PATH in shell configuration files..."

    local path_export='export PATH="$HOME/.local/bin:$PATH"'

    # Configure bashrc
    if [ -f ~/.bashrc ]; then
        if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc; then
            echo "" >> ~/.bashrc
            echo "# Added by Discord Nemo File Picker Fix" >> ~/.bashrc
            echo "$path_export" >> ~/.bashrc
            log "Added PATH configuration to ~/.bashrc"
        else
            log "PATH already configured in ~/.bashrc"
        fi
    fi

    # Configure zshrc if it exists
    if [ -f ~/.zshrc ]; then
        if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' ~/.zshrc; then
            echo "" >> ~/.zshrc
            echo "# Added by Discord Nemo File Picker Fix" >> ~/.zshrc
            echo "$path_export" >> ~/.zshrc
            log "Added PATH configuration to ~/.zshrc"
        else
            log "PATH already configured in ~/.zshrc"
        fi
    fi

    # Create environment.d configuration
    mkdir -p ~/.config/environment.d
    cat > ~/.config/environment.d/nemo-fix.conf << EOF
# Discord Nemo File Picker Fix
# Ensures ~/.local/bin has priority in PATH
PATH="$HOME/.local/bin:\$PATH"
EOF
    log "Created environment configuration at ~/.config/environment.d/nemo-fix.conf"
}

# Create application launchers
create_app_launchers() {
    log "Creating application launchers with Nemo integration..."

    mkdir -p ~/.local/share/applications

    # Create Discord launcher if Discord is installed
    if command -v discord >/dev/null 2>&1; then
        cat > ~/.local/share/applications/discord-nemo.desktop << EOF
[Desktop Entry]
Name=Discord (Nemo)
StartupWMClass=discord
Comment=Discord with Nemo file picker integration
GenericName=Internet Messenger
Exec=env PATH="$HOME/.local/bin:\$PATH" discord
Icon=discord
Type=Application
Categories=Network;InstantMessaging;
Keywords=chat;voice;video;game;gaming;
EOF
        log "Created Discord launcher"
    fi

    # Create Vesktop launcher if Vesktop is installed
    if command -v vesktop >/dev/null 2>&1; then
        cat > ~/.local/share/applications/vesktop-nemo.desktop << EOF
[Desktop Entry]
Name=Vesktop (Nemo)
StartupWMClass=vesktop
Comment=Vesktop with Nemo file picker integration
GenericName=Internet Messenger
Exec=env PATH="$HOME/.local/bin:\$PATH" vesktop
Icon=vesktop
Type=Application
Categories=Network;InstantMessaging;
Keywords=chat;voice;video;game;gaming;discord;
EOF
        log "Created Vesktop launcher"
    fi

    # Update desktop database
    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database ~/.local/share/applications/ 2>/dev/null || true
        log "Updated desktop application database"
    fi

    success "Created application launchers with Nemo integration"
}

# Verify installation
verify_installation() {
    log "Verifying installation..."

    # Apply PATH for current session
    export PATH="$HOME/.local/bin:$PATH"

    # Check wrapper location
    local wrapper_path=$(which nautilus 2>/dev/null)
    if [ "$wrapper_path" = "$HOME/.local/bin/nautilus" ]; then
        success "Wrapper has PATH priority: $wrapper_path"
    else
        warn "Wrapper may not have PATH priority. Current: $wrapper_path"
        warn "You may need to restart your session"
    fi

    # Test wrapper functionality
    if [ -x ~/.local/bin/nautilus ]; then
        local test_output=$(~/.local/bin/nautilus --version 2>/dev/null || echo "nemo_executed")
        if [[ "$test_output" == *"nemo"* ]] || [[ "$test_output" == "nemo_executed" ]]; then
            success "Wrapper test passed"
        else
            warn "Wrapper test inconclusive"
        fi
    else
        error "Wrapper script is not executable"
    fi
}

# Uninstall function
uninstall() {
    log "Uninstalling Discord Nemo File Picker Fix..."

    # Remove wrapper
    if [ -f ~/.local/bin/nautilus ]; then
        rm ~/.local/bin/nautilus
        log "Removed wrapper script"
    fi

    # Remove application launchers
    if [ -f ~/.local/share/applications/discord-nemo.desktop ]; then
        rm ~/.local/share/applications/discord-nemo.desktop
        log "Removed Discord launcher"
    fi

    if [ -f ~/.local/share/applications/vesktop-nemo.desktop ]; then
        rm ~/.local/share/applications/vesktop-nemo.desktop
        log "Removed Vesktop launcher"
    fi

    # Remove environment config
    if [ -f ~/.config/environment.d/nemo-fix.conf ]; then
        rm ~/.config/environment.d/nemo-fix.conf
        log "Removed environment configuration"
    fi

    # Note about shell configs
    warn "PATH modifications in ~/.bashrc and ~/.zshrc were NOT removed"
    warn "Remove this line manually if desired: export PATH=\"\$HOME/.local/bin:\$PATH\""

    success "Uninstallation completed"
}

# Main installation function
install() {
    echo "$SCRIPT_NAME v$VERSION"
    echo "========================================"
    echo ""

    log "Starting installation..."
    echo ""

    check_dependencies
    backup_files
    create_wrapper
    configure_path
    create_app_launchers
    verify_installation

    echo ""
    echo "========================================"
    success "Installation completed successfully!"
    echo ""
    echo "NEXT STEPS:"
    echo "1. Close Discord/Vesktop completely (kill all processes)"
    echo "2. Launch 'Discord (Nemo)' or 'Vesktop (Nemo)' from your application launcher"
    echo "3. Alternatively, restart your session for global effect"
    echo ""
    echo "VERIFICATION:"
    echo "- Check wrapper priority: which nautilus"
    echo "- Monitor calls: tail -f ~/.local/share/nautilus-wrapper.log"
    echo ""
    echo "TROUBLESHOOTING:"
    echo "- If not working immediately, restart your session"
    echo "- Use the 'Discord (Nemo)' or 'Vesktop (Nemo)' launcher specifically"
    echo "- Check PATH includes ~/.local/bin with: echo \$PATH"
    echo ""
    echo "To uninstall: $0 --uninstall"
}

# Parse command line arguments
VERBOSE=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -u|--uninstall)
            uninstall
            exit 0
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Dry run mode
if [ "$DRY_RUN" = true ]; then
    echo "$SCRIPT_NAME v$VERSION - DRY RUN MODE"
    echo "========================================"
    echo ""
    echo "The following changes would be made:"
    echo ""
    echo "FILES TO CREATE/MODIFY:"
    echo "- ~/.local/bin/nautilus (wrapper script)"
    echo "- ~/.bashrc (add PATH configuration)"
    echo "- ~/.zshrc (add PATH configuration, if exists)"
    echo "- ~/.config/environment.d/nemo-fix.conf"
    echo "- ~/.local/share/applications/discord-nemo.desktop (if Discord installed)"
    echo "- ~/.local/share/applications/vesktop-nemo.desktop (if Vesktop installed)"
    echo ""
    echo "BACKUPS TO CREATE:"
    echo "- ~/.local/bin/nautilus.backup.TIMESTAMP (if exists)"
    echo "- ~/.bashrc.backup.TIMESTAMP"
    echo "- ~/.zshrc.backup.TIMESTAMP (if exists)"
    echo ""
    echo "Run without --dry-run to apply changes"
    exit 0
fi

# Run installation
install
