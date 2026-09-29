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

        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                // Clique comum: maximiza ou restaura a janela focada
                root.controller.toggleMaximize();
            } else if (mouse.button === Qt.MiddleButton) {
                // Clique do meio (scroll click): cicla para a próxima janela aberta
                root.controller.cycleWindow(1);
            }
        }

        onWheel: (wheel) => {
            // Rolar a roda do mouse: navega ciclicamente pelas janelas abertas
            if (wheel.angleDelta.y > 0) {
                root.controller.cycleWindow(-1); // Janela anterior
            } else if (wheel.angleDelta.y < 0) {
                root.controller.cycleWindow(1);  // Próxima janela
            }
        }
    }
}
