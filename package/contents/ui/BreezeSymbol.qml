// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: 2026 Arthur Celestino

import QtQuick

// Geometria local dos símbolos Breeze, sem consulta ao tema de ícones.
Canvas {
    required property string action
    required property color color
    Accessible.ignored: true
    onActionChanged: requestPaint()
    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.scale(width / 20, height / 20);
        ctx.strokeStyle = color;
        ctx.lineWidth = 1.5;
        ctx.lineJoin = "round";
        ctx.lineCap = "round";
        ctx.beginPath();
        if (action === "minimize") {
            ctx.moveTo(4, 7); ctx.lineTo(10, 13); ctx.lineTo(16, 7);
        } else if (action === "maximize") {
            ctx.moveTo(4, 13); ctx.lineTo(10, 7); ctx.lineTo(16, 13);
        } else if (action === "restore") {
            ctx.moveTo(4, 10); ctx.lineTo(10, 4); ctx.lineTo(16, 10);
            ctx.lineTo(10, 16); ctx.closePath();
        } else if (action === "close") {
            ctx.moveTo(5, 5); ctx.lineTo(15, 15);
            ctx.moveTo(15, 5); ctx.lineTo(5, 15);
        }
        ctx.stroke();
    }
}
