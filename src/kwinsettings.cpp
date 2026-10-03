// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: 2026 Arthur Celestino

#include "kwinsettings.h"

#include <KConfig>
#include <KConfigGroup>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>
#include <QDir>
#include <QFileInfo>
#include <QStandardPaths>
#include <QCoreApplication>
#include <QSet>
#include <QLockFile>
#include <memory>
#include <utility>

namespace {
QSet<KWinSettings *> instances;
QSet<KWinSettings *> owners;
bool externallyChanged = false;
std::unique_ptr<QLockFile> ownershipLock;
quint64 reloadGeneration = 0;
KWinSettings::Error sharedError = KWinSettings::NoError;
constexpr auto ownershipGroup = "WindowTitleAndButtonsOwnership";

bool lockOwnership()
{
    if (ownershipLock) {
        return true;
    }
    const QString directory = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation);
    QDir().mkpath(directory);
    auto lock = std::make_unique<QLockFile>(directory + QStringLiteral("/windowtitleandbuttons-kwin.lock"));
    lock->setStaleLockTime(0);
    if (!lock->tryLock()) {
        return false;
    }
    ownershipLock = std::move(lock);
    return true;
}
}

KWinSettings::KWinSettings(QObject *parent)
    : QObject(parent)
{
    instances.insert(this);
    m_error = sharedError;
    connect(qApp, &QCoreApplication::aboutToQuit, this, [this] { setManaged(false); });
    connect(&m_packageWatcher, &QFileSystemWatcher::fileChanged, this, &KWinSettings::checkPackage);
    connect(&m_packageWatcher, &QFileSystemWatcher::directoryChanged, this, &KWinSettings::checkPackage);
    connect(&m_watcher, &QFileSystemWatcher::fileChanged, this, &KWinSettings::reload);
    connect(&m_watcher, &QFileSystemWatcher::directoryChanged, this, &KWinSettings::reload);
    // Recupera somente uma alteração documentada por esta versão, nunca uma
    // preferência preexistente. O lock impede recuperar a sessão de outro processo.
    if (owners.isEmpty() && lockOwnership()) {
        externallyChanged = false;
        restoreManagedSetting();
        ownershipLock.reset();
    }
    reload();
}

KWinSettings::~KWinSettings()
{
    setManaged(false);
    instances.remove(this);
}

void KWinSettings::setPackageFile(const QUrl &file)
{
    m_packageFile = file;
    if (!m_packageWatcher.files().isEmpty()) {
        m_packageWatcher.removePaths(m_packageWatcher.files());
    }
    if (!m_packageWatcher.directories().isEmpty()) {
        m_packageWatcher.removePaths(m_packageWatcher.directories());
    }
    if (file.isLocalFile()) {
        const QString path = file.toLocalFile();
        if (QFileInfo::exists(path)) {
            m_packageWatcher.addPath(path);
            m_packageWatcher.addPath(QFileInfo(path).absolutePath());
        }
    }
}

void KWinSettings::checkPackage()
{
    if (m_packageFile.isLocalFile() && !QFileInfo::exists(m_packageFile.toLocalFile())) {
        setManaged(false);
    } else if (m_packageFile.isLocalFile() && !m_packageWatcher.files().contains(m_packageFile.toLocalFile())) {
        m_packageWatcher.addPath(m_packageFile.toLocalFile());
    }
}

