# Miniland

Miniland adds a familiar minimize-window workflow to Hyprland using a named special workspace.

## Install

Clone the repository and run:

    sh install.sh

Or run the installer directly:

    curl -fsSL https://raw.githubusercontent.com/Jackson4Rocks/miniland/main/install.sh | sh

The installer is interactive and lets you choose the keybinds. Type combinations naturally:

    SUPER + M
    SUPER + SHIFT + M
    CTRL + ALT + M

Defaults:

- Minimize: SUPER + M
- Picker: SUPER + SHIFT + M
- Shelf: SUPER + ALT + M

Run the installer again to change them.

## Miniland picker

Press the picker binding or run:

    miniland picker

The picker opens a searchable graphical menu containing every minimized window. Each entry includes the application/class, window title, PID, and original workspace.

Select a window and Miniland moves that exact window to the currently active Hyprland workspace and focuses it.

The menu is scrollable for large lists and uses the first available backend:

1. fuzzel
2. wofi
3. rofi / rofi-wayland

Install one of those separately when no picker backend is detected.

## Commands

    miniland minimize
    miniland picker
    miniland restore-last
    miniland restore N
    miniland restore-all
    miniland list
    miniland toggle-shelf

Minimized-window metadata is kept in:

    ~/.local/state/miniland/state.json

## Dependencies

Core:

- Hyprland / hyprctl
- jq

Picker:

- fuzzel, wofi, or rofi-wayland / rofi

Miniland uses Hyprland's named special workspaces for the hidden window shelf and targeted movetoworkspacesilent operations for restoration.

## License

MIT