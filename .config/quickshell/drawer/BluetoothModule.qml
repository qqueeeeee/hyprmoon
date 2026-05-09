import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    spacing: 8

    Text {
        text: "BLUETOOTH"
        font.family: "monospace"
        font.pixelSize: 10
        color: "#4a4f5a"
        font.letterSpacing: 2
    }

    Text {
        id: bluetoothStatus
        text: "--"
        font.family: "monospace"
        font.pixelSize: 13
        color: "#c8ccd4"
    }

    ColumnLayout {
        id: deviceList
        spacing: 2
    }

    Process {
        id: connectProc
        onExited: refreshBluetooth()
    }

    Process {
        id: scanProc
        onExited: refreshBluetooth()
    }

    Process {
        id: infoRefreshProc
        command: ["sh", "-c", "bluetoothctl info 2>/dev/null | grep Name | cut -d: -f2 | xargs"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var name = text.trim();
                bluetoothStatus.text = name || "no device";
                bluetoothStatus.color = name ? "#c8ccd4" : "#4a4f5a";
                devicesRefreshProc.running = true;
            }
        }
    }

    Process {
        id: devicesRefreshProc
        command: ["sh", "-c", "bluetoothctl devices | grep Device"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                deviceModel.clear();
                var lines = text.trim().split("\n");
                var connectedName = bluetoothStatus.text !== "no device" ? bluetoothStatus.text : "";
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line) {
                        var parts = line.split(/\s+/);
                        if (parts.length >= 3) {
                            var mac = parts[1];
                            var name = parts.slice(2).join(" ");
                            var isConnected = name === connectedName;
                            deviceModel.append({ mac: mac, name: name, connected: isConnected });
                        }
                    }
                }
            }
        }
    }

    ListModel {
        id: deviceModel
    }

    function refreshBluetooth() {
        infoRefreshProc.running = true;
    }

    function connectDevice(mac, name) {
        bluetoothStatus.text = "connecting...";
        bluetoothStatus.color = "#4a4f5a";
        connectProc.command = ["bluetoothctl", "connect", mac];
        connectProc.running = true;
    }

    function startScan() {
        scanButtonText.text = "scanning...";
        scanButton.enabled = false;
        scanProc.command = ["bluetoothctl", "--timeout", "8", "scan", "on"];
        scanProc.running = true;

        scanTimer.start();
    }

    Timer {
        id: scanTimer
        interval: 10000
        onTriggered: {
            scanButtonText.text = "SCAN";
            scanButton.enabled = true;
            refreshBluetooth();
        }
    }

    Component.onCompleted: refreshBluetooth()

    Component {
        id: deviceDelegate
        Rectangle {
            id: deviceRow
            width: 228
            height: 36
            color: deviceArea.containsMouse ? "#1a1a1a" : "#0f0f0f"

            Rectangle {
                width: 3
                height: parent.height
                color: model.connected ? "#c8ccd4" : "transparent"
            }

            Text {
                text: model.name
                font.family: "monospace"
                font.pixelSize: 12
                color: model.connected ? "#c8ccd4" : "#c8ccd4"
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
            }

            MouseArea {
                id: deviceArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: connectDevice(model.mac, model.name)
            }
        }
    }

    Repeater {
        model: deviceModel
        delegate: deviceDelegate
    }

    Rectangle {
        id: scanButton
        width: 228
        height: 36
        color: "#0f0f0f"
        border.color: "#2a2e35"
        border.width: 1

        Text {
            id: scanButtonText
            anchors.centerIn: parent
            text: "SCAN"
            font.family: "monospace"
            font.pixelSize: 12
            color: "#c8ccd4"
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onContainsMouseChanged: scanButton.color = containsMouse ? "#1a1a1a" : "#0f0f0f"
            onClicked: startScan()
        }
    }
}
