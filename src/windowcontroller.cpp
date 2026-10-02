// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: 2026 Arthur Celestino

#include "windowcontroller.h"
#include "kwinsettings.h"

#include <taskmanager/tasksmodel.h>
#include <taskmanager/abstracttasksmodel.h>
#include <taskmanager/activityinfo.h>
#include <taskmanager/taskfilterproxymodel.h>

WindowController::WindowController(QObject *parent)
    : QObject(parent)
    , m_tasksModel(new TaskManager::TaskFilterProxyModel(this))
    , m_kwinSettings(new KWinSettings(this))
{
    // Cada índice deve representar uma janela individual, evitando ações sobre grupos do mesmo aplicativo.
    auto *sourceTasks = new TaskManager::TasksModel(m_tasksModel);
    sourceTasks->setGroupMode(TaskManager::TasksModel::GroupDisabled);
    m_tasksModel->setSourceModel(sourceTasks);

    // Centraliza os filtros na API pública do proxy, inclusive para janelas pedindo atenção.
    m_tasksModel->setDemandingAttentionSkipsFilters(false);
    // Configura filtros para isolar a tela, o desktop virtual e a atividade correntes.
    m_tasksModel->setFilterByVirtualDesktop(true);
    m_tasksModel->setFilterByCurrentVirtualDesktop(true);
    m_tasksModel->setFilterByActivity(true);
    m_tasksModel->setFilterHidden(true);
    m_tasksModel->setFilterByScreen(true);

    auto *activityInfo = new TaskManager::ActivityInfo(this);
    const auto updateActivity = [this, activityInfo]() {
        m_tasksModel->setActivity(activityInfo->currentActivity());
        updateWindowState();
    };
    connect(activityInfo, &TaskManager::ActivityInfo::currentActivityChanged, this, updateActivity);
    updateActivity();

    connect(m_tasksModel, &QAbstractItemModel::dataChanged, this, &WindowController::updateWindowState);
    connect(m_tasksModel, &QAbstractItemModel::rowsInserted, this, &WindowController::updateWindowState);
    connect(m_tasksModel, &QAbstractItemModel::rowsRemoved, this, &WindowController::updateWindowState);
    connect(m_tasksModel, &QAbstractItemModel::modelReset, this, &WindowController::updateWindowState);

    // Mantém a API do controlador sincronizada com a preferência global do KWin.
    connect(m_kwinSettings, &KWinSettings::borderlessMaximizedChanged,
            this, &WindowController::borderlessMaximizedChanged);

    updateWindowState();
}

WindowController::~WindowController() = default;

bool WindowController::hasActiveWindow() const
{
    return m_hasActiveWindow;
}

QString WindowController::windowTitle() const
{
    return m_windowTitle;
}

QVariant WindowController::windowIcon() const
{
    return m_windowIcon;
}

bool WindowController::isMaximized() const
{
    return m_isMaximized;
}

bool WindowController::canMaximize() const
{
    return m_canMaximize;
}

bool WindowController::canMinimize() const
{
    return m_canMinimize;
}

bool WindowController::canClose() const
{
    return m_canClose;
}

int WindowController::windowCount() const
{
    return m_windowCount;
}

bool WindowController::borderlessMaximized() const
{
    return m_kwinSettings->borderlessMaximized();
}

void WindowController::setBorderlessMaximized(bool enabled)
{
    m_kwinSettings->setBorderlessMaximized(enabled);
}

QRect WindowController::screenGeometry() const
{
    return m_screenGeometry;
}

void WindowController::setScreenGeometry(const QRect &geometry)
{
    if (m_screenGeometry == geometry) {
        return;
    }
    m_screenGeometry = geometry;
    if (m_tasksModel) {
        m_tasksModel->setScreenGeometry(geometry);
    }
    Q_EMIT screenGeometryChanged();
    updateWindowState();
}

QModelIndex WindowController::activeIndex() const
{
    if (!m_tasksModel) {
        return {};
    }

    const int rowCount = m_tasksModel->rowCount();
    for (int r = 0; r < rowCount; ++r) {
        const QModelIndex idx = m_tasksModel->index(r, 0);
        if (idx.data(TaskManager::AbstractTasksModel::IsActive).toBool()) {
            return idx;
        }
    }
    return {};
}

