import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: root
    required property var screen

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    visible: false
    color: "#0f0f0f"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    property bool open: false
    property string wallpaperDir: "/home/que/Pictures/Wallpapers"
    property int selectedIndex: 0
    property bool loading: false

    readonly property int cellW: 240
    readonly property int cellH: 150
    readonly property int cols: Math.max(1, Math.floor(gridView.width / gridView.cellWidth))

    onOpenChanged: {
        visible = open
        if (open) {
            loading = true
            searchInput.text = ""
            selectedIndex = 0
            scanProc.running = true
            searchInput.forceActiveFocus()
        }
    }

    ListModel { id: allWalls }
    ListModel { id: filteredWalls }

    Process {
        id: scanProc
        command: ["sh", "-c",
            "find '" + root.wallpaperDir +
            "' -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' \\) 2>/dev/null | sort -f"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                allWalls.clear()
                var lines = text.trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var p = lines[i]
                    if (!p) continue
                    var slash = p.lastIndexOf("/")
                    var name = slash >= 0 ? p.substring(slash + 1) : p
                    allWalls.append({ filePath: p, fileName: name })
                }
                root.loading = false
                root.filter()
            }
        }
    }

    function filter() {
        filteredWalls.clear()
        var q = searchInput.text.toLowerCase().trim()
        var parts = q.length > 0 ? q.split(/\s+/) : []
        for (var i = 0; i < allWalls.count; i++) {
            var w = allWalls.get(i)
            var name = w.fileName.toLowerCase()
            var ok = parts.every(function(p) { return name.indexOf(p) !== -1 })
            if (ok) filteredWalls.append({ filePath: w.filePath, fileName: w.fileName })
        }
        selectedIndex = filteredWalls.count > 0 ? 0 : -1
        gridView.positionViewAtBeginning()
    }

    function apply() {
        if (selectedIndex < 0 || selectedIndex >= filteredWalls.count) return
        var item = filteredWalls.get(selectedIndex)
        Quickshell.execDetached(["/home/que/.config/quickshell/wallpaper/set-wallpaper.sh", item.filePath])
        root.open = false
    }

    function move(dx, dy) {
        if (filteredWalls.count === 0) return
        var idx = root.selectedIndex < 0 ? 0 : root.selectedIndex
        idx += dx + dy * root.cols
        idx = Math.max(0, Math.min(filteredWalls.count - 1, idx))
        root.selectedIndex = idx
        gridView.positionViewAtIndex(idx, GridView.Contain)
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            spacing: 0

            Item { width: 12 }
            Text {
                text: "─ WALLPAPERS"
                color: "#4a4f5a"
                font.family: "monospace"
                font.pixelSize: 10
                font.letterSpacing: 2
                Layout.alignment: Qt.AlignVCenter
            }
            Item { Layout.fillWidth: true }
            Text {
                text: root.loading ? "loading..." : (filteredWalls.count + " items")
                color: "#4a4f5a"
                font.family: "monospace"
                font.pixelSize: 10
                Layout.alignment: Qt.AlignVCenter
            }
            Item { width: 16 }
            Text {
                text: "[esc]"
                color: "#4a4f5a"
                font.family: "monospace"
                font.pixelSize: 10
                Layout.alignment: Qt.AlignVCenter
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.open = false
                }
            }
            Item { width: 12 }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#2a2e35" }

        // Search row — owns keyboard focus
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            spacing: 0

            Item { width: 12 }
            Text {
                text: "> "
                color: "#4a4f5a"
                font.family: "monospace"
                font.pixelSize: 13
                Layout.alignment: Qt.AlignVCenter
            }
            TextInput {
                id: searchInput
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                color: "#c8ccd4"
                selectionColor: "#2a2e35"
                selectedTextColor: "#ffffff"
                font.family: "monospace"
                font.pixelSize: 13
                selectByMouse: true
                clip: true

                onTextChanged: root.filter()

                Keys.onUpPressed: { root.move(0, -1); event.accepted = true }
                Keys.onDownPressed: { root.move(0, 1); event.accepted = true }
                Keys.onLeftPressed: { root.move(-1, 0); event.accepted = true }
                Keys.onRightPressed: { root.move(1, 0); event.accepted = true }
                Keys.onReturnPressed: { root.apply(); event.accepted = true }
                Keys.onEnterPressed: { root.apply(); event.accepted = true }
                Keys.onEscapePressed: { root.open = false; event.accepted = true }
            }
            Item { width: 12 }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#2a2e35" }

        // Body
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Text {
                visible: root.loading
                anchors.centerIn: parent
                text: "loading..."
                color: "#4a4f5a"
                font.family: "monospace"
                font.pixelSize: 12
            }

            Text {
                visible: !root.loading && filteredWalls.count === 0
                anchors.centerIn: parent
                text: "no wallpapers"
                color: "#4a4f5a"
                font.family: "monospace"
                font.pixelSize: 12
            }

            GridView {
                id: gridView
                visible: !root.loading && filteredWalls.count > 0
                anchors.fill: parent
                anchors.margins: 16
                model: filteredWalls
                cellWidth: root.cellW
                cellHeight: root.cellH
                clip: true
                currentIndex: root.selectedIndex
                cacheBuffer: root.cellH * 4

                delegate: Rectangle {
                    width: gridView.cellWidth - 8
                    height: gridView.cellHeight - 8
                    color: "#0f0f0f"
                    border.color: index === root.selectedIndex ? "#c8ccd4" : "#2a2e35"
                    border.width: 1
                    radius: 2

                    Image {
                        anchors.fill: parent
                        anchors.margins: 1
                        source: "file://" + model.filePath
                        fillMode: Image.PreserveAspectCrop
                        clip: true
                        asynchronous: true
                        cache: true
                        sourceSize.width: 480
                        sourceSize.height: 300
                    }

                    Rectangle {
                        height: 18
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 1
                        color: "#cc0f0f0f"
                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            text: model.fileName
                            color: index === root.selectedIndex ? "#ffffff" : "#c8ccd4"
                            font.family: "monospace"
                            font.pixelSize: 10
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.selectedIndex = index
                        onClicked: { root.selectedIndex = index; root.apply() }
                    }
                }
            }
        }

        // Footer hint strip
        Rectangle { Layout.fillWidth: true; height: 1; color: "#2a2e35" }
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 22
            spacing: 16
            Item { width: 12 }
            Text {
                text: "↑↓←→ navigate"
                color: "#4a4f5a"
                font.family: "monospace"
                font.pixelSize: 10
                Layout.alignment: Qt.AlignVCenter
            }
            Text {
                text: "enter apply"
                color: "#4a4f5a"
                font.family: "monospace"
                font.pixelSize: 10
                Layout.alignment: Qt.AlignVCenter
            }
            Text {
                text: "type to filter"
                color: "#4a4f5a"
                font.family: "monospace"
                font.pixelSize: 10
                Layout.alignment: Qt.AlignVCenter
            }
            Item { Layout.fillWidth: true }
            Item { width: 12 }
        }
    }
}
