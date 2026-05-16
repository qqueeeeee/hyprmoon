import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: 6
    width: 248
    Layout.preferredWidth: 248

    property date today: new Date()
    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth()

    function monthName(month) {
        return ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"][month];
    }

    function daysInMonth(year, month) {
        return new Date(year, month + 1, 0).getDate();
    }

    function cellDay(index) {
        var first = new Date(viewYear, viewMonth, 1).getDay();
        var day = index - first + 1;
        return day > 0 && day <= daysInMonth(viewYear, viewMonth) ? day : 0;
    }

    function isToday(day) {
        return day === today.getDate()
            && viewYear === today.getFullYear()
            && viewMonth === today.getMonth();
    }

    function shiftMonth(delta) {
        var m = viewMonth + delta;
        var y = viewYear;
        while (m < 0) { m += 12; y -= 1; }
        while (m > 11) { m -= 12; y += 1; }
        viewMonth = m;
        viewYear = y;
    }

    function gotoToday() {
        viewYear = today.getFullYear();
        viewMonth = today.getMonth();
    }

    Text {
        text: "─ CALENDAR"
        color: "#4a4f5a"
        font.family: "monospace"
        font.pixelSize: 10
        font.letterSpacing: 2
    }

    RowLayout {
        Layout.fillWidth: true

        Text {
            text: "[<]"
            color: prevArea.containsMouse ? "#ffffff" : "#c8ccd4"
            font.family: "monospace"
            font.pixelSize: 12
            MouseArea {
                id: prevArea
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                onClicked: root.shiftMonth(-1)
            }
        }

        Item { Layout.fillWidth: true }

        Text {
            text: root.monthName(viewMonth) + " " + viewYear
            color: "#c8ccd4"
            font.family: "monospace"
            font.pixelSize: 13
            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                onClicked: root.gotoToday()
            }
        }

        Item { Layout.fillWidth: true }

        Text {
            text: "[>]"
            color: nextArea.containsMouse ? "#ffffff" : "#c8ccd4"
            font.family: "monospace"
            font.pixelSize: 12
            MouseArea {
                id: nextArea
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                onClicked: root.shiftMonth(1)
            }
        }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 7
        rowSpacing: 2
        columnSpacing: 0

        Repeater {
            model: ["S", "M", "T", "W", "T", "F", "S"]
            Text {
                Layout.preferredWidth: 248 / 7
                text: modelData
                color: "#4a4f5a"
                font.family: "monospace"
                font.pixelSize: 10
                horizontalAlignment: Text.AlignHCenter
            }
        }

        Repeater {
            model: 42
            delegate: Rectangle {
                Layout.preferredWidth: 248 / 7
                height: 20
                property int day: root.cellDay(index)
                property bool todayCell: root.isToday(day)
                color: todayCell ? "#1a1a1a" : "#0f0f0f"

                Text {
                    anchors.centerIn: parent
                    text: parent.day === 0 ? "·"
                          : (parent.todayCell ? "[" + parent.day + "]" : "" + parent.day)
                    color: parent.day === 0 ? "#2a2e35"
                          : (parent.todayCell ? "#ffffff" : "#c8ccd4")
                    font.family: "monospace"
                    font.pixelSize: parent.todayCell ? 12 : 12
                }
            }
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.today = new Date()
    }
}
