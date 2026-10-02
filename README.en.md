# Plasma Title & Buttons

> 🌐 **Language / Idioma**: [Ler em Português (README.md)](README.md)

An elegant and highly configurable panel applet (plasmoid) for **KDE Plasma 6**, integrating the active window title and window control buttons (Minimize, Maximize/Restore, and Close) directly into your taskbar or top panel.

> Specially crafted for Unity-like or macOS-style workflows, providing maximum vertical screen estate savings by removing the native title bar on maximized windows.

> [!IMPORTANT]
> This project was developed primarily for personal use, with assistance from generative artificial intelligence tools. Although tested prior to published releases, it is provided without warranties and may not receive continuous maintenance. Community bug reports, suggestions, and pull requests are warmly welcomed.

---

## 🚀 Key Features

- **Smart Active Window Title**:
  - Displays the focused window title with customizable application icon support.
  - When no window is focused, gently falls back to `Plasma Workspace`.
  - **Quick Title Bar Actions**:
    - **Left click**: Minimizes the focused window when maximized; otherwise, maximizes it, if the window supports the action.
    - **Mouse wheel scroll or Middle click**: Cycles through open windows, including minimized ones, on the same screen, current virtual desktop, and current activity. Scrolling accumulates small touchpad movements and limits switching to once every 300 ms; middle click remains immediate. Attention requests do not let windows from other contexts enter the cycle.
- **Conditional Window Control Buttons**:
  - Close, Minimize, and Maximize/Restore buttons appear **only when the active window is maximized**, saving panel space during unmaximized work.
  - Actions unsupported by the window are disabled. All three styles support Tab navigation, Space activation, focus indicators, and translatable accessible names.
- **Selectable Button Styles**:
  - **System Theme (Default)**: Uses native icons from the active Plasma/KWin window decoration theme (Breeze, etc.).
  - **macOS / Traffic Lights**: Classic circular buttons (red, yellow, green) with symbols revealing on hover.
  - **Minimalist**: Clean, geometric monochrome design.
- **Dynamic Layout & Synchronized Alignment**:
  - **Automatic Expansion**: Dynamically occupies all available panel space without fixed sizing.
  - **Title Positioning**: Place the title on the **Left**, **Center**, or **Right**.
  - **Absolute Panel Centering**: Keeps the title mathematically centered relative to the entire panel width, compensating for asymmetrical elements (such as system tray, clock, or application launchers).
    - The calculation uses the displayed width, including when text is elided. If the panel center cannot fit within the widget's free space, the title stays within the available area to avoid overlapping the buttons.
  - **Smart Panel Edge Detection**:
    - Detects neighboring panel applets, distinguishing margins from small widgets. While the panel loads or is being edited, it waits for a valid layout without clearing preferences.
    - If other elements occupy one panel edge, buttons can only be placed on the free edge.
    - If other elements occupy both edges, the window buttons option is disabled and unchecked once the layout settles, with contextual help (`?`). After moving the widget to an edge, the option can be enabled again manually.
  - **Synchronized Button Placement**: The configuration interface automatically prevents the title and buttons from clashing on the same edge.
    - If the title occupies the only free edge, buttons are hidden. Settings help explains how to center or reposition the title, or move the widget. Preferences are preserved for when a valid position becomes available.
  - **Button Sizing Control**: Select between **Small (Compact)**, **Medium / Default**, and **Large (Spacious)**:
    - **Width / Click target area**: 24 px (small), 32 px (medium), and 44 px (large);
    - **Base icon size**: 14 px (small), 18 px (medium), and 22 px (large);
    - **Height**: adaptive to panel thickness (with optimized support for compact 24–26 px panels).
  - Independent toggle switches for Window Title, Window Icon, and Control Buttons.
- **Native Title Bar Removal**:
  - Seamless KWin integration to toggle `BorderlessMaximizedWindows`, hiding the native window title bar whenever an application is maximized.

---

## 🛠️ System Requirements

- **Operating System**: Any Linux distribution running KDE Plasma 6.
- **Desktop Environment**: KDE Plasma 6.7 or newer (Qt 6 and KF6).
  > [!NOTE]
  > Currently tested and validated on **KDE Plasma 6.7**. Earlier or later versions may require adaptations due to changes in Plasma Workspace internal APIs (specifically `PW::LibTaskManager` and KWin integration).
- **Build Dependencies**:
  - CMake 3.20+
  - C++20 compliant compiler (GCC or Clang)
  - Extra CMake Modules (ECM)
  - Ninja (recommended) or Make
  - Qt 6 (Core, Gui, Qml, Quick, Svg)
  - KDE Frameworks 6 (KCoreAddons, KI18n, KConfig, KWindowSystem)
  - Plasma 6 Workspace (`libplasma`, `PW::LibTaskManager`)

