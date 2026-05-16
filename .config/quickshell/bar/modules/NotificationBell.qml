import QtQuick
import QtQuick.Layouts

Item {
    id: root
    required property var screen
    property var store: null
    property bool drawerOpen: false

    property int unreadCount: store ? store.unreadCount : 0
    property int totalCount: store ? store.historyCount : 0
    property bool dnd: store ? store.dnd : false

    signal toggleDrawer()

    implicitHeight: 28
    implicitWidth: visible ? labelText.width + 8 : 0
    visible: unreadCount > 0 || dnd || drawerOpen

    Text {
        id: labelText
        anchors.centerIn: parent
        text: root.dnd ? "[N:dnd]"
              : root.unreadCount > 0 ? "[N:" + root.unreadCount + "]"
              : "[N]"
        color: root.drawerOpen ? "#ffffff"
               : (root.dnd ? "#4a4f5a"
               : (root.unreadCount > 0 ? "#c8ccd4" : "#4a4f5a"))
        font.family: "monospace"
        font.pixelSize: 12
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.toggleDrawer()
    }
}
