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

KWinSettings::KWinSettings(QObject *parent)
    : QObject(parent)
{
    connect(&m_watcher, &QFileSystemWatcher::fileChanged, this, &KWinSettings::reload);
    connect(&m_watcher, &QFileSystemWatcher::directoryChanged, this, &KWinSettings::reload);
    // A construção só lê: adicionar widgets nunca altera as preferências do KWin.
    reload();
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
    if (m_borderlessMaximized != enabled) {
        m_borderlessMaximized = enabled;
        Q_EMIT borderlessMaximizedChanged();
    }
}

void KWinSettings::setError(Error error)
{
    if (m_error != error) {
        m_error = error;
        Q_EMIT errorChanged();
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
        return;
    }
    setError(NoError);
    m_busy = true;
    Q_EMIT busyChanged();
    const auto message = QDBusMessage::createMethodCall(
        QStringLiteral("org.kde.KWin"), QStringLiteral("/KWin"),
        QStringLiteral("org.kde.KWin"), QStringLiteral("reconfigure"));
    auto *watcher = new QDBusPendingCallWatcher(QDBusConnection::sessionBus().asyncCall(message, 5000), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this, watcher]() {
        const QDBusPendingReply<> reply = *watcher;
        // Em caso de falha, mantém o valor salvo e permite repetir apenas a recarga.
        // Reverter aqui poderia sobrescrever uma alteração feita por outra instância.
        setError(reply.isError() ? ReloadError : NoError);
        reload();
        m_busy = false;
        Q_EMIT busyChanged();
        watcher->deleteLater();
    });
}
