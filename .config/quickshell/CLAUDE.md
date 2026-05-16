# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A personal Quickshell (QML) config providing a top bar, right-side system drawer, right-side notification drawer, fullscreen app launcher, fullscreen wallpaper picker, fullscreen power menu, bottom-edge OSD, and a DBus notification daemon with toasts. All for Hyprland. No build system — Quickshell loads `shell.qml` directly.

## Running and reloading

- `./launch.sh` — starts `quickshell` if not already running (used by Hyprland autostart).
- `pkill -x quickshell && quickshell &` — restart after editing QML. Quickshell does not hot-reload reliably for structural changes.
- IPC from a terminal (also used by Hyprland keybinds):
  - `qs ipc call shell toggleDrawer` / `closePopups`
  - `qs ipc call wallpaper toggle`
  - `qs ipc call launcher toggle`
  - `qs ipc call power toggle`
  - `qs ipc call osd showVolume` / `showBrightness` / `showMic`
  - `qs ipc call notifications toggleDrawer` / `toggleDnd` / `clear`

There is no test suite, linter, or build step.

## Architecture

**`shell.qml` is the single root.** It owns `drawerOpen`, `notificationDrawerOpen`, `activePopup`, the singleton `NotificationDaemon`, all `IpcHandler` blocks, and the OSD reader processes (`volumeReadProc`, `brightnessReadProc`, `micReadProc`). A `QtObject { signal broadcast(...) }` named `osdBroadcast` is the fan-out channel: shell processes read the system, emit `osdBroadcast.broadcast(...)`, and every per-screen OSD's `Connections { target: osdBroadcast }` calls `osdInstance.show(...)`. Always add new IPC entry points here, not inside subcomponents.

**Per-screen vs single-instance overlays.** `Bar`, `Drawer`, `NotificationDrawer`, `Osd`, and `NotificationToasts` are spawned via `Variants { model: Quickshell.screens }` — one per monitor. `WallpaperPicker`, `AppLauncher`, and `PowerMenu` are single-instance fullscreen overlays anchored to `Quickshell.screens[0]`.

**Bar popup coordination.** Indicators `bar/modules/{Battery,Bluetooth,Network,Volume}Indicator.qml` each own their own `PanelWindow` popup anchored under the bar. Only one popup may be visible at a time, enforced by the `activePopup` string on `shell.qml`. Click → emits `togglePopup()` → `Bar.setActivePopup("name")` → root toggles the string → `popupOpen` is derived as `activePopup === "myname"`. Add new bar popups by following this pattern; do not add boolean flags per indicator. `NotificationBell` does **not** use this system — it's just a count display, clicking it toggles the right-side notification drawer via the `toggleNotificationDrawer` signal.

**Drawer animation.** Both `Drawer.qml` and `NotificationDrawer.qml` keep `drawerVisible` true for 210ms after `drawerOpen` flips false so the slide-out can play before the `PanelWindow` is hidden. Don't bind `visible` directly to `drawerOpen`.

**Exclusive zone.** Every `PanelWindow` that should overlay rather than reshape the workspace MUST set `exclusiveZone: 0`. The default is auto-compute (Hyprland resizes other windows to make room), which feels broken for transient surfaces. Files that set `exclusiveZone: 0`: `drawer/Drawer.qml`, `notifications/NotificationDrawer.qml`, `notifications/NotificationToasts.qml`, `osd/Osd.qml`. The bar **deliberately** leaves it auto so windows respect the 28px top reservation.

**Fullscreen overlays (launcher, wallpaper picker, power menu).** Use:
```qml
WlrLayershell.layer: WlrLayer.Overlay
WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
```
Exclusive keyboard focus lets a `TextInput` capture typing and `Keys.onPressed` handle Esc/arrows without Hyprland eating the keys.

**External data via `Process` + `StdioCollector`.** Standard pattern for sensors: a shell pipeline in `Process.command`, a `StdioCollector` parsing `text` in `onStreamFinished`, and a `Timer` flipping `running = true` on an interval to repoll.

**Streaming external data via `Process` + `SplitParser`.** Used for event streams like `pactl subscribe` — see `VolumeIndicator.qml` / `MicIndicator.qml`, which subscribe so the bar pill stays in sync with external changes (pavucontrol, headphone unplug, etc.).

