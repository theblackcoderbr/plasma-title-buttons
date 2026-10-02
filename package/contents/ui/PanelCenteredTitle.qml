// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: 2026 Arthur Celestino

import QtQuick

// Fora do RowLayout: a largura exibida é definida antes de calcular a posição,
// evitando realimentação entre o espaçador e o título truncado.
WindowTitle {
    id: root
    property real panelLength: 0
    property real panelOffset: 0
    property real leftInset: 0
    property real rightInset: 0

    readonly property real leftBound: Math.min(parent.width, Math.max(0, leftInset))
    readonly property real rightBound: Math.max(leftBound, parent.width - Math.max(0, rightInset))
    readonly property real availableWidth: rightBound - leftBound
    width: Math.max(0, Math.min(implicitWidth, parent.width * 0.65, availableWidth))
    height: parent.height
    clip: true
    alignment: "center"
    x: {
        const desiredCenter = panelLength > 0 ? panelLength / 2 - panelOffset : parent.width / 2;
        // Quando o centro do painel não cabe no applet, mantém o título na área
        // disponível. Os únicos espaços reservados são os dos botões visíveis.
        return Math.max(leftBound, Math.min(desiredCenter - width / 2, rightBound - width));
    }
}
