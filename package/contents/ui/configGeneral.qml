// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: 2026 Arthur Celestino

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../plugin" as WTButtons

Kirigami.ScrollablePage {
    id: root

    property alias cfg_showIcon: showIconCheckBox.checked
    property var cfg_showIconDefault

    property alias cfg_showTitle: showTitleCheckBox.checked
    property var cfg_showTitleDefault

    property alias cfg_showButtons: showButtonsCheckBox.checked
    property var cfg_showButtonsDefault

    property string cfg_titlePosition: "left"
    property var cfg_titlePositionDefault

    property alias cfg_centerInPanel: centerInPanelCheckBox.checked
    property var cfg_centerInPanelDefault

    property string cfg_buttonsPosition: "right"
    property var cfg_buttonsPositionDefault

    property string cfg_buttonsStyle: "system"
    property var cfg_buttonsStyleDefault

    property string cfg_buttonsSize: "medium"
    property var cfg_buttonsSizeDefault

    // Estado global: não participa do salvamento/restauração das preferências locais.
    WTButtons.KWinSettings {
        id: kwinSettings
    }

    property bool cfg_isAtLeftEdge: false
    property var cfg_isAtLeftEdgeDefault

    property bool cfg_isAtRightEdge: false
    property var cfg_isAtRightEdgeDefault
    property bool cfg_edgesKnown: false
    property var cfg_edgesKnownDefault

    // Não desmarca durante carga/edição. Só confirma o bloqueio com layout conhecido.
    Timer {
        interval: 300
        running: root.cfg_edgesKnown && !root.isAtLeftEdge && !root.isAtRightEdge && root.cfg_showButtons
        onTriggered: root.cfg_showButtons = false
    }

    // Estado das extremidades do painel fornecido pelas configurações sincronizadas do applet
    readonly property bool isAtLeftEdge: cfg_isAtLeftEdge
    readonly property bool isAtRightEdge: cfg_isAtRightEdge
    readonly property bool canShowButtons: cfg_edgesKnown && buttonPlacement.available
    readonly property string buttonPlacementHelp: !cfg_edgesKnown
        ? i18n("The panel layout is not ready or is being edited. Window buttons are temporarily unavailable; your preference is preserved.")
        : (!isAtLeftEdge && !isAtRightEdge)
        ? i18n("Both panel edges are occupied by other elements. Move this widget to a panel edge to show window buttons.")
        : (!canShowButtons
            ? i18n("The title occupies the only available panel edge. Center the title, move it to the opposite side, or move this widget to another panel edge to show window buttons.")
            : (!isAtLeftEdge
                ? i18n("The left or top edge of the panel is occupied by other elements. Window buttons can only be placed on the right or bottom edge.")
                : i18n("The right or bottom edge of the panel is occupied by other elements. Window buttons can only be placed on the left or top edge.")))

    ButtonPlacement {
        id: buttonPlacement
        titlePosition: root.cfg_titlePosition
        preferredPosition: root.cfg_buttonsPosition
        isAtLeftEdge: root.isAtLeftEdge
        isAtRightEdge: root.isAtRightEdge
    }

    // Preserva as preferências ao mudar a geometria; a posição efetiva é derivada.
    function onTitlePositionSelected(pos) {
        root.cfg_titlePosition = pos;
    }

    Kirigami.FormLayout {
        id: formLayout

        // ==========================================
        // 1. VISIBILIDADE DOS ELEMENTOS
        // ==========================================
        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Element Visibility")
        }

        QQC2.CheckBox {
            id: showIconCheckBox
            Kirigami.FormData.label: i18n("Window Icon:")
            text: i18n("Show application icon")
        }

        QQC2.CheckBox {
            id: showTitleCheckBox
            Kirigami.FormData.label: i18n("Window Title:")
            text: i18n("Show active window title")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Window Buttons:")
            spacing: Kirigami.Units.smallSpacing

            QQC2.CheckBox {
                id: showButtonsCheckBox
                text: i18n("Show control buttons (Minimize, Maximize, Close)")
                enabled: root.canShowButtons
            }

            Kirigami.ContextualHelpButton {
                visible: !root.canShowButtons
                toolTipText: root.buttonPlacementHelp
            }
        }

        // ==========================================
        // 2. DISPOSIÇÃO E ALINHAMENTO (SINCRONIZADOS)
        // ==========================================
        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Alignment & Positioning")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Title Position:")
            spacing: Kirigami.Units.largeSpacing

            QQC2.RadioButton {
                text: i18n("Left / Top")
                checked: root.cfg_titlePosition === "left"
                onToggled: if (checked) root.onTitlePositionSelected("left")
            }

            QQC2.RadioButton {
                text: i18n("Center")
                checked: root.cfg_titlePosition === "center"
                onToggled: if (checked) root.onTitlePositionSelected("center")
            }

            QQC2.RadioButton {
                text: i18n("Right / Bottom")
                checked: root.cfg_titlePosition === "right"
                onToggled: if (checked) root.onTitlePositionSelected("right")
            }
        }

        RowLayout {
            Kirigami.FormData.label: ""
            visible: root.cfg_titlePosition === "center"
            spacing: Kirigami.Units.smallSpacing

            QQC2.CheckBox {
                id: centerInPanelCheckBox
                text: i18n("Center relative to the entire panel (absolute)")
            }

            Kirigami.ContextualHelpButton {
                toolTipText: i18n("Maintains the window title mathematically centered on the full panel length, even when asymmetric elements (such as the system tray or application launcher) exist on the panel.")
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Buttons Position:")
            spacing: Kirigami.Units.largeSpacing

            QQC2.RadioButton {
                id: buttonsLeftRadio
                objectName: "buttonsLeftRadio"
                text: i18n("Left / Top")
                checked: buttonPlacement.position === "left"
                enabled: root.cfg_edgesKnown && buttonPlacement.leftAllowed
                onClicked: root.cfg_buttonsPosition = "left"
            }

            QQC2.RadioButton {
                id: buttonsRightRadio
                objectName: "buttonsRightRadio"
                text: i18n("Right / Bottom")
                checked: buttonPlacement.position === "right"
                enabled: root.cfg_edgesKnown && buttonPlacement.rightAllowed
                onClicked: root.cfg_buttonsPosition = "right"
            }

            Kirigami.ContextualHelpButton {
                visible: !root.canShowButtons || (!root.isAtLeftEdge || !root.isAtRightEdge)
                toolTipText: root.buttonPlacementHelp
            }
        }


        // ==========================================
        // 3. ESTILO E TAMANHO DOS BOTÕES
        // ==========================================
        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Buttons Style & Size")
        }

        QQC2.ComboBox {
            id: styleCombo
            Kirigami.FormData.label: i18n("Button Style:")
            property var options: [
                { text: i18n("System Theme (Breeze / Active Theme)"), value: "system" },
                { text: i18n("macOS Traffic Lights (Colored Circles)"), value: "macos" },
                { text: i18n("Minimalist (Geometric Outline)"), value: "minimal" }
            ]
            textRole: "text"
            valueRole: "value"
            model: options

            function findIndex(val) {
                if (!options) return 0;
                for (let i = 0; i < options.length; ++i) {
                    if (options[i].value === val) return i;
                }
                return 0;
            }

            currentIndex: findIndex(root.cfg_buttonsStyle)
            displayText: (currentIndex >= 0 && options && options[currentIndex]) ? options[currentIndex].text : ""

            onActivated: {
                root.cfg_buttonsStyle = options[currentIndex].value;
            }
        }

        QQC2.ComboBox {
            id: sizeCombo
            Kirigami.FormData.label: i18n("Button Size:")
            property var options: [
                { text: i18n("Small (Compact - 24px)"), value: "small" },
                { text: i18n("Medium (Default - 32px)"), value: "medium" },
                { text: i18n("Large (Spacious - 44px)"), value: "large" }
            ]
            textRole: "text"
            valueRole: "value"
            model: options

            function findIndex(val) {
                if (!options) return 1;
                for (let i = 0; i < options.length; ++i) {
                    if (options[i].value === val) return i;
                }
                return 1;
            }

            currentIndex: findIndex(root.cfg_buttonsSize)
            displayText: (currentIndex >= 0 && options && options[currentIndex]) ? options[currentIndex].text : ""

            onActivated: {
                root.cfg_buttonsSize = options[currentIndex].value;
            }
        }

        // ==========================================
        // 4. INTEGRAÇÃO COM KWIN
        // ==========================================
        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Window Management")
        }

        QQC2.CheckBox {
            id: borderlessCheckBox
            objectName: "borderlessCheckBox"
            Kirigami.FormData.label: i18n("Maximized Windows:")
            text: i18n("Hide original window title bar when maximized (KWin)")
            checked: kwinSettings.borderlessMaximized
            enabled: !kwinSettings.busy
            onClicked: {
                kwinSettings.setBorderlessMaximized(checked);
                // Restaura o binding mesmo se a gravação falhar sem mudar o valor global.
                checked = Qt.binding(() => kwinSettings.borderlessMaximized);
            }
        }

        Kirigami.ContextualHelpButton {
            Kirigami.FormData.label: ""
            toolTipText: i18n("This KWin setting applies to all monitors and widget instances. Changes take effect immediately and are not undone by Cancel.")
        }

        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: i18n("Global setting for all monitors. Changes apply immediately.")
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: kwinSettings.error !== WTButtons.KWinSettings.NoError
            type: Kirigami.MessageType.Error
            text: kwinSettings.error === WTButtons.KWinSettings.WriteError
                ? i18n("Could not save the KWin setting. Check write permissions for kwinrc and whether the setting is locked.")
                : i18n("The setting was saved, but KWin could not reload it. Retry to apply the saved setting.")
            actions: [
                Kirigami.Action {
                    text: i18n("Retry")
                    visible: kwinSettings.error === WTButtons.KWinSettings.ReloadError
                    enabled: !kwinSettings.busy
                    onTriggered: kwinSettings.reconfigure()
                }
            ]
        }
    }
}
