// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: 2026 Arthur Celestino

import QtQuick

// Regra compartilhada pelo applet e pela configuração: nunca viola uma restrição
// para atender a outra. Posição vazia significa que não há combinação válida.
QtObject {
    property string titlePosition: "left"
    property string preferredPosition: "right"
    property bool isAtLeftEdge: true
    property bool isAtRightEdge: true

    readonly property bool leftAllowed: isAtLeftEdge && titlePosition !== "left"
    readonly property bool rightAllowed: isAtRightEdge && titlePosition !== "right"
    readonly property string position: {
        if (preferredPosition === "left" && leftAllowed) return "left";
        if (preferredPosition === "right" && rightAllowed) return "right";
        if (leftAllowed) return "left";
        if (rightAllowed) return "right";
        return "";
    }
    readonly property bool available: position !== ""
}
