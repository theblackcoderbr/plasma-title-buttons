# Plasma Title & Buttons

> 🌐 **Idioma**: [Ler em Português (README.md)](README.md)

An elegant and highly configurable panel applet (plasmoid) for **KDE Plasma 6**, integrating the active window title bar and window control buttons (Minimize, Maximize/Restore, and Close) directly into your taskbar or top panel.

Specially crafted for Unity-like or macOS-style workflows, providing maximum vertical screen estate savings by removing the native title bar on maximized windows.

> [!WARNING]
> ### ⚠️ Important Notice / Disclaimer
> - **AI-Assisted Development**: This project was built with the assistance of generative Artificial Intelligence tools. The author does not have a formal educational or professional background in computer science or software engineering.
> - **Use at Your Own Risk**: This software is provided "as is", without warranty of any kind. Any issues, desktop instability, or incompatibilities arising from its use are entirely the user's responsibility.
> - **Personal Project & No Long-Term Maintenance Guarantee**: This extension was conceived primarily for the author's own personal workflow. The author makes no commitment to provide ongoing support, regular updates, or long-term maintenance.
> - **Professional Feedback is Welcome**: Suggestions, bug fixes, architecture reviews, and pull requests from seasoned developers or tech professionals are warmly welcomed!

---

## 🚀 Key Features

- **Smart Active Window Title**:
  - Displays the focused window title with customizable application icon support.
  - When no window is focused, gently falls back to `Plasma Workspace`.
  - **Title Bar Actions**:
    - **Left click**: Toggles maximize/restore on the focused window.
    - **Mouse wheel scroll or Middle click**: Cycles through open windows on the same screen and virtual desktop.
- **Conditional Window Control Buttons**:
  - Close, Minimize, and Maximize/Restore buttons appear **only when the active window is maximized**, freeing panel space during unmaximized work.
- **Selectable Button Styles**:
  - **System Theme (Default)**: Uses native icons from the active Plasma/KWin window decoration theme (Breeze, etc.).
  - **macOS / Traffic Lights**: Classic circular buttons (red, yellow, green) with symbols revealing on hover.
  - **Minimalist**: Clean, geometric monochrome design.
- **Dynamic Layout & Synchronized Alignment**:
  - **Automatic Expansion**: Dynamically occupies all available panel space without fixed sizing.
  - **Title Positioning**: Place the title on the **Left**, **Center**, or **Right**.
  - **Synchronized Button Placement**: The configuration interface automatically prevents the title and buttons from clashing on the same edge (when title is on the left, buttons shift to the right and vice versa; centered title allows selecting either edge with symmetry balancing).
  - **Button Sizing Control**: Select between **Small (Compact - 24px)**, **Medium / Default (32px)**, and **Large (Spacious - 44px)**.
  - Independent toggle switches for Window Title, Window Icon, and Control Buttons.
- **Native Title Bar Removal**:
  - Seamless KWin integration to toggle `BorderlessMaximizedWindows`, hiding the native window title bar whenever an application is maximized.

---

## 🛠️ Requirements & Environment

- **Operating System**: Linux (developed and optimized for NixOS).
- **Desktop Environment**: KDE Plasma 6 (>= 6.0, tested on 6.7+).
- **Frameworks & Libraries**:
  - Qt 6 (Core, Gui, Qml, Quick, Svg)
  - KDE Frameworks 6 (Extra CMake Modules, KCoreAddons, KI18n, KConfig, KWindowSystem)
  - Plasma 6 Workspace (`libplasma`, `PW::LibTaskManager`)
  - Ninja and CMake 3.20+

---

## 🛡️ Resource-Constrained Safe Compilation (NixOS)

This project is tailored for machines with **~7GB of RAM**. Because compiling C++ with Qt 6 and KF6 across 12 CPU threads can quickly trigger Out-Of-Memory (OOM) errors and aggressive zram swap thrashing, the build environment is strictly capped at **2 parallel compilation threads**.

### 1. Enter the Nix Development Shell
```bash
nix-shell
```

### 2. Build and Install Locally
Inside `nix-shell`, you can run the helper alias:
```bash
build-applet
```
Or execute manually:
```bash
cmake -B build -S . -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$HOME/.local
ninja -C build -j2
ninja -C build install
```

### 3. Test with Plasmoidviewer
To preview and test the widget UI without restarting the Plasma shell:
```bash
run-test
# or manually:
plasmoidviewer -a org.kde.plasma.windowtitleandbuttons
```

---

## 📂 Repository Structure

```text
.
├── shell.nix                     # Reproducible NixOS shell with memory safeguards
├── CMakeLists.txt                # Global CMake build configuration
├── README.md                     # Portuguese documentation
├── README.en.md                  # English documentation
├── AGENTS.md                     # Architecture guidelines and rules for AI agents
├── src/                          # C++ backend (KWin and LibTaskManager integration)
│   ├── CMakeLists.txt
│   ├── plugin.h / plugin.cpp     # QML plugin registration
│   ├── windowcontroller.h        # Window controller header
│   └── windowcontroller.cpp      # Cycling, focus, and decoration logic
└── package/                      # Plasma 6 Plasmoid package
    ├── metadata.json             # Applet metadata and identifiers
    └── contents/
        ├── config/
        │   ├── main.xml          # KConfigXT settings schema
        │   └── config.qml        # Settings page loader
        └── ui/
            ├── main.qml          # Main applet view
            ├── WindowTitle.qml   # Title component and event interceptor
            ├── WindowButtons.qml # Window buttons component
            └── configGeneral.qml # General user settings page
```

---

## ⚙️ Available Settings in Plasma

Right-clicking the widget and selecting **Configure Window Title and Buttons...** provides the following options:
1. **Show Window Icon**: Toggle application icon visibility.
2. **Show Window Title**: Toggle title text visibility.
3. **Show Control Buttons**: Toggle close, minimize, and maximize buttons.
4. **Title Position**: Choose between Left, Center, or Right.
5. **Button Position**: Choose between Left or Right (automatically synchronized).
6. **Button Style**: System Theme, macOS, or Minimalist.
7. **Button Size**: Small (16px), Medium / Default (22px), or Large (28px).
8. **Remove border on maximized windows**: Toggles KWin's `BorderlessMaximizedWindows`.

---

## 📄 License

Distributed under the GPLv3 (or later) license, fully compatible with the KDE Plasma ecosystem.
