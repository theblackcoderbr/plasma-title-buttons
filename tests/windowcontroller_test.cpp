// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: 2026 Arthur Celestino

#include "windowcontroller.h"

#include <taskmanager/abstracttasksmodel.h>
#include <taskmanager/activityinfo.h>
#include <taskmanager/taskfilterproxymodel.h>
#include <taskmanager/tasksmodel.h>
#include <QGuiApplication>
#include <QIcon>
#include <QPixmap>
#include <QTemporaryDir>
#include <QTest>
#include <QSignalSpy>

class FakeWindows : public TaskManager::AbstractTasksModel
{
public:
    struct Window {
        QString title;
        QStringList activities;
        QVariantList desktops;
        QRect screen;
        bool attention = false;
        bool active = false;
        bool allDesktops = false;
        bool hidden = false;
        bool minimized = false;
        bool skipTaskbar = false;
        bool canClose = true;
        bool canMinimize = true;
        bool canMaximize = true;
        bool maximized = false;
        QVariant icon{};
        bool isWindow = true;
    };
    QList<Window> windows;
    int activated = -1;
    int closed = -1;
    int minimized = -1;
    int maximized = -1;
    mutable int windowReads = 0;
    mutable int titleReads = 0;

    int rowCount(const QModelIndex &parent = {}) const override { return parent.isValid() ? 0 : windows.size(); }
    QVariant data(const QModelIndex &index, int role) const override
    {
        if (!index.isValid() || index.row() >= windows.size()) {
            return {};
        }
        const auto &window = windows[index.row()];
        switch (role) {
        case Qt::DisplayRole: ++titleReads; return window.title;
        case Qt::DecorationRole: return window.icon;
        case IsWindow: ++windowReads; return window.isWindow;
        case IsMaximized: return window.maximized;
        case IsActive: return window.active;
        case Activities: return window.activities;
        case VirtualDesktops: return window.desktops;
        case ScreenGeometry: return window.screen;
        case IsDemandingAttention: return window.attention;
        case IsOnAllVirtualDesktops: return window.allDesktops;
        case IsHidden: return window.hidden;
        case IsMinimized: return window.minimized;
        case SkipTaskbar: return window.skipTaskbar;
        case IsClosable: return window.canClose;
        case IsMinimizable: return window.canMinimize;
        case IsMaximizable: return window.canMaximize;
        default: return {};
        }
    }
    void requestActivate(const QModelIndex &index) override { activated = index.row(); }
    void requestClose(const QModelIndex &index) override { closed = index.row(); }
    void requestToggleMinimized(const QModelIndex &index) override { minimized = index.row(); }
    void requestToggleMaximized(const QModelIndex &index) override { maximized = index.row(); }
};

class WindowControllerTest : public QObject
{
    Q_OBJECT
private Q_SLOTS:
    void emptyIconsAreNormalized()
    {
        FakeWindows source;
        source.windows = {{QStringLiteral("focused"), {}, {}, QRect(), false, true, true}};
        WindowController controller;
        auto *filter = controller.findChild<TaskManager::TaskFilterProxyModel *>(QString(), Qt::FindDirectChildrenOnly);
        QVERIFY(filter);
        filter->setSourceModel(&source);
        QPixmap pixmap(16, 16);
        pixmap.fill(Qt::red);
        const QIcon validIcon(pixmap);
        QSignalSpy changed(&controller, &WindowController::activeWindowChanged);
        for (int repetition = 0; repetition < 2; ++repetition) {
            source.windows[0].icon = validIcon;
            Q_EMIT source.dataChanged(source.index(0), source.index(0), {Qt::DecorationRole});
            QCOMPARE(controller.windowIcon().value<QIcon>().cacheKey(), validIcon.cacheKey());
            source.windows[0].icon = QIcon();
            Q_EMIT source.dataChanged(source.index(0), source.index(0), {Qt::DecorationRole});
            QVERIFY(!controller.windowIcon().isValid());
        }
        QCOMPARE(changed.count(), 4);
    }

