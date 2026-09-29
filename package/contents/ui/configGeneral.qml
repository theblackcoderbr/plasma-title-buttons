// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: 2026 Arthur Celestino

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

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

    property alias cfg_borderlessMaximized: borderlessCheckBox.checked
    property var cfg_borderlessMaximizedDefault

    property bool cfg_isAtLeftEdge: true
    property var cfg_isAtLeftEdgeDefault

    property bool cfg_isAtRightEdge: true
    property var cfg_isAtRightEdgeDefault

    // Estado das extremidades do painel fornecido pelas configurações sincronizadas do applet
    readonly property bool isAtLeftEdge: cfg_isAtLeftEdge
    readonly property bool isAtRightEdge: cfg_isAtRightEdge
    readonly property bool canShowButtons: isAtLeftEdge || isAtRightEdge

    onIsAtLeftEdgeChanged: enforceButtonEdgeConsistency()
    onIsAtRightEdgeChanged: enforceButtonEdgeConsistency()

    function enforceButtonEdgeConsistency() {
        if (!isAtLeftEdge && isAtRightEdge) {
            if (root.cfg_buttonsPosition === "left") {
                root.cfg_buttonsPosition = "right";
            }
        } else if (!isAtRightEdge && isAtLeftEdge) {
            if (root.cfg_buttonsPosition === "right") {
                root.cfg_buttonsPosition = "left";
            }
        }
    }

    // Garante que título e botões nunca fiquem simultaneamente no mesmo lado
    // e respeita a disponibilidade das pontas do painel
    function onTitlePositionSelected(pos) {
        root.cfg_titlePosition = pos;
        if (pos === "left") {
            if (root.isAtRightEdge) {
                root.cfg_buttonsPosition = "right";
            }
        } else if (pos === "right") {
            if (root.isAtLeftEdge) {
                root.cfg_buttonsPosition = "left";
            }
        } else if (pos === "center") {
            enforceButtonEdgeConsistency();
        }
    }

    Component.onCompleted: {
        enforceButtonEdgeConsistency();
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
                toolTipText: i18n("Window control buttons can only be placed at the edges of the panel. Because there are other elements on both sides of this widget, buttons are disabled.")
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
                text: i18n("Left")
                checked: root.cfg_titlePosition === "left"
                onToggled: if (checked) root.onTitlePositionSelected("left")
            }

            QQC2.RadioButton {
                text: i18n("Center")
                checked: root.cfg_titlePosition === "center"
                onToggled: if (checked) root.onTitlePositionSelected("center")
            }

            QQC2.RadioButton {
                text: i18n("Right")
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
                toolTipText: i18n("Maintains the window title mathematically centered on the full panel width, even when asymmetric elements (such as the system tray or application launcher) exist on the panel.")
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Buttons Position:")
            spacing: Kirigami.Units.largeSpacing

            QQC2.RadioButton {
                id: buttonsLeftRadio
                text: i18n("Left")
                checked: root.cfg_buttonsPosition === "left"
                enabled: root.canShowButtons && root.isAtLeftEdge && (root.cfg_titlePosition !== "left")
                onToggled: if (checked) root.cfg_buttonsPosition = "left"
            }

            QQC2.RadioButton {
                id: buttonsRightRadio
                text: i18n("Right")
                checked: root.cfg_buttonsPosition === "right"
                enabled: root.canShowButtons && root.isAtRightEdge && (root.cfg_titlePosition !== "right")
                onToggled: if (checked) root.cfg_buttonsPosition = "right"
            }

            Kirigami.ContextualHelpButton {
                visible: !root.canShowButtons || (!root.isAtLeftEdge || !root.isAtRightEdge)
                toolTipText: !root.canShowButtons
                    ? i18n("Both panel edges are occupied by other elements. Window buttons cannot be placed.")
                    : (!root.isAtLeftEdge
                        ? i18n("The left edge of the panel is occupied by other elements. Window buttons can only be placed on the right edge.")
                        : i18n("The right edge of the panel is occupied by other elements. Window buttons can only be placed on the left edge."))
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
            Kirigami.FormData.label: i18n("Maximized Windows:")
            text: i18n("Hide original window title bar when maximized (KWin)")
        }

        Kirigami.ContextualHelpButton {
            Kirigami.FormData.label: ""
            toolTipText: i18n("Enables KWin's BorderlessMaximizedWindows setting, removing the window's original decoration when maximized to save screen space.")
        }
    }
}
