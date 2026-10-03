// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: 2026 Arthur Celestino

import QtQuick

// Conserva a geometria durante a saída e libera o conteúdo ao terminar.
Loader {
    id: root
    property bool shown: false

    active: shown || opacity > 0
    visible: active
    // Controles em desaparecimento não recebem mouse, teclado ou ações acessíveis.
    enabled: shown
    opacity: shown ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 150 } }
}
