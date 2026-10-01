// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: 2026 Arthur Celestino

#pragma once

#include <QObject>
#include <QString>
#include <QVariant>
#include <QRect>
#include <QModelIndex>
#include <qqmlregistration.h>

namespace TaskManager {
class TasksModel;
}
class KWinSettings;

class WindowController : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(bool hasActiveWindow READ hasActiveWindow NOTIFY activeWindowChanged)
    Q_PROPERTY(QString windowTitle READ windowTitle NOTIFY activeWindowChanged)
    Q_PROPERTY(QVariant windowIcon READ windowIcon NOTIFY activeWindowChanged)
    Q_PROPERTY(bool isMaximized READ isMaximized NOTIFY activeWindowChanged)
    Q_PROPERTY(bool canMaximize READ canMaximize NOTIFY activeWindowChanged)
    Q_PROPERTY(bool canMinimize READ canMinimize NOTIFY activeWindowChanged)
    Q_PROPERTY(bool canClose READ canClose NOTIFY activeWindowChanged)
    Q_PROPERTY(int windowCount READ windowCount NOTIFY windowCountChanged)
    Q_PROPERTY(bool borderlessMaximized READ borderlessMaximized WRITE setBorderlessMaximized NOTIFY borderlessMaximizedChanged)
    Q_PROPERTY(QRect screenGeometry READ screenGeometry WRITE setScreenGeometry NOTIFY screenGeometryChanged)

public:
    explicit WindowController(QObject *parent = nullptr);
    ~WindowController() override;

    bool hasActiveWindow() const;
    QString windowTitle() const;
    QVariant windowIcon() const;
    bool isMaximized() const;
    bool canMaximize() const;
    bool canMinimize() const;
    bool canClose() const;
    int windowCount() const;

    bool borderlessMaximized() const;
    Q_INVOKABLE void setBorderlessMaximized(bool enabled);
    Q_INVOKABLE void setBorderlessMaximizedWindows(bool enabled) { setBorderlessMaximized(enabled); }

    QRect screenGeometry() const;
    void setScreenGeometry(const QRect &geometry);

    Q_INVOKABLE void toggleMaximize();
    Q_INVOKABLE void minimize();
    Q_INVOKABLE void close();
    Q_INVOKABLE void cycleWindow(int direction);

Q_SIGNALS:
    void activeWindowChanged();
    void windowCountChanged();
    void borderlessMaximizedChanged();
    void screenGeometryChanged();

private Q_SLOTS:
    void updateWindowState();

private:
    QModelIndex activeIndex() const;
    QList<int> validWindowRows() const;

    TaskManager::TasksModel *m_tasksModel{nullptr};

    bool m_hasActiveWindow{false};
    QString m_windowTitle{QStringLiteral("Plasma Workspace")};
    QVariant m_windowIcon;
    bool m_isMaximized{false};
    bool m_canMaximize{false};
    bool m_canMinimize{false};
    bool m_canClose{false};
    int m_windowCount{0};

    QRect m_screenGeometry;
    KWinSettings *m_kwinSettings{nullptr};
};
