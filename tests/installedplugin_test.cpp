#include <QDir>
#include <QGuiApplication>
#include <QQmlComponent>
#include <QQmlEngine>
#include <QTemporaryDir>
#include <QDebug>
#include <memory>

int main(int argc, char **argv)
{
    if (argc != 2) {
        return 1;
    }
    const QString pluginDirectory = QString::fromLocal8Bit(argv[1]);
    QTemporaryDir config;
    if (!config.isValid()) {
        return 1;
    }
    qputenv("XDG_CONFIG_HOME", config.path().toUtf8());
    qputenv("XDG_CONFIG_DIRS", config.path().toUtf8());
    QGuiApplication app(argc, argv);
    QQmlEngine engine;

    // Importa pelo diretório instalado, como o applet. Este executável não é
    // ligado ao backend: resolução do plugin e de suas bibliotecas é real.
    for (const QByteArray &type : {QByteArray("WindowController"), QByteArray("KWinSettings")}) {
        QQmlComponent component(&engine);
        component.setData("import \".\" as Widget\nWidget." + type + " {}",
                          QUrl::fromLocalFile(QDir(pluginDirectory).filePath(QStringLiteral("probe.qml"))));
        std::unique_ptr<QObject> object(component.create());
        if (!object) {
            qCritical().noquote() << component.errorString();
            return 1;
        }
        if (type == "WindowController" && object->property("windowTitle").toString() != QStringLiteral("Plasma Workspace")) {
            qCritical() << "Unexpected initial controller state";
            return 1;
        }
    }
    return 0;
}
