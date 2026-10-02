// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: 2026 Arthur Celestino

#include "kwinsettings.h"

#include <KConfig>
#include <KConfigGroup>
#include <KLocalizedContext>
#include <QDBusConnection>
#include <QDBusContext>
#include <QDir>
#include <QFile>
#include <QGuiApplication>
#include <QQmlComponent>
#include <QQmlContext>
#include <QQmlEngine>
#include <QQuickItem>
#include <QQuickWindow>
#include <QSaveFile>
#include <QSignalSpy>
#include <QTemporaryDir>
#include <QTest>
#include <QWheelEvent>
#include <QAccessible>

class FakeKWin : public QObject, protected QDBusContext
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.kde.KWin")
public:
    int calls = 0;
    bool fail = false;
public Q_SLOTS:
    void reconfigure()
    {
        ++calls;
        if (fail) {
            sendErrorReply(QDBusError::Failed, QStringLiteral("Simulated reload failure"));
        }
    }
};

class KWinSettingsTest : public QObject
{
    Q_OBJECT
    FakeKWin m_kwin;

    QString path() const { return qEnvironmentVariable("XDG_CONFIG_HOME") + QStringLiteral("/kwinrc"); }
    void writeConfig(const QByteArray &data)
    {
        QSaveFile file(path());
        QVERIFY(file.open(QIODevice::WriteOnly));
        QCOMPARE(file.write(data), data.size());
        QVERIFY(file.commit());
    }
    QByteArray readConfig()
    {
        QFile file(path());
        if (!file.open(QIODevice::ReadOnly)) {
            return {};
        }
        return file.readAll();
    }

private Q_SLOTS:
    void verticalPanelGeometry_data()
    {
        QTest::addColumn<QString>("style");
        QTest::addColumn<int>("thickness");
        for (const QString &style : {QStringLiteral("system"), QStringLiteral("macos"), QStringLiteral("minimal")}) {
            for (int thickness : {24, 26, 44}) {
                const QByteArray name = style.toUtf8() + QByteArray::number(thickness);
                QTest::newRow(name.constData()) << style << thickness;
            }
        }
    }

