// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: 2026 Arthur Celestino

#include "kwinsettings.h"

#include <KLocalizedContext>
#include <KLocalizedString>
#include <QAccessible>
#include <QFile>
#include <QGuiApplication>
#include <QJsonDocument>
#include <QJsonObject>
#include <QQmlComponent>
#include <QQmlContext>
#include <QQmlEngine>
#include <QTemporaryDir>
#include <QTest>
#include <clocale>

class TranslationsTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void initTestCase()
    {
        // Gettext não traduz sob C/C.UTF-8; o CTest fornece en_US.UTF-8.
        QVERIFY2(std::setlocale(LC_MESSAGES, ""), "The translations test requires the en_US.UTF-8 locale.");
        QVERIFY(KLocalizedString::availableDomainTranslations(QByteArray(APPLET_TRANSLATION_DOMAIN)).contains(QStringLiteral("pt_BR")));
    }

    void domainMatchesApplet()
    {
        QFile metadata(QStringLiteral(PACKAGE_PATH "/metadata.json"));
        QVERIFY(metadata.open(QIODevice::ReadOnly));
        const auto plugin = QJsonDocument::fromJson(metadata.readAll()).object().value(QStringLiteral("KPlugin")).toObject();
        QCOMPARE(QStringLiteral("plasma_applet_") + plugin.value(QStringLiteral("Id")).toString(),
                 QStringLiteral(APPLET_TRANSLATION_DOMAIN));
    }

    void qmlUsesCatalog_data()
    {
        QTest::addColumn<QString>("language");
        QTest::addColumn<bool>("portuguese");
        QTest::newRow("pt_BR") << QStringLiteral("pt_BR") << true;
        QTest::newRow("English") << QStringLiteral("en_US") << false;
        QTest::newRow("untranslated-language") << QStringLiteral("de") << false;
    }

    void qmlUsesCatalog()
    {
        QFETCH(QString, language);
        QFETCH(bool, portuguese);
        KLocalizedString::setLanguages({language});
        QQmlEngine engine;
        // O Plasma fornece este domínio ao contexto QML de cada applet.
        auto *context = new KLocalizedContext(&engine);
        context->setTranslationDomain(QStringLiteral(APPLET_TRANSLATION_DOMAIN));
        engine.rootContext()->setContextObject(context);
        QCOMPARE(context->i18n(QStringLiteral("Minimize window")),
                 portuguese ? QStringLiteral("Minimizar janela") : QStringLiteral("Minimize window"));

        QQmlComponent buttonsComponent(&engine);
        buttonsComponent.setData(R"(
            import QtQuick
            WindowButtons {
                controller: QtObject {
                    objectName: "controller"
                    property bool hasActiveWindow: true
                    property bool isMaximized: false
                    property bool canMinimize: true
                    property bool canMaximize: true
                    property bool canClose: true
                }
            }
        )", QUrl::fromLocalFile(QStringLiteral(PACKAGE_PATH "/contents/ui/translation-test.qml")));
        QScopedPointer<QObject> buttons(buttonsComponent.create());
        QVERIFY2(buttons, qPrintable(buttonsComponent.errorString()));
        const QStringList actions{QStringLiteral("minimize"), QStringLiteral("maximize"), QStringLiteral("close")};
        const QStringList expected = portuguese
            ? QStringList{QStringLiteral("Minimizar janela"), QStringLiteral("Maximizar janela"), QStringLiteral("Fechar janela")}
            : QStringList{QStringLiteral("Minimize window"), QStringLiteral("Maximize window"), QStringLiteral("Close window")};
        for (const QString &style : {QStringLiteral("system"), QStringLiteral("macos"), QStringLiteral("minimal")}) {
            buttons->setProperty("buttonStyle", style);
            for (int i = 0; i < actions.size(); ++i) {
                auto *button = buttons->findChild<QObject *>(style + QLatin1Char('-') + actions[i]);
                QVERIFY(button);
                QCOMPARE(button->property("text").toString(), expected[i]);
                auto *accessible = QAccessible::queryAccessibleInterface(button);
                QVERIFY(accessible);
                QCOMPARE(accessible->text(QAccessible::Name), expected[i]);
            }
        }
        auto *controller = buttons->findChild<QObject *>(QStringLiteral("controller"));
        QVERIFY(controller);
        controller->setProperty("isMaximized", true);
        QCOMPARE(buttons->findChild<QObject *>(QStringLiteral("minimal-maximize"))->property("text").toString(),
                 portuguese ? QStringLiteral("Restaurar janela") : QStringLiteral("Restore window"));

        QFile config(QStringLiteral(PACKAGE_PATH "/contents/ui/configGeneral.qml"));
        QVERIFY(config.open(QIODevice::ReadOnly));
        auto qml = config.readAll();
        qml.replace("import \"../plugin\" as WTButtons", "import Test.WTButtons 1.0 as WTButtons");
        QQmlComponent configComponent(&engine);
        configComponent.setData(qml, QUrl::fromLocalFile(config.fileName()));
        QScopedPointer<QObject> page(configComponent.create());
        QVERIFY2(page, qPrintable(configComponent.errorString()));
        QStringList displayed;
        for (auto *child : page->findChildren<QObject *>()) {
            displayed.append(child->property("text").toString());
        }
        QVERIFY(displayed.contains(portuguese ? QStringLiteral("Exibir o ícone do aplicativo") : QStringLiteral("Show application icon")));
        QVERIFY(displayed.contains(portuguese ? QStringLiteral("Exibir o título da janela ativa") : QStringLiteral("Show active window title")));
        QVERIFY(displayed.contains(portuguese ? QStringLiteral("A configuração anterior do KWin é restaurada quando nenhum widget precisa ocultar as barras de título.")
                                             : QStringLiteral("The previous KWin setting is restored when no widget needs to hide title bars.")));

        QQmlComponent categoriesComponent(&engine, QUrl::fromLocalFile(QStringLiteral(PACKAGE_PATH "/contents/config/config.qml")));
        QScopedPointer<QObject> categories(categoriesComponent.create());
        QVERIFY2(categories, qPrintable(categoriesComponent.errorString()));
        QStringList names;
        for (auto *child : categories->findChildren<QObject *>()) {
            names.append(child->property("name").toString());
        }
        QVERIFY(names.contains(portuguese ? QStringLiteral("Geral") : QStringLiteral("General")));
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
    KLocalizedString::addDomainLocaleDir(QByteArray(APPLET_TRANSLATION_DOMAIN), QStringLiteral(TRANSLATIONS_PATH));
    qmlRegisterType<KWinSettings>("Test.WTButtons", 1, 0, "KWinSettings");
    TranslationsTest test;
    return QTest::qExec(&test, argc, argv);
}

#include "translations_test.moc"
