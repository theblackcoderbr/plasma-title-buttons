// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: 2026 Arthur Celestino

import QtQuick

// Símbolos geométricos locais; maximizar e restaurar usam o mesmo quadrado.
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
        ctx.lineJoin = "miter";
        ctx.lineCap = "square";
        ctx.beginPath();
        if (action === "minimize") {
            ctx.moveTo(5, 10); ctx.lineTo(15, 10);
        } else if (action === "maximize" || action === "restore") {
            ctx.rect(5, 5, 10, 10);
        } else if (action === "close") {
            ctx.moveTo(5, 5); ctx.lineTo(15, 15);
            ctx.moveTo(15, 5); ctx.lineTo(5, 15);
        }
        ctx.stroke();
    }
}
