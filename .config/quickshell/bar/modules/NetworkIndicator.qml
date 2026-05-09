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
    property bool popupOpen: activePopup === "network"
    property string currentSsid: ""
    property string feedback: ""
    property bool failed: false
    property int lastRxBytes: 0
    property int lastTxBytes: 0
    property real downloadRate: 0
    property real uploadRate: 0
    property var speedHistory: []

    signal togglePopup()

    Text {
        id: labelText
        anchors.centerIn: parent
        text: root.currentSsid ? "NET*" : "NET-"
        color: root.popupOpen ? "#ffffff" : "#c8ccd4"
        font.family: "monospace"
        font.pixelSize: 12
        elide: Text.ElideRight
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.togglePopup()
    }

    ListModel {
        id: networkModel
    }

    Process {
        id: activeRefreshProc
        command: ["sh", "-c", "nmcli -t -f active,ssid dev wifi 2>/dev/null | awk -F: '$1==\"yes\" {print substr($0,5); exit}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.currentSsid = text.trim();
            }
        }
    }

    Process {
        id: listRefreshProc
        command: ["sh", "-c", "nmcli -t -f active,ssid dev wifi list 2>/dev/null | head -6"]
        stdout: StdioCollector {
            onStreamFinished: {
                networkModel.clear();
                var lines = text.trim().split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (!line)
                        continue;
                    var active = line.indexOf("yes:") === 0;
                    var ssid = line.slice(line.indexOf(":") + 1);
                    if (ssid)
                        networkModel.append({ ssid: ssid, active: active });
                }
            }
        }
    }

    Process {
        id: connectProc
        onExited: function(exitCode) {
            root.failed = exitCode !== 0;
            root.feedback = root.failed ? "failed" : "";
            activeRefreshProc.running = true;
            listRefreshProc.running = true;
            feedbackTimer.restart();
        }
    }

    Process {
        id: speedProc
        command: ["sh", "-c", "iface=$(ip route get 1.1.1.1 2>/dev/null | awk '{for (i=1;i<=NF;i++) if ($i==\"dev\") {print $(i+1); exit}}'); if [ -n \"$iface\" ] && [ -r /sys/class/net/$iface/statistics/rx_bytes ]; then cat /sys/class/net/$iface/statistics/rx_bytes; cat /sys/class/net/$iface/statistics/tx_bytes; else echo 0; echo 0; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split("\n");
                var rx = parseInt(parts[0] || "0");
                var tx = parseInt(parts[1] || "0");
                if (isNaN(rx))
                    rx = 0;
                if (isNaN(tx))
                    tx = 0;
                if (root.lastRxBytes > 0) {
                    root.downloadRate = Math.max(0, rx - root.lastRxBytes);
                    root.uploadRate = Math.max(0, tx - root.lastTxBytes);
                    var next = root.speedHistory.slice();
                    next.push(root.downloadRate);
                    while (next.length > 42)
                        next.shift();
                    root.speedHistory = next;
                    speedGraph.requestPaint();
                }
                root.lastRxBytes = rx;
                root.lastTxBytes = tx;
            }
        }
    }

    Timer {
        id: feedbackTimer
        interval: 2000
        onTriggered: {
            root.feedback = "";
            root.failed = false;
        }
    }

    function refreshNetwork(showFeedback) {
        if (showFeedback) {
            root.feedback = "scanning...";
            root.failed = false;
        }
        activeRefreshProc.running = true;
        listRefreshProc.running = true;
    }

    function connectToNetwork(ssid) {
        root.feedback = "connecting...";
        root.failed = false;
        connectProc.command = ["nmcli", "dev", "wifi", "connect", ssid];
        connectProc.running = true;
    }

    Component.onCompleted: refreshNetwork(false)

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: refreshNetwork(false)
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: speedProc.running = true
    }

    function formatRate(bytes) {
        if (bytes >= 1048576)
            return (bytes / 1048576).toFixed(1) + " MB/s";
        if (bytes >= 1024)
            return Math.round(bytes / 1024) + " KB/s";
        return Math.round(bytes) + " B/s";
    }

    PanelWindow {
        id: popup
        screen: root.screen
        visible: root.popupOpen
        implicitWidth: 280
        implicitHeight: 468
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
                        text: "NETWORK"
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
                    text: root.feedback || (root.currentSsid ? root.currentSsid : "disconnected")
                    color: root.failed ? "#ff5555" : (root.currentSsid || root.feedback ? "#c8ccd4" : "#4a4f5a")
                    font.family: "monospace"
                    font.pixelSize: 13
                    elide: Text.ElideRight
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#2a2e35"
                }

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "SPEED"
                        color: "#4a4f5a"
                        font.family: "monospace"
                        font.pixelSize: 10
                        font.letterSpacing: 2
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "↓ " + root.formatRate(root.downloadRate) + "  ↑ " + root.formatRate(root.uploadRate)
                        color: "#c8ccd4"
                        font.family: "monospace"
                        font.pixelSize: 10
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 64
                    color: "#0f0f0f"
                    border.color: "#2a2e35"
                    border.width: 1

                    Canvas {
                        id: speedGraph
                        anchors.fill: parent
                        anchors.margins: 1

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            ctx.fillStyle = "#0f0f0f";
                            ctx.fillRect(0, 0, width, height);

                            ctx.strokeStyle = "#2a2e35";
                            ctx.lineWidth = 1;
                            for (var y = height / 4; y < height; y += height / 4) {
                                ctx.beginPath();
                                ctx.moveTo(0, Math.floor(y) + 0.5);
                                ctx.lineTo(width, Math.floor(y) + 0.5);
                                ctx.stroke();
                            }

                            var history = root.speedHistory;
                            if (!history.length)
                                return;

                            var max = 1024;
                            for (var i = 0; i < history.length; i++)
                                max = Math.max(max, history[i]);

                            var step = history.length > 1 ? width / (history.length - 1) : width;

                            ctx.beginPath();
                            ctx.moveTo(0, height);
                            for (var j = 0; j < history.length; j++) {
                                var x = j * step;
                                var yValue = history[j] / max;
                                var y = height - 2 - yValue * (height - 6);
                                ctx.lineTo(x, y);
                            }
                            ctx.lineTo(width, height);
                            ctx.closePath();
                            ctx.fillStyle = "#1a1a1a";
                            ctx.fill();

                            ctx.beginPath();
                            for (var k = 0; k < history.length; k++) {
                                var lineX = k * step;
                                var lineValue = history[k] / max;
                                var lineY = height - 2 - lineValue * (height - 6);
                                if (k === 0)
                                    ctx.moveTo(lineX, lineY);
                                else
                                    ctx.lineTo(lineX, lineY);
                            }
                            ctx.strokeStyle = "#c8ccd4";
                            ctx.lineWidth = 1;
                            ctx.stroke();
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#2a2e35"
                }

                Text {
                    text: "AVAILABLE"
                    color: "#4a4f5a"
                    font.family: "monospace"
                    font.pixelSize: 10
                    font.letterSpacing: 2
                }

                Repeater {
                    model: networkModel

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 36
                        color: networkArea.containsMouse ? "#1a1a1a" : "#0f0f0f"

                        Rectangle {
                            width: 3
                            height: parent.height
                            color: model.active ? "#c8ccd4" : "transparent"
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 20
                            text: model.ssid
                            color: "#c8ccd4"
                            font.family: "monospace"
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            id: networkArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.connectToNetwork(model.ssid)
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    color: refreshArea.containsMouse ? "#1a1a1a" : "#0f0f0f"

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: "↻ REFRESH"
                        color: "#c8ccd4"
                        font.family: "monospace"
                        font.pixelSize: 13
                    }

                    MouseArea {
                        id: refreshArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.refreshNetwork(true)
                    }
                }

                Item {
                    Layout.fillHeight: true
                }
            }
        }
    }
}
