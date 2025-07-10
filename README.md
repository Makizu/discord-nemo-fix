# Nemo Global File Picker Fix for Hyprland

Universal solution to make **all applications** use Nemo instead of Nautilus as file picker on Hyprland.

## Problem

Many applications (Discord, Vesktop, Firefox, Chrome, VS Code, etc.) ignore system file manager settings on Hyprland, always using Nautilus even when Nemo is preferred.

## Solution

This fix addresses the issue at multiple levels:

1. **XDG Desktop Portal Configuration** - Configures portal to use GTK backend for file chooser
2. **GTK File Manager Settings** - Sets Nemo as default file manager in GTK
3. **Wrapper Script** - Fallback wrapper that redirects nautilus calls to nemo
4. **Environment Setup** - Proper PATH and environment configuration

## Requirements

- **Hyprland** window manager
- **Nemo** file manager
- **GUM** for CLI interface
- **xdg-desktop-portal-gtk** (usually installed with Hyprland)

## Installation

### Install Dependencies

```bash
# Arch/Manjaro
sudo pacman -S nemo gum

# Other distros - install nemo and gum according to your package manager
```

### Run the Fix

```bash
chmod +x nemo-fix.sh
./nemo-fix.sh
```

## How It Works

### XDG Portal Configuration
Creates both portal configuration files for maximum compatibility:

`~/.config/xdg-desktop-portal/hyprland-portals.conf`:
```ini
[preferred]
default = hyprland;gtk
org.freedesktop.impl.portal.FileChooser = gtk
```

`~/.config/xdg-desktop-portal/portals.conf`:
```ini
[preferred]
default=gtk
org.freedesktop.impl.portal.FileChooser=gtk
```

### GTK Configuration
Updates `~/.config/gtk-3.0/settings.ini` to use GIO backend and sets Nemo as default.

### Wrapper Script
Creates `~/.local/bin/nautilus` that redirects calls to Nemo with fallback to system Nautilus.

### Environment Setup
- Adds `~/.local/bin` to PATH
- Creates systemd environment configuration
- Updates shell configurations

## Usage

The CLI provides four simple options:

1. **Install/Update Fix** - Apply the complete fix
2. **Check Status** - View current configuration status
3. **Uninstall Fix** - Remove all changes
4. **Exit** - Close the application

## Verification

After installation:

1. Restart any application completely
2. Test file upload/open/save dialogs - should open Nemo
3. Works with: Discord, Vesktop, Firefox, Chrome, VS Code, and all XDG Portal applications
4. Check status with the CLI tool

## Files Modified

- `~/.config/xdg-desktop-portal/hyprland-portals.conf` (Hyprland-specific)
- `~/.config/xdg-desktop-portal/portals.conf` (compatibility)
- `~/.config/gtk-3.0/settings.ini`
- `~/.local/bin/nautilus`
- `~/.config/environment.d/nemo-fix.conf`
- `~/.bashrc` and `~/.zshrc` (PATH only)

## Backup & Restore

The script automatically creates timestamped backups of all modified files before making changes:
- `hyprland-portals.conf.backup.TIMESTAMP`
- `portals.conf.backup.TIMESTAMP`
- `settings.ini.backup.TIMESTAMP`
- `nautilus.backup.TIMESTAMP`

During uninstallation, original files are restored from backups when available.

## Troubleshooting

### Fix not working
- Restart your session completely
- Ensure xdg-desktop-portal-gtk is installed
- Check that Nemo is properly installed

### Portal issues
- Verify Hyprland is using the correct portal backend
- Check `echo $XDG_CURRENT_DESKTOP` returns "Hyprland"

### Still opens Nautilus
- Ensure Discord/Vesktop is completely closed before testing
- Check wrapper script permissions: `ls -la ~/.local/bin/nautilus`

## Uninstall

The CLI uninstall option intelligently:
1. **Restores original files** from automatic backups when available
2. **Removes created files** only if no backups exist
3. **Preserves user data** and configurations

Manual removal (if needed):
- `~/.config/xdg-desktop-portal/hyprland-portals.conf`
- `~/.config/xdg-desktop-portal/portals.conf`
- `~/.local/bin/nautilus`
- `~/.config/environment.d/nemo-fix.conf`
- GTK settings modifications

## Technical Details

This solution works by:

1. **Portal Level**: Configuring XDG Desktop Portal to use GTK backend for file chooser operations
2. **GTK Level**: Setting Nemo as the default file manager in GTK settings
3. **Direct Call Level**: Wrapper script intercepts direct nautilus calls
4. **Environment Level**: Ensuring proper PATH priority and environment variables

The multi-layer approach ensures compatibility across different ways applications might invoke file choosers.

## Applications Supported

This fix works with **all applications** that use file pickers:

- ✅ **Web Browsers**: Firefox, Chrome, Chromium, Edge
- ✅ **Communication**: Discord, Vesktop, Slack, Teams
- ✅ **Development**: VS Code, Atom, Sublime Text
- ✅ **Media**: GIMP, Inkscape, Blender
- ✅ **Office**: LibreOffice, OnlyOffice
- ✅ **Electron Apps**: Any Electron-based application
- ✅ **GTK Apps**: All native GTK applications
- ✅ **XDG Portal Apps**: Modern applications using portals

## Version

**v3.0** - Universal Hyprland solution with multi-level XDG Portal integration

## License

MIT License - See original project for details.