void KWinSettings::setManaged(bool managed)
{
    if (m_managed == managed) {
        return;
    }
    if (managed && m_packageFile.isLocalFile() && !QFileInfo::exists(m_packageFile.toLocalFile())) {
        return;
    }
    if (managed && !lockOwnership()) {
        setError(WriteError);
        return;
    }
    m_managed = managed;
    if (managed) {
        const bool first = owners.isEmpty();
        owners.insert(this);
        if (first) {
            setError(NoError);
            externallyChanged = false;
            KConfig config(QStringLiteral("kwinrc"), KConfig::NoGlobals);
            KConfigGroup windows(&config, QStringLiteral("Windows"));
            KConfigGroup ownership(&config, QString::fromLatin1(ownershipGroup));
            if (!windows.readEntry("BorderlessMaximizedWindows", false)) {
                if (windows.isEntryImmutable("BorderlessMaximizedWindows") || !config.isConfigWritable(false)) {
                    setError(WriteError);
                } else {
                    // Salva a origem e a alteração na mesma transação. Um próximo
                    // carregamento pode recuperar a origem após uma queda do Shell.
                    ownership.writeEntry("HadEntry", windows.hasKey("BorderlessMaximizedWindows"));
                    ownership.writeEntry("Active", true);
                    windows.writeEntry("BorderlessMaximizedWindows", true);
                    if (config.sync()) {
                        reload();
                        reconfigure();
                    } else {
                        config.markAsClean();
                        setError(WriteError);
                    }
                }
            }
        }
    } else {
        owners.remove(this);
        if (owners.isEmpty()) {
            if (!restoreManagedSetting()) {
                qWarning("Window Title and Buttons: could not restore kwinrc; recovery record retained");
            }
            ownershipLock.reset();
        }
    }
    Q_EMIT managedChanged();
}

bool KWinSettings::restoreManagedSetting()
{
    KConfig config(QStringLiteral("kwinrc"), KConfig::NoGlobals);
    KConfigGroup windows(&config, QStringLiteral("Windows"));
    KConfigGroup ownership(&config, QString::fromLatin1(ownershipGroup));
    if (!ownership.readEntry("Active", false)) {
        return true;
    }
    const bool restore = !externallyChanged && windows.readEntry("BorderlessMaximizedWindows", false);
    if (!config.isConfigWritable(false) || (restore && windows.isEntryImmutable("BorderlessMaximizedWindows"))) {
        setError(WriteError);
        return false;
    }
    if (restore) {
        if (ownership.readEntry("HadEntry", false)) {
            windows.writeEntry("BorderlessMaximizedWindows", false);
        } else {
            windows.revertToDefault("BorderlessMaximizedWindows");
        }
    }
    ownership.revertToDefault("Active");
    ownership.revertToDefault("HadEntry");
    if (!config.sync()) {
        config.markAsClean();
        setError(WriteError);
        return false;
    }
    reload();
    if (restore) {
        // A liberação não pode ser perdida por haver uma recarga pendente.
        // A chamada não depende da vida útil do objeto que está sendo removido.
        const auto message = QDBusMessage::createMethodCall(
            QStringLiteral("org.kde.KWin"), QStringLiteral("/KWin"),
            QStringLiteral("org.kde.KWin"), QStringLiteral("reconfigure"));
        setError(NoError);
        const auto generation = ++reloadGeneration;
        auto *watcher = new QDBusPendingCallWatcher(QDBusConnection::sessionBus().asyncCall(message, 5000), qApp);
        connect(watcher, &QDBusPendingCallWatcher::finished, qApp, [watcher, generation] {
            const QDBusPendingReply<> reply = *watcher;
            if (generation == reloadGeneration && !instances.isEmpty()) {
                (*instances.begin())->setError(reply.isError() ? ReloadError : NoError);
            }
            if (reply.isError()) {
                qWarning("Window Title and Buttons: KWin could not reload the restored title bars");
            }
            watcher->deleteLater();
        });
    }
    return true;
}

