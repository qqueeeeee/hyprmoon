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
    property bool popupOpen: activePopup === "volume"
    property int volume: 0
    property bool muted: false
    property string feedback: ""

    // Emitted whenever the system-side state changes (so an OSD can react).
    signal externalChange(int volume, bool muted)

    signal togglePopup()

    function fillBar(percent, segments) {
        var filled = Math.round((percent / 100) * segments);
        if (filled > segments) filled = segments;
        if (filled < 0) filled = 0;
        return "▆".repeat(filled) + "▁".repeat(segments - filled);
    }

    Text {
        id: labelText
        anchors.centerIn: parent
        text: root.muted ? "[♪ M]" : "[♪" + root.volume + "]"
        color: root.popupOpen ? "#ffffff"
               : (root.muted ? "#ff5555" : "#c8ccd4")
        font.family: "monospace"
        font.pixelSize: 12
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.togglePopup()
    }

    WheelHandler {
        onWheel: function(event) {
            root.setVolume(root.volume + (event.angleDelta.y > 0 ? 5 : -5));
        }
    }

    Process {
        id: volumeRefreshProc
        property bool initial: true
        command: ["sh", "-c", "pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -oP '\\d+(?=%)' | head -1; pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split("\n");
                var newVol = Math.max(0, Math.min(100, parseInt(parts[0] || "0")));
                var newMuted = (parts[1] || "").indexOf("yes") !== -1;
                var changed = (newVol !== root.volume) || (newMuted !== root.muted);
                root.volume = newVol;
                root.muted = newMuted;
                root.feedback = "";
                if (changed && !volumeRefreshProc.initial)
                    root.externalChange(newVol, newMuted);
                volumeRefreshProc.initial = false;
            }
        }
    }

    Process {
        id: volumeSetProc
        onExited: volumeRefreshProc.running = true
    }

    Process {
        id: muteProc
        command: ["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"]
        onExited: volumeRefreshProc.running = true
    }

    // Refresh the bar display on real sink changes (not sink-input stream events,
    // which fire constantly when apps start/stop audio).
    Process {
        id: subscribeProc
        command: ["pactl", "subscribe"]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                if (line.indexOf("on sink #") !== -1)
                    volumeRefreshProc.running = true;
            }
        }
    }

    function setVolume(value) {
        root.feedback = "applying...";
        volumeSetProc.command = ["pactl", "set-sink-volume", "@DEFAULT_SINK@", Math.round(value) + "%"];
        volumeSetProc.running = true;
    }

    Component.onCompleted: volumeRefreshProc.running = true

    PanelWindow {
        id: popup
        screen: root.screen
        visible: root.popupOpen
        implicitWidth: 300
        implicitHeight: 200
        color: "#0f0f0f"
        anchors.top: true
        anchors.right: true
        margins.top: 28

        WheelHandler {
            onWheel: function(event) {
                root.setVolume(root.volume + (event.angleDelta.y > 0 ? 5 : -5));
            }
        }

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
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "─ VOLUME"
                        color: "#4a4f5a"
                        font.family: "monospace"
                        font.pixelSize: 10
                        font.letterSpacing: 2
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "[" + (root.muted ? "unmute" : "mute") + "]"
                        color: muteArea.containsMouse ? "#ffffff" : "#c8ccd4"
                        font.family: "monospace"
                        font.pixelSize: 10
                        MouseArea {
                            id: muteArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: muteProc.running = true
                        }
                    }
                    Item { width: 8 }
                    Text {
                        text: "[x]"
                        color: "#4a4f5a"
                        font.family: "monospace"
                        font.pixelSize: 10
                        MouseArea { anchors.fill: parent; onClicked: root.togglePopup() }
                    }
                }

                Text {
                    text: root.muted ? "MUTED" : root.volume + "%"
                    color: root.muted ? "#ff5555" : "#c8ccd4"
                    font.family: "monospace"
                    font.pixelSize: 24
                }

                Text {
                    Layout.fillWidth: true
                    text: "[" + root.fillBar(root.muted ? 0 : root.volume, 20) + "]"
                    color: root.muted ? "#ff5555" : "#c8ccd4"
                    font.family: "monospace"
                    font.pixelSize: 13
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Rectangle {
                        Layout.fillWidth: true
                        height: 26
                        color: downArea.containsMouse ? "#1a1a1a" : "#0f0f0f"
                        border.color: "#2a2e35"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "[ -5 ]"
                            color: "#c8ccd4"
                            font.family: "monospace"
                            font.pixelSize: 13
                        }

                        MouseArea {
                            id: downArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.setVolume(Math.max(0, root.volume - 5))
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 26
                        color: upArea.containsMouse ? "#1a1a1a" : "#0f0f0f"
                        border.color: "#2a2e35"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "[ +5 ]"
                            color: "#c8ccd4"
                            font.family: "monospace"
                            font.pixelSize: 13
                        }

                        MouseArea {
                            id: upArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.setVolume(Math.min(100, root.volume + 5))
                        }
                    }
                }

                Text {
                    text: root.feedback
                    color: "#4a4f5a"
                    font.family: "monospace"
                    font.pixelSize: 10
                    font.letterSpacing: 2
                }

                Item { Layout.fillHeight: true }
            }
        }
    }
}
