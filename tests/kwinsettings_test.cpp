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
#include <QSaveFile>
#include <QTemporaryDir>
#include <QTest>

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