**`pactl subscribe` event filter gotcha.** `pactl subscribe` emits `Event 'change' on sink #N` for actual sink/volume changes **and** `Event 'new' on sink-input #N` whenever an app starts a new audio stream (e.g. opening a video). Matching the substring `on sink` catches both, which made the OSD pop every time the user played a video. Always filter with `on sink #` (note the space + `#`) — same rule applies to `on source #` vs `on source-output #`. There is **no** shell-level pactl subscribe → OSD broadcast; the OSD only shows when an IPC `osd showX` is invoked (which the user's volume/brightness keybinds do explicitly), so audio stream start/stop will never trigger it.

**Wheel input.** `MouseArea` does NOT receive wheel events in Qt 6. Use `WheelHandler` for scroll-to-adjust UX (see `VolumeIndicator.qml` and `Workspaces.qml`).

**Notifications.** `notifications/NotificationDaemon.qml` owns a `NotificationServer` from `Quickshell.Services.Notifications` plus two `ListModel`s — `history` (capped at 50) and `toasts` (capped at 4 visible). `NotificationDaemon` is a single instance under the root; `Bar`, `NotificationToasts`, and `NotificationDrawer` all reference it through a `notificationStore` / `daemon` property passed down from the `Variants` delegates. The bar bell shows when `unreadCount > 0` or DND is on; clicking it (or `SUPER+SHIFT+O`) opens the right-side notification drawer at `notifications/NotificationDrawer.qml`, which marks everything read on open. Clear all via the drawer's `[clear]` button or the `notifications.clear` IPC.

**OSD.** `osd/Osd.qml` is a bottom-center `PanelWindow` per screen. It does not own its data — it exposes `show(mode, value, muted)` and an auto-hide `Timer`. The shell broadcasts updates from `osdBroadcast` to every screen's OSD. New OSD types: add a `mode` string handler in `modeLabel()` / `modeSymbol()`.

**Launching external programs.** `Quickshell.execDetached(["sh", "-c", cmd])` for fire-and-forget. Use `Process { command: [...]; onExited: ... }` when you need to know the exit code.

**Wallpaper backend.** `wallpaper/set-wallpaper.sh` rewrites `~/.config/hypr/hyprpaper.conf` and restarts `hyprpaper`. The hardcoded output `eDP-1` is laptop-specific — change it if porting.

## Design language — Pure TUI

**No Nerd Font private-use-area glyphs.** Use only ASCII + Unicode box-drawing + Unicode block characters so the bar would survive copy/paste into a real terminal.

| Token | Use |
|-------|-----|
| `#0f0f0f` | Background (bar, drawer, popups, overlays) |
| `#1a1a1a` | Hover / selected-row background |
| `#2a2e35` | Borders, dividers, separator `│`, block-bar track, unfocused popup edges |
| `#c8ccd4` | Primary text |
| `#4a4f5a` | Dim text / section labels (uppercase + letterSpacing 2) |
| `#ffffff` | Active / hover / selected text |
| `#ff5555` | Error, low battery (<20%), muted mic, critical-urgency toast border |

Font: `font.family: "monospace"` everywhere. Sizes: `13` for body, `12` for bar items, `10` for section labels with `font.letterSpacing: 2`. **Never** introduce a different font family — the whole aesthetic depends on monospace tiling.

**Glyph conventions** (these are how the design speaks):
- `[ ... ]` brackets a clickable button or a stateful pill (`[APP]`, `[scan]`, `[BT*]`, `[BAT▆▆▆▆▁ 84]`).
- `│` (U+2502) is the bar's section separator — `Bar.qml` exposes a `Divider` inline component.
- `─` (U+2500) prefixes section headers in popups: `─ NETWORK`, `─ SYSTEM`. The dash visually merges with the popup border.
- `▆` (filled) + `▁` (empty) form 5-segment battery bars, 20-segment popup bars, and Wi-Fi signal blocks. Use `fillBar(percent, segments)` (defined locally in modules that need it).
- ` ▁▂▃▄▅▆▇█` are the 9 sparkline levels (see `SystemModule.sparkline()` and `NetworkIndicator.blockSpark()`).
- `> name` (selection caret) and `[conn]` (state tag) for list items (devices, wifi networks, paired devices).
- `v` / `^` for down/up traffic, `▲` charging / `▼` discharging, `[x]` close, `[<]` / `[>]` calendar nav.
- `~ title` prefixes the active-window title to feel shell-like.

When adding new UI: reach for a bracket pill, a `─` header, and `▆▁` fill bars before introducing any new visual primitive. Popup outer borders are 1px `#2a2e35` Rectangles on a `#0f0f0f` fill — see `BatteryIndicator.qml` for the canonical popup layout.

## File layout

- `shell.qml` — root, all `IpcHandler`s, OSD broadcast bus, top-level Variants
- `bar/Bar.qml` — 28px top panel; defines `Divider` + `BarButton` inline components
- `bar/Workspaces.qml` — Hyprland workspace pills (bracketed when occupied, white when active)
- `bar/modules/` — `ActiveWindow`, `BatteryIndicator`, `BluetoothIndicator`, `NetworkIndicator`, `VolumeIndicator`, `MicIndicator` (hidden unless muted), `NotificationBell` (hidden unless unread > 0 or DND on; clicking it opens `NotificationDrawer`, not a local popup)
- `drawer/Drawer.qml` + `drawer/*Module.qml` — right slide-in dashboard. `SystemModule` has CPU sparkline + thermal, `BrightnessModule` reads `/sys/class/backlight/*`, `MediaModule` has a position/length progress bar, `CalendarModule` supports `<` / `>` month nav (click month name to jump to today), `QuickActionsModule` is a 2-column grid with vim-style `[key] label` cells.
- `launcher/AppLauncher.qml` — fullscreen app launcher
- `wallpaper/WallpaperPicker.qml` + `set-wallpaper.sh` — fullscreen wallpaper grid
- `power/PowerMenu.qml` — fullscreen session dialog (lock/logout/sleep/reboot/poweroff). Keyboard: arrows / `L O S R P` jump keys / Enter / Esc.
- `osd/Osd.qml` — bottom-center popup; shows for ~1.4s. Modes: `volume`, `brightness`, `mic`.
- `notifications/NotificationDaemon.qml` — DBus notification server + history/toast models + DND. Cap: 50 history, 4 visible toasts.
- `notifications/NotificationToasts.qml` — per-screen stack of toast cards (slide in from right, auto-dismiss 6s normal / 12s critical).
- `notifications/NotificationDrawer.qml` — right-side slide-in drawer (380px wide) showing the full history. Header has `[count] [dnd:on/off] [clear]` controls; each entry is a card with app name, time, summary, body, and `[x]` dismiss. Opening it marks all entries read.

## Hyprland keybinds

The user's Hyprland config is in `~/.config/hypr/` and uses a Lua wrapper (`hl.bind(...)`) — not the standard `bind = ...` syntax. Currently live binds (`keybinds.lua`):

```lua
hl.bind(mainMod .. " + O",         hl.dsp.exec_cmd("quickshell ipc call shell toggleDrawer"))
hl.bind(mainMod .. " + SHIFT + O", hl.dsp.exec_cmd("quickshell ipc call notifications toggleDrawer"))
hl.bind(mainMod .. " + space",     hl.dsp.exec_cmd("quickshell ipc call launcher toggle"))
hl.bind(mainMod .. " + W",         hl.dsp.exec_cmd("quickshell ipc call wallpaper toggle"))
hl.bind(mainMod .. " + escape",    hl.dsp.exec_cmd("quickshell ipc call power toggle"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("quickshell ipc call notifications toggleDnd"))
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("quickshell ipc call notifications clear"))

hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+ && quickshell ipc call osd showVolume"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && quickshell ipc call osd showVolume"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && quickshell ipc call osd showVolume"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle && quickshell ipc call osd showMic"),      { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+ && quickshell ipc call osd showBrightness"),              { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%- && quickshell ipc call osd showBrightness"),              { locked = true, repeating = true })
```

The `quickshell ipc call osd showX` tail on each volume/brightness bind is what makes the OSD pop — there is no auto-trigger from `pactl subscribe` at the shell level (see the gotcha in *Architecture*). When wiring a new media-key style action, follow the same `mutate-state && quickshell ipc call ...` pattern.

After editing `keybinds.lua`, reload with `hyprctl reload`. If running from a fresh shell, you may need `HYPRLAND_INSTANCE_SIGNATURE=<sig> hyprctl reload` because the env var sometimes inherits stale from a previous instance — the live signature is whichever dir under `/run/user/1000/hypr/` contains `hyprland.lock` plus a `.socket.sock`.
