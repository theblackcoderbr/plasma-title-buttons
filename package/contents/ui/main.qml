// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: 2026 Arthur Celestino

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import "../plugin" as WTButtons

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
    readonly property bool isAtLeftEdge: panelEdges.isAtLeftEdge
    readonly property bool isAtRightEdge: panelEdges.isAtRightEdge
    readonly property bool canShowButtons: buttonPlacement.available

    readonly property bool showButtonsConfig: Plasmoid.configuration.showButtons && canShowButtons
    readonly property bool buttonsAreMaximized: windowController.isMaximized
    readonly property bool buttonsVisible: showButtonsConfig && buttonsAreMaximized

    readonly property string titlePos: Plasmoid.configuration.titlePosition || "left"

    // Resolve simultaneamente a posição do título e as extremidades livres.
    ButtonPlacement {
        id: buttonPlacement
        titlePosition: root.titlePos
        preferredPosition: Plasmoid.configuration.buttonsPosition || "right"
        isAtLeftEdge: root.isAtLeftEdge
        isAtRightEdge: root.isAtRightEdge
    }
    readonly property string buttonsPos: buttonPlacement.position

    readonly property bool buttonsOnLeft: buttonsPos === "left"
    readonly property bool buttonsOnRight: buttonsPos === "right"

    readonly property bool titleOnLeft: titlePos === "left"
    readonly property bool titleOnCenter: titlePos === "center"
    readonly property bool titleOnRight: titlePos === "right"

    readonly property bool centerInPanel: Plasmoid.configuration.centerInPanel || false

    PanelEdges {
        id: panelEdges
        appletItem: root
        vertical: root.isVertical
        layoutReady: !!Plasmoid.containment && Plasmoid.containment.isUiReady
        editing: !!(Plasmoid.containment && Plasmoid.containment.corona && Plasmoid.containment.corona.editMode)
        onKnownChanged: root.syncEdges()
        onIsAtLeftEdgeChanged: root.syncEdges()
        onIsAtRightEdgeChanged: root.syncEdges()
        onBothEdgesOccupied: Plasmoid.configuration.showButtons = false
        Component.onCompleted: root.syncEdges()
    }

    function syncEdges() {
        Plasmoid.configuration.edgesKnown = panelEdges.known;
        Plasmoid.configuration.isAtLeftEdge = panelEdges.isAtLeftEdge;
        Plasmoid.configuration.isAtRightEdge = panelEdges.isAtRightEdge;
    }

    // Controlador de Janelas nativo em C++
    WTButtons.WindowController {
        id: windowController
        screenGeometry: root.screenGeometry
    }

    WTButtons.KWinSettings {
        id: titlebarSettings
        property bool removed: false
        packageFile: Qt.resolvedUrl("../../metadata.json")
        managed: Plasmoid.configuration.hideOriginalTitlebar && Plasmoid.configuration.showButtons && !removed
    }

    Connections {
        target: Plasmoid
        function onDestroyedChanged(destroyed) {
            titlebarSettings.removed = destroyed;
        }
    }

    fullRepresentation: Item {
        id: container

        anchors.fill: parent
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

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

        PanelAxis {
            id: panelAxis
            vertical: root.isVertical

            RowLayout {
                id: contentLayout
                anchors.fill: parent
                spacing: 6

                // =============================================================
                // 1. SEÇÃO ESQUERDA
                // =============================================================

                // Botões de controle à esquerda
                FadingLoader {
                    id: buttonsLeft
                    shown: root.buttonsOnLeft && root.buttonsVisible
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                    Layout.fillHeight: true
                    sourceComponent: Component {
                        WindowButtons {
                            vertical: root.isVertical
                            controller: windowController
                            panelThickness: root.panelThickness
                            buttonStyle: Plasmoid.configuration.buttonsStyle
                            buttonsSize: Plasmoid.configuration.buttonsSize
                        }
                    }
                }

                // Título à esquerda
                Loader {
                    id: titleLeft
                    active: root.titleOnLeft
                    visible: active
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                    Layout.fillWidth: root.titleOnLeft
                    Layout.fillHeight: true
                    Layout.maximumWidth: parent.width * 0.8
                    sourceComponent: Component {
                        WindowTitle {
                            vertical: root.isVertical
                            controller: windowController
                            panelThickness: root.panelThickness
                            showIcon: Plasmoid.configuration.showIcon
                            showTitle: Plasmoid.configuration.showTitle
                            alignment: "left"
                        }
                    }
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

                    Layout.fillWidth: true
                    visible: root.titleOnCenter || (!root.titleOnLeft && !root.buttonsOnLeft) || (root.titleOnLeft && root.buttonsOnRight)
                }

                // =============================================================
                // 3. SEÇÃO CENTRAL (Título centralizado)
                // =============================================================
                Loader {
                    id: titleCenter
                    active: root.titleOnCenter && !root.centerInPanel
                    visible: active
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                    Layout.fillHeight: true
                    Layout.maximumWidth: parent.width * 0.65
                    sourceComponent: Component {
                        WindowTitle {
                            vertical: root.isVertical
                            controller: windowController
                            panelThickness: root.panelThickness
                            showIcon: Plasmoid.configuration.showIcon
                            showTitle: Plasmoid.configuration.showTitle
                            alignment: "center"
                        }
                    }
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
                Loader {
                    id: titleRight
                    active: root.titleOnRight
                    visible: active
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                    Layout.fillWidth: root.titleOnRight
                    Layout.fillHeight: true
                    Layout.maximumWidth: parent.width * 0.8
                    sourceComponent: Component {
                        WindowTitle {
                            vertical: root.isVertical
                            controller: windowController
                            panelThickness: root.panelThickness
                            showIcon: Plasmoid.configuration.showIcon
                            showTitle: Plasmoid.configuration.showTitle
                            alignment: "right"
                        }
                    }
                }

                // Botões de controle à direita
                FadingLoader {
                    id: buttonsRight
                    shown: root.buttonsOnRight && root.buttonsVisible
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                    Layout.fillHeight: true
                    sourceComponent: Component {
                        WindowButtons {
                            vertical: root.isVertical
                            controller: windowController
                            panelThickness: root.panelThickness
                            buttonStyle: Plasmoid.configuration.buttonsStyle
                            buttonsSize: Plasmoid.configuration.buttonsSize
                        }
                    }
                }
            }

            Loader {
                anchors.fill: parent
                active: root.titleOnCenter && root.centerInPanel
                visible: active
                sourceComponent: Component {
                    Item {
                        PanelCenteredTitle {
                            vertical: root.isVertical
                            controller: windowController
                            panelThickness: root.panelThickness
                            showIcon: Plasmoid.configuration.showIcon
                            showTitle: Plasmoid.configuration.showTitle
                            panelLength: container.totalPanelLength
                            panelOffset: container.globalPos
                            leftInset: buttonsLeft.visible ? buttonsLeft.x + buttonsLeft.width + contentLayout.spacing : 0
                            rightInset: buttonsRight.visible ? panelAxis.width - buttonsRight.x + contentLayout.spacing : 0
                        }
                    }
                }
            }
        }
    }
}