    void selectiveStateUpdates()
    {
        FakeWindows source;
        source.windows = {
            {QStringLiteral("focused"), {}, {}, QRect(), false, true, true},
            {QStringLiteral("other"), {}, {}, QRect(), false, false, true},
        };
        WindowController controller;
        auto *filter = controller.findChild<TaskManager::TaskFilterProxyModel *>(QString(), Qt::FindDirectChildrenOnly);
        QVERIFY(filter);
        filter->setSourceModel(&source);
        QCOMPARE(controller.windowCount(), 2);
        QSignalSpy stateChanged(&controller, &WindowController::activeWindowChanged);
        QSignalSpy countChanged(&controller, &WindowController::windowCountChanged);
        source.windowReads = source.titleReads = 0;
        // Eventos reais atravessam o proxy, mas não provocam leitura do estado.
        for (int i = 0; i < 100; ++i) {
            Q_EMIT source.dataChanged(source.index(0), source.index(1), {TaskManager::AbstractTasksModel::IsKeepAbove});
        }
        QCOMPARE(source.titleReads, 0);
        QCOMPARE(source.windowReads, 0);
        QCOMPARE(stateChanged.count(), 0);
        source.windows[0].title = QStringLiteral("renamed");
        Q_EMIT source.dataChanged(source.index(0), source.index(0), {Qt::DisplayRole});
        QCOMPARE(controller.windowTitle(), QStringLiteral("renamed"));
        QCOMPARE(stateChanged.count(), 1);
        QCOMPARE(countChanged.count(), 0);
        QCOMPARE(source.windowReads, 2); // Uma passagem, sem lista intermediária.

        source.windows[0].icon = QStringLiteral("test-icon");
        source.windows[0].maximized = true;
        Q_EMIT source.dataChanged(source.index(0), source.index(0),
                                 {Qt::DecorationRole, TaskManager::AbstractTasksModel::IsMaximized});
        QCOMPARE(controller.windowIcon().toString(), QStringLiteral("test-icon"));
        QVERIFY(controller.isMaximized());
        QCOMPARE(stateChanged.count(), 2); // Uma atualização mesmo com vários papéis.
        source.windows[0].canClose = false;
        Q_EMIT source.dataChanged(source.index(0), source.index(0), {TaskManager::AbstractTasksModel::IsClosable});
        QVERIFY(!controller.canClose());
        source.windows[0].canMinimize = false;
        Q_EMIT source.dataChanged(source.index(0), source.index(0), {TaskManager::AbstractTasksModel::IsMinimizable});
        QVERIFY(!controller.canMinimize());
        source.windows[0].canMaximize = false;
        Q_EMIT source.dataChanged(source.index(0), source.index(0), {TaskManager::AbstractTasksModel::IsMaximizable});
        QVERIFY(!controller.canMaximize());
        source.windows[0].active = false;
        source.windows[1].active = true;
        Q_EMIT source.dataChanged(source.index(0), source.index(1), {TaskManager::AbstractTasksModel::IsActive});
        QCOMPARE(controller.windowTitle(), QStringLiteral("other"));
        source.windows[1].title = QStringLiteral("unspecified roles");
        Q_EMIT source.dataChanged(source.index(1), source.index(1));
        QCOMPARE(controller.windowTitle(), QStringLiteral("unspecified roles"));

        source.windows[1].isWindow = false;
        Q_EMIT source.dataChanged(source.index(1), source.index(1), {TaskManager::AbstractTasksModel::IsWindow});
        QCOMPARE(controller.windowCount(), 1);
        QVERIFY(!controller.hasActiveWindow());
        source.windows[1].isWindow = true;
        Q_EMIT source.dataChanged(source.index(1), source.index(1), {TaskManager::AbstractTasksModel::IsWindow});
        QCOMPARE(controller.windowCount(), 2);
        QVERIFY(controller.hasActiveWindow());

        // SkipTaskbar não é um papel exibido, mas altera a estrutura do proxy.
        source.windows[1].skipTaskbar = true;
        Q_EMIT source.dataChanged(source.index(1), source.index(1), {TaskManager::AbstractTasksModel::SkipTaskbar});
        QCOMPARE(controller.windowCount(), 1);
        QVERIFY(!controller.hasActiveWindow());
        QCOMPARE(controller.windowTitle(), QStringLiteral("Plasma Workspace"));
        source.windows[1].skipTaskbar = false;
        Q_EMIT source.dataChanged(source.index(1), source.index(1), {TaskManager::AbstractTasksModel::SkipTaskbar});
        QCOMPARE(controller.windowCount(), 2);
        QCOMPARE(controller.windowTitle(), QStringLiteral("unspecified roles"));
    }

