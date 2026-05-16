import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: workspacesRoot

    spacing: 2

    property list<bool> workspaceOccupied: []
    property int effectiveActiveWorkspaceId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
    property int workspacesShown: 10
    property int workspaceGroup: Math.floor((effectiveActiveWorkspaceId - 1) / workspacesShown)
    property int workspaceIndexInGroup: (effectiveActiveWorkspaceId - 1) % workspacesShown

    function updateWorkspaceOccupied() {
        workspaceOccupied = Array.from({ length: workspacesShown }, (_, i) => {
            var targetWs = workspaceGroup * workspacesShown + i + 1;
            return Hyprland.workspaces.values.some(function(ws) { return ws.id === targetWs; });
        });
    }

    Component.onCompleted: updateWorkspaceOccupied()

    Connections {
        target: Hyprland.workspaces
        function onValuesChanged() { updateWorkspaceOccupied(); }
    }

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() { updateWorkspaceOccupied(); }
    }

    onWorkspaceGroupChanged: updateWorkspaceOccupied()

    Repeater {
        model: workspacesShown

        delegate: Item {
            property int workspaceValue: workspaceGroup * workspacesShown + index + 1
            property bool isActive: effectiveActiveWorkspaceId === workspaceValue
            property bool occupied: workspaceOccupied[index] === true

            implicitWidth: label.width + 4
            implicitHeight: 28

            Text {
                id: label
                anchors.centerIn: parent
                text: isActive ? "[" + parent.workspaceValue + "]"
                                : (parent.occupied ? "[" + parent.workspaceValue + "]"
                                                   : " " + parent.workspaceValue + " ")
                font.family: "monospace"
                font.pixelSize: 13
                color: parent.isActive ? "#ffffff"
                                       : (parent.occupied ? "#c8ccd4" : "#4a4f5a")
                opacity: parent.isActive ? 1.0 : (parent.occupied ? 0.85 : 0.45)
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Hyprland.dispatch("workspace " + parent.workspaceValue)
            }
        }
    }

    WheelHandler {
        onWheel: (event) => {
            if (event.angleDelta.y < 0)
                Hyprland.dispatch("workspace r+1");
            else if (event.angleDelta.y > 0)
                Hyprland.dispatch("workspace r-1");
        }
    }
}
