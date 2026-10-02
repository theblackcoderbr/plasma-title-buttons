// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: 2026 Arthur Celestino

import QtQuick

// O eixo x local sempre acompanha o comprimento do painel. A transformação
// também converte hit testing, espaçadores e limites do título para o eixo y.
Item {
    property bool vertical: false
    anchors.centerIn: parent
    width: vertical ? parent.height : parent.width
    height: vertical ? parent.width : parent.height
    rotation: vertical ? 90 : 0
}
