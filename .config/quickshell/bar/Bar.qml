import Quickshell
import QtQuick
import QtQuick.Layouts
import "modules"

PanelWindow {
    id: root

    property bool drawerOpen: false
    property string activePopup: ""

    required property var screen

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 28

    color: "#0f0f0f"

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Workspaces {
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
        }

        Item {
            Layout.fillWidth: true

            ActiveWindow {
                anchors.centerIn: parent
                width: Math.min(parent.width - 24, 520)
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            spacing: 0

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

            BatteryIndicator {
                screen: root.screen
                activePopup: root.activePopup
                onTogglePopup: root.setActivePopup("battery")
            }

            Item {
                width: 12
            }

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

            Item {
                width: 8
            }

            Text {
                id: toggleBtn
                text: "SYS"
                font.family: "monospace"
                font.pixelSize: 13
                color: drawerOpen ? "#ffffff" : "#c8ccd4"

                MouseArea {
                    anchors.fill: parent
                    onClicked: toggleDrawer()
                }
            }

            Item {
                width: 8
            }
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
    signal setActivePopup(string name)
}
