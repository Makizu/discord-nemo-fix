# Discord/Vesktop Nemo File Picker Fix

Makes Discord and Vesktop use Nemo instead of Nautilus as file picker on Linux.

## Problem

Discord and Vesktop ignore system file manager settings and always use Nautilus, even when Nemo is set as default.

## Solution

Creates a wrapper script that intercepts `nautilus` calls and redirects them to `nemo`.

## Requirements

- Nemo file manager
- Discord and/or Vesktop

## Installation

```bash
chmod +x fix-discord-nemo.sh
./fix-discord-nemo.sh
```

Preview changes first (optional):
```bash
./fix-discord-nemo.sh --dry-run
```

## Usage

After installation:
1. Close Discord/Vesktop completely
2. Launch "Discord (Nemo)" or "Vesktop (Nemo)" from your app launcher
3. Or restart your session

## Verification

```bash
which nautilus  # Should show: ~/.local/bin/nautilus
nautilus --version  # Should show: nemo version
```

## Uninstall

```bash
./fix-discord-nemo.sh --uninstall
```

## What it does

- Creates `~/.local/bin/nautilus` wrapper script
- Adds `~/.local/bin` to PATH
- Creates Discord and/or Vesktop launchers with correct PATH
- Makes backups of modified files

## Troubleshooting

- Make sure Discord/Vesktop is completely closed before testing
- Use the "Discord (Nemo)" or "Vesktop (Nemo)" launcher specifically
- Restart your session if needed
