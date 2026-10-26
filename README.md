# Fedora Sway + Quickshell (Mangobutter port)

This is a best-effort Sway port of the supplied Mangobutter Quickshell files and
network app, integrated into `sway2.14-setup`.

## Install

From the extracted repository directory:

```bash
chmod +x install.sh
./install.sh
```

The installer enables the `errornointernet/quickshell` COPR, installs Quickshell,
and places the shell, network app, and helper scripts under
`~/.local/share/sway-quickshell/`. Sway autostart launches Quickshell instead
of Waybar. Waybar remains installed as a fallback but is stopped by autostart.

To install only the configuration, use `./install.sh --only-config`. This mode
does not install Quickshell or dependencies, so install `quickshell` separately
first.

## Sway compatibility notes

- `Wm.qml` is replaced with a Sway IPC backend using `swaymsg` for workspaces,
  focused window titles, workspace occupancy, layout switching, and logout.
- Workspace buttons map to Sway workspaces 1–10.
- Mango-only layouts/effects (blur, compositor shadows, animations, master
  width/count) do not exist as equivalent Sway controls; those controls are
  inert or limited to Sway's native layout/gap/border commands.
- Mango-specific Keybinds and Rules editor features, Mango wallpaper theming,
  and a few auxiliary scripts still need a deeper port before their settings
  panels can be considered fully functional. Do not use Mango's original
  `mmsg`/`mango-ipc` scripts under Sway.
- The network app is included as a separate Quickshell config and uses
  NetworkManager (`nmcli`), `nm-connection-editor`, and Bluetooth tools.
  Bluetooth functions require BlueZ and a running `bluetooth` service.
- If the bar fails to launch, inspect Quickshell output with:
  `~/.local/share/sway-quickshell/scripts/bar log`

## Files

- `share/quickshell/` — main bar and shared QML modules
- `share/quickshell-network/` — standalone network app
- `share/scripts/` — scripts used by the bar and network app
- `config/scripts/autostart.sh` — Sway session startup
