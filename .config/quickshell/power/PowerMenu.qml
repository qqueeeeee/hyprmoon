import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: root
    required property var screen

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    visible: false
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    property bool open: false
    property int selectedIndex: 0

    readonly property var actions: [
        { key: "L", label: "LOCK",     hint: "loginctl lock-session", command: ["loginctl", "lock-session"] },
        { key: "O", label: "LOGOUT",   hint: "hyprctl dispatch exit",  command: ["hyprctl", "dispatch", "exit"] },
        { key: "S", label: "SLEEP",    hint: "systemctl suspend",      command: ["systemctl", "suspend"] },
        { key: "R", label: "REBOOT",   hint: "systemctl reboot",       command: ["systemctl", "reboot"] },
        { key: "P", label: "POWEROFF", hint: "systemctl poweroff",     command: ["systemctl", "poweroff"] }
    ]

    onOpenChanged: {
        visible = open;
        if (open) {
            selectedIndex = 0;
            focusGrabber.forceActiveFocus();
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#0f0f0f"
        opacity: 0.92
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.open = false
    }

    Item {
        id: focusGrabber
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.open = false
        Keys.onUpPressed: root.selectedIndex = (root.selectedIndex - 1 + root.actions.length) % root.actions.length
        Keys.onDownPressed: root.selectedIndex = (root.selectedIndex + 1) % root.actions.length
        Keys.onLeftPressed: root.selectedIndex = (root.selectedIndex - 1 + root.actions.length) % root.actions.length
        Keys.onRightPressed: root.selectedIndex = (root.selectedIndex + 1) % root.actions.length
        Keys.onReturnPressed: root.runSelected()
        Keys.onEnterPressed: root.runSelected()
        Keys.onPressed: function(event) {
            var ch = event.text.toUpperCase();
            for (var i = 0; i < root.actions.length; i++) {
                if (root.actions[i].key === ch) {
                    root.selectedIndex = i;
                    root.runSelected();
                    event.accepted = true;
                    return;
                }
            }
            if (ch === "Q") {
                root.open = false;
                event.accepted = true;
            }
        }
    }

    function runSelected() {
        var act = root.actions[root.selectedIndex];
        if (!act) return;
        actionProc.command = act.command;
        actionProc.running = true;
        root.open = false;
    }

    Process {
        id: actionProc
    }

    // Centered TUI dialog
    Item {
        anchors.centerIn: parent
        width: 520
        height: dialogColumn.implicitHeight + 32

        MouseArea { anchors.fill: parent }

        Rectangle {
            anchors.fill: parent
            color: "#0f0f0f"
            border.color: "#2a2e35"
            border.width: 1

            ColumnLayout {
                id: dialogColumn
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 16
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "─ SESSION"
                        color: "#4a4f5a"
                        font.family: "monospace"
                        font.pixelSize: 10
                        font.letterSpacing: 2
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "[esc]"
                        color: "#4a4f5a"
                        font.family: "monospace"
                        font.pixelSize: 10
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "Choose an action. ↑/↓ to move, Enter to confirm, key to jump."
                    color: "#4a4f5a"
                    font.family: "monospace"
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: "#2a2e35" }

                Repeater {
                    model: root.actions

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 36
                        color: index === root.selectedIndex ? "#1a1a1a"
                              : (rowArea.containsMouse ? "#171717" : "#0f0f0f")
                        border.color: index === root.selectedIndex ? "#c8ccd4" : "transparent"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12

                            Text {
                                text: "[" + modelData.key + "]"
                                color: index === root.selectedIndex ? "#ffffff" : "#c8ccd4"
                                font.family: "monospace"
                                font.pixelSize: 13
                            }

                            Text {
                                text: modelData.label
                                color: index === root.selectedIndex ? "#ffffff" : "#c8ccd4"
                                font.family: "monospace"
                                font.pixelSize: 13
                                Layout.preferredWidth: 100
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: modelData.hint
                                color: "#4a4f5a"
                                font.family: "monospace"
                                font.pixelSize: 10
                            }
                        }

                        MouseArea {
                            id: rowArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: root.selectedIndex = index
                            onClicked: { root.selectedIndex = index; root.runSelected(); }
                        }
                    }
                }
            }
        }
    }
}
