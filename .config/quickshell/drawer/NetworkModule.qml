import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    spacing: 8

    Text {
        text: "NETWORK"
        font.family: "monospace"
        font.pixelSize: 10
        color: "#4a4f5a"
        font.letterSpacing: 2
    }

    Text {
        id: networkStatus
        text: "--"
        font.family: "monospace"
        font.pixelSize: 13
        color: "#c8ccd4"
    }

    ColumnLayout {
        id: networkList
        spacing: 2
    }

    Process {
        id: connectProc
        onExited: function(exitCode) {
            networkStatus.text = exitCode === 0 ? "connected" : "failed";
            networkStatus.color = exitCode === 0 ? "#c8ccd4" : "#ff5555";
            feedbackTimer.restart();
            refreshNetwork();
        }
    }

    Process {
        id: refreshProc
    }

    Process {
        id: activeRefreshProc
        command: ["sh", "-c", "nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                networkStatus.text = text.trim() || "disconnected";
                networkStatus.color = text.trim() ? "#c8ccd4" : "#4a4f5a";
            }
        }
    }

    Process {
        id: listRefreshProc
        command: ["sh", "-c", "nmcli -t -f active,ssid dev wifi list | head -5"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                networkModel.clear();
                var lines = text.trim().split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line) {
                        var isActive = line.startsWith("yes:");
                        var ssid = line.substring(line.indexOf(":") + 1);
                        networkModel.append({ ssid: ssid, active: isActive });
                    }
                }
            }
        }
    }

    ListModel {
        id: networkModel
    }

    function refreshNetwork() {
        activeRefreshProc.running = true;
        listRefreshProc.running = true;
    }

    function connectToNetwork(ssid) {
        networkStatus.text = "connecting...";
        networkStatus.color = "#4a4f5a";
        connectProc.command = ["nmcli", "dev", "wifi", "connect", ssid];
        connectProc.running = true;
    }

    Timer {
        id: feedbackTimer
        interval: 2000
        onTriggered: refreshNetwork()
    }

    Component.onCompleted: refreshNetwork()

    Component {
        id: networkDelegate
        Rectangle {
            id: networkRow
            width: 228
            height: 36
            color: networkArea.containsMouse ? "#1a1a1a" : "#0f0f0f"

            Rectangle {
                width: 3
                height: parent.height
                color: model.active ? "#c8ccd4" : "transparent"
            }

            Text {
                text: model.ssid
                font.family: "monospace"
                font.pixelSize: 12
                color: model.active ? "#c8ccd4" : "#c8ccd4"
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
            }

            MouseArea {
                id: networkArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: connectToNetwork(model.ssid)
            }
        }
    }

    Repeater {
        model: networkModel
        delegate: networkDelegate
    }

    Rectangle {
        id: refreshButton
        width: 228
        height: 36
        color: "#0f0f0f"
        border.color: "#2a2e35"
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: "↻ REFRESH"
            font.family: "monospace"
            font.pixelSize: 12
            color: "#c8ccd4"
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onContainsMouseChanged: refreshButton.color = containsMouse ? "#1a1a1a" : "#0f0f0f"
            onClicked: {
                networkStatus.text = "scanning...";
                networkStatus.color = "#4a4f5a";
                refreshNetwork();
            }
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: refreshNetwork()
    }
}
