# Miniland

Minimize windows on Hyprland without losing them.

Press a key and the focused window is parked on a hidden shelf. Press another
key and it comes back — still running, still where you left it.

## Quick start

    sh install.sh

or, if you don't have the repo yet:

    curl -fsSL https://raw.githubusercontent.com/Jackson4Rocks/miniland/main/install.sh | sh

The installer walks you through the whole thing:

1. asks which keys you want (all of them editable)
2. installs the `miniland` command to `~/.local/bin`
3. wires the keybinds into your Hyprland config
4. reloads Hyprland and checks that the binds really registered

No root, no daemons, nothing to clean up later.

## Keybinds

| Key | Action | What happens |
| --- | --- | --- |
| `SUPER + M` | Minimize | The focused window disappears onto the shelf |
| `SUPER + SHIFT + N` | Picker | Opens a searchable menu of everything you minimized |
| `SUPER + ALT + M` | Shelf | Shows or hides the shelf itself |
| `SUPER + R` | Restore | Brings back the window you minimized most recently |

Every key is editable. The installer asks, and you can re-run it whenever you
want to change them. It also warns you if a combination is already used by
another bind in your Hyprland config.

## Using it

- **Minimize** hides the focused window on a shelf that is out of the way. The
  app keeps running, so music and downloads are not interrupted.
- **Restore** brings the most recently minimized window back, on the workspace
  it came from, and focuses it.
- **Picker** shows every minimized window in a searchable list. Pick one and it
  opens on the workspace you are on right now.
- **Shelf** shows the hidden workspace itself, so you can see what is parked
  there.

## Commands

    miniland minimize       # hide the focused window
    miniland picker         # searchable menu of minimized windows
    miniland restore-last   # bring back the most recently minimized window
    miniland restore 2      # bring back the 2nd window in the list
    miniland restore-all    # bring back everything
    miniland list           # show what is minimized right now
    miniland toggle-shelf   # show or hide the shelf

## Requirements

- Hyprland (works on 0.55+ Lua configs and older `hyprland.conf` setups)
- `jq`
- A picker for the menu: `fuzzel`, `wofi` or `rofi` (only the picker needs it)

## How it works

Miniland parks windows on a Hyprland special workspace called
`special:miniland`. That is a real workspace, so windows keep their size,
position and running state — and Hyprland keeps drawing the shelf when you
toggle it into view.

Which windows are minimized is remembered in:

    ~/.local/state/miniland/state.json

On Hyprland 0.55 and newer the config is Lua: the installer writes
`miniland.lua` next to your other config files and adds `require("miniland")`
to your `hyprland.lua`. Older versions get a `miniland.conf` with plain
`bind = ...` lines instead.

## Troubleshooting

**A keybind does nothing**

    hyprctl binds | grep -i miniland
    hyprctl configerrors

The first command should list your Miniland binds, the second should be empty.
Re-running `sh install.sh` repairs a config that was never wired up.

**Nothing happens when I minimize**

Check `hyprctl version`. On 0.55+ your config has to be Lua, and Miniland has
to be required from it — look for `require("miniland")` in your
`hyprland.lua`.

**The picker does not open**

Install one of `fuzzel`, `wofi` or `rofi`. `miniland picker` tells you when it
cannot find any of them.

**I want different keys**

Re-run `sh install.sh` and choose *customize*.

## Uninstall

    rm ~/.local/bin/miniland
    rm ~/.config/hypr/miniland.lua      # or miniland.conf on older Hyprland
    rm -rf ~/.local/state/miniland

Then drop the `require("miniland")` line from your `hyprland.lua`.

## License

MIT
