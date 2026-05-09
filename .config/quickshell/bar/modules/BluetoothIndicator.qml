import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    height: 28
    implicitWidth: labelText.width + 12
    width: implicitWidth
    Layout.preferredWidth: implicitWidth

    required property var screen
    property string activePopup: ""
    property bool popupOpen: activePopup === "bluetooth"
    property string connectedName: ""
    property string feedback: ""
    property bool scanning: false

    signal togglePopup()

    Text {
        id: labelText
        anchors.centerIn: parent
        text: root.connectedName ? "BT*" : "BT-"
        color: root.popupOpen ? "#ffffff" : "#c8ccd4"
        font.family: "monospace"
        font.pixelSize: 12
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.togglePopup()
    }

    ListModel {
        id: deviceModel
    }

    Process {
        id: infoRefreshProc
        command: ["sh", "-c", "bluetoothctl info 2>/dev/null | awk -F': ' '/Name:/ {print $2; exit}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.connectedName = text.trim();
                devicesRefreshProc.running = true;
            }
        }
    }

    Process {
        id: devicesRefreshProc
        command: ["sh", "-c", "bluetoothctl devices 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                deviceModel.clear();
                var lines = text.trim().split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (!line)
                        continue;
                    var parts = line.split(/\s+/);
                    if (parts.length < 3)
                        continue;
                    var mac = parts[1];
                    var name = parts.slice(2).join(" ");
                    deviceModel.append({ mac: mac, name: name, connected: name === root.connectedName });
                }
            }
        }
    }

    Process {
        id: connectProc
        onExited: {
            root.feedback = "";
            root.refreshBluetooth();
        }
    }

    Process {
        id: scanProc
        command: ["bluetoothctl", "--timeout", "8", "scan", "on"]
        onExited: {
            root.refreshBluetooth();
        }
    }

    Timer {
        id: scanTimer
        interval: 10000
        onTriggered: {
            root.scanning = false;
            root.feedback = "";
            root.refreshBluetooth();
        }
    }

    function refreshBluetooth() {
        infoRefreshProc.running = true;
    }

    function connectDevice(mac) {
        root.feedback = "connecting...";
        connectProc.command = ["bluetoothctl", "connect", mac];
        connectProc.running = true;
    }

    function scanDevices() {
        root.scanning = true;
        root.feedback = "scanning...";
        scanProc.running = true;
        scanTimer.restart();
    }

    Component.onCompleted: refreshBluetooth()

    PanelWindow {
        id: popup
        screen: root.screen
        visible: root.popupOpen
        implicitWidth: 280
        implicitHeight: 372
        color: "#0f0f0f"
        anchors.top: true
        anchors.right: true
        margins.top: 28

        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: root.togglePopup()
        }

        Rectangle {
            anchors.fill: parent
            color: "#0f0f0f"
            border.color: "#2a2e35"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "BLUETOOTH"
                        color: "#4a4f5a"
                        font.family: "monospace"
                        font.pixelSize: 10
                        font.letterSpacing: 2
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "✕"
                        color: "#4a4f5a"
                        font.family: "monospace"
                        font.pixelSize: 10

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.togglePopup()
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.feedback || (root.connectedName ? root.connectedName : "no device")
                    color: root.connectedName && !root.feedback ? "#c8ccd4" : "#4a4f5a"
                    font.family: "monospace"
                    font.pixelSize: 13
                    elide: Text.ElideRight
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#2a2e35"
                }

                Text {
                    text: "PAIRED DEVICES"
                    color: "#4a4f5a"
                    font.family: "monospace"
                    font.pixelSize: 10
                    font.letterSpacing: 2
                }

                Repeater {
                    model: deviceModel

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 36
                        color: deviceArea.containsMouse ? "#1a1a1a" : "#0f0f0f"

                        Rectangle {
                            width: 3
                            height: parent.height
                            color: model.connected ? "#c8ccd4" : "transparent"
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 20
                            text: model.name
                            color: "#c8ccd4"
                            font.family: "monospace"
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            id: deviceArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.connectDevice(model.mac)
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    color: scanArea.containsMouse && !root.scanning ? "#1a1a1a" : "#0f0f0f"
                    opacity: root.scanning ? 0.7 : 1
                    border.color: "#2a2e35"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: root.scanning ? "scanning..." : "SCAN"
                        color: "#c8ccd4"
                        font.family: "monospace"
                        font.pixelSize: 13
                    }

                    MouseArea {
                        id: scanArea
                        anchors.fill: parent
                        enabled: !root.scanning
                        hoverEnabled: true
                        onClicked: root.scanDevices()
                    }
                }

                Item {
                    Layout.fillHeight: true
                }
            }
        }
    }
}