    void actionsRespectCapabilities()
    {
        FakeWindows source;
        source.windows = {{QStringLiteral("focused"), {}, {}, QRect(), false, true, true}};
        WindowController controller;
        auto *filter = controller.findChild<TaskManager::TaskFilterProxyModel *>(QString(), Qt::FindDirectChildrenOnly);
        QVERIFY(filter);
        filter->setSourceModel(&source);
        for (int mask = 0; mask < 8; ++mask) {
            source.windows[0].canClose = mask & 1;
            source.windows[0].canMinimize = mask & 2;
            source.windows[0].canMaximize = mask & 4;
            Q_EMIT source.dataChanged(source.index(0), source.index(0));
            QCOMPARE(controller.canClose(), bool(mask & 1));
            QCOMPARE(controller.canMinimize(), bool(mask & 2));
            QCOMPARE(controller.canMaximize(), bool(mask & 4));
            source.closed = source.minimized = source.maximized = -1;
            controller.close();
            controller.minimize();
            controller.toggleMaximize();
            QCOMPARE(source.closed, mask & 1 ? 0 : -1);
            QCOMPARE(source.minimized, mask & 2 ? 0 : -1);
            QCOMPARE(source.maximized, mask & 4 ? 0 : -1);
        }
    }

    void actionsIgnoreActiveNonWindows()
    {
        FakeWindows source;
        source.windows = {
            {QStringLiteral("active non-window"), {}, {}, QRect(), false, true, true},
            {QStringLiteral("real window"), {}, {}, QRect(), false, false, true},
        };
        // Mantém todas as capacidades verdadeiras para testar especificamente IsWindow.
        source.windows[0].isWindow = false;
        WindowController controller;
        auto *filter = controller.findChild<TaskManager::TaskFilterProxyModel *>(QString(), Qt::FindDirectChildrenOnly);
        QVERIFY(filter);
        filter->setSourceModel(&source);
        QCOMPARE(filter->rowCount(), 2);
        QVERIFY(!controller.hasActiveWindow());
        controller.close();
        controller.minimize();
        controller.toggleMaximize();
        QCOMPARE(source.closed, -1);
        QCOMPARE(source.minimized, -1);
        QCOMPARE(source.maximized, -1);

        // Um item não-janela ativo antes da janela real não pode capturar as ações.
        source.windows[1].active = true;
        Q_EMIT source.dataChanged(source.index(1), source.index(1), {TaskManager::AbstractTasksModel::IsActive});
        QCOMPARE(controller.windowTitle(), QStringLiteral("real window"));
        controller.close();
        controller.minimize();
        controller.toggleMaximize();
        QCOMPARE(source.closed, 1);
        QCOMPARE(source.minimized, 1);
        QCOMPARE(source.maximized, 1);
    }

    void cycleSingleWindow_data()
    {
        QTest::addColumn<int>("direction");
        QTest::addColumn<bool>("active");
        QTest::addColumn<bool>("available");
        for (int direction : {-1, 0, 1}) {
            for (bool active : {false, true}) {
                for (bool available : {false, true}) {
                    const QByteArray name = QByteArray::number(direction) + '-' + QByteArray::number(active)
                        + '-' + QByteArray::number(available);
                    QTest::newRow(name.constData()) << direction << active << available;
                }
            }
        }
    }

    void cycleSingleWindow()
    {
        QFETCH(int, direction);
        QFETCH(bool, active);
        QFETCH(bool, available);
        FakeWindows source;
        const QRect screen(0, 0, 1920, 1080);
        // O foco em outro monitor não deve impedir a ativação da janela local.
        source.windows = {
            {QStringLiteral("other screen"), {QStringLiteral("A")}, {1}, QRect(1920, 0, 1920, 1080), false, !active},
        };
        if (available) {
            // Sem foco, simula uma janela minimizada e oculta pelo compositor.
            source.windows.append({QStringLiteral("local"), {QStringLiteral("A")}, {1}, screen, false, active, false, !active, !active});
        }
        WindowController controller;
        auto *filter = controller.findChild<TaskManager::TaskFilterProxyModel *>(QString(), Qt::FindDirectChildrenOnly);
        QVERIFY(filter);
        filter->setFilterByCurrentVirtualDesktop(false);
        filter->setVirtualDesktop(1);
        filter->setActivity(QStringLiteral("A"));
        controller.setScreenGeometry(screen);
        filter->setSourceModel(&source);
        QCOMPARE(controller.windowCount(), available ? 1 : 0);
        controller.cycleWindow(direction);
        QCOMPARE(source.activated, available && !active && direction != 0 ? 1 : -1);
    }

