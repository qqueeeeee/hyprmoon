import Quickshell
import Quickshell.Services.Notifications
import QtQuick

// Owns the DBus notification server, history model, and DND toggle.
// Spawn one of these per ShellRoot; consumers read .history, .unreadCount, .dnd.
Item {
    id: daemon

    property bool dnd: false
    property int unreadCount: 0
    property int historyCount: 0
    property ListModel history: ListModel { id: historyModel }
    property ListModel toasts: ListModel { id: toastModel }

    signal toastAdded(int notifId)

    function timeAgo(ms) {
        var d = (Date.now() - ms) / 1000;
        if (d < 60) return "now";
        if (d < 3600) return Math.floor(d / 60) + "m";
        if (d < 86400) return Math.floor(d / 3600) + "h";
        return Math.floor(d / 86400) + "d";
    }

    function refreshTimes() {
        for (var i = 0; i < historyModel.count; i++) {
            var entry = historyModel.get(i);
            historyModel.setProperty(i, "timeLabel", timeAgo(entry.createdAt));
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: daemon.refreshTimes()
    }

    function dismiss(id) {
        for (var i = 0; i < historyModel.count; i++) {
            if (historyModel.get(i).notifId === id) {
                historyModel.remove(i);
                daemon.historyCount = historyModel.count;
                if (daemon.unreadCount > 0) daemon.unreadCount = daemon.unreadCount - 1;
                break;
            }
        }
        for (var j = 0; j < toastModel.count; j++) {
            if (toastModel.get(j).notifId === id) {
                toastModel.remove(j);
                break;
            }
        }
    }

    function dismissToast(id) {
        for (var j = 0; j < toastModel.count; j++) {
            if (toastModel.get(j).notifId === id) {
                toastModel.remove(j);
                break;
            }
        }
    }

    function clearAll() {
        historyModel.clear();
        toastModel.clear();
        daemon.historyCount = 0;
        daemon.unreadCount = 0;
    }

    function markRead() {
        daemon.unreadCount = 0;
    }

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: false
        bodySupported: true
        bodyMarkupSupported: false
        imageSupported: false
        persistenceSupported: true

        onNotification: function(notif) {
            notif.tracked = true;
            var id = notif.id;
            var entry = {
                notifId: id,
                appName: notif.appName || "",
                summary: notif.summary || "",
                body: notif.body || "",
                urgency: notif.urgency ? notif.urgency.toString() : "normal",
                createdAt: Date.now(),
                timeLabel: "now"
            };
            historyModel.insert(0, entry);
            // cap history at 50
            while (historyModel.count > 50) historyModel.remove(historyModel.count - 1);
            daemon.historyCount = historyModel.count;

            if (!daemon.dnd) {
                daemon.unreadCount = daemon.unreadCount + 1;
                toastModel.append(entry);
                daemon.toastAdded(id);
                // auto-trim toasts so we never stack more than 4 on-screen
                while (toastModel.count > 4) toastModel.remove(0);
            }
        }
    }
}
