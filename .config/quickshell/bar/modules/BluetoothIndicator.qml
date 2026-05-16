import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    height: 28
    implicitWidth: labelText.width + 8
    width: implicitWidth
    Layout.preferredWidth: implicitWidth

    required property var screen
    property string activePopup: ""
    property bool popupOpen: activePopup === "bluetooth"
    property string connectedName: ""
    property string feedback: ""
    property bool poweredOn: true
    property bool scanning: false

    signal togglePopup()

    Text {
        id: labelText
        anchors.centerIn: parent
        text: !root.poweredOn ? "[BT off]"
              : root.connectedName ? "[BT*]"
              : "[BT-]"
        color: root.popupOpen ? "#ffffff"
               : (root.connectedName ? "#c8ccd4" : "#4a4f5a")
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
        command: ["sh", "-c", "p=$(bluetoothctl show 2>/dev/null | awk -F': ' '/Powered:/ {print $2; exit}'); echo \"${p:-no}\"; bluetoothctl info 2>/dev/null | awk -F': ' '/Name:/ {print $2; exit}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n");
                root.poweredOn = (lines[0] || "").trim() === "yes";
                root.connectedName = (lines[1] || "").trim();
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
                    if (!line) continue;
                    var parts = line.split(/\s+/);
                    if (parts.length < 3) continue;
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
        id: powerProc
        onExited: root.refreshBluetooth()
    }

    Process {
        id: scanProc
        command: ["bluetoothctl", "--timeout", "8", "scan", "on"]
        onExited: root.refreshBluetooth()
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

    Timer {
        interval: 15000
        running: true
        repeat: true
        onTriggered: root.refreshBluetooth()
    }

    function refreshBluetooth() { infoRefreshProc.running = true; }

    function connectDevice(mac) {
        root.feedback = "connecting...";
        connectProc.command = ["bluetoothctl", "connect", mac];
        connectProc.running = true;
    }

    function togglePower() {
        powerProc.command = ["bluetoothctl", "power", root.poweredOn ? "off" : "on"];
        powerProc.running = true;
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
        implicitWidth: 300
        implicitHeight: 420
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
                anchors.margins: 14
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "─ BLUETOOTH"
                        color: "#4a4f5a"
                        font.family: "monospace"
                        font.pixelSize: 10
                        font.letterSpacing: 2
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "[" + (root.poweredOn ? "on" : "off") + "]"
                        color: powerArea.containsMouse ? "#ffffff" : "#c8ccd4"
                        font.family: "monospace"
                        font.pixelSize: 10
                        MouseArea {
                            id: powerArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.togglePower()
                        }
                    }
                    Item { width: 8 }
                    Text {
                        text: "[x]"
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
                    text: root.feedback || (root.connectedName ? "> " + root.connectedName : "  no device")
                    color: root.connectedName && !root.feedback ? "#c8ccd4" : "#4a4f5a"
                    font.family: "monospace"
                    font.pixelSize: 13
                    elide: Text.ElideRight
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: "#2a2e35" }

                Text {
                    text: "PAIRED"
                    color: "#4a4f5a"
                    font.family: "monospace"
                    font.pixelSize: 10
                    font.letterSpacing: 2
                }

                Repeater {
                    model: deviceModel
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 30
                        color: deviceArea.containsMouse ? "#1a1a1a" : "#0f0f0f"

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 16
                            text: (model.connected ? "> " : "  ") + model.name +
                                  (model.connected ? "  [conn]" : "")
                            color: model.connected ? "#c8ccd4" : "#c8ccd4"
                            opacity: model.connected ? 1.0 : 0.75
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

                Rectangle { Layout.fillWidth: true; height: 1; color: "#2a2e35" }

                Rectangle {
                    Layout.fillWidth: true
                    height: 30
                    color: scanArea.containsMouse && !root.scanning ? "#1a1a1a" : "#0f0f0f"
                    opacity: root.scanning ? 0.6 : 1
                    border.color: "#2a2e35"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: root.scanning ? "[ scanning... ]" : "[ scan ]"
                        color: "#c8ccd4"
                        font.family: "monospace"
                        font.pixelSize: 13
                    }

                    MouseArea {
                        id: scanArea
                        anchors.fill: parent
                        enabled: !root.scanning && root.poweredOn
                        hoverEnabled: true
                        onClicked: root.scanDevices()
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }
    }
}