    void followsActivityNotifications()
    {
        WindowController controller;
        auto *filter = controller.findChild<TaskManager::TaskFilterProxyModel *>(QString(), Qt::FindDirectChildrenOnly);
        auto *activity = controller.findChild<TaskManager::ActivityInfo *>(QString(), Qt::FindDirectChildrenOnly);
        QVERIFY(filter);
        QVERIFY(activity);
        QCOMPARE(filter->activity(), activity->currentActivity());
        QVERIFY(filter->filterByCurrentVirtualDesktop());
        QVERIFY(filter->filterByActivity());
        QVERIFY(!filter->demandingAttentionSkipsFilters());
        QVERIFY(!filter->filterHidden());
        QVERIFY(!filter->filterMinimized());
        auto *source = qobject_cast<TaskManager::TasksModel *>(filter->sourceModel());
        QVERIFY(source);
        QCOMPARE(source->groupMode(), TaskManager::TasksModel::GroupDisabled);

        // Exercita a conexão real do controlador sem mudar atividades da sessão do usuário.
        filter->setActivity(QStringLiteral("outdated-activity"));
        QVERIFY(QMetaObject::invokeMethod(activity, "currentActivityChanged"));
        QCOMPARE(filter->activity(), activity->currentActivity());
    }

    void attentionCannotEscapeFiltersOrReceiveActions()
    {
        FakeWindows source;
        const QRect screen(0, 0, 1920, 1080);
        const QRect otherScreen(1920, 0, 1920, 1080);
        source.windows = {
            {QStringLiteral("other activity"), {QStringLiteral("B")}, {1}, screen, true, true},
            {QStringLiteral("other desktop"), {QStringLiteral("A")}, {2}, screen, true, false, false, true, true},
            {QStringLiteral("other screen"), {QStringLiteral("A")}, {1}, otherScreen, true, false, false, true, true},
            {QStringLiteral("focused"), {QStringLiteral("A")}, {1}, screen, true, true},
            {QStringLiteral("next minimized"), {QStringLiteral("A")}, {1}, screen, false, false, false, true, true},
            {QStringLiteral("all contexts minimized"), {}, {}, screen, false, false, true, true, true},
            {QStringLiteral("skip taskbar"), {QStringLiteral("A")}, {1}, screen, true, false, false, true, false, true},
        };
        WindowController controller;
        auto *filter = controller.findChild<TaskManager::TaskFilterProxyModel *>(QString(), Qt::FindDirectChildrenOnly);
        QVERIFY(filter);
        // Usa um desktop explícito porque o teste não tem compositor/monitores reais.
        filter->setFilterByCurrentVirtualDesktop(false);
        filter->setVirtualDesktop(1);
        filter->setActivity(QStringLiteral("A"));
        controller.setScreenGeometry(screen);
        filter->setSourceModel(&source);
        QCOMPARE(controller.windowCount(), 3);
        QCOMPARE(controller.windowTitle(), QStringLiteral("focused"));
        controller.close();
        controller.minimize();
        controller.toggleMaximize();
        QCOMPARE(source.closed, 3);
        QCOMPARE(source.minimized, 3);
        QCOMPARE(source.maximized, 3);
        controller.cycleWindow(1);
        QCOMPARE(source.activated, 4);
        controller.cycleWindow(-1);
        QCOMPARE(source.activated, 5);

        filter->setActivity(QStringLiteral("B"));
        QCOMPARE(controller.windowCount(), 2);
        QCOMPARE(controller.windowTitle(), QStringLiteral("other activity"));
        filter->setActivity(QStringLiteral("A"));
        filter->setVirtualDesktop(2);
        QCOMPARE(controller.windowCount(), 2);
        QVERIFY(!controller.hasActiveWindow());
        QCOMPARE(controller.windowTitle(), QStringLiteral("Plasma Workspace"));
        controller.close();
        QCOMPARE(source.closed, 3); // Nenhuma nova ação em janela fora do contexto.

        filter->setVirtualDesktop(1);
        controller.setScreenGeometry(otherScreen);
        QCOMPARE(controller.windowCount(), 1);
        QVERIFY(!controller.hasActiveWindow());
    }
};

int main(int argc, char **argv)
{
    QTemporaryDir temporary;
    if (!temporary.isValid()) {
        return 1;
    }
    qputenv("XDG_CONFIG_HOME", temporary.path().toUtf8());
    qputenv("XDG_CONFIG_DIRS", temporary.path().toUtf8());
    QGuiApplication app(argc, argv);
    WindowControllerTest test;
    return QTest::qExec(&test, argc, argv);
}

#include "windowcontroller_test.moc"
