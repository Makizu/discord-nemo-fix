#!/bin/bash
# Nemo Global File Picker Fix for Hyprland
# Universal solution for all applications using XDG Portals + GTK + Direct calls

set -e

VERSION="3.0"
SCRIPT_NAME="Nemo Global File Picker Fix"

# Colors
export GUM_CHOOSE_CURSOR_FOREGROUND="#00D4AA"
export GUM_CHOOSE_SELECTED_FOREGROUND="#00D4AA"
export GUM_CONFIRM_SELECTED_FOREGROUND="#00D4AA"
export GUM_SPIN_SPINNER_FOREGROUND="#00D4AA"

# Check dependencies
check_dependencies() {
    local missing=()

    command -v gum >/dev/null 2>&1 || missing+=("gum")
    command -v nemo >/dev/null 2>&1 || missing+=("nemo")

    if [ ${#missing[@]} -gt 0 ]; then
        echo "❌ Missing dependencies: ${missing[*]}"
        echo ""
        echo "Install with:"
        [[ " ${missing[*]} " =~ " gum " ]] && echo "  • GUM: https://github.com/charmbracelet/gum#installation"
        [[ " ${missing[*]} " =~ " nemo " ]] && echo "  • Nemo: sudo pacman -S nemo (or your distro equivalent)"
        exit 1
    fi
}

# System status check
check_status() {
    local status="✅"
    local issues=()

    # Check XDG Portal config
    if [ ! -f ~/.config/xdg-desktop-portal/portals.conf ]; then
        status="⚠️"
        issues+=("XDG Portal not configured")
    fi

    # Check GTK settings
    if [ ! -f ~/.config/gtk-3.0/settings.ini ]; then
        status="⚠️"
        issues+=("GTK settings missing")
    elif ! grep -q "nemo" ~/.config/gtk-3.0/settings.ini 2>/dev/null; then
        status="⚠️"
        issues+=("Nemo not set as GTK default")
    fi

    # Check wrapper
    if [ ! -f ~/.local/bin/nautilus ]; then
        status="⚠️"
        issues+=("Wrapper script missing")
    fi

    echo "$status"
    if [ ${#issues[@]} -gt 0 ]; then
        printf " %s\n" "${issues[@]}"
    else
        echo " All components configured"
    fi
}

# Configure XDG Desktop Portal
configure_portal() {
    mkdir -p ~/.config/xdg-desktop-portal

    cat > ~/.config/xdg-desktop-portal/portals.conf << 'EOF'
[preferred]
default=gtk
org.freedesktop.impl.portal.FileChooser=gtk
EOF

    echo "✅ XDG Portal configured"
}

# Configure GTK file manager
configure_gtk() {
    mkdir -p ~/.config/gtk-3.0

    # Create or update GTK settings
    if [ -f ~/.config/gtk-3.0/settings.ini ]; then
        # Update existing file
        if grep -q "gtk-file-chooser-backend" ~/.config/gtk-3.0/settings.ini; then
            sed -i 's/gtk-file-chooser-backend=.*/gtk-file-chooser-backend=gio/' ~/.config/gtk-3.0/settings.ini
        else
            echo "gtk-file-chooser-backend=gio" >> ~/.config/gtk-3.0/settings.ini
        fi
    else
        # Create new file
        cat > ~/.config/gtk-3.0/settings.ini << 'EOF'
[Settings]
gtk-file-chooser-backend=gio
EOF
    fi

    # Set Nemo as default file manager in GIO
    gio mime inode/directory nemo.desktop 2>/dev/null || true

    echo "✅ GTK configured for Nemo"
}

# Create wrapper script
create_wrapper() {
    mkdir -p ~/.local/bin

    cat > ~/.local/bin/nautilus << 'EOF'
#!/bin/bash
# Nautilus to Nemo wrapper for Discord/Vesktop
exec nemo "$@" 2>/dev/null || {
    # Fallback to system nautilus if nemo fails
    exec /usr/bin/nautilus "$@" 2>/dev/null || exit 1
}
EOF

    chmod +x ~/.local/bin/nautilus
    echo "✅ Wrapper script created"
}

# Configure environment
configure_environment() {
    # Add ~/.local/bin to PATH if not present
    local shell_configs=("$HOME/.bashrc" "$HOME/.zshrc")
    local path_line='export PATH="$HOME/.local/bin:$PATH"'

    for config in "${shell_configs[@]}"; do
        if [ -f "$config" ] && ! grep -q "$path_line" "$config"; then
            echo "" >> "$config"
            echo "# Nemo Fix - PATH configuration" >> "$config"
            echo "$path_line" >> "$config"
        fi
    done

    # Environment.d for systemd sessions
    mkdir -p ~/.config/environment.d
    echo 'PATH="$HOME/.local/bin:$PATH"' > ~/.config/environment.d/nemo-fix.conf

    echo "✅ Environment configured"
}

# Install fix
install_fix() {
    gum style --foreground="#00D4AA" --bold "Installing Nemo File Picker Fix..."
    echo ""

    gum spin --spinner="dot" --title="Configuring XDG Portal..." -- sleep 1
    configure_portal

    gum spin --spinner="dot" --title="Configuring GTK..." -- sleep 1
    configure_gtk

    gum spin --spinner="dot" --title="Creating wrapper..." -- sleep 1
    create_wrapper

    gum spin --spinner="dot" --title="Setting up environment..." -- sleep 1
    configure_environment

    echo ""
    gum style --foreground="#00D4AA" --bold "✅ Installation complete!"
    echo ""
    echo "Next steps:"
    echo "1. Restart Discord/Vesktop"
    echo "2. Or restart your session for full effect"
    echo ""
}

# Uninstall fix
uninstall_fix() {
    gum style --foreground="#FF6B6B" --bold "Uninstalling Nemo File Picker Fix..."
    echo ""

    # Remove files
    [ -f ~/.config/xdg-desktop-portal/portals.conf ] && rm ~/.config/xdg-desktop-portal/portals.conf
    [ -f ~/.local/bin/nautilus ] && rm ~/.local/bin/nautilus
    [ -f ~/.config/environment.d/nemo-fix.conf ] && rm ~/.config/environment.d/nemo-fix.conf

    # Reset GTK to default
    if [ -f ~/.config/gtk-3.0/settings.ini ]; then
        sed -i '/gtk-file-chooser-backend/d' ~/.config/gtk-3.0/settings.ini
    fi

    echo "✅ Uninstallation complete"
    echo ""
    echo "Note: PATH modifications in shell configs were not removed"
    echo "Remove manually if desired: export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
}

# Main menu
main_menu() {
    while true; do
        clear

        # Header
        gum style \
            --foreground="#00D4AA" \
            --border="rounded" \
            --border-foreground="#00D4AA" \
            --padding="1 2" \
            --margin="1 0" \
            --align="center" \
            "$SCRIPT_NAME v$VERSION"

        echo ""

        # Status
        gum style --foreground="#666" "Status: $(check_status)"
        echo ""

        # Menu
        choice=$(gum choose \
            --cursor="▶ " \
            --height=6 \
            "Install/Update Fix" \
            "Check Status" \
            "Uninstall Fix" \
            "Exit")

        echo ""

        case "$choice" in
            "Install/Update Fix")
                if gum confirm "Install Nemo file picker fix?"; then
                    echo ""
                    install_fix
                    gum input --placeholder="Press Enter to continue..."
                fi
                ;;
            "Check Status")
                echo "System Status:"
                echo ""

                # Detailed status
                echo "Dependencies:"
                command -v nemo >/dev/null && echo "✅ Nemo installed" || echo "❌ Nemo missing"
                command -v xdg-desktop-portal >/dev/null && echo "✅ XDG Portal available" || echo "❌ XDG Portal missing"

                echo ""
                echo "Configuration:"
                [ -f ~/.config/xdg-desktop-portal/portals.conf ] && echo "✅ Portal configured" || echo "❌ Portal not configured"
                [ -f ~/.config/gtk-3.0/settings.ini ] && echo "✅ GTK settings exist" || echo "❌ GTK settings missing"
                [ -f ~/.local/bin/nautilus ] && echo "✅ Wrapper installed" || echo "❌ Wrapper missing"

                echo ""
                gum input --placeholder="Press Enter to continue..."
                ;;
            "Uninstall Fix")
                if gum confirm --default=false "Remove Nemo file picker fix?"; then
                    echo ""
                    uninstall_fix
                    gum input --placeholder="Press Enter to continue..."
                fi
                ;;
            "Exit")
                echo "👋 Goodbye!"
                exit 0
                ;;
        esac
    done
}

# Entry point
main() {
    check_dependencies
    main_menu
}

main "$@"
