// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: 2026 Arthur Celestino

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.private.windowtitleandbuttons 1.0 as WTButtons

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation
    compactRepresentation: null

    // Expande para ocupar dinamicamente todo o espaço disponível no painel
    Layout.fillWidth: true
    Layout.fillHeight: true

    readonly property bool isVertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property real panelThickness: isVertical ? root.width : root.height

    // Estado das extremidades do painel
    property bool isAtLeftEdge: true
    property bool isAtRightEdge: true
    readonly property bool canShowButtons: isAtLeftEdge || isAtRightEdge

    readonly property bool showButtonsConfig: Plasmoid.configuration.showButtons && canShowButtons
    readonly property bool buttonsAreMaximized: windowController.isMaximized
    readonly property bool buttonsVisible: showButtonsConfig && buttonsAreMaximized

    readonly property string titlePos: Plasmoid.configuration.titlePosition || "left"

    // Sincronização estrita: se o título estiver na mesma ponta dos botões, força a ponta oposta.
    // Além disso, se uma extremidade do painel estiver ocupada por outros itens, força a ponta livre.
    readonly property string buttonsPos: {
        let p = Plasmoid.configuration.buttonsPosition || "right";
        if (titlePos === "left") {
            p = "right";
        } else if (titlePos === "right") {
            p = "left";
        }

        if (!isAtLeftEdge && isAtRightEdge) {
            return "right";
        } else if (!isAtRightEdge && isAtLeftEdge) {
            return "left";
        }
        return p;
    }

    readonly property bool buttonsOnLeft: buttonsPos === "left"
    readonly property bool buttonsOnRight: buttonsPos === "right"

    readonly property bool titleOnLeft: titlePos === "left"
    readonly property bool titleOnCenter: titlePos === "center"
    readonly property bool titleOnRight: titlePos === "right"

    readonly property bool centerInPanel: Plasmoid.configuration.centerInPanel || false

    // Controlador de Janelas nativo em C++
    WTButtons.WindowController {
        id: windowController
        screenGeometry: root.screenGeometry
    }

    // Sincroniza a configuração de borda de janelas maximizadas com o KWin
    Connections {
        target: Plasmoid.configuration
        function onBorderlessMaximizedChanged() {
            windowController.setBorderlessMaximized(Plasmoid.configuration.borderlessMaximized);
        }
    }

    Component.onCompleted: {
        if (Plasmoid.configuration.borderlessMaximized !== undefined) {
            windowController.setBorderlessMaximized(Plasmoid.configuration.borderlessMaximized);
        }
    }

    fullRepresentation: Item {
        id: container

        anchors.fill: parent
        Layout.fillWidth: true
        Layout.fillHeight: true

        // =========================================================================
        // GEOMETRIA REAL E DETECÇÃO DE BORDAS NO PAINEL
        // =========================================================================
        readonly property real hierarchyPosTrack: {
            let p1 = parent ? (root.isVertical ? parent.y : parent.x) : 0;
            let p2 = (parent && parent.parent) ? (root.isVertical ? parent.parent.y : parent.parent.x) : 0;
            let p3 = (parent && parent.parent && parent.parent.parent) ? (root.isVertical ? parent.parent.parent.y : parent.parent.parent.x) : 0;
            return p1 + p2 + p3 + (root.isVertical ? container.y : container.x);
        }

        readonly property real globalPos: {
            // Força dependência reativa em hierarchyPosTrack para atualizar quando o painel posicionar os itens
            let _track = hierarchyPosTrack;
            let pt = container.mapToItem(null, 0, 0);
            if (!pt) return 0.0;
            return root.isVertical ? pt.y : pt.x;
        }

        readonly property real currentLength: root.isVertical ? container.height : container.width

        readonly property real totalPanelLength: {
            let win = container.Window.window;
            if (win) {
                let val = root.isVertical ? win.height : win.width;
                if (val > 0) return val;
            }
            return 0.0;
        }

        // Tolerância de 40px para cobrir margens/padding externos do painel
        readonly property bool detectedAtLeftEdge: (currentLength > 50 && totalPanelLength > 100)
            ? (globalPos <= 40)
            : true

        readonly property bool detectedAtRightEdge: (currentLength > 50 && totalPanelLength > 100)
            ? ((totalPanelLength - (globalPos + currentLength)) <= 40)
            : true

        function syncEdges() {
            if (currentLength > 50 && totalPanelLength > 100) {
                root.isAtLeftEdge = detectedAtLeftEdge;
                root.isAtRightEdge = detectedAtRightEdge;
                if (Plasmoid.configuration.isAtLeftEdge !== detectedAtLeftEdge) {
                    Plasmoid.configuration.isAtLeftEdge = detectedAtLeftEdge;
                }
                if (Plasmoid.configuration.isAtRightEdge !== detectedAtRightEdge) {
                    Plasmoid.configuration.isAtRightEdge = detectedAtRightEdge;
                }
            }
        }

        onDetectedAtLeftEdgeChanged: syncEdges()
        onDetectedAtRightEdgeChanged: syncEdges()
        onCurrentLengthChanged: syncEdges()
        onGlobalPosChanged: syncEdges()

        Timer {
            id: initialEdgeSyncTimer
            interval: 400
            running: true
            repeat: false
            onTriggered: container.syncEdges()
        }

        RowLayout {
            id: contentLayout
            anchors.fill: parent
            spacing: 6

            // =============================================================
            // 1. SEÇÃO ESQUERDA
            // =============================================================

            // Botões de controle à esquerda
            WindowButtons {
                id: buttonsLeft
                controller: windowController
                panelThickness: root.panelThickness
                buttonStyle: Plasmoid.configuration.buttonsStyle
                buttonsSize: Plasmoid.configuration.buttonsSize
                visible: root.buttonsOnLeft && root.buttonsVisible
                opacity: (root.buttonsOnLeft && root.buttonsVisible) ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 150 } }
                Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                Layout.fillHeight: true
            }

            // Título à esquerda
            WindowTitle {
                id: titleLeft
                controller: windowController
                panelThickness: root.panelThickness
                showIcon: Plasmoid.configuration.showIcon
                showTitle: Plasmoid.configuration.showTitle
                alignment: "left"
                visible: root.titleOnLeft
                Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                Layout.fillWidth: root.titleOnLeft
                Layout.fillHeight: true
                Layout.maximumWidth: parent.width * 0.8
            }

            // Contrapeso de simetria (para centralizar o título quando botões estão à direita, no modo relativo)
            Item {
                id: leftCounterweight
                visible: root.titleOnCenter && !root.centerInPanel
                implicitWidth: (buttonsRight.visible && root.buttonsOnRight) ? buttonsRight.width : 0
                Behavior on implicitWidth { NumberAnimation { duration: 150 } }
            }

            // =============================================================
            // 2. ESPAÇADOR EXPANSIVO ESQUERDO
            // =============================================================
            Item {
                id: spacerLeft

                readonly property bool useAbsoluteCenter: root.titleOnCenter && root.centerInPanel

                readonly property real absoluteWidth: {
                    if (!useAbsoluteCenter) return -1;
                    let panelLen = container.totalPanelLength;
                    if (panelLen <= 0) return -1;

                    let panelCenter = panelLen / 2;
                    let localCenter = panelCenter - container.globalPos;
                    let titleW = (titleCenter.implicitWidth > 0) ? titleCenter.implicitWidth : titleCenter.width;
                    let titleLeft = localCenter - (titleW / 2);

                    let leftOccupied = (buttonsLeft.visible && root.buttonsOnLeft) ? (buttonsLeft.width + contentLayout.spacing) : 0;
                    return Math.max(0, titleLeft - leftOccupied - contentLayout.spacing);
                }

                Layout.fillWidth: !useAbsoluteCenter
                Layout.preferredWidth: useAbsoluteCenter ? absoluteWidth : -1
                Layout.minimumWidth: useAbsoluteCenter ? absoluteWidth : 0
                Layout.maximumWidth: useAbsoluteCenter ? absoluteWidth : -1
                visible: root.titleOnCenter || (!root.titleOnLeft && !root.buttonsOnLeft) || (root.titleOnLeft && root.buttonsOnRight)

                Behavior on Layout.preferredWidth { NumberAnimation { duration: 150 } }
            }

            // =============================================================
            // 3. SEÇÃO CENTRAL (Título centralizado)
            // =============================================================
            WindowTitle {
                id: titleCenter
                controller: windowController
                panelThickness: root.panelThickness
                showIcon: Plasmoid.configuration.showIcon
                showTitle: Plasmoid.configuration.showTitle
                alignment: "center"
                visible: root.titleOnCenter
                Layout.alignment: Qt.AlignVCenter | (spacerLeft.useAbsoluteCenter ? Qt.AlignLeft : Qt.AlignHCenter)
                Layout.fillHeight: true
                Layout.maximumWidth: parent.width * 0.65
            }

            // =============================================================
            // 4. ESPAÇADOR EXPANSIVO DIREITO
            // =============================================================
            Item {
                id: spacerRight
                Layout.fillWidth: true
                visible: root.titleOnCenter || (!root.titleOnRight && !root.buttonsOnRight) || (root.titleOnRight && root.buttonsOnLeft)
            }

            // =============================================================
            // 5. SEÇÃO DIREITA
            // =============================================================

            // Contrapeso de simetria (para centralizar o título quando botões estão à esquerda, no modo relativo)
            Item {
                id: rightCounterweight
                visible: root.titleOnCenter && !root.centerInPanel
                implicitWidth: (buttonsLeft.visible && root.buttonsOnLeft) ? buttonsLeft.width : 0
                Behavior on implicitWidth { NumberAnimation { duration: 150 } }
            }

            // Título à direita
            WindowTitle {
                id: titleRight
                controller: windowController
                panelThickness: root.panelThickness
                showIcon: Plasmoid.configuration.showIcon
                showTitle: Plasmoid.configuration.showTitle
                alignment: "right"
                visible: root.titleOnRight
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                Layout.fillWidth: root.titleOnRight
                Layout.fillHeight: true
                Layout.maximumWidth: parent.width * 0.8
            }

            // Botões de controle à direita
            WindowButtons {
                id: buttonsRight
                controller: windowController
                panelThickness: root.panelThickness
                buttonStyle: Plasmoid.configuration.buttonsStyle
                buttonsSize: Plasmoid.configuration.buttonsSize
                visible: root.buttonsOnRight && root.buttonsVisible
                opacity: (root.buttonsOnRight && root.buttonsVisible) ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 150 } }
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                Layout.fillHeight: true
            }
        }
    }
}
