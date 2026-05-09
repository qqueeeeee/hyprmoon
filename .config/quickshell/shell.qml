import Quickshell
import Quickshell.Io
import QtQuick
import "bar"
import "drawer"
import "wallpaper"

ShellRoot {
    id: root

    property bool drawerOpen: false
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
    }

    IpcHandler {
        target: "wallpaper"

        function toggle(): void {
            wallpaperPicker.open = !wallpaperPicker.open;
        }
    }

    WallpaperPicker {
        id: wallpaperPicker
        screen: Quickshell.screens[0]
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            Bar {
                required property var modelData
                screen: modelData
                drawerOpen: root.drawerOpen
                activePopup: root.activePopup
                onSetActivePopup: function(name) {
                    root.activePopup = root.activePopup === name ? "" : name
                }
                onToggleDrawer: root.drawerOpen = !root.drawerOpen
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
            }
        }
    }
}