    void verticalPanelGeometry()
    {
        QFETCH(QString, style);
        QFETCH(int, thickness);
        QQmlEngine engine;
        engine.rootContext()->setContextObject(new KLocalizedContext(&engine));
        QQuickWindow window;
        window.resize(thickness, 800);
        QQmlComponent component(&engine);
        component.setData(R"(
            import QtQuick
            Item {
                width: 26; height: 800
                QtObject {
                    id: fakeController
                    property string windowTitle: "A very long window title ".repeat(100)
                    property bool hasActiveWindow: true
                    property bool isMaximized: true
                    property bool canClose: true
                    property bool canMinimize: true
                    property bool canMaximize: true
                    property int calls: 0
                    function close() { calls++; }
                    function minimize() { calls++; }
                    function toggleMaximize() { calls++; }
                    objectName: "controller"
                }
                PanelAxis {
                    id: axis; objectName: "axis"; vertical: true
                    WindowButtons {
                        id: buttons; objectName: "buttons"
                        controller: fakeController
                        vertical: axis.vertical
                        panelThickness: axis.height
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    PanelCenteredTitle {
                        objectName: "title"
                        controller: fakeController
                        vertical: axis.vertical
                        panelThickness: axis.height
                        showIcon: false
                        panelLength: 1000; panelOffset: 100
                        leftInset: buttons.width + 6
                    }
                }
            }
        )", QUrl::fromLocalFile(QStringLiteral(CONFIG_QML_PATH)));
        QScopedPointer<QObject> fixture(component.create());
        QVERIFY2(fixture, qPrintable(component.errorString()));
        auto *item = qobject_cast<QQuickItem *>(fixture.data());
        item->setWidth(thickness);
        item->setParentItem(window.contentItem());
        auto *axis = fixture->findChild<QQuickItem *>(QStringLiteral("axis"));
        auto *buttons = fixture->findChild<QQuickItem *>(QStringLiteral("buttons"));
        auto *title = fixture->findChild<QQuickItem *>(QStringLiteral("title"));
        QVERIFY(axis && buttons && title);
        buttons->setProperty("buttonStyle", style);
        window.show();
        QVERIFY(QTest::qWaitForWindowExposed(&window));
        QTRY_COMPARE(title->width(), 520.0);
        QCOMPARE(axis->width(), 800.0);
        QCOMPARE(axis->height(), qreal(thickness));
        const auto center = title->mapToScene(QPointF(title->width() / 2, title->height() / 2));
        QVERIFY(qAbs(center.x() - thickness / 2.0) < 0.01);
        QVERIFY(qAbs(center.y() - 400) < 0.01);
        qreal previousBottom = -1;
        for (const QString &action : {QStringLiteral("minimize"), QStringLiteral("maximize"), QStringLiteral("close")}) {
            auto *button = fixture->findChild<QQuickItem *>(style + QLatin1Char('-') + action);
            QVERIFY(button);
            const QRectF rect = button->mapRectToScene(QRectF(0, 0, button->width(), button->height()));
            QVERIFY(rect.left() >= -0.01 && rect.right() <= thickness + 0.01);
            QVERIFY(rect.top() >= previousBottom);
            previousBottom = rect.bottom();
            QTest::mouseClick(&window, Qt::LeftButton, Qt::NoModifier, rect.center().toPoint());
        }
        QCOMPARE(fixture->findChild<QObject *>(QStringLiteral("controller"))->property("calls").toInt(), 3);
        // O título respeita a reserva dos botões quando o centro não cabe.
        title->setProperty("panelOffset", 490);
        const QRectF titleRect = title->mapRectToScene(QRectF(0, 0, title->width(), title->height()));
        QVERIFY(titleRect.top() >= previousBottom);
        // Trocar a orientação reutiliza a mesma geometria, sem recriar o conteúdo.
        item->setWidth(800);
        item->setHeight(thickness);
        axis->setProperty("vertical", false);
        QCOMPARE(axis->width(), 800.0);
        QCOMPARE(axis->height(), qreal(thickness));
        QCOMPARE(axis->rotation(), 0.0);
    }

    void windowButtonsAreAccessible_data()
    {
        QTest::addColumn<QString>("style");
        QTest::newRow("system") << QStringLiteral("system");
        QTest::newRow("macos") << QStringLiteral("macos");
        QTest::newRow("minimal") << QStringLiteral("minimal");
    }

    void windowButtonsAreAccessible()
    {
        QFETCH(QString, style);
        QQmlEngine engine;
        engine.rootContext()->setContextObject(new KLocalizedContext(&engine));
        QQuickWindow window;
        window.resize(200, 40);
        QQmlComponent component(&engine);
        component.setData(R"(
            import QtQuick
            WindowButtons {
                controller: QtObject {
                    objectName: "controller"
                    property bool hasActiveWindow: true
                    property bool isMaximized: false
                    property bool canClose: true
                    property bool canMinimize: true
                    property bool canMaximize: true
                    property int closeCalls: 0
                    property int minimizeCalls: 0
                    property int maximizeCalls: 0
                    function close() { closeCalls++; }
                    function minimize() { minimizeCalls++; }
                    function toggleMaximize() { maximizeCalls++; }
                }
            }
        )", QUrl::fromLocalFile(QStringLiteral(CONFIG_QML_PATH)));
        QScopedPointer<QObject> buttons(component.create());
        QVERIFY2(buttons, qPrintable(component.errorString()));
        buttons->setProperty("buttonStyle", style);
        auto *item = qobject_cast<QQuickItem *>(buttons.data());
        QVERIFY(item);
        item->setParentItem(window.contentItem());
        window.show();
        QVERIFY(QTest::qWaitForWindowExposed(&window));
        auto *controller = buttons->findChild<QObject *>(QStringLiteral("controller"));
        QVERIFY(controller);
        const QStringList actions{QStringLiteral("close"), QStringLiteral("minimize"), QStringLiteral("maximize")};
        const QStringList capabilities{QStringLiteral("canClose"), QStringLiteral("canMinimize"), QStringLiteral("canMaximize")};
        const QStringList names{QStringLiteral("Close window"), QStringLiteral("Minimize window"), QStringLiteral("Maximize window")};
        for (int i = 0; i < actions.size(); ++i) {
            auto *button = buttons->findChild<QQuickItem *>(style + QLatin1Char('-') + actions[i]);
            QVERIFY(button);
            QVERIFY(button->isVisible());
            auto *accessible = QAccessible::queryAccessibleInterface(button);
            QVERIFY(accessible);
            QCOMPARE(accessible->role(), QAccessible::Button);
            QCOMPARE(accessible->text(QAccessible::Name), names[i]);
            const QByteArray capability = capabilities[i].toUtf8();
            const QByteArray counter = (actions[i] + QStringLiteral("Calls")).toUtf8();
            button->forceActiveFocus(Qt::TabFocusReason);
            QVERIFY(button->hasActiveFocus());
            QTest::keyClick(&window, Qt::Key_Space);
            QCOMPARE(controller->property(counter.constData()).toInt(), 1);
            QTest::keyClick(&window, Qt::Key_Tab);
            QVERIFY(window.activeFocusItem() != button);
            QVERIFY(window.activeFocusItem());
            QVERIFY(window.activeFocusItem()->isVisible());
            controller->setProperty(capability.constData(), false);
            QVERIFY(!button->isEnabled());
            QVERIFY(accessible->state().disabled);
            auto *accessibleActions = accessible->actionInterface();
            QVERIFY(accessibleActions);
            accessibleActions->doAction(QAccessibleActionInterface::pressAction());
            QCOMPARE(controller->property(counter.constData()).toInt(), 1);
            const QPoint position = button->mapToScene(QPointF(button->width() / 2, button->height() / 2)).toPoint();
            QTest::mouseClick(&window, Qt::LeftButton, Qt::NoModifier, position);
            QCOMPARE(controller->property(counter.constData()).toInt(), 1);
            controller->setProperty(capability.constData(), true);
            QVERIFY(button->isEnabled());
            QTest::mouseClick(&window, Qt::LeftButton, Qt::NoModifier, position);
            QCOMPARE(controller->property(counter.constData()).toInt(), 2);
            accessibleActions->doAction(QAccessibleActionInterface::pressAction());
            QCOMPARE(controller->property(counter.constData()).toInt(), 3);
        }
        controller->setProperty("isMaximized", true);
        auto *maximize = buttons->findChild<QQuickItem *>(style + QStringLiteral("-maximize"));
        QCOMPARE(QAccessible::queryAccessibleInterface(maximize)->text(QAccessible::Name), QStringLiteral("Restore window"));
        controller->setProperty("hasActiveWindow", false);
        for (const QString &action : actions) {
            QVERIFY(!buttons->findChild<QQuickItem *>(style + QLatin1Char('-') + action)->isEnabled());
        }
    }

    void titleScrollIsPaced()
    {
        QQmlEngine engine;
        QQuickWindow window;
        window.resize(400, 32);
        QQmlComponent component(&engine);
        component.setData(R"(
            import QtQuick
            WindowTitle {
                id: scrollTitle
                width: 400; height: 32; showIcon: false
                property int calls: 0
                property int lastDirection: 0
                controller: QtObject {
                    property string windowTitle: "Scroll test"
                    property bool hasActiveWindow: false
                    function cycleWindow(direction) { scrollTitle.calls++; scrollTitle.lastDirection = direction; }
                }
            }
        )", QUrl::fromLocalFile(QStringLiteral(CONFIG_QML_PATH)));
        QScopedPointer<QObject> title(component.create());
        QVERIFY2(title, qPrintable(component.errorString()));
        auto *item = qobject_cast<QQuickItem *>(title.data());
        QVERIFY(item);
        item->setParentItem(window.contentItem());
        window.show();
        QVERIFY(QTest::qWaitForWindowExposed(&window));
        const auto wheel = [&window](QPoint pixels, QPoint angles) {
            QWheelEvent event(QPointF(100, 16), window.mapToGlobal(QPoint(100, 16)), pixels, angles,
                              Qt::NoButton, Qt::NoModifier, Qt::NoScrollPhase, false);
            QCoreApplication::sendEvent(&window, &event);
        };
        const auto calls = [&title]() { return title->property("calls").toInt(); };
        for (int i = 0; i < 3; ++i) {
            wheel({}, QPoint(0, 30));
        }
        QCOMPARE(calls(), 0);
        wheel({}, QPoint(0, 30));
        QCOMPARE(calls(), 1);
        QCOMPARE(title->property("lastDirection").toInt(), -1);
        for (int i = 0; i < 50; ++i) {
            wheel(QPoint(0, -20), QPoint(0, -120));
        }
        QCOMPARE(calls(), 1);
        QTest::qWait(350);
        QCOMPARE(calls(), 1); // Nenhuma troca pendente após a rajada.
        wheel(QPoint(0, -20), QPoint(0, -120));
        QCOMPARE(calls(), 1); // Usa pixels, sem contar também o delta angular.
        wheel(QPoint(0, -20), QPoint(0, -120));
        QCOMPARE(calls(), 2);
        QCOMPARE(title->property("lastDirection").toInt(), 1);
        QTest::qWait(350);
        wheel(QPoint(0, 30), {});
        wheel(QPoint(0, -20), {});
        QCOMPARE(calls(), 2); // Inverter a direção descarta o movimento anterior.
        QTest::qWait(250);
        wheel(QPoint(0, -20), {});
        QCOMPARE(calls(), 2); // Uma pausa também descarta o movimento residual.
        wheel(QPoint(40, 0), {});
        QCOMPARE(calls(), 2);
        wheel(QPoint(0, -20), {});
        QCOMPARE(calls(), 3);
        QTest::mouseClick(&window, Qt::MiddleButton, Qt::NoModifier, QPoint(100, 16));
        QCOMPARE(calls(), 4); // Clique do meio não sofre o limite do scroll.
    }

    void absoluteTitleUsesDisplayedWidth()
    {
        QQmlEngine engine;
        QQuickWindow window;
        window.resize(800, 32);
        QQmlComponent component(&engine);
        component.setData(R"(
import QtQuick
Item {
    width: 800; height: 32
    QtObject {
        id: titleController
        objectName: "controller"
        property string windowTitle: "A very long title ".repeat(100)
        property bool hasActiveWindow: true
        property var windowIcon: "application-x-executable"
    }
    PanelCenteredTitle {
        objectName: "title"
        controller: titleController
        panelLength: 1000
        panelOffset: 100
        showIcon: false
    }
}
)", QUrl::fromLocalFile(QStringLiteral(CONFIG_QML_PATH)));
        QVERIFY2(component.isReady(), qPrintable(component.errorString()));
        QScopedPointer<QObject> fixture(component.create());
        QVERIFY2(fixture, qPrintable(component.errorString()));
        qobject_cast<QQuickItem *>(fixture.data())->setParentItem(window.contentItem());
        window.show(); // Permite que os layouts internos atualizem a largura implícita.
        auto *title = fixture->findChild<QObject *>(QStringLiteral("title"));
        auto *controller = fixture->findChild<QObject *>(QStringLiteral("controller"));
        QVERIFY(title && controller);
        QTRY_COMPARE(title->property("width").toDouble(), 520.0);
        QVERIFY(title->property("implicitWidth").toDouble() > 800);
        QCOMPARE(title->property("x").toDouble(), 140.0);

        // Nenhum espaçamento fantasma: o centro permanece exato com os botões
        // à esquerda, à direita ou ocultos, desde que exista espaço suficiente.
        for (const bool left : {true, false}) {
            title->setProperty("leftInset", left ? 106 : 0);
            title->setProperty("rightInset", left ? 0 : 106);
            QCOMPARE(title->property("x").toDouble() + title->property("width").toDouble() / 2, 400.0);
        }
        title->setProperty("showIcon", true);
        QTRY_COMPARE(title->property("width").toDouble(), 520.0);
        controller->setProperty("windowTitle", QStringLiteral("Short title"));
        QTRY_VERIFY(title->property("width").toDouble() < 520);
        QCOMPARE(title->property("x").toDouble() + title->property("width").toDouble() / 2, 400.0);
        controller->setProperty("windowTitle", QString(2000, QLatin1Char('W')));
        QTRY_COMPARE(title->property("width").toDouble(), 520.0);
        title->setProperty("panelOffset", 450);
        title->setProperty("leftInset", 106);
        QCOMPARE(title->property("x").toDouble(), 106.0);
        title->setProperty("panelOffset", -400);
        QCOMPARE(title->property("x").toDouble() + title->property("width").toDouble(), 694.0);
        fixture->setProperty("width", 150);
        QTRY_COMPARE(title->property("width").toDouble(), 0.0);
        QVERIFY(title->property("x").toDouble() <= 150);
    }
    void panelEdgesTrackRealNeighbors_data()
    {
        QTest::addColumn<bool>("vertical");
        QTest::newRow("horizontal") << false;
        QTest::newRow("vertical") << true;
    }

    void panelEdgesTrackRealNeighbors()
    {
        QFETCH(bool, vertical);
        QQmlEngine engine;
        QQmlComponent component(&engine);
        component.setData(R"(
import QtQuick
Item {
    id: panel
    property bool vertical: false
    width: 1000; height: 32
    Item { x: 0; width: 64; height: 32 } // Margem auxiliar, não é applet.
    Item {
        objectName: "before"; property bool isAppletContainer: true
        x: panel.vertical ? 0 : 64; y: panel.vertical ? 64 : 0; width: 32; height: 32
    }
    Item {
        objectName: "own"; property bool isAppletContainer: true
        x: panel.vertical ? 0 : 100; y: panel.vertical ? 100 : 0
        width: panel.vertical ? 32 : 24; height: panel.vertical ? 24 : 32
        Item { Item { id: target; width: 24; height: 32 } }
    }
    Item {
        objectName: "after"; property bool isAppletContainer: true
        x: panel.vertical ? 0 : 130; y: panel.vertical ? 130 : 0
        width: panel.vertical ? 32 : 1; height: panel.vertical ? 1 : 32
    }
    PanelEdges { objectName: "edges"; appletItem: target; vertical: panel.vertical }
}
)", QUrl::fromLocalFile(QStringLiteral(CONFIG_QML_PATH)));
        QVERIFY2(component.isReady(), qPrintable(component.errorString()));
        QScopedPointer<QObject> fixture(component.create());
        QVERIFY2(fixture, qPrintable(component.errorString()));
        fixture->setProperty("vertical", vertical);
        const char *lengthProperty = vertical ? "height" : "width";
        const char *positionProperty = vertical ? "y" : "x";
        auto *edges = fixture->findChild<QObject *>(QStringLiteral("edges"));
        auto *before = fixture->findChild<QObject *>(QStringLiteral("before"));
        auto *after = fixture->findChild<QObject *>(QStringLiteral("after"));
        auto *own = fixture->findChild<QObject *>(QStringLiteral("own"));
        QVERIFY(edges && before && after && own);
        QSignalSpy blocked(edges, SIGNAL(bothEdgesOccupied()));
        QVERIFY(edges->property("known").toBool());
        QVERIFY(!edges->property("isAtLeftEdge").toBool());
        QVERIFY(!edges->property("isAtRightEdge").toBool());
        QTRY_COMPARE(blocked.count(), 1);
        before->setProperty("visible", false);
        QVERIFY(edges->property("isAtLeftEdge").toBool()); // Margem de 100px ignorada.
        after->setProperty("visible", false);
        QVERIFY(edges->property("isAtRightEdge").toBool());
        own->setProperty(lengthProperty, 0);
        QVERIFY(!edges->property("known").toBool());
        QVERIFY(!edges->property("isAtLeftEdge").toBool());
        own->setProperty(lengthProperty, 24);
        QVERIFY(edges->property("known").toBool());
        before->setProperty("visible", true);
        after->setProperty("visible", true);
        edges->setProperty("editing", true);
        QTest::qWait(350);
        QCOMPARE(blocked.count(), 1);
        QVERIFY(!edges->property("known").toBool());
        edges->setProperty("editing", false);
        after->setProperty(positionProperty, 110); // Sobreposição transitória.
        QVERIFY(!edges->property("known").toBool());
        QTest::qWait(350);
        QCOMPARE(blocked.count(), 1);
        after->setProperty(positionProperty, 130);
        QTRY_COMPARE(blocked.count(), 2);
        before->setParent(nullptr);
        delete before;
        QVERIFY(edges->property("isAtLeftEdge").toBool());
    }
    void buttonPlacementCombinations()
    {
        struct Scenario {
            const char *title;
            bool left;
            bool right;
            const char *preferLeft;
            const char *preferRight;
        };
        const Scenario scenarios[] = {
            {"left", false, false, "", ""},
            {"left", true, false, "", ""},
            {"left", false, true, "right", "right"},
            {"left", true, true, "right", "right"},
            {"center", false, false, "", ""},
            {"center", true, false, "left", "left"},
            {"center", false, true, "right", "right"},
            {"center", true, true, "left", "right"},
            {"right", false, false, "", ""},
            {"right", true, false, "left", "left"},
            {"right", false, true, "", ""},
            {"right", true, true, "left", "left"},
        };
        QQmlEngine engine;
        const QString path = QFileInfo(QStringLiteral(CONFIG_QML_PATH)).dir().filePath(QStringLiteral("ButtonPlacement.qml"));
        QQmlComponent component(&engine, QUrl::fromLocalFile(path));
        QVERIFY2(component.isReady(), qPrintable(component.errorString()));
        for (const auto &scenario : scenarios) {
            for (const bool preferLeft : {true, false}) {
                QScopedPointer<QObject> placement(component.create());
                QVERIFY(placement);
                placement->setProperty("titlePosition", QString::fromLatin1(scenario.title));
                placement->setProperty("isAtLeftEdge", scenario.left);
                placement->setProperty("isAtRightEdge", scenario.right);
                placement->setProperty("preferredPosition", preferLeft ? QStringLiteral("left") : QStringLiteral("right"));
                const QString expected = QString::fromLatin1(preferLeft ? scenario.preferLeft : scenario.preferRight);
                QCOMPARE(placement->property("position").toString(), expected);
                QCOMPARE(placement->property("available").toBool(), !expected.isEmpty());
            }
        }
    }
    void initTestCase()
    {
        auto bus = QDBusConnection::sessionBus();
        QVERIFY(bus.registerService(QStringLiteral("org.kde.KWin")));
        QVERIFY(bus.registerObject(QStringLiteral("/KWin"), &m_kwin, QDBusConnection::ExportAllSlots));
    }
    void init()
    {
        QFile::remove(path());
        m_kwin.calls = 0;
        m_kwin.fail = false;
    }
    void startupDoesNotWrite()
    {
        KWinSettings empty;
        QVERIFY(!empty.borderlessMaximized());
        QVERIFY(!QFile::exists(path()));
        writeConfig("[Windows]\nBorderlessMaximizedWindows=true\nOtherSetting=keep\n");
        const auto original = readConfig();
        KWinSettings first;
        KWinSettings second;
        QVERIFY(first.borderlessMaximized());
        QVERIFY(second.borderlessMaximized());
        QTRY_VERIFY(empty.borderlessMaximized());
        QCOMPARE(readConfig(), original);
        QCOMPARE(m_kwin.calls, 0);
    }
    void instancesFollowExplicitChanges()
    {
        writeConfig("[Windows]\nBorderlessMaximizedWindows=false\nOtherSetting=keep\n");
        KWinSettings first;
        KWinSettings second;
        first.setBorderlessMaximized(true);
        QTRY_VERIFY(!first.busy());
        QCOMPARE(first.error(), KWinSettings::NoError);
        QTRY_VERIFY(second.borderlessMaximized());
        QCOMPARE(m_kwin.calls, 1);
        QVERIFY(readConfig().contains("OtherSetting=keep"));
        second.setBorderlessMaximized(false);
        QTRY_VERIFY(!second.busy());
        QTRY_VERIFY(!first.borderlessMaximized());
        QCOMPARE(m_kwin.calls, 2);
    }
    void externalChangesNeverRequestReload()
    {
        writeConfig("[Windows]\nBorderlessMaximizedWindows=false\n");
        KWinSettings first;
        KWinSettings second;
        for (int i = 0; i < 3; ++i) {
            writeConfig("[Windows]\nBorderlessMaximizedWindows=true\n");
            QTRY_VERIFY(first.borderlessMaximized());
            QTRY_VERIFY(second.borderlessMaximized());
            writeConfig("[Windows]\nBorderlessMaximizedWindows=false\n");
            QTRY_VERIFY(!first.borderlessMaximized());
            QTRY_VERIFY(!second.borderlessMaximized());
        }
        writeConfig("[Windows]\nBorderlessMaximizedWindows=true\n");
        QTRY_VERIFY(first.borderlessMaximized());
        QVERIFY(QFile::remove(path()));
        QTRY_VERIFY(!first.borderlessMaximized());
        writeConfig("[Windows]\nBorderlessMaximizedWindows=true\n");
        QTRY_VERIFY(first.borderlessMaximized());
        QTRY_VERIFY(second.borderlessMaximized());
        QCOMPARE(m_kwin.calls, 0);
    }
    void lockedSettingReportsWriteError()
    {
        writeConfig("[Windows]\nBorderlessMaximizedWindows[$i]=false\n");
        const auto original = readConfig();
        KWinSettings settings;
        settings.setBorderlessMaximized(true);
        QCOMPARE(settings.error(), KWinSettings::WriteError);
        QVERIFY(!settings.borderlessMaximized());
        QVERIFY(!settings.busy());
        QCOMPARE(readConfig(), original);
        QCOMPARE(m_kwin.calls, 0);
    }
    void reloadFailurePreservesNewerChangesAndCanRetry()
    {
        KWinSettings first;
        KWinSettings second;
        m_kwin.fail = true;
        first.setBorderlessMaximized(true);
        // Uma alteração externa enquanto a chamada está pendente não pode ser revertida.
        writeConfig("[Windows]\nBorderlessMaximizedWindows=false\nOtherSetting=new\n");
        QTRY_VERIFY(!first.busy());
        QCOMPARE(first.error(), KWinSettings::ReloadError);
        QVERIFY(!first.borderlessMaximized());
        QTRY_VERIFY(!second.borderlessMaximized());
        const auto saved = readConfig();
        m_kwin.fail = false;
        first.reconfigure();
        QTRY_VERIFY(!first.busy());
        QCOMPARE(first.error(), KWinSettings::NoError);
        QCOMPARE(readConfig(), saved);
        QCOMPARE(m_kwin.calls, 2);
    }
    void configurationPageTracksGlobalState()
    {
        writeConfig("[Windows]\nBorderlessMaximizedWindows=true\n");
        qmlRegisterType<KWinSettings>("Test.WTButtons", 1, 0, "KWinSettings");
        QQmlEngine engine;
        engine.rootContext()->setContextObject(new KLocalizedContext(&engine));
        QFile source(QStringLiteral(CONFIG_QML_PATH));
        QVERIFY(source.open(QIODevice::ReadOnly));
        auto qml = source.readAll();
        // Testa a página real com o backend do teste, sem carregar o plugin instalado.
        qml.replace("import \"../plugin\" as WTButtons", "import Test.WTButtons 1.0 as WTButtons");
        QQmlComponent component(&engine);
        component.setData(qml, QUrl::fromLocalFile(QStringLiteral(CONFIG_QML_PATH)));
        QTRY_VERIFY_WITH_TIMEOUT(component.status() != QQmlComponent::Loading, 5000);
        QVERIFY2(component.isReady(), qPrintable(component.errorString()));
        QScopedPointer<QObject> page(component.create());
        QVERIFY2(page, qPrintable(component.errorString()));
        auto *checkbox = page->findChild<QObject *>(QStringLiteral("borderlessCheckBox"));
        QVERIFY(checkbox);
        QVERIFY(checkbox->property("checked").toBool());
        QCOMPARE(m_kwin.calls, 0);

        // A página usa a mesma regra do applet e permite sair de um conflito sem
        // alterar silenciosamente a posição do título ou a preferência dos botões.
        auto *leftRadio = page->findChild<QObject *>(QStringLiteral("buttonsLeftRadio"));
        auto *rightRadio = page->findChild<QObject *>(QStringLiteral("buttonsRightRadio"));
        QVERIFY(leftRadio);
        QVERIFY(rightRadio);
        page->setProperty("cfg_showButtons", true);
        page->setProperty("cfg_edgesKnown", true);
        page->setProperty("cfg_isAtLeftEdge", true);
        page->setProperty("cfg_buttonsPosition", QStringLiteral("right"));
        page->setProperty("cfg_titlePosition", QStringLiteral("left"));
        page->setProperty("cfg_isAtRightEdge", false);
        QVERIFY(!page->property("canShowButtons").toBool());
        QVERIFY(!leftRadio->property("enabled").toBool());
        QVERIFY(!rightRadio->property("enabled").toBool());
        QVERIFY(!leftRadio->property("checked").toBool());
        QVERIFY(!rightRadio->property("checked").toBool());
        QCOMPARE(page->property("cfg_titlePosition").toString(), QStringLiteral("left"));
        page->setProperty("cfg_titlePosition", QStringLiteral("center"));
        QVERIFY(page->property("canShowButtons").toBool());
        QVERIFY(leftRadio->property("checked").toBool());
        QCOMPARE(page->property("cfg_buttonsPosition").toString(), QStringLiteral("right"));
        page->setProperty("cfg_isAtRightEdge", true);
        QVERIFY(rightRadio->property("checked").toBool());
        QVERIFY(page->property("cfg_showButtons").toBool());

        // Geometria desconhecida não apaga preferências; bloqueio confirmado desmarca.
        page->setProperty("cfg_edgesKnown", false);
        page->setProperty("cfg_isAtLeftEdge", false);
        page->setProperty("cfg_isAtRightEdge", false);
        QTest::qWait(350);
        QVERIFY(page->property("cfg_showButtons").toBool());
        QVERIFY(!page->property("canShowButtons").toBool());
        page->setProperty("cfg_edgesKnown", true);
        QTRY_VERIFY(!page->property("cfg_showButtons").toBool());
        page->setProperty("cfg_isAtLeftEdge", true);
        QVERIFY(page->property("canShowButtons").toBool());
        QVERIFY(!page->property("cfg_showButtons").toBool());

        writeConfig("[Windows]\nBorderlessMaximizedWindows=false\n");
        QTRY_VERIFY(!checkbox->property("checked").toBool());
        QCOMPARE(m_kwin.calls, 0);
        // Simula a ação explícita; mudanças de estado programáticas acima não salvam.
        checkbox->setProperty("checked", true);
        QVERIFY(QMetaObject::invokeMethod(checkbox, "clicked"));
        QTRY_COMPARE(m_kwin.calls, 1);
        QTRY_VERIFY(checkbox->property("enabled").toBool());
        writeConfig("[Windows]\nBorderlessMaximizedWindows[$i]=false\n");
        QTRY_VERIFY(!checkbox->property("checked").toBool());
        checkbox->setProperty("checked", true);
        QVERIFY(QMetaObject::invokeMethod(checkbox, "clicked"));
        QVERIFY(!checkbox->property("checked").toBool());
        QCOMPARE(m_kwin.calls, 1);
    }
};

int main(int argc, char **argv)
{
    // Isola leitura e escrita de configuração antes de inicializar Qt/KConfig.
    QTemporaryDir temporary;
    if (!temporary.isValid()) {
        return 1;
    }
    qputenv("XDG_CONFIG_HOME", temporary.path().toUtf8());
    qputenv("XDG_CONFIG_DIRS", temporary.path().toUtf8());
    QGuiApplication app(argc, argv);
    KWinSettingsTest test;
    return QTest::qExec(&test, argc, argv);
}

#include "kwinsettings_test.moc"
