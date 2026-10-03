// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: 2026 Arthur Celestino

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents3

RowLayout {
    id: root

    required property var controller
    property string buttonStyle: "system" // "system", "macos", "minimal"
    property string buttonsSize: "medium" // "small", "medium", "large"
    property real panelThickness: 32
    property bool vertical: false

    // Altura do botão respeitando a altura disponível no painel
    readonly property real buttonHeight: Math.max(16, Math.min(baseTargetHeight, panelThickness - 2))

    readonly property real baseTargetHeight: {
        switch (buttonsSize) {
            case "small": return 20;
            case "large": return 36;
            case "medium":
            default: return 26;
        }
    }

    // Largura do botão (permite alvos de clique amplos e fáceis de acertar, adaptando a painéis compactos)
    readonly property real buttonWidth: {
        let factor = Math.min(1.0, Math.max(0.75, panelThickness / 32.0));
        switch (buttonsSize) {
            case "small": return Math.round(24 * factor);
            case "large": return Math.round(44 * factor);
            case "medium":
            default: return Math.round(32 * factor);
        }
    }

    // Tamanho do ícone proporcional que NUNCA excede a altura do botão com margem de segurança
    readonly property real iconSize: Math.max(10, Math.min(baseIconSize, buttonHeight - 6))

    readonly property real baseIconSize: {
        switch (buttonsSize) {
            case "small": return 14;
            case "large": return 22;
            case "medium":
            default: return 18;
        }
    }

    // Diâmetro dos círculos estilo macOS (garante folga para animação sem transbordar)
    readonly property real macDiameter: Math.max(9, Math.min(baseMacDiameter, panelThickness - 8))

    readonly property real baseMacDiameter: {
        switch (buttonsSize) {
            case "small": return 12;
            case "large": return 22;
            case "medium":
            default: return 16;
        }
    }

    readonly property real macSymbolSize: Math.max(7, Math.floor(macDiameter * 0.6))
    readonly property real macSpacing: {
        let sp = buttonsSize === "small" ? 6 : (buttonsSize === "large" ? 12 : 8);
        return panelThickness < 30 ? Math.max(4, sp - 2) : sp;
    }

    spacing: buttonStyle === "macos" ? macSpacing : 3

    implicitHeight: buttonStyle === "macos" ? macDiameter : buttonHeight
    implicitWidth: {
        let count = 3;
        let btnW = (buttonStyle === "macos") ? macDiameter : buttonWidth;
        let sp = (buttonStyle === "macos") ? macSpacing : spacing;
        return (count * btnW) + ((count - 1) * sp);
    }

    // ==========================================
    // 1. ESTILO MAC-OS (Círculos Coloridos)
    // ==========================================
    component MacButton: SystemButton {
        id: macBtn
        property color normalColor: "#FF5F56"
        property color hoverBorderColor: "#E0443E"
        property string symbolText: ""
        implicitWidth: root.macDiameter
        implicitHeight: root.macDiameter
        padding: 0
        leftPadding: 0
        rightPadding: 0
        topPadding: 0
        bottomPadding: 0
        opacity: enabled ? 1 : 0.4
        background: Rectangle {
            radius: width / 2
            color: macBtn.normalColor
            border.color: macBtn.visualFocus ? Kirigami.Theme.highlightColor
                : (macBtn.hovered ? macBtn.hoverBorderColor : Qt.darker(macBtn.normalColor, 1.15))
            border.width: macBtn.visualFocus ? 2 : 1
        }
        scale: down ? 0.92 : (hovered ? 1.08 : 1.0)
        Behavior on scale { NumberAnimation { duration: 120 } }

        contentItem: Text {
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: macBtn.symbolText
            font.pixelSize: root.macSymbolSize
            font.bold: true
            color: "#4A0000"
            opacity: macBtn.hovered || macBtn.visualFocus ? 0.85 : 0.0
            Accessible.ignored: true
            Behavior on opacity { NumberAnimation { duration: 100 } }
        }

    }

    // ==========================================
    // 2. ESTILO SISTEMA (Breeze / Tema Ativo)
    // ==========================================
    component SystemButton: PlasmaComponents3.ToolButton {
        id: sysBtn
        property string iconName: ""
        signal clickedAction()

        implicitWidth: root.buttonWidth
        implicitHeight: root.buttonHeight
        display: PlasmaComponents3.AbstractButton.IconOnly
        // O controle nativo fornece Tab, Espaço e a ação de acessibilidade.
        focusPolicy: Qt.StrongFocus
        Accessible.role: Accessible.Button
        Accessible.name: text
        // O contêiner gira o layout inteiro; apenas o desenho é contrarrotacionado.
        Binding {
            target: sysBtn.contentItem
            property: "rotation"
            value: root.vertical ? -90 : 0
        }
        PlasmaComponents3.ToolTip.text: text
        PlasmaComponents3.ToolTip.visible: hovered || visualFocus
        PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay

        padding: 0
        leftPadding: 2
        rightPadding: 2
        topPadding: 2
        bottomPadding: 2

        icon.name: iconName
        icon.width: root.iconSize
        icon.height: root.iconSize

        // A ação acessível do Plasma emite clicked() diretamente, inclusive se
        // solicitada por código. Valida o estado antes de encaminhar a operação.
        onClicked: {
            if (enabled && visible) {
                clickedAction();
            }
        }
    }

    // ==========================================
    // 3. ESTILO MINIMALISTA (Geométrico Clean)
    // ==========================================
    component MinimalButton: SystemButton {
        id: minBtn
        opacity: enabled ? 1 : 0.4
        background: Rectangle {
            radius: 4
            color: minBtn.down ? Qt.rgba(1, 1, 1, 0.25)
                : (minBtn.hovered ? Qt.rgba(1, 1, 1, 0.15) : "transparent")
            border.color: Kirigami.Theme.highlightColor
            border.width: minBtn.visualFocus ? 2 : 0
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        contentItem: Item {
            Kirigami.Icon {
                anchors.centerIn: parent
                width: root.iconSize
                height: root.iconSize
                source: minBtn.iconName
                opacity: minBtn.hovered || minBtn.visualFocus ? 1.0 : 0.75
                Accessible.ignored: true
                Behavior on opacity { NumberAnimation { duration: 120 } }
            }
        }
    }

    // Somente o estilo selecionado mantém controles e bindings ativos.
    Loader {
        sourceComponent: root.buttonStyle === "macos" ? macosStyle
            : (root.buttonStyle === "minimal" ? minimalStyle : systemStyle)
    }

    // LAYOUT SEGUNDO O ESTILO SELECIONADO:

    // ------------------------------------------
    // Renderizador: Estilo macOS (Minimizar, Maximizar/Restaurar, Fechar)
    // ------------------------------------------
    Component {
        id: macosStyle
        Row {
            spacing: root.spacing

            MacButton {
                objectName: "macos-minimize"
                text: i18n("Minimize window")
                enabled: root.controller.hasActiveWindow && root.controller.canMinimize
                normalColor: "#FFBD2E"
                hoverBorderColor: "#DEA123"
                symbolText: "−"
                onClickedAction: root.controller.minimize()
            }

            MacButton {
                objectName: "macos-maximize"
                text: root.controller.isMaximized ? i18n("Restore window") : i18n("Maximize window")
                enabled: root.controller.hasActiveWindow && root.controller.canMaximize
                normalColor: "#27C93F"
                hoverBorderColor: "#1AAB29"
                symbolText: "+"
                onClickedAction: root.controller.toggleMaximize()
            }

            MacButton {
                objectName: "macos-close"
                text: i18n("Close window")
                enabled: root.controller.hasActiveWindow && root.controller.canClose
                normalColor: "#FF5F56"
                hoverBorderColor: "#E0443E"
                symbolText: "×"
                onClickedAction: root.controller.close()
            }
        }
    }

    // ------------------------------------------
    // Renderizador: Estilo Sistema / Breeze
    // ------------------------------------------
    Component {
        id: systemStyle
        Row {
            spacing: 2

            SystemButton {
                objectName: "system-minimize"
                text: i18n("Minimize window")
                enabled: root.controller.hasActiveWindow && root.controller.canMinimize
                iconName: "window-minimize"
                onClickedAction: root.controller.minimize()
            }

            SystemButton {
                objectName: "system-maximize"
                text: root.controller.isMaximized ? i18n("Restore window") : i18n("Maximize window")
                enabled: root.controller.hasActiveWindow && root.controller.canMaximize
                iconName: root.controller.isMaximized ? "window-restore" : "window-maximize"
                onClickedAction: root.controller.toggleMaximize()
            }

            SystemButton {
                objectName: "system-close"
                text: i18n("Close window")
                enabled: root.controller.hasActiveWindow && root.controller.canClose
                iconName: "window-close"
                onClickedAction: root.controller.close()
            }
        }
    }

    // ------------------------------------------
    // Renderizador: Estilo Minimalista
    // ------------------------------------------
    Component {
        id: minimalStyle
        Row {
            spacing: 2

            MinimalButton {
                objectName: "minimal-minimize"
                text: i18n("Minimize window")
                enabled: root.controller.hasActiveWindow && root.controller.canMinimize
                iconName: "window-minimize"
                onClickedAction: root.controller.minimize()
            }

            MinimalButton {
                objectName: "minimal-maximize"
                text: root.controller.isMaximized ? i18n("Restore window") : i18n("Maximize window")
                enabled: root.controller.hasActiveWindow && root.controller.canMaximize
                iconName: root.controller.isMaximized ? "window-restore" : "window-maximize"
                onClickedAction: root.controller.toggleMaximize()
            }

            MinimalButton {
                objectName: "minimal-close"
                text: i18n("Close window")
                enabled: root.controller.hasActiveWindow && root.controller.canClose
                iconName: "window-close"
                onClickedAction: root.controller.close()
            }
        }
    }
}
