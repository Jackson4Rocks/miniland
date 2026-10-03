# Miniland

Miniland adds a familiar minimize-window workflow to Hyprland using a named special workspace.

## Install

Clone the repository and run:

    sh install.sh

Or run the installer directly:

    curl -fsSL https://raw.githubusercontent.com/Jackson4Rocks/miniland/main/install.sh | sh

The installer detects the Hyprland configuration style it is running with:

- Legacy Hyprland 0.54 and earlier style: `hyprland.conf` / `bind = ...`
- Hyprland 0.55+ Lua style: `hyprland.lua` / `hl.bind(...)`

### Recommended defaults

- Minimize: `SUPER + M`
- Picker: `SUPER + SHIFT + N`
- Shelf: `SUPER + ALT + M`

During setup you can keep your current bindings, use the recommended defaults, or customize them.

Bindings are written using the syntax required by the detected Hyprland config. In legacy config, combined modifiers are emitted as `SUPER_SHIFT`, not `SUPER SHIFT`.

## Miniland picker

Press `SUPER + SHIFT + N` by default, or run:

    miniland picker

The picker opens a searchable graphical menu containing every minimized window. Entries include the application/class, title, PID, and original workspace.

Selecting a window restores that exact window onto the currently active Hyprland workspace and focuses it.

The picker is scrollable for large lists and automatically uses the first available backend:

1. fuzzel
2. wofi
3. rofi / rofi-wayland

Fuzzel is used in dmenu mode with a bounded number of visible rows, while wofi/rofi provide their own scrollable menu views.

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

- Hyprland / `hyprctl`
- `jq`

Picker:

- `fuzzel`, `wofi`, or `rofi-wayland` / `rofi`

Miniland uses Hyprland's named special workspaces for the hidden window shelf and targeted window moves for restoration.

## License

MIT