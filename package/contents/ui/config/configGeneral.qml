import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support

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

    property string cfg_buttonsPosition: "right"
    property var cfg_buttonsPositionDefault

    property string cfg_buttonsStyle: "system"
    property var cfg_buttonsStyleDefault

    property string cfg_buttonsSize: "medium"
    property var cfg_buttonsSizeDefault

    property alias cfg_borderlessMaximized: borderlessCheckBox.checked
    property var cfg_borderlessMaximizedDefault

    // Garante que título e botões nunca fiquem simultaneamente no mesmo lado
    function onTitlePositionSelected(pos) {
        root.cfg_titlePosition = pos;
        if (pos === "left" && root.cfg_buttonsPosition === "left") {
            root.cfg_buttonsPosition = "right";
        } else if (pos === "right" && root.cfg_buttonsPosition === "right") {
            root.cfg_buttonsPosition = "left";
        }
    }

    Plasma5Support.DataSource {
        id: kwinConfigRunner
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            disconnectSource(sourceName);
        }
    }

    function saveConfig() {
        let val = borderlessCheckBox.checked ? "true" : "false";
        let cmd = "kwriteconfig6 --file kwinrc --group Windows --key BorderlessMaximizedWindows " + val + " && (qdbus org.kde.KWin /KWin reconfigure || busctl --user call org.kde.KWin /KWin org.kde.KWin reconfigure)";
        kwinConfigRunner.connectSource(cmd);
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

        QQC2.CheckBox {
            id: showButtonsCheckBox
            Kirigami.FormData.label: i18n("Window Buttons:")
            text: i18n("Show control buttons (Minimize, Maximize, Close)")
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
            Kirigami.FormData.label: i18n("Buttons Position:")
            spacing: Kirigami.Units.largeSpacing

            QQC2.RadioButton {
                id: buttonsLeftRadio
                text: i18n("Left")
                checked: root.cfg_buttonsPosition === "left"
                enabled: root.cfg_titlePosition !== "left"
                onToggled: if (checked) root.cfg_buttonsPosition = "left"
            }

            QQC2.RadioButton {
                id: buttonsRightRadio
                text: i18n("Right")
                checked: root.cfg_buttonsPosition === "right"
                enabled: root.cfg_titlePosition !== "right"
                onToggled: if (checked) root.cfg_buttonsPosition = "right"
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
