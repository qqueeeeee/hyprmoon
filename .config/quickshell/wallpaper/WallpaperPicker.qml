import QtQuick 2.0
import QtQuick.Controls 2.15
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: root
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    visible: false
    color: "#0f0f0f"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    property bool open: false
    onOpenChanged: {
        visible = open
        if (open) {
            searchInput.text = ""
            focusedIndex = -1
            folderModel.folder = Qt.resolvedUrl(wallpaperDir)
            focusScope.focus = true
        }
    }

    property string wallpaperDir: "/home/que/Pictures/Wallpapers/"
    property string searchQuery: ""
    property list<string> extensions: ["jpg", "jpeg", "png", "webp", "gif"]
    property int focusedIndex: -1

    FolderListModel {
        id: folderModel
        folder: Qt.resolvedUrl(root.wallpaperDir)
        caseSensitive: false
        nameFilters: root.extensions.map(ext => `*.${ext}`)
        showDirs: false
        showDotAndDotDot: false
        showOnlyReadable: true
        sortField: FolderListModel.Time
        sortReversed: false
    }

    function filterWallpapers() {
        if (searchQuery === "") {
            gridView.model = folderModel
        } else {
            var filtered = []
            var queryParts = searchQuery.split(" ").filter(s => s.length > 0)
            for (var i = 0; i < folderModel.count; i++) {
                var filePath = folderModel.get(i, "filePath")
                if (!filePath) continue
                var fileName = filePath.split("/").pop().toLowerCase()
                var matches = queryParts.every(part => fileName.indexOf(part.toLowerCase()) !== -1)
                if (matches) filtered.push({ filePath: filePath })
            }
            gridView.model = filteredModel
            filteredModel.clear()
            for (var j = 0; j < filtered.length; j++) {
                filteredModel.append(filtered[j])
            }
        }
        focusedIndex = -1
    }

    ListModel {
        id: filteredModel
    }

    function setWallpaper(filePath) {
        print("Setting wallpaper: " + filePath)
        Quickshell.execDetached(["bash", "-c", "/home/que/.config/quickshell/wallpaper/set-wallpaper.sh \"" + filePath + "\""])
        root.open = false
    }

    function moveSelectionLeft() {
        if (gridView.model.count > 0) {
            focusedIndex = Math.max(0, focusedIndex - 1)
            gridView.currentIndex = focusedIndex
            gridView.positionViewAtIndex(focusedIndex, GridView.Contain)
        }
    }

    function moveSelectionRight() {
        if (gridView.model.count > 0) {
            focusedIndex = Math.min(gridView.model.count - 1, focusedIndex + 1)
            gridView.currentIndex = focusedIndex
            gridView.positionViewAtIndex(focusedIndex, GridView.Contain)
        }
    }

    function moveSelectionUp() {
        if (gridView.model.count > 0) {
            var cols = 4
            focusedIndex = Math.max(0, focusedIndex - cols)
            gridView.currentIndex = focusedIndex
            gridView.positionViewAtIndex(focusedIndex, GridView.Contain)
        }
    }

    function moveSelectionDown() {
        if (gridView.model.count > 0) {
            var cols = 4
            focusedIndex = Math.min(gridView.model.count - 1, focusedIndex + cols)
            gridView.currentIndex = focusedIndex
            gridView.positionViewAtIndex(focusedIndex, GridView.Contain)
        }
    }

    FocusScope {
        id: focusScope
        anchors.fill: parent
        activeFocusOnTab: true

        // Header
        Rectangle {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 28
            color: "#0f0f0f"

            Text {
                text: "WALLPAPERS"
                color: "#4a4f5a"
                font.family: "monospace"
                font.pixelSize: 10
                font.letterSpacing: 2
                verticalAlignment: Text.AlignVCenter
                leftPadding: 12
            }

            Rectangle {
                width: 28
                height: 28
                anchors.right: parent.right
                color: "transparent"
                Text {
                    text: "×"
                    color: "#c8ccd4"
                    anchors.centerIn: parent
                    font.pixelSize: 14
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.open = false
                }
            }
        }

        // Search bar
        Rectangle {
            id: searchBar
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 28
            color: "#0f0f0f"
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 1
                color: "#2a2e35"
            }
            TextInput {
                id: searchInput
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: 12
                rightPadding: 12
                color: "#c8ccd4"
                font.family: "monospace"
                font.pixelSize: 11
                onTextChanged: {
                    root.searchQuery = text
                    filterWallpapers()
                }
            }
        }

        // Grid view
        GridView {
            id: gridView
            anchors.top: searchBar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.topMargin: 16
            anchors.bottomMargin: 16
            model: folderModel
            cellWidth: 200
            cellHeight: 130
            highlightFollowsCurrentItem: true
            currentIndex: -1
            delegate: Rectangle {
                id: cell
                width: 200
                height: 130
                color: "#0f0f0f"
                border.width: 1
                border.color: "#2a2e35"
                radius: 2

                property bool isSelected: index === gridView.currentIndex

                // Selection highlight - outer glow effect
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -3
                    color: "transparent"
                    visible: isSelected
                    border.width: 3
                    border.color: "#c8ccd4"
                    radius: 4
                }
                Rectangle {
                    anchors.fill: parent
                    color: "#1a1a1a"
                    visible: isSelected
                    opacity: 0.3
                }

                Image {
                    id: wallpaperImg
                    anchors.fill: parent
                    source: model.filePath
                    fillMode: Image.PreserveAspectCrop
                    clip: true
                }

                Rectangle {
                    height: 20
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    color: "#CC0f0f0f"
                    Text {
                        text: (model.filePath.split("/").pop())
                        color: "#c8ccd4"
                        font.family: "monospace"
                        font.pixelSize: 9
                        elide: Text.ElideRight
                        anchors.verticalCenter: parent.verticalCenter
                        leftPadding: 6
                        rightPadding: 6
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.setWallpaper(model.filePath)
                }
            }
        }

        // Keyboard handling
        Keys.onEscapePressed: root.open = false
        Keys.onPressed: {
            if (event.key === Qt.Key_H || event.key === Qt.Key_Left) {
                moveSelectionLeft()
                event.accepted = true
            } else if (event.key === Qt.Key_J || event.key === Qt.Key_Down) {
                moveSelectionDown()
                event.accepted = true
            } else if (event.key === Qt.Key_K || event.key === Qt.Key_Up) {
                moveSelectionUp()
                event.accepted = true
            } else if (event.key === Qt.Key_L || event.key === Qt.Key_Right) {
                moveSelectionRight()
                event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (focusedIndex >= 0 && focusedIndex < gridView.model.count) {
                    var item = gridView.model.get(focusedIndex)
                    if (item && item.filePath) root.setWallpaper(item.filePath)
                }
                event.accepted = true
            } else if (event.key === Qt.Key_Space) {
                if (gridView.model.count > 0) {
                    var idx = focusedIndex >= 0 ? focusedIndex : 0
                    var currentItem = gridView.model.get(idx)
                    if (currentItem && currentItem.filePath) root.setWallpaper(currentItem.filePath)
                }
                event.accepted = true
            }
        }
    }
}