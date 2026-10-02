// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: 2026 Arthur Celestino

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents3

Item {
    id: root

    required property var controller
    property bool showIcon: true
    property bool showTitle: true
    property string alignment: "left" // "left", "center", "right"
    property real panelThickness: 32
    property bool vertical: false

    implicitHeight: root.panelThickness
    implicitWidth: contentLayout.implicitWidth

    // Retângulo com destaque sutil de hover para indicar interatividade (sem transbordar o painel)
    Rectangle {
        id: hoverBg
        anchors.fill: parent
        anchors.topMargin: 1
        anchors.bottomMargin: 1
        anchors.leftMargin: -2
        anchors.rightMargin: -2
        radius: 4
        color: mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    RowLayout {
        id: contentLayout
        anchors.fill: parent
        spacing: 6
        layoutDirection: Qt.LeftToRight

        // Ícone da Janela Ativa
        Kirigami.Icon {
            id: iconItem
            // O texto acompanha o painel, mas o ícone da aplicação fica de pé.
            rotation: root.vertical ? -90 : 0
            visible: root.showIcon && root.controller.hasActiveWindow && (root.controller.windowIcon !== undefined)
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: Math.min(22, Math.max(14, root.panelThickness - 8))
            Layout.preferredHeight: Layout.preferredWidth
            source: root.controller.windowIcon

            scale: mouseArea.containsMouse ? 1.05 : 1.0
            Behavior on scale { NumberAnimation { duration: 120 } }
        }

        // Texto do Título
        PlasmaComponents3.Label {
            id: labelText
            visible: root.showTitle
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true

            text: root.controller.windowTitle
            // Títulos vêm de outros aplicativos e devem ser exibidos sem interpretar marcação.
            textFormat: Text.PlainText
            font.bold: root.controller.hasActiveWindow
            font.pixelSize: Math.max(10, Math.min(13, Math.floor(root.panelThickness * 0.42)))
            elide: Text.ElideRight
            maximumLineCount: 1
            horizontalAlignment: root.alignment === "center" ? Text.AlignHCenter : (root.alignment === "right" ? Text.AlignRight : Text.AlignLeft)

            opacity: root.controller.hasActiveWindow ? 1.0 : 0.65
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

        property real scrollDistance: 0
        property bool pixelScroll: false

        // Descarta movimento residual após uma pausa; nunca agenda trocas futuras.
        Timer {
            id: scrollReset
            interval: 200
            onTriggered: mouseArea.scrollDistance = 0
        }
        Timer {
            id: scrollCooldown
            interval: 300
        }
        onExited: scrollDistance = 0

        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                // Clique comum: minimiza se maximizada; caso contrário, maximiza a janela focada.
                if (root.controller.hasActiveWindow) {
                    if (root.controller.isMaximized) {
                        if (root.controller.canMinimize) {
                            root.controller.minimize();
                        }
                    } else if (root.controller.canMaximize) {
                        root.controller.toggleMaximize();
                    }
                }
            } else if (mouse.button === Qt.MiddleButton) {
                // Clique do meio (scroll click): cicla para a próxima janela aberta
                root.controller.cycleWindow(1);
            }
        }

        onWheel: (wheel) => {
            wheel.accepted = true;
            const usePixels = wheel.pixelDelta.x !== 0 || wheel.pixelDelta.y !== 0;
            const delta = usePixels ? wheel.pixelDelta.y : wheel.angleDelta.y;
            if (delta === 0) {
                return;
            }
            scrollReset.restart();
            // Eventos durante o intervalo são descartados, sem acumular uma fila.
            if (scrollCooldown.running) {
                return;
            }
            if (pixelScroll !== usePixels || scrollDistance * delta < 0) {
                scrollDistance = 0;
            }
            pixelScroll = usePixels;
            scrollDistance += delta;
            // Uma posição da roda convencional = 120 unidades angulares.
            // Touchpads com deltas em pixels precisam de um movimento deliberado.
            const threshold = usePixels ? 40 : 120;
            if (Math.abs(scrollDistance) < threshold) {
                return;
            }
            root.controller.cycleWindow(scrollDistance > 0 ? -1 : 1);
            scrollDistance = 0;
            scrollCooldown.start();
        }
    }
}
