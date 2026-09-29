import QtQuick
import org.kde.taskmanager as TaskManager
import org.kde.plasma.plasma5support as Plasma5Support

Item {
    id: root

    property rect screenGeometry

    property bool hasActiveWindow: false
    property string windowTitle: "Plasma Workspace"
    property var windowIcon: undefined
    property bool isMaximized: false
    property bool canMaximize: false
    property bool canMinimize: false
    property bool canClose: false
    property int windowCount: 0
    property bool borderlessMaximized: false

    TaskManager.TasksModel {
        id: tasksModel

        filterByScreen: true
        screenGeometry: root.screenGeometry
        filterByVirtualDesktop: true
        filterByCurrentVirtualDesktop: true
        filterByActivity: true
        filterHidden: true

        onCountChanged: root.updateState()
        onActiveTaskChanged: root.updateState()
        onDataChanged: root.updateState()
        onModelReset: root.updateState()
        onRowsInserted: root.updateState()
        onRowsRemoved: root.updateState()
    }

    onScreenGeometryChanged: {
        tasksModel.screenGeometry = root.screenGeometry;
        updateState();
    }

    function activeModelIndex() {
        for (let i = 0; i < tasksModel.count; ++i) {
            let idx = tasksModel.index(i, 0);
            if (tasksModel.data(idx, TaskManager.AbstractTasksModel.IsActive)) {
                return idx;
            }
        }
        return null;
    }

    function validWindowIndices() {
        let list = [];
        for (let i = 0; i < tasksModel.count; ++i) {
            let idx = tasksModel.index(i, 0);
            if (tasksModel.data(idx, TaskManager.AbstractTasksModel.IsWindow)) {
                list.push(idx);
            }
        }
        return list;
    }

    function updateState() {
        let wins = validWindowIndices();
        root.windowCount = wins.length;

        let active = activeModelIndex();
        if (active && tasksModel.data(active, TaskManager.AbstractTasksModel.IsWindow)) {
            root.hasActiveWindow = true;
            let t = tasksModel.data(active, Qt.DisplayRole);
            root.windowTitle = (t && t.toString().trim().length > 0) ? t.toString() : "Plasma Workspace";
            root.windowIcon = tasksModel.data(active, Qt.DecorationRole);
            root.isMaximized = tasksModel.data(active, TaskManager.AbstractTasksModel.IsMaximized) || false;
            root.canMaximize = tasksModel.data(active, TaskManager.AbstractTasksModel.IsMaximizable) || false;
            root.canMinimize = tasksModel.data(active, TaskManager.AbstractTasksModel.IsMinimizable) || false;
            root.canClose = tasksModel.data(active, TaskManager.AbstractTasksModel.IsClosable) || false;
        } else {
            root.hasActiveWindow = false;
            root.windowTitle = "Plasma Workspace";
            root.windowIcon = undefined;
            root.isMaximized = false;
            root.canMaximize = false;
            root.canMinimize = false;
            root.canClose = false;
        }
    }

    function toggleMaximize() {
        let active = activeModelIndex();
        if (active) {
            tasksModel.requestToggleMaximized(active);
        }
    }

    function minimize() {
        let active = activeModelIndex();
        if (active) {
            tasksModel.requestToggleMinimized(active);
        }
    }

    function close() {
        let active = activeModelIndex();
        if (active) {
            tasksModel.requestClose(active);
        }
    }

    function cycleWindow(direction) {
        if (!direction) return;
        let wins = validWindowIndices();
        if (wins.length <= 1) return;

        let currentPos = -1;
        for (let i = 0; i < wins.length; ++i) {
            if (tasksModel.data(wins[i], TaskManager.AbstractTasksModel.IsActive)) {
                currentPos = i;
                break;
            }
        }

        let nextPos = 0;
        if (currentPos !== -1) {
            if (direction > 0) {
                nextPos = (currentPos + 1) % wins.length;
            } else {
                nextPos = (currentPos - 1 + wins.length) % wins.length;
            }
        }

        tasksModel.requestActivate(wins[nextPos]);
    }

    Plasma5Support.DataSource {
        id: kwinConfigRunner
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            disconnectSource(sourceName);
        }
    }

    function setBorderlessMaximized(enabled) {
        root.borderlessMaximized = enabled;
        let val = enabled ? "true" : "false";
        let cmd = "kwriteconfig6 --file kwinrc --group Windows --key BorderlessMaximizedWindows " + val + " && (qdbus org.kde.KWin /KWin reconfigure || busctl --user call org.kde.KWin /KWin org.kde.KWin reconfigure)";
        kwinConfigRunner.connectSource(cmd);
    }

    Component.onCompleted: {
        updateState();
    }
}
