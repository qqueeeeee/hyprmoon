import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: 8

    property date now: new Date()

    function monthName(month) {
        return ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"][month];
    }

    function daysInMonth(year, month) {
        return new Date(year, month + 1, 0).getDate();
    }

    function cellText(index) {
        var first = new Date(now.getFullYear(), now.getMonth(), 1).getDay();
        var day = index - first + 1;
        return day > 0 && day <= daysInMonth(now.getFullYear(), now.getMonth()) ? day : "";
    }

    Text {
        text: "CALENDAR"
        color: "#4a4f5a"
        font.family: "monospace"
        font.pixelSize: 10
        font.letterSpacing: 2
    }

    Text {
        text: monthName(now.getMonth()) + " " + now.getFullYear()
        color: "#c8ccd4"
        font.family: "monospace"
        font.pixelSize: 13
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 7
        rowSpacing: 4
        columnSpacing: 0

        Repeater {
            model: ["S", "M", "T", "W", "T", "F", "S"]

            Text {
                Layout.preferredWidth: 228 / 7
                text: modelData
                color: "#4a4f5a"
                font.family: "monospace"
                font.pixelSize: 10
                horizontalAlignment: Text.AlignHCenter
            }
        }

        Repeater {
            model: 42

            Rectangle {
                Layout.preferredWidth: 228 / 7
                height: 20
                color: {
                    var d = root.cellText(index);
                    return d === root.now.getDate() ? "#1a1a1a" : "#0f0f0f";
                }

                Rectangle {
                    anchors.left: parent.left
                    width: root.cellText(index) === root.now.getDate() ? 3 : 0
                    height: parent.height
                    color: "#c8ccd4"
                }

                Text {
                    anchors.centerIn: parent
                    text: root.cellText(index)
                    color: text === "" ? "#4a4f5a" : "#c8ccd4"
                    font.family: "monospace"
                    font.pixelSize: 13
                }
            }
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }
}