void KWinSettings::updateWatchPaths()
{
    // Observa também o diretório: editores e KConfig podem substituir o arquivo
    // atomicamente. Reinscreve arquivos removidos/recriados em cada notificação.
    const auto locations = QStandardPaths::standardLocations(QStandardPaths::GenericConfigLocation);
    for (const QString &location : locations) {
        const QString path = QDir(location).filePath(QStringLiteral("kwinrc"));
        if (QFileInfo::exists(path) && !m_watcher.files().contains(path)) {
            m_watcher.addPath(path);
        }
        QString directory = location;
        while (!QFileInfo::exists(directory)) {
            const QString parent = QFileInfo(directory).absolutePath();
            if (parent == directory) {
                break;
            }
            directory = parent;
        }
        if (!m_watcher.directories().contains(directory)) {
            m_watcher.addPath(directory);
        }
    }
}

void KWinSettings::reload()
{
    updateWatchPaths();
    // Objeto independente evita cache compartilhado e alterações pendentes de outras instâncias.
    KConfig config(QStringLiteral("kwinrc"), KConfig::NoGlobals);
    const KConfigGroup windows(&config, QStringLiteral("Windows"));
    const bool enabled = windows.readEntry("BorderlessMaximizedWindows", false);
    if (!owners.isEmpty() && !enabled && !externallyChanged) {
        externallyChanged = true;
        // Abandona também o registro persistente: uma queda posterior não pode
        // fazer a recuperação sobrescrever uma nova escolha externa.
        KConfigGroup ownership(&config, QString::fromLatin1(ownershipGroup));
        if (ownership.readEntry("Active", false)) {
            ownership.revertToDefault("Active");
            ownership.revertToDefault("HadEntry");
            if (!config.sync()) {
                config.markAsClean();
                setError(WriteError);
            }
        }
    }
    if (m_borderlessMaximized != enabled) {
        m_borderlessMaximized = enabled;
        Q_EMIT borderlessMaximizedChanged();
    }
}

void KWinSettings::setError(Error error)
{
    sharedError = error;
    for (KWinSettings *instance : std::as_const(instances)) {
        if (instance->m_error != error) {
            instance->m_error = error;
            Q_EMIT instance->errorChanged();
        }
    }
}

void KWinSettings::setBorderlessMaximized(bool enabled)
{
    if (m_busy) {
        return;
    }
    setError(NoError);
    KConfig config(QStringLiteral("kwinrc"), KConfig::NoGlobals);
    KConfigGroup windows(&config, QStringLiteral("Windows"));
    if (windows.readEntry("BorderlessMaximizedWindows", false) != enabled) {
        if (windows.isEntryImmutable("BorderlessMaximizedWindows") || !config.isConfigWritable(false)) {
            setError(WriteError);
            reload();
            return;
        }
        windows.writeEntry("BorderlessMaximizedWindows", enabled);
        if (!config.sync()) {
            // Não permite que o destrutor tente salvar novamente uma gravação que falhou.
            config.markAsClean();
            setError(WriteError);
            reload();
            return;
        }
    }
    reload();
    reconfigure();
}

void KWinSettings::reconfigure()
{
    if (m_busy) {
        m_reloadAgain = true;
        return;
    }
    setError(NoError);
    m_busy = true;
    Q_EMIT busyChanged();
    const auto message = QDBusMessage::createMethodCall(
        QStringLiteral("org.kde.KWin"), QStringLiteral("/KWin"),
        QStringLiteral("org.kde.KWin"), QStringLiteral("reconfigure"));
    auto *watcher = new QDBusPendingCallWatcher(QDBusConnection::sessionBus().asyncCall(message, 5000), this);
    const auto generation = ++reloadGeneration;
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this, watcher, generation]() {
        const QDBusPendingReply<> reply = *watcher;
        // Em caso de falha, mantém o valor salvo e permite repetir apenas a recarga.
        // Reverter aqui poderia sobrescrever uma alteração feita por outra instância.
        if (generation == reloadGeneration) {
            setError(reply.isError() ? ReloadError : NoError);
        }
        reload();
        m_busy = false;
        Q_EMIT busyChanged();
        watcher->deleteLater();
        if (m_reloadAgain) {
            m_reloadAgain = false;
            reconfigure();
        }
    });
}