---

## 🏗️ Build & Installation

### Option 1: Standard Build (Any Linux Distribution)

Clone the repository and build the project using CMake and Ninja:

```bash
# 1. Configure the build for local user installation (~/.local)
cmake -B build -S . -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$HOME/.local" &&

# 2. Build with the default limit of two jobs
cmake --build build --parallel 2 &&

# 3. Install only after a successful build
cmake --install build
```

> [!TIP]
> **Parallelism**: The project uses two build jobs on all machines as a conservative memory usage default. CMake also limits Ninja compilation and linking tasks to two concurrent jobs. Installation with `cmake --install` does not trigger another build.

### Option 2: Reproducible Environment with Nix / NixOS (`shell.nix`)

For **Nix** or **NixOS** users, the repository includes a ready-to-use [`shell.nix`](shell.nix) file providing all required dependencies, build tools, and environment variables:

```bash
# 1. Enter the Nix shell
nix-shell

# 2. Build and install to the local user prefix (~/.local)
build-applet

# 3. (Optional) Run the applet in an isolated test window
run-test
```

### Applying Changes to the Plasma Session

Automated tests are optional (`-DBUILD_TESTING=ON`) and require Qt Test and `dbus-run-session`, available in the Nix shell. After building with this option, run `ctest --test-dir build --output-on-failure`. Tests use temporary configuration and a private D-Bus session without modifying the desktop session's KWin.

After installation, restart the Plasma shell to load the updated applet:

```bash
systemctl --user restart plasma-plasmashell.service
```

---

## ⚙️ Available Settings

Right-clicking the widget and selecting **Configure Window Title and Buttons...** provides the following options:

1. **Show Window Icon**: Toggle application icon visibility.
2. **Show Window Title**: Toggle title text visibility.
3. **Show Control Buttons**: Toggle close, minimize, and maximize buttons.
4. **Title Position**: Choose between **Left**, **Center**, or **Right**.
5. **Center relative to the entire panel**: Keep the title mathematically centered on the full panel width (absolute centering).
6. **Button Position**: Choose between **Left** or **Right** (automatically synchronized and restricted to available panel edges).
7. **Button Style**: System Theme, macOS (Traffic Lights), or Minimalist.
8. **Button Size**: Small, Medium (Default), or Large.
9. **Remove border on maximized windows**: Toggles KWin's global `BorderlessMaximizedWindows` setting. Changes apply immediately to all monitors and widget instances and are not undone by Cancel. Opening settings or adding another instance only reads the existing state. External changes are tracked automatically; save or reload failures are displayed in the interface.

---

## 📂 Repository Structure

```text
.
├── shell.nix                     # Reproducible development shell for Nix/NixOS
├── CMakeLists.txt                # Main CMake build system definition
├── README.md                     # Documentation in Portuguese
├── README.en.md                  # Documentation in English
├── AGENTS.md                     # Technical guidelines for development agents
├── src/                          # C++ backend (KWin and LibTaskManager integration)
│   ├── CMakeLists.txt            # Native QML module configuration (qt_add_qml_module)
│   ├── windowcontroller.h        # Window controller class declaration
│   ├── windowcontroller.cpp      # Focus tracking and window cycling
│   ├── kwinsettings.h            # Global KWin settings state
│   └── kwinsettings.cpp          # kwinrc synchronization and D-Bus reload
└── package/                      # Plasmoid package for Plasma 6
    ├── metadata.json             # Applet metadata and manifest
    └── contents/
        ├── config/
        │   ├── main.xml          # KConfigXT schema definitions
        │   └── config.qml        # Configuration pages registry
        └── ui/
            ├── main.qml          # Root plasmoid component and layout management
            ├── WindowTitle.qml   # Title rendering and interaction component
            ├── WindowButtons.qml # Window buttons rendering component
            └── configGeneral.qml # General settings page UI
```

---

## 🤝 Contributing

Community contributions, architectural suggestions, bug reports, and translations are warmly welcomed! Feel free to open an Issue or submit a Pull Request.

---

## 💡 Inspirations & Acknowledgements

This project was developed independently, but was inspired by the work of [Michail Vourlakos (psifidotos)](https://github.com/psifidotos) on the [Window Title](https://github.com/psifidotos/applet-window-title) and [Window Buttons](https://github.com/psifidotos/applet-window-buttons) applets.

Special thanks also to [dhruv8sh](https://github.com/dhruv8sh) for porting Window Title to Plasma 6, and to [moodyhunter](https://github.com/moodyhunter) for porting Window Buttons to Plasma 6.

This project features an independent implementation and does not intentionally incorporate code from the mentioned projects.

---

## 📄 License

This project is free software licensed under the **GNU General Public License v3.0** (**GPLv3**). See source file headers for individual copyright notices.
