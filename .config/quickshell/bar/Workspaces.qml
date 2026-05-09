import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: workspacesRoot

    spacing: 8

    Item {
        width: 8
    }

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
        function onValuesChanged() {
            updateWorkspaceOccupied();
        }
    }

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            updateWorkspaceOccupied();
        }
    }

    onWorkspaceGroupChanged: {
        updateWorkspaceOccupied();
    }

    Repeater {
        model: workspacesShown

        delegate: Text {
            property int workspaceValue: workspaceGroup * workspacesShown + index + 1

            text: workspaceValue
            font.family: "monospace"
            font.pixelSize: 13
            color: (workspaceOccupied[index] && effectiveActiveWorkspaceId === workspaceValue) ? "#ffffff" : "#4a4f5a"
            opacity: workspaceOccupied[index] ? 1 : 0.3

            MouseArea {
                anchors.fill: parent
                onClicked: Hyprland.dispatch("workspace " + workspaceValue)
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