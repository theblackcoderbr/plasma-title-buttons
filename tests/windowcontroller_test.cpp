// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: 2026 Arthur Celestino

#include "windowcontroller.h"

#include <taskmanager/abstracttasksmodel.h>
#include <taskmanager/activityinfo.h>
#include <taskmanager/taskfilterproxymodel.h>
#include <taskmanager/tasksmodel.h>
#include <QGuiApplication>
#include <QTemporaryDir>
#include <QTest>

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
    };
    QList<Window> windows;
    int activated = -1;
    int closed = -1;
    int minimized = -1;
    int maximized = -1;

    int rowCount(const QModelIndex &parent = {}) const override { return parent.isValid() ? 0 : windows.size(); }
    QVariant data(const QModelIndex &index, int role) const override
    {
        if (!index.isValid() || index.row() >= windows.size()) {
            return {};
        }
        const auto &window = windows[index.row()];
        switch (role) {
        case Qt::DisplayRole: return window.title;
        case IsWindow: return true;
        case IsActive: return window.active;
        case Activities: return window.activities;
        case VirtualDesktops: return window.desktops;
        case ScreenGeometry: return window.screen;
        case IsDemandingAttention: return window.attention;
        case IsOnAllVirtualDesktops: return window.allDesktops;
        case IsHidden: return window.hidden;
        case IsMinimized: return window.minimized;
        case SkipTaskbar: return window.skipTaskbar;
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
