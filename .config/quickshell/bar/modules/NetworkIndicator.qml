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
    property bool popupOpen: activePopup === "network"
    property string currentSsid: ""
    property int currentSignal: 0
    property string feedback: ""
    property bool failed: false
    property int lastRxBytes: 0
    property int lastTxBytes: 0
    property real downloadRate: 0
    property real uploadRate: 0
    property var speedHistory: []

    signal togglePopup()

    function signalBars(strength) {
        if (strength <= 0) return "----";
        var filled = strength >= 75 ? 4 : strength >= 50 ? 3 : strength >= 25 ? 2 : 1;
        return "▆".repeat(filled) + "▁".repeat(4 - filled);
    }

    Text {
        id: labelText
        anchors.centerIn: parent
        text: "[w:" + (root.currentSsid ? root.signalBars(root.currentSignal) : "----") + "]"
        color: root.popupOpen ? "#ffffff"
               : (root.currentSsid ? "#c8ccd4" : "#4a4f5a")
        font.family: "monospace"
        font.pixelSize: 12
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.togglePopup()
    }

    ListModel { id: networkModel }

    Process {
        id: activeRefreshProc
        command: ["sh", "-c", "nmcli -t -f active,ssid,signal dev wifi 2>/dev/null | awk -F: '$1==\"yes\" {print $2\"\\n\"$3; exit}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n");
                root.currentSsid = (lines[0] || "").trim();
                root.currentSignal = parseInt(lines[1] || "0") || 0;
            }
        }
    }

    Process {
        id: listRefreshProc
        command: ["sh", "-c", "nmcli -t -f active,ssid,signal dev wifi list 2>/dev/null | head -10"]
        stdout: StdioCollector {
            onStreamFinished: {
                networkModel.clear();
                var lines = text.trim().split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split(":");
                    if (parts.length < 3) continue;
                    var active = parts[0] === "yes";
                    var ssid = parts[1];
                    var signal = parseInt(parts[2]) || 0;
                    if (!ssid) continue;
                    networkModel.append({ ssid: ssid, active: active, signal: signal });
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
                var rx = parseInt(parts[0] || "0") || 0;
                var tx = parseInt(parts[1] || "0") || 0;
                if (root.lastRxBytes > 0) {
                    root.downloadRate = Math.max(0, rx - root.lastRxBytes);
                    root.uploadRate = Math.max(0, tx - root.lastTxBytes);
                    var next = root.speedHistory.slice();
                    next.push(root.downloadRate);
                    while (next.length > 42) next.shift();
                    root.speedHistory = next;
                }
                root.lastRxBytes = rx;
                root.lastTxBytes = tx;
            }
        }
    }

    Timer {
        id: feedbackTimer
        interval: 2000
        onTriggered: { root.feedback = ""; root.failed = false; }
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

    Timer { interval: 30000; running: true; repeat: true; onTriggered: refreshNetwork(false) }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: speedProc.running = true }

    function formatRate(bytes) {
        if (bytes >= 1048576) return (bytes / 1048576).toFixed(1) + " MB/s";
        if (bytes >= 1024) return Math.round(bytes / 1024) + " KB/s";
        return Math.round(bytes) + " B/s";
    }

    function blockSpark(history) {
        if (!history || history.length === 0) return "                              ";
        var blocks = " ▁▂▃▄▅▆▇█";
        var max = 1024;
        for (var i = 0; i < history.length; i++) if (history[i] > max) max = history[i];
        var out = "";
        var slice = history.slice(-30);
        for (var j = 0; j < slice.length; j++) {
            var v = Math.min(8, Math.round((slice[j] / max) * 8));
            out += blocks.charAt(v);
        }
        while (out.length < 30) out = " " + out;
        return out;
    }

    PanelWindow {
        id: popup
        screen: root.screen
        visible: root.popupOpen
        implicitWidth: 320
        implicitHeight: 520
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
                        text: "─ NETWORK"
                        color: "#4a4f5a"
                        font.family: "monospace"
                        font.pixelSize: 10
                        font.letterSpacing: 2
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "[x]"
                        color: "#4a4f5a"
                        font.family: "monospace"
                        font.pixelSize: 10
                        MouseArea { anchors.fill: parent; onClicked: root.togglePopup() }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.feedback || (root.currentSsid
                          ? "> " + root.currentSsid + "  [" + root.signalBars(root.currentSignal) + "]"
                          : "  disconnected")
                    color: root.failed ? "#ff5555" : (root.currentSsid || root.feedback ? "#c8ccd4" : "#4a4f5a")
                    font.family: "monospace"
                    font.pixelSize: 13
                    elide: Text.ElideRight
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: "#2a2e35" }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "SPEED"
                        color: "#4a4f5a"
                        font.family: "monospace"
                        font.pixelSize: 10
                        font.letterSpacing: 2
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "v " + root.formatRate(root.downloadRate) + "  ^ " + root.formatRate(root.uploadRate)
                        color: "#c8ccd4"
                        font.family: "monospace"
                        font.pixelSize: 10
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.blockSpark(root.speedHistory)
                    color: "#c8ccd4"
                    font.family: "monospace"
                    font.pixelSize: 14
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: "#2a2e35" }

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
                        height: 30
                        color: networkArea.containsMouse ? "#1a1a1a" : "#0f0f0f"

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 16
                            text: (model.active ? "> " : "  ") + model.ssid +
                                  "  [" + root.signalBars(model.signal) + "]" +
                                  (model.active ? "  [conn]" : "")
                            color: "#c8ccd4"
                            opacity: model.active ? 1.0 : 0.75
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
                    height: 30
                    color: refreshArea.containsMouse ? "#1a1a1a" : "#0f0f0f"
                    border.color: "#2a2e35"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "[ refresh ]"
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

                Item { Layout.fillHeight: true }
            }
        }
    }
}
