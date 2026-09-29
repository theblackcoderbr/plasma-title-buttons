import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation
    compactRepresentation: null

    // Expande para ocupar dinamicamente todo o espaço disponível no painel
    Layout.fillWidth: true
    Layout.fillHeight: true

    readonly property bool isVertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property real panelThickness: isVertical ? root.width : root.height
    readonly property bool showButtonsConfig: Plasmoid.configuration.showButtons
    readonly property bool buttonsAreMaximized: windowController.isMaximized
    readonly property bool buttonsVisible: showButtonsConfig && buttonsAreMaximized

    readonly property string titlePos: Plasmoid.configuration.titlePosition || "left"

    // Sincronização estrita: se o título estiver na mesma ponta dos botões, força a ponta oposta
    readonly property string buttonsPos: {
        let p = Plasmoid.configuration.buttonsPosition || "right";
        if (titlePos === "left") {
            return "right";
        } else if (titlePos === "right") {
            return "left";
        }
        return p;
    }

    readonly property bool buttonsOnLeft: buttonsPos === "left"
    readonly property bool buttonsOnRight: buttonsPos === "right"

    readonly property bool titleOnLeft: titlePos === "left"
    readonly property bool titleOnCenter: titlePos === "center"
    readonly property bool titleOnRight: titlePos === "right"

    // Controlador de Janelas nativo
    WindowController {
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

            // Contrapeso de simetria (para centralizar perfeitamente o título quando botões estão à direita)
            Item {
                id: leftCounterweight
                visible: root.titleOnCenter
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
            WindowTitle {
                id: titleCenter
                controller: windowController
                panelThickness: root.panelThickness
                showIcon: Plasmoid.configuration.showIcon
                showTitle: Plasmoid.configuration.showTitle
                alignment: "center"
                visible: root.titleOnCenter
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
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

            // Contrapeso de simetria (para centralizar perfeitamente o título quando botões estão à esquerda)
            Item {
                id: rightCounterweight
                visible: root.titleOnCenter
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
