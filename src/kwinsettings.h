// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: 2026 Arthur Celestino

#pragma once

#include <QObject>
#include <QFileSystemWatcher>
#include <QUrl>
#include <qqmlregistration.h>

// A configuração pertence ao KWin, não a uma instância do plasmoid.
class KWinSettings : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(bool borderlessMaximized READ borderlessMaximized NOTIFY borderlessMaximizedChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(Error error READ error NOTIFY errorChanged)
    Q_PROPERTY(bool managed READ managed WRITE setManaged NOTIFY managedChanged)
    Q_PROPERTY(QUrl packageFile READ packageFile WRITE setPackageFile)

public:
    enum Error { NoError, WriteError, ReloadError };
    Q_ENUM(Error)

    explicit KWinSettings(QObject *parent = nullptr);
    ~KWinSettings() override;
    bool managed() const { return m_managed; }
    void setManaged(bool managed);
    QUrl packageFile() const { return m_packageFile; }
    void setPackageFile(const QUrl &file);
    bool borderlessMaximized() const { return m_borderlessMaximized; }
    bool busy() const { return m_busy; }
    Error error() const { return m_error; }

    Q_INVOKABLE void setBorderlessMaximized(bool enabled);
    Q_INVOKABLE void reconfigure();

Q_SIGNALS:
    void borderlessMaximizedChanged();
    void busyChanged();
    void errorChanged();
    void managedChanged();

private:
    void reload();
    void updateWatchPaths();
    void setError(Error error);
    bool restoreManagedSetting();
    void checkPackage();

    QFileSystemWatcher m_watcher;
    bool m_borderlessMaximized{false};
    bool m_busy{false};
    bool m_reloadAgain{false};
    Error m_error{NoError};
    bool m_managed{false};
    QUrl m_packageFile;
    QFileSystemWatcher m_packageWatcher;
};
