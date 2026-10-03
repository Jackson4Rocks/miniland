# Miniland

Miniland is a tiny Hyprland utility that adds a familiar **minimize window** workflow using a named special workspace.
PS: If you have a better name, srsly let me know -_-
## Install

Run the installer from a cloned repository:

    sh install.sh

Or download and run it directly:

    curl -fsSL https://raw.githubusercontent.com/Jackson4Rocks/miniland/main/install.sh | sh

The installer guides you through your keybinds. You can type bindings naturally, for example:

    SUPER + M
    SUPER + SHIFT + M
    ALT + F9

It creates a small Hyprland config at ~/.config/hypr/miniland.conf and sources it from hyprland.conf.

## Commands

    miniland minimize
    miniland restore-last
    miniland restore N
    miniland restore-all
    miniland list
    miniland toggle-shelf
    miniland toggle

Minimized windows are moved to special:miniland, while Miniland records the original workspace so the window can be restored to where it came from.

## Dependencies

Miniland needs:

- Hyprland / hyprctl
- jq

## License

MIT
