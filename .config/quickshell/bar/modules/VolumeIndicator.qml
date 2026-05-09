import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    height: 28
    implicitWidth: labelText.width + 12
    width: implicitWidth
    Layout.preferredWidth: implicitWidth

    required property var screen
    property string activePopup: ""
    property bool popupOpen: activePopup === "volume"
    property int volume: 0
    property bool muted: false
    property string feedback: ""

    signal togglePopup()

    Text {
        id: labelText
        anchors.centerIn: parent
        text: root.muted ? "MUTED" : root.volume + "%"
        color: root.popupOpen ? "#ffffff" : "#c8ccd4"
        font.family: "monospace"
        font.pixelSize: 12
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.togglePopup()
    }

    Process {
        id: volumeRefreshProc
        command: ["sh", "-c", "pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -oP '\\d+(?=%)' | head -1; pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split("\n");
                root.volume = Math.max(0, Math.min(100, parseInt(parts[0] || "0")));
                root.muted = (parts[1] || "").indexOf("yes") !== -1;
                root.feedback = "";
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

    function setVolume(value) {
        root.feedback = "applying...";
        volumeSetProc.command = ["pactl", "set-sink-volume", "@DEFAULT_SINK@", Math.round(value) + "%"];
        volumeSetProc.running = true;
    }

    Component.onCompleted: volumeRefreshProc.running = true

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: volumeRefreshProc.running = true
    }

    PanelWindow {
        id: popup
        screen: root.screen
        visible: root.popupOpen
        implicitWidth: 280
        implicitHeight: 220
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
                anchors.margins: 16
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "VOLUME"
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
                    text: root.muted ? "MUTED" : root.volume + "%"
                    color: "#c8ccd4"
                    font.family: "monospace"
                    font.pixelSize: 20
                }

                Slider {
                    id: slider
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    stepSize: 1
                    value: root.volume
                    onMoved: root.setVolume(value)

                    background: Rectangle {
                        x: slider.leftPadding
                        y: slider.topPadding + slider.availableHeight / 2 - height / 2
                        width: slider.availableWidth
                        height: 4
                        color: "#2a2e35"

                        Rectangle {
                            width: slider.visualPosition * parent.width
                            height: parent.height
                            color: "#c8ccd4"
                        }
                    }

                    handle: Rectangle {
                        x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                        y: slider.topPadding + slider.availableHeight / 2 - height / 2
                        width: 14
                        height: 14
                        color: "#ffffff"
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    color: root.muted ? "#1a1a1a" : (muteArea.containsMouse ? "#1a1a1a" : "#0f0f0f")
                    border.color: "#2a2e35"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: root.muted ? "UNMUTE" : "MUTE"
                        color: "#c8ccd4"
                        font.family: "monospace"
                        font.pixelSize: 13
                    }

                    MouseArea {
                        id: muteArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            root.feedback = "applying...";
                            muteProc.running = true;
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

                Item {
                    Layout.fillHeight: true
                }
            }
        }
    }
}
