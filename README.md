# Miniland

**Minimize windows on Hyprland without closing them.**

Ever wanted to temporarily hide a window without closing it or losing your work?

That's exactly what Miniland does.

Press a keyboard shortcut to move the currently focused window to a hidden shelf. The application keeps running, and you can bring it back whenever you need it.

Your music keeps playing, downloads continue, and your windows stay exactly where you left them.

## Quick Start

Already cloned the repository?

```sh
sh install.sh
```

Haven't downloaded Miniland yet? Run:

```sh
curl -fsSL https://raw.githubusercontent.com/Jackson4Rocks/miniland/main/install.sh | sh
```

The installer guides you through the entire setup:

1. **Choose your keybinds.** Customize every shortcut individually or keep the suggested defaults.
2. **Install Miniland.** The `miniland` command is installed to `~/.local/bin`.
3. **Configure Hyprland.** The installer adds the required keybinds to your configuration.
4. **Apply and verify.** Hyprland is reloaded, and the installer checks whether your shortcuts registered successfully.

That's it! No root permissions, background services, or daemons required.

## Keyboard Shortcuts

Miniland comes with suggested default shortcuts, but **you are not locked into them**.

| Default Shortcut | Action | Description |
| --- | --- | --- |
| `SUPER + M` | Minimize | Moves the focused window to the hidden shelf. |
| `SUPER + SHIFT + N` | Picker | Opens a searchable list of minimized windows. |
| `SUPER + ALT + M` | Toggle Shelf | Shows or hides the hidden shelf. |
| `SUPER + R` | Restore | Restores the most recently minimized window. |

### Customize Your Keybinds

Every Miniland shortcut is fully customizable.

During installation, you can choose your preferred key combination for each action. You can accept the suggested defaults, change just a few shortcuts, or customize all of them.

**Already installed Miniland?** You can change your shortcuts at any time by running the installer again:

```sh
sh install.sh
```

Choose the customization option and configure your preferred key combinations.

Miniland also checks your existing Hyprland configuration for keybind conflicts and warns you if a shortcut is already being used.

Your keyboard, your shortcuts.

## How to Use Miniland

### Minimize a Window

Focus the window you want to hide and press your configured minimize shortcut.

The window disappears from your current workspace and moves to Miniland's hidden shelf. The application stays open and continues running normally.

### Restore the Last Window

Press your configured restore shortcut to bring back the most recently minimized window.

It returns to the workspace where you originally minimized it, and Hyprland focuses it automatically.

### Open the Window Picker

Press your configured picker shortcut to open a searchable list of all your minimized windows.

Find the application you want and select it. Miniland restores that window to your currently active workspace.

### Show or Hide the Shelf

Press your configured shelf shortcut to show or hide the hidden workspace.

This lets you see all the windows currently stored in Miniland.

## Command Reference

You can also control Miniland directly from your terminal.

| Command | Description |
| --- | --- |
| `miniland minimize` | Minimize the currently focused window. |
| `miniland picker` | Open the searchable window picker. |
| `miniland restore-last` | Restore the most recently minimized window. |
| `miniland restore 2` | Restore the second window in the list. |
| `miniland restore-all` | Restore every minimized window. |
| `miniland list` | Display all currently minimized windows. |
| `miniland toggle-shelf` | Show or hide the hidden shelf. |

## Requirements

Before installing Miniland, make sure you have:

- **Hyprland:** Supports Lua configurations on version 0.55 and newer, as well as traditional `hyprland.conf` configurations on older versions.
- **jq:** Used to manage Miniland's saved window information.
- **A window picker:** Install at least one of `fuzzel`, `wofi`, or `rofi`. This is only required when using the searchable picker.

## How Does It Work?

Miniland uses a special Hyprland workspace called `special:miniland`.

When you minimize a window, Miniland moves it to this workspace instead of closing it. Since the window is still managed by Hyprland, the application continues running normally.

This means:

- Your applications stay open.
- Background tasks continue running.
- Window sizes and positions are preserved.
- You can restore windows whenever you need them.

Miniland also remembers which windows you have minimized. Its state is stored here:

```sh
~/.local/state/miniland/state.json
```

### Hyprland Configuration

Miniland supports two Hyprland configuration styles.

**Hyprland 0.55 and newer**

These versions use Lua configuration files. The installer creates `miniland.lua` alongside your other Hyprland configuration files and adds the following line to your `hyprland.lua`:

```lua
require("miniland")
```

**Older Hyprland versions**

The installer creates a `miniland.conf` file containing the required traditional `bind = ...` keybind definitions.

You do not need to configure these manually. The installer handles everything for you.

## Troubleshooting

### A keyboard shortcut does nothing

First, check whether Miniland's keybinds were registered:

```sh
hyprctl binds | grep -i miniland
```

You can also check for configuration errors:

```sh
hyprctl configerrors
```

The first command should display your Miniland keybinds. Ideally, the second command should not report any errors.

Still having trouble? Run the installer again:

```sh
sh install.sh
```

This can repair a configuration that was not set up correctly.

### Minimizing a window does nothing

Check your installed Hyprland version:

```sh
hyprctl version
```

If you are using Hyprland 0.55 or newer, make sure you are using the Lua configuration format and that this line exists in your `hyprland.lua`:

```lua
require("miniland")
```

### The window picker does not open

Miniland needs a supported picker application to display the searchable window list.

Install at least one of these:

- `fuzzel`
- `wofi`
- `rofi`

You can then try again:

```sh
miniland picker
```

Miniland will notify you if it cannot find a supported picker.

### I want to change my keyboard shortcuts

You can customize your keybinds whenever you want.

Simply run the installer again:

```sh
sh install.sh
```

Choose the customization option and configure the shortcuts you prefer.

You do not need to reinstall Hyprland or manually edit your keybinds.

## Uninstalling Miniland

Want to remove Miniland? You can do so manually using the following commands:

```sh
rm ~/.local/bin/miniland
rm ~/.config/hypr/miniland.lua
rm -rf ~/.local/state/miniland
```

If you are using an older Hyprland configuration, remove `miniland.conf` instead of `miniland.lua`.

Finally, open your `hyprland.lua` and remove:

```lua
require("miniland")
```

Reload Hyprland, and Miniland will be removed.

## License

Miniland is licensed under the [MIT License](LICENSE).
