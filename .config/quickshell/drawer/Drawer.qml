import Quickshell
import QtQuick
import QtQuick.Layouts
import "."

PanelWindow {
    id: drawerWindow

    property bool drawerOpen: false
    property bool drawerVisible: drawerOpen

    required property var screen

    anchors {
        top: true
        right: true
        bottom: true
    }

    implicitWidth: 260

    visible: drawerVisible

    color: "#0f0f0f"

    Item {
        id: drawerWrapper
        x: drawerOpen ? 0 : 260
        width: 260
        height: parent.height

        Behavior on x {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 1
            color: "#2a2e35"
        }

        Flickable {
						height: drawerWrapper.height - 40
            anchors.fill: parent
            anchors.topMargin: 40
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.bottomMargin: 16
            clip: true

            ColumnLayout {
                id: layout
                width: 228
                spacing: 8

                Text {
                    text: "DASHBOARD"
                    color: "#4a4f5a"
                    font.family: "monospace"
                    font.pixelSize: 10
                    font.letterSpacing: 2
                }

                Rectangle {
                    width: 228
                    height: 1
                    color: "#2a2e35"
                }

                SystemModule {}

                Rectangle {
                    width: 228
                    height: 1
                    color: "#2a2e35"
                }

                MediaModule {}

                Rectangle {
                    width: 228
                    height: 1
                    color: "#2a2e35"
                }

                CalendarModule {}

                Rectangle {
                    width: 228
                    height: 1
                    color: "#2a2e35"
                }

                QuickActionsModule {}

                Item {
                    height: 16
                }
            }

            contentHeight: layout.implicitHeight
        }
    }

    onDrawerOpenChanged: {
        if (drawerOpen)
            drawerVisible = true;
        else
            hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: 210
        onTriggered: {
            if (!drawerOpen)
                drawerVisible = false;
        }
    }
}
