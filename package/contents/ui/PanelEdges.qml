// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: 2026 Arthur Celestino

import QtQuick

Item {
    id: root
    required property Item appletItem
    property bool vertical: false
    property bool editing: false
    property bool layoutReady: true
    visible: false

    // AppletContainer é o contêiner usado pelo painel Plasma 6.7. Procuramos o
    // marcador, sem assumir uma profundidade fixa na hierarquia. Em outro layout,
    // a posição fica desconhecida em vez de presumir que as pontas estão livres.
    readonly property var snapshot: {
        let own = appletItem;
        while (own && own.isAppletContainer !== true) own = own.parent;
        const unknown = { known: false, left: false, right: false };
        if (!own || !own.parent || editing || !layoutReady || !own.visible) return unknown;
        const length = vertical ? own.height : own.width;
        const start = vertical ? own.y : own.x;
        if (!Number.isFinite(length) || length <= 0 || !Number.isFinite(start)) return unknown;

        let left = true;
        let right = true;
        const siblings = own.parent.children;
        for (let item of siblings) {
            // Margens e itens auxiliares não são applets. Espaçadores adicionados
            // pelo usuário são applets e contam como vizinhos, mesmo se pequenos.
            if (item === own || item.isAppletContainer !== true || !item.visible) continue;
            const size = vertical ? item.height : item.width;
            const pos = vertical ? item.y : item.x;
            if (!Number.isFinite(size) || size <= 0 || !Number.isFinite(pos)) return unknown;
            if (pos + size <= start) left = false;
            else if (pos >= start + length) right = false;
            else return unknown; // Sobreposição durante carga/animação/arraste.
        }
        return { known: true, left: left, right: right };
    }

    readonly property bool known: snapshot.known
    readonly property bool isAtLeftEdge: known && snapshot.left
    readonly property bool isAtRightEdge: known && snapshot.right
    signal bothEdgesOccupied()

    // Evita apagar a preferência em estados transitórios da organização do painel.
    onSnapshotChanged: settleTimer.restart()
    Component.onCompleted: settleTimer.restart()
    Timer {
        id: settleTimer
        interval: 300
        onTriggered: {
            if (root.known && !root.isAtLeftEdge && !root.isAtRightEdge)
                root.bothEdgesOccupied();
        }
    }
}
