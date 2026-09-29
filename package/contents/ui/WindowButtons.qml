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
    component MacButton: Rectangle {
        id: macBtn
        property color normalColor: "#FF5F56"
        property color hoverBorderColor: "#E0443E"
        property string symbolText: ""
        signal clicked()

        width: root.macDiameter
        height: root.macDiameter
        radius: root.macDiameter / 2
        color: normalColor
        border.color: mouseArea.containsMouse ? hoverBorderColor : Qt.darker(normalColor, 1.15)
        border.width: 1

        scale: mouseArea.pressed ? 0.92 : (mouseArea.containsMouse ? 1.08 : 1.0)
        Behavior on scale { NumberAnimation { duration: 120 } }

        Text {
            anchors.centerIn: parent
            text: macBtn.symbolText
            font.pixelSize: root.macSymbolSize
            font.bold: true
            color: "#4A0000"
            opacity: mouseArea.containsMouse ? 0.85 : 0.0
            Behavior on opacity { NumberAnimation { duration: 100 } }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: macBtn.clicked()
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

        padding: 0
        leftPadding: 2
        rightPadding: 2
        topPadding: 2
        bottomPadding: 2

        icon.name: iconName
        icon.width: root.iconSize
        icon.height: root.iconSize

        onClicked: clickedAction()
    }

    // ==========================================
    // 3. ESTILO MINIMALISTA (Geométrico Clean)
    // ==========================================
    component MinimalButton: Rectangle {
        id: minBtn
        property string iconName: ""
        signal clicked()

        implicitWidth: root.buttonWidth
        implicitHeight: root.buttonHeight
        radius: 4
        color: minMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }

        Kirigami.Icon {
            anchors.centerIn: parent
            width: root.iconSize
            height: root.iconSize
            source: minBtn.iconName
            opacity: minMouse.containsMouse ? 1.0 : 0.75
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }

        MouseArea {
            id: minMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: minBtn.clicked()
        }
    }

    // LAYOUT SEGUNDO O ESTILO SELECIONADO:

    // ------------------------------------------
    // Renderizador: Estilo macOS (Fechar, Minimizar, Maximizar)
    // ------------------------------------------
    Row {
        spacing: root.spacing
        visible: root.buttonStyle === "macos"

        MacButton {
            normalColor: "#FF5F56"
            hoverBorderColor: "#E0443E"
            symbolText: "×"
            onClicked: root.controller.close()
        }

        MacButton {
            normalColor: "#FFBD2E"
            hoverBorderColor: "#DEA123"
            symbolText: "−"
            onClicked: root.controller.minimize()
        }

        MacButton {
            normalColor: "#27C93F"
            hoverBorderColor: "#1AAB29"
            symbolText: "+"
            onClicked: root.controller.toggleMaximize()
        }
    }

    // ------------------------------------------
    // Renderizador: Estilo Sistema / Breeze
    // ------------------------------------------
    Row {
        spacing: 2
        visible: root.buttonStyle === "system"

        SystemButton {
            iconName: "window-minimize"
            onClickedAction: root.controller.minimize()
        }

        SystemButton {
            iconName: root.controller.isMaximized ? "window-restore" : "window-maximize"
            onClickedAction: root.controller.toggleMaximize()
        }

        SystemButton {
            iconName: "window-close"
            onClickedAction: root.controller.close()
        }
    }

    // ------------------------------------------
    // Renderizador: Estilo Minimalista
    // ------------------------------------------
    Row {
        spacing: 2
        visible: root.buttonStyle === "minimal"

        MinimalButton {
            iconName: "window-minimize"
            onClicked: root.controller.minimize()
        }

        MinimalButton {
            iconName: root.controller.isMaximized ? "window-restore" : "window-maximize"
            onClicked: root.controller.toggleMaximize()
        }

        MinimalButton {
            iconName: "window-close"
            onClicked: root.controller.close()
        }
    }
}
