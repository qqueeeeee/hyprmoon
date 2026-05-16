import Quickshell
import Quickshell.Io
import QtQuick
import "bar"
import "drawer"
import "wallpaper"
import "launcher"
import "power"
import "osd"
import "notifications"

ShellRoot {
    id: root

    property bool drawerOpen: false
    property bool notificationDrawerOpen: false
    property string activePopup: ""

    signal toggleDrawer()

    IpcHandler {
        target: "shell"

        function toggleDrawer(): void {
            root.drawerOpen = !root.drawerOpen;
        }

        function setDrawerOpen(open: bool): void {
            root.drawerOpen = open;
        }

        function getDrawerOpen(): bool {
            return root.drawerOpen;
        }

        function closePopups(): void {
            root.activePopup = "";
        }
    }

    IpcHandler {
        target: "wallpaper"
        function toggle(): void { wallpaperPicker.open = !wallpaperPicker.open; }
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { appLauncher.open = !appLauncher.open; }
    }

    IpcHandler {
        target: "power"
        function toggle(): void { powerMenu.open = !powerMenu.open; }
        function open(): void { powerMenu.open = true; }
        function close(): void { powerMenu.open = false; }
    }

    IpcHandler {
        target: "osd"

        function showVolume(): void {
            volumeReadProc.running = true;
        }

        function showBrightness(): void {
            brightnessReadProc.running = true;
        }

        function showMic(): void {
            micReadProc.running = true;
        }
    }

    IpcHandler {
        target: "notifications"

        function toggleDnd(): void {
            notificationDaemon.dnd = !notificationDaemon.dnd;
        }

        function clear(): void {
            notificationDaemon.clearAll();
        }

        function toggleDrawer(): void {
            root.notificationDrawerOpen = !root.notificationDrawerOpen;
        }

        function setDrawerOpen(open: bool): void {
            root.notificationDrawerOpen = open;
        }
    }

    NotificationDaemon {
        id: notificationDaemon
    }

    WallpaperPicker {
        id: wallpaperPicker
        screen: Quickshell.screens[0]
    }

    AppLauncher {
        id: appLauncher
        screen: Quickshell.screens[0]
    }

    PowerMenu {
        id: powerMenu
        screen: Quickshell.screens[0]
    }

    // OSD readers — fetch current state on IPC, then push to the OSD windows.
    Process {
        id: volumeReadProc
        command: ["sh", "-c", "pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -oP '\\d+(?=%)' | head -1; pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split("\n");
                var v = parseInt(parts[0] || "0") || 0;
                var m = (parts[1] || "").indexOf("yes") !== -1;
                osdBroadcast.broadcast("volume", v, m);
            }
        }
    }

    Process {
        id: brightnessReadProc
        command: ["sh", "-c", "dir=$(ls -d /sys/class/backlight/*/ 2>/dev/null | head -1); if [ -n \"$dir\" ]; then cur=$(cat \"${dir}brightness\"); max=$(cat \"${dir}max_brightness\"); [ \"$max\" -gt 0 ] && echo $((cur * 100 / max)) || echo 0; else echo missing; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                var line = text.trim();
                if (line === "missing") return;
                osdBroadcast.broadcast("brightness", parseInt(line) || 0, false);
            }
        }
    }

    Process {
        id: micReadProc
        command: ["sh", "-c", "pactl get-source-volume @DEFAULT_SOURCE@ 2>/dev/null | grep -oP '\\d+(?=%)' | head -1; pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split("\n");
                var v = parseInt(parts[0] || "0") || 0;
                var m = (parts[1] || "").indexOf("yes") !== -1;
                osdBroadcast.broadcast("mic", v, m);
            }
        }
    }

    QtObject {
        id: osdBroadcast
        signal broadcast(string mode, int value, bool muted)
    }

    // No pactl subscribe at the shell level: every keybind that changes
    // volume/mic already calls `quickshell ipc call osd showX`, and auto-broadcast
    // was firing on sink-input (per-app stream) events too, popping the OSD on
    // every video play. Bar indicators do their own re-reads (see VolumeIndicator).

    Variants {
        model: Quickshell.screens

        delegate: Component {
            Bar {
                required property var modelData
                screen: modelData
                drawerOpen: root.drawerOpen
                notificationDrawerOpen: root.notificationDrawerOpen
                activePopup: root.activePopup
                notificationStore: notificationDaemon
                onSetActivePopup: function(name) {
                    root.activePopup = root.activePopup === name ? "" : name
                }
                onToggleDrawer: root.drawerOpen = !root.drawerOpen
                onToggleNotificationDrawer: root.notificationDrawerOpen = !root.notificationDrawerOpen
                onToggleLauncher: appLauncher.open = !appLauncher.open
            }
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            Drawer {
                required property var modelData
                screen: modelData
                drawerOpen: root.drawerOpen
                notificationStore: notificationDaemon
            }
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            Osd {
                id: osdInstance
                required property var modelData
                screen: modelData

                Connections {
                    target: osdBroadcast
                    function onBroadcast(mode, value, muted) {
                        osdInstance.show(mode, value, muted);
                    }
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            NotificationToasts {
                required property var modelData
                screen: modelData
                daemon: notificationDaemon
            }
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            NotificationDrawer {
                required property var modelData
                screen: modelData
                drawerOpen: root.notificationDrawerOpen
                daemon: notificationDaemon
            }
        }
    }
}