QList<int> WindowController::validWindowRows() const
{
    QList<int> rows;
    if (!m_tasksModel) {
        return rows;
    }

    const int rowCount = m_tasksModel->rowCount();
    for (int r = 0; r < rowCount; ++r) {
        const QModelIndex idx = m_tasksModel->index(r, 0);
        if (idx.data(TaskManager::AbstractTasksModel::IsWindow).toBool()) {
            rows.append(r);
        }
    }
    return rows;
}

void WindowController::updateWindowState()
{
    if (!m_tasksModel) {
        return;
    }

    const QList<int> winRows = validWindowRows();
    const int newCount = winRows.size();
    if (m_windowCount != newCount) {
        m_windowCount = newCount;
        Q_EMIT windowCountChanged();
    }

    const QModelIndex active = activeIndex();

    bool hasActive = false;
    QString title = QStringLiteral("Plasma Workspace");
    QVariant icon;
    bool maximized = false;
    bool canMax = false;
    bool canMin = false;
    bool canCls = false;

    if (active.isValid() && active.data(TaskManager::AbstractTasksModel::IsWindow).toBool()) {
        hasActive = true;
        title = active.data(Qt::DisplayRole).toString();
        if (title.trimmed().isEmpty()) {
            title = QStringLiteral("Plasma Workspace");
        }
        icon = active.data(Qt::DecorationRole);
        maximized = active.data(TaskManager::AbstractTasksModel::IsMaximized).toBool();
        canMax = active.data(TaskManager::AbstractTasksModel::IsMaximizable).toBool();
        canMin = active.data(TaskManager::AbstractTasksModel::IsMinimizable).toBool();
        canCls = active.data(TaskManager::AbstractTasksModel::IsClosable).toBool();
    }

    if (m_hasActiveWindow != hasActive ||
        m_windowTitle != title ||
        m_windowIcon != icon ||
        m_isMaximized != maximized ||
        m_canMaximize != canMax ||
        m_canMinimize != canMin ||
        m_canClose != canCls) {

        m_hasActiveWindow = hasActive;
        m_windowTitle = title;
        m_windowIcon = icon;
        m_isMaximized = maximized;
        m_canMaximize = canMax;
        m_canMinimize = canMin;
        m_canClose = canCls;

        Q_EMIT activeWindowChanged();
    }
}

void WindowController::toggleMaximize()
{
    const QModelIndex idx = activeIndex();
    if (idx.isValid() && m_tasksModel) {
        m_tasksModel->requestToggleMaximized(idx);
    }
}

void WindowController::minimize()
{
    const QModelIndex idx = activeIndex();
    if (idx.isValid() && m_tasksModel) {
        m_tasksModel->requestToggleMinimized(idx);
    }
}

void WindowController::close()
{
    const QModelIndex idx = activeIndex();
    if (idx.isValid() && m_tasksModel) {
        m_tasksModel->requestClose(idx);
    }
}

void WindowController::cycleWindow(int direction)
{
    if (!m_tasksModel || direction == 0) {
        return;
    }

    const QList<int> rows = validWindowRows();
    if (rows.isEmpty()) {
        return;
    }

    int currentPos = -1;
    for (int i = 0; i < rows.size(); ++i) {
        const QModelIndex idx = m_tasksModel->index(rows[i], 0);
        if (idx.data(TaskManager::AbstractTasksModel::IsActive).toBool()) {
            currentPos = i;
            break;
        }
    }

    // Uma única janela sem foco ainda precisa ser ativada, por exemplo em outro monitor.
    if (rows.size() == 1 && currentPos != -1) {
        return;
    }

    int nextPos = 0;
    if (currentPos != -1) {
        if (direction > 0) {
            nextPos = (currentPos + 1) % rows.size();
        } else {
            nextPos = (currentPos - 1 + rows.size()) % rows.size();
        }
    }

    const QModelIndex targetIndex = m_tasksModel->index(rows[nextPos], 0);
    m_tasksModel->requestActivate(targetIndex);
}
