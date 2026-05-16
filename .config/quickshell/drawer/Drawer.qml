import Quickshell
import QtQuick
import QtQuick.Layouts
import "."

PanelWindow {
    id: drawerWindow

    property bool drawerOpen: false
    property bool drawerVisible: drawerOpen
    property var notificationStore: null

    required property var screen

    anchors {
        top: true
        right: true
        bottom: true
    }

    implicitWidth: 280

    visible: drawerVisible
    color: "#0f0f0f"
    exclusiveZone: 0  // overlay over windows, don't reserve space

    Item {
        id: drawerWrapper
        x: drawerOpen ? 0 : 280
        width: 280
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

        // Title row
        Item {
            id: titleRow
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 14
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            height: 18

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "─ DASHBOARD"
                color: "#4a4f5a"
                font.family: "monospace"
                font.pixelSize: 10
                font.letterSpacing: 2
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDateTime(new Date(), "ddd dd MMM")
                color: "#4a4f5a"
                font.family: "monospace"
                font.pixelSize: 10
                font.letterSpacing: 2
            }
        }

        Flickable {
            anchors.fill: parent
            anchors.topMargin: 40
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.bottomMargin: 14
            clip: true
            contentHeight: layout.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: layout
                width: 248
                spacing: 10

                Rectangle { width: 248; height: 1; color: "#2a2e35"; Layout.preferredWidth: 248 }

                SystemModule {}

                Rectangle { width: 248; height: 1; color: "#2a2e35"; Layout.preferredWidth: 248 }

                BrightnessModule {}

                Rectangle { width: 248; height: 1; color: "#2a2e35"; Layout.preferredWidth: 248 }

                MediaModule {}

                Rectangle { width: 248; height: 1; color: "#2a2e35"; Layout.preferredWidth: 248 }

                CalendarModule {}

                Rectangle { width: 248; height: 1; color: "#2a2e35"; Layout.preferredWidth: 248 }

                QuickActionsModule {}

                Item { height: 14 }
            }
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
        onTriggered: if (!drawerOpen) drawerVisible = false
    }
}
