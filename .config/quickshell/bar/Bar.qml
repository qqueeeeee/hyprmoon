import Quickshell
import QtQuick
import QtQuick.Layouts
import "modules"

PanelWindow {
    id: root

    property bool drawerOpen: false
    property bool notificationDrawerOpen: false
    property string activePopup: ""
    property var notificationStore: null

    required property var screen

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 28

    color: "#0f0f0f"

    component Divider: Text {
        text: "│"
        font.family: "monospace"
        font.pixelSize: 13
        color: "#2a2e35"
    }

    component BarButton: Item {
        property string label: ""
        property bool highlighted: false
        signal clicked()

        implicitWidth: txt.width + 10
        implicitHeight: 28

        Text {
            id: txt
            anchors.centerIn: parent
            text: "[" + parent.label + "]"
            font.family: "monospace"
            font.pixelSize: 13
            color: parent.highlighted || area.containsMouse ? "#ffffff" : "#c8ccd4"
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            onClicked: parent.clicked()
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ── Left: APP launcher + workspaces ───────────────────────────────
        Item { width: 6 }

        BarButton {
            label: "APP"
            onClicked: toggleLauncher()
        }

        Item { width: 6 }

        Divider {}

        Item { width: 6 }

        Workspaces {
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
        }

        Item { width: 6 }

        Divider {}

        // ── Center: active window title ───────────────────────────────────
        Item {
            Layout.fillWidth: true

            ActiveWindow {
                anchors.centerIn: parent
                width: Math.min(parent.width - 24, 560)
            }
        }

        // ── Right: status indicators + clock + SYS ────────────────────────
        RowLayout {
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            spacing: 4

            Divider {}

            Item { width: 2 }

            BluetoothIndicator {
                screen: root.screen
                activePopup: root.activePopup
                onTogglePopup: root.setActivePopup("bluetooth")
            }

            NetworkIndicator {
                screen: root.screen
                activePopup: root.activePopup
                onTogglePopup: root.setActivePopup("network")
            }

            VolumeIndicator {
                screen: root.screen
                activePopup: root.activePopup
                onTogglePopup: root.setActivePopup("volume")
            }

            MicIndicator {
                screen: root.screen
            }

            NotificationBell {
                screen: root.screen
                store: root.notificationStore
                drawerOpen: root.notificationDrawerOpen
                onToggleDrawer: root.toggleNotificationDrawer()
            }

            BatteryIndicator {
                screen: root.screen
                activePopup: root.activePopup
                onTogglePopup: root.setActivePopup("battery")
            }

            Item { width: 2 }

            Divider {}

            Item { width: 8 }

            Text {
                id: clockText
                font.family: "monospace"
                font.pixelSize: 13
                color: "#c8ccd4"
                property int tick: 0
                text: {
                    tick;
                    var now = new Date();
                    var hours = String(now.getHours()).padStart(2, '0');
                    var minutes = String(now.getMinutes()).padStart(2, '0');
                    hours + ":" + minutes;
                }
            }

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: clockText.tick = clockText.tick + 1
            }

            Item { width: 8 }

            Divider {}

            Item { width: 4 }

            BarButton {
                label: "SYS"
                highlighted: root.drawerOpen
                onClicked: toggleDrawer()
            }

            Item { width: 6 }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: "#2a2e35"
    }

    signal toggleDrawer()
    signal toggleNotificationDrawer()
    signal toggleLauncher()
    signal setActivePopup(string name)
}
