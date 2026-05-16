import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: root
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    visible: false
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    required property var screen

    property bool open: false
    property string searchQuery: ""
    property int selectedIndex: 0
    property bool loading: false

    onOpenChanged: {
        visible = open
        if (open) {
            loading = true
            searchInput.text = ""
            searchQuery = ""
            selectedIndex = 0
            appsProc.running = true
            searchInput.forceActiveFocus()
        }
    }

    ListModel { id: allApps }
    ListModel { id: filteredApps }

    Process {
        id: appsProc
        command: ["sh", "-c", "find /usr/share/applications ~/.local/share/applications -name '*.desktop' 2>/dev/null | while IFS= read -r f; do grep -q '^Type=Application' \"$f\" || continue; grep -q '^NoDisplay=true' \"$f\" && continue; n=$(grep '^Name=' \"$f\" | head -1 | cut -d= -f2-); e=$(grep '^Exec=' \"$f\" | head -1 | cut -d= -f2- | sed 's/ *%[A-Za-z]//g' | sed 's/^ *//;s/ *$//'); [ -z \"$n\" ] || [ -z \"$e\" ] && continue; printf '%s\\t%s\\n' \"$n\" \"$e\"; done | sort -f"]
        stdout: StdioCollector {
            onStreamFinished: {
                allApps.clear()
                var lines = text.trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i]
                    if (!line) continue
                    var tab = line.indexOf("\t")
                    if (tab < 0) continue
                    allApps.append({ name: line.substring(0, tab), exec: line.substring(tab + 1) })
                }
                root.loading = false
                root.filterApps()
            }
        }
    }

    function filterApps() {
        filteredApps.clear()
        var q = searchQuery.toLowerCase()
        for (var i = 0; i < allApps.count; i++) {
            var app = allApps.get(i)
            if (!q || app.name.toLowerCase().indexOf(q) >= 0)
                filteredApps.append({ name: app.name, exec: app.exec })
        }
        selectedIndex = 0
        appsList.positionViewAtBeginning()
    }

    function launch() {
        if (selectedIndex < 0 || selectedIndex >= filteredApps.count) return
        var app = filteredApps.get(selectedIndex)
        Quickshell.execDetached(["sh", "-c", app.exec])
        root.open = false
    }

    // Dim overlay — click outside to close
    Rectangle {
        anchors.fill: parent
        color: "#cc000000"
        MouseArea {
            anchors.fill: parent
            onClicked: root.open = false
        }
    }

    // Dialog box
    Rectangle {
        id: dialog
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 80
        width: 560
        color: "#0f0f0f"
        border.color: "#2a2e35"
        border.width: 1
        clip: true

        property int contentRows: root.loading || filteredApps.count === 0 ? 1 : Math.min(filteredApps.count, 12)
        height: 28 + 1 + 34 + 1 + contentRows * 34

        // Eat mouse events so clicking inside doesn't close the launcher
        MouseArea { anchors.fill: parent }

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
                    text: "APP LAUNCHER"
                    color: "#4a4f5a"
                    font.family: "monospace"
                    font.pixelSize: 10
                    font.letterSpacing: 2
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: root.loading ? "loading..." : (filteredApps.count + " apps")
                    color: "#2a2e35"
                    font.family: "monospace"
                    font.pixelSize: 10
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { width: 12 }

                Text {
                    text: "✕"
                    color: "#4a4f5a"
                    font.family: "monospace"
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignVCenter
                    MouseArea { anchors.fill: parent; onClicked: root.open = false }
                }

                Item { width: 12 }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#2a2e35" }

            // Search row
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
                    font.family: "monospace"
                    font.pixelSize: 13
                    selectByMouse: true

                    onTextChanged: {
                        root.searchQuery = text
                        root.filterApps()
                    }

                    Keys.onUpPressed: {
                        if (filteredApps.count > 0) {
                            root.selectedIndex = Math.max(0, root.selectedIndex - 1)
                            appsList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                        }
                        event.accepted = true
                    }
                    Keys.onDownPressed: {
                        if (filteredApps.count > 0) {
                            root.selectedIndex = Math.min(filteredApps.count - 1, root.selectedIndex + 1)
                            appsList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                        }
                        event.accepted = true
                    }
                    Keys.onReturnPressed: { root.launch(); event.accepted = true }
                    Keys.onEnterPressed: { root.launch(); event.accepted = true }
                    Keys.onEscapePressed: { root.open = false; event.accepted = true }
                }

                Item { width: 12 }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#2a2e35" }

            // Loading state
            Text {
                visible: root.loading
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                leftPadding: 12
                text: "loading..."
                color: "#4a4f5a"
                font.family: "monospace"
                font.pixelSize: 12
                verticalAlignment: Text.AlignVCenter
            }

            // Empty state
            Text {
                visible: !root.loading && filteredApps.count === 0
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                leftPadding: 12
                text: "no results"
                color: "#4a4f5a"
                font.family: "monospace"
                font.pixelSize: 12
                verticalAlignment: Text.AlignVCenter
            }

            // App list
            ListView {
                id: appsList
                visible: !root.loading && filteredApps.count > 0
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(filteredApps.count, 12) * 34
                model: filteredApps
                clip: true

                delegate: Rectangle {
                    id: appRow
                    width: appsList.width
                    height: 34
                    color: index === root.selectedIndex ? "#1a1a1a" : (rowArea.containsMouse ? "#141414" : "#0f0f0f")

                    Rectangle {
                        width: 2
                        height: parent.height
                        color: index === root.selectedIndex ? "#c8ccd4" : "transparent"
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: model.name
                        color: index === root.selectedIndex ? "#ffffff" : "#c8ccd4"
                        font.family: "monospace"
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        id: rowArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: root.selectedIndex = index
                        onClicked: {
                            root.selectedIndex = index
                            root.launch()
                        }
                    }
                }
            }
        }
    }
}
