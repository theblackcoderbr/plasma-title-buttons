# Plasma Title & Buttons

> 🌐 **Language / Idioma**: [Ler em Português (README.md)](README.md)

An elegant and highly configurable panel applet (plasmoid) for **KDE Plasma 6**, integrating the active window title and window control buttons (Minimize, Maximize/Restore, and Close) directly into your taskbar or top panel.

![Demonstration](docs/demo.gif)

> Specially crafted for Unity-like or macOS-style workflows, providing maximum vertical screen estate savings by removing the native title bar on maximized windows.

> [!IMPORTANT]
> This project was developed primarily for personal use, with assistance from generative artificial intelligence tools. Although tested prior to published releases, it is provided without warranties and may not receive continuous maintenance. Community bug reports, suggestions, and pull requests are warmly welcomed.

---

## 🚀 Key Features

- **Smart Active Window Title**:
  - Displays the focused window title, with an option to show the application icon. Titles are rendered as plain text.
  - When no window is focused, gently falls back to `Plasma Workspace`.
  - **Quick Title Bar Actions**:
    - **Left click**: Minimizes the focused window when maximized; otherwise, maximizes it, if the window supports the action.
    - **Mouse wheel scroll or Middle click**: Cycles through open windows, including minimized ones, on the same screen, current virtual desktop, and current activity. Scrolling accumulates small touchpad movements and limits switching to once every 300 ms; middle click remains immediate. Attention requests do not let windows from other contexts enter the cycle.
- **Conditional Window Control Buttons**:
  - Buttons appear in the order **Minimize, Maximize/Restore, Close**, when enabled, with an allowed panel position and a maximized active window.
  - Actions unsupported by the window are disabled. All three styles support Tab navigation, Space activation, focus indicators, and translatable accessible names.
  - When hiding, buttons immediately stop accepting input and complete a 150 ms opacity transition before releasing their occupied space.
- **Selectable Button Styles**:
  - **System Theme (Default)**: Uses native Plasma controls and icons from the active theme (Breeze, etc.).
  - **macOS / Traffic Lights**: Yellow for Minimize, green for Maximize/Restore, and red for Close, with symbols shown on hover or keyboard focus.
  - **Minimalist**: Clean, geometric monochrome design.
- **Dynamic Layout & Synchronized Alignment**:
  - **Vertical panels**: Top-to-bottom title and stacked buttons, with upright icons. Left/right correspond to top/bottom; centering follows the panel's length.
  - **Automatic Expansion**: Dynamically occupies all available panel space without fixed sizing.
  - **Title Positioning**: Place the title on the **Left**, **Center**, or **Right**.
  - **Absolute Panel Centering**: Keeps the title mathematically centered relative to the entire panel length, compensating for asymmetrical elements (such as system tray, clock, or application launchers).
    - The calculation uses the displayed width, including when text is elided. If the panel center cannot fit within the widget's free space, the title stays within the available area to avoid overlapping the buttons.
  - **Smart Panel Edge Detection**:
    - Detects neighboring panel applets, distinguishing margins from small widgets. While the panel loads or is being edited, it waits for a valid layout without clearing preferences.
    - If other elements occupy one panel edge, buttons can only be placed on the free edge.
    - If other elements occupy both edges, the window buttons option is disabled and unchecked once the layout settles, with contextual help (`?`). After moving the widget to an edge, the option can be enabled again manually.
  - **Synchronized Button Placement**: The configuration interface automatically prevents the title and buttons from clashing on the same edge.
    - If the title occupies the only free edge, buttons are hidden. Settings help explains how to center or reposition the title, or move the widget. Preferences are preserved for when a valid position becomes available.
  - **Button Sizing Control**: Select between **Small (Compact)**, **Medium / Default**, and **Large (Spacious)**:
    - **Base width in System and Minimalist styles**: 24 px (small), 32 px (medium), and 44 px (large), scaled down on compact panels;
    - **Base diameter in macOS style**: 12, 16, and 22 px, limited by panel thickness;
    - **Base icon size**: 14 px (small), 18 px (medium), and 22 px (large);
    - **Height**: adaptive to panel thickness (with optimized support for compact 24–26 px panels).
  - Independent toggle switches for Window Title, Window Icon, and Control Buttons.
- **Native Title Bar Removal**:
  - Seamless KWin integration to toggle `BorderlessMaximizedWindows`, hiding the native window title bar whenever an application is maximized.
- **On-Demand Loading**:
  - Instantiates only the title at the selected position and the button style in use. Controls are unloaded once the fade-out animation finishes.
  - The backend ignores property notifications that do not affect the widget and updates the window count and active window in a single model pass.
- **Translated Interface**:
  - Complete Brazilian Portuguese (`pt_BR`) translation, including help, errors, and accessible names, with English as the source language and fallback.

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
  - GNU Gettext (translation catalogs)
  - Qt 6 (Core, Gui for QIcon validation, Qml, and DBus used directly by the backend)
  - KDE Frameworks 6 (KConfig, ConfigCore component)
  - Plasma 6 Workspace (`libplasma`, `PW::LibTaskManager`)
- **Interface and transitive dependencies**: Qt Quick/Gui, the Plasma QML modules, and Kirigami remain necessary. `libplasma` also provides the package installation CMake macros; transitive dependencies are resolved by the Qt/KDE packages.
- **Validation and preview**: Qt Test, Qt Quick, KI18n, `dbus-run-session`, and the `en_US.UTF-8` locale for tests; Plasma SDK (`plasmoidviewer`) for visual previews. The Nix shell provides these resources.

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

### Option 2: Development Environment with Nix / NixOS (`shell.nix`)

For **Nix** or **NixOS** users, the repository includes a ready-to-use [`shell.nix`](shell.nix) file providing all required dependencies, build tools, and environment variables:

The environment uses the nixpkgs commit and hash recorded in [`nix/nixpkgs.json`](nix/nixpkgs.json). [`nix/pkgs.nix`](nix/pkgs.nix) verifies the source with `builtins.fetchTarball` and disables personal configuration and overlays. Channel updates and changes to `NIX_PATH` do not change the selected packages. First use may require network access to obtain sources and dependencies; flakes are not required. This follows the [nixpkgs pinning documentation](https://wiki.nixos.org/wiki/FAQ/Pinning_Nixpkgs).

Use `nix-shell --pure` to reduce the influence of session variables. The shell prioritizes Plasma QML modules from the pinned revision. The host architecture and graphical session still influence execution; the optional `pkgs` argument allows deliberately replacing the pinned package set for experiments.

`nix-shell` itself selects its initial Bash before loading the project, using channels or `PATH`, even with `--pure`. To pin that executable as well and avoid channels entirely, run from the repository root:

```bash
NIX_BUILD_SHELL="$(nix-build --no-out-link --max-jobs 2 --cores 2 -E '(import ./nix/pkgs.nix).bashInteractive')/bin/bash" \
  nix-shell --pure
```

This distinction is described in the [nix-shell manual](https://nix.dev/manual/nix/2.32/command-ref/nix-shell.html).

```bash
# 1. Enter the Nix shell
nix-shell

# 2. Build and install to the local user prefix (~/.local)
build-applet

# 3. (Optional) Run the applet in an isolated test window
run-test
```

To update dependencies, choose a full commit from the NixOS/nixpkgs repository and obtain the unpacked source hash:

```bash
nix-prefetch-url --unpack --name source "https://github.com/NixOS/nixpkgs/archive/<COMMIT>.tar.gz"
```

Update both `rev` and `sha256` in `nix/nixpkgs.json`; the printed base32 hash is accepted, as is the initial SRI format. Configure a new build directory to avoid dependency paths retained by the CMake cache, build with two jobs, and run the tests before installing and restarting the Shell. Review compatibility with the running Plasma session when changing Qt/KDE. Commit the pin file together with any necessary project changes.

### Applying Changes to the Plasma Session

CMake also installs the native module in the package's `contents/plugin/` and translation catalogs in `contents/locale/`. QML imports the plugin through a relative path, without relying on `QML2_IMPORT_PATH` to find that module in the session. Qt/KDE libraries remain system dependencies.

After installation, restart the Plasma shell to load the updated applet:

```bash
systemctl --user restart plasma-plasmashell.service
```

---

## 🧪 Automated Validation

The [CI workflow](.github/workflows/ci.yml) runs on pushes, pull requests, and manual dispatch in GitHub Actions, using Ubuntu 24.04 and the pinned Nix environment. It validates the workflow with actionlint and the script with ShellCheck, builds with two jobs, and runs tests sequentially. Failures stop the pipeline; logs and the JUnit report are retained in the `validation-reports` artifact for 14 days, including when a test fails. Actions are pinned to commits, with read permissions and no credentials persisted in the checkout.

To reproduce the same pipeline locally:

```bash
wtb_bash=$(nix-build --no-out-link --max-jobs 2 --cores 2 -E '(import ./nix/pkgs.nix).bashInteractive') &&
NIX_PATH= NIX_BUILD_SHELL="$wtb_bash/bin/bash" nix-shell --pure --run 'bash tests/ci.sh'
```

The script uses `build-ci/`, writes logs to `build-ci/logs/`, and produces `build-ci/junit.xml`. The test installation lives in `build-ci/test-install/`, isolated with `DESTDIR`; CI does not install into a desktop session or restart Plasma. Use a fresh `build-ci/` after changing the nixpkgs revision. To prevent merges with failing checks, require **Build and test (Nix)** in GitHub branch protection; the workflow alone does not enforce that policy.

Tests are optional and disabled by default. In the Nix shell, or with the test dependencies installed, run:

```bash
cmake -B build -S . -DBUILD_TESTING=ON &&
cmake --build build --parallel 2 &&
ctest --test-dir build --output-on-failure
```

| Test | Coverage |
|---|---|
| `windowcontroller` | Ungrouped windows, screen/desktop/activity filters, capabilities, circular navigation, and model updates. |
| `kwinsettings` | KWin synchronization and failures, QML settings, positioning, vertical panels, accessibility, scrolling, on-demand loading, and animations. |
| `translations` | Catalog domain, QML translation, and accessible names in `pt_BR`, English, and fallback for a language without a catalog. |
| `translation_catalogs` | Current `.pot` template and complete message coverage in `pt_BR`. |
| `install_package` | Isolated installation, required package files, and matching catalogs at both destinations. |
| `installed_plugin` | QML import of native types from the installed package, without linking the test to the backend. Requires the CTest installation fixture. |

The KDE build may also register `appstreamtest` to validate metadata, depending on available tools. C++ tests use temporary configuration and a private D-Bus session; KWin integration is simulated. QML tests run offscreen. Visual checks on real panels, multiple monitors, mouse/touchpad devices, and a screen reader remain manual steps.

---

## ⚙️ Available Settings

Right-clicking the widget and selecting **Configure Window Title and Buttons...** provides the following options:

1. **Show Window Icon**: Toggle application icon visibility. When no valid icon is available, the title does not reserve space for it.
2. **Show Window Title**: Toggle title text visibility.
3. **Show Control Buttons**: Toggle minimize, maximize/restore, and close buttons.
4. **Title Position**: Choose between **Left / Top**, **Center**, or **Right / Bottom**, according to panel orientation.
5. **Center relative to the entire panel**: Keep the title mathematically centered on the full panel width (absolute centering).
6. **Button Position**: Choose between **Left / Top** or **Right / Bottom**, respecting the title position and free panel edges. Conflicts hide the buttons without overwriting the preferred side.
7. **Button Style**: System Theme, macOS (Traffic Lights), or Minimalist.
8. **Button Size**: Small, Medium (Default), or Large.
9. **Hide original window title bar when maximized (KWin)**: A per-instance preference, off by default and saved with **Apply/OK**. While at least one instance has both this option and **Show Control Buttons** enabled, the widget requests `BorderlessMaximizedWindows` for all monitors. Disabling the buttons, clearing this option, removing the last participating instance, or uninstalling its package restores the previous state. Undoing removal reactivates the request. Closing the settings window does not affect active instances.

A KWin preference that already hid title bars before activation is preserved. When upgrading from older versions, clear the option and use **Restore title bars now** to explicitly remove the inherited global setting; this button acts immediately and is not undone by Cancel. Then enable the new option and apply to use automatic restoration.

The widget records its change in `kwinrc`, preserves other settings, and relinquishes restoration when it observes an external preference change. Normal Plasma shutdown restores the state; after an abrupt crash, the record allows recovery the next time the widget loads. There is no separate service to restore settings while Plasma remains forcibly stopped. Separate processes, such as a preview and the Shell, cannot control the preference simultaneously. Write/reload errors appear in settings; failures during removal are also logged.

---

## 📂 Repository Structure

```text
.
├── .github/workflows/ci.yml      # CI: lint, build, tests, and reports
├── .gitignore                    # Ignored generated artifacts and local files
├── AGENTS.md                     # Technical development guidelines
├── CMakeLists.txt                # Build, dependencies, translations, and optional tests
├── LICENSE                       # GPL-3.0 license
├── Messages.sh                   # Message extraction into the .pot template
├── README.md                     # Documentation in Portuguese
├── README.en.md                  # Documentation in English
├── shell.nix                     # Nix/NixOS development shell
├── nix/
│   ├── nixpkgs.json              # nixpkgs source commit and hash
│   └── pkgs.nix                  # Verified import without personal overlays
├── docs/
│   └── demo.gif                  # Widget demonstration
├── package/                      # Plasmoid package sources
│   ├── metadata.json             # Widget identity and translated names
│   └── contents/
│       ├── config/
│       │   ├── config.qml        # Configuration page registration
│       │   └── main.xml          # Per-instance preferences schema
│       └── ui/
│           ├── main.qml          # Controller integration and applet layout
│           ├── ButtonPlacement.qml    # Shared button placement rule
│           ├── FadingLoader.qml       # Fade-out animation and unloading
│           ├── PanelAxis.qml          # Local axis for horizontal/vertical panels
│           ├── PanelCenteredTitle.qml # Centering along the entire panel length
│           ├── PanelEdges.qml         # Neighbor and free-edge detection
│           ├── WindowButtons.qml      # Accessible controls and on-demand style
│           ├── WindowTitle.qml        # Title, icon, and mouse interaction
│           └── configGeneral.qml      # Settings interface
├── po/
│   ├── CMakeLists.txt            # Catalog validation, compilation, and installation
│   ├── update.sh                 # Template and .po file updates
│   ├── plasma_applet_org.kde.plasma.windowtitleandbuttons.pot
│   └── pt_BR/
│       └── plasma_applet_org.kde.plasma.windowtitleandbuttons.po
├── src/
│   ├── CMakeLists.txt            # Native QML module and plugin installation
│   ├── kwinsettings.cpp          # kwinrc synchronization and D-Bus reload
│   ├── kwinsettings.h            # Reactive global preference and error states
│   ├── windowcontroller.cpp      # Window filters, focus, capabilities, and actions
│   └── windowcontroller.h        # Controller API exposed to QML
└── tests/
    ├── CMakeLists.txt            # Test executables and CTest registration
    ├── check-translations.sh     # Template freshness and pt_BR coverage
    ├── ci.sh                     # Shared CI and local validation pipeline
    ├── install-package.cmake     # Isolated installation and package validation
    ├── installedplugin_test.cpp  # Loading the installed plugin
    ├── dbus-session.conf         # Private D-Bus configuration for tests
    ├── kwinsettings_test.cpp     # KWin integration and QML components
    ├── translations_test.cpp     # Actual QML translation and accessibility
    └── windowcontroller_test.cpp # Simulated models and per-window actions
```

`build/` contains generated artifacts, including `.mo` catalogs in `build/po/`. The `contents/plugin/` and `contents/locale/` directories are populated in the package installed by CMake. Local reports `RELATORIO_REVISAO.md` and `RELATORIO_DESENVOLVIMENTO.md` are ignored by Git and are not part of the tracked tree above.

---

## 🌐 Translations

The interface follows Plasma's language, with a complete **Brazilian Portuguese (`pt_BR`)** translation and English as the source language and fallback. Application window titles and the no-window text `Plasma Workspace` are preserved.

The build validates catalogs with `msgfmt --check` and compiles them automatically; `cmake --install build` installs `.mo` files both in `share/locale` and in the widget package's `contents/locale`. The translation domain is `plasma_applet_org.kde.plasma.windowtitleandbuttons`.

To update the `.pot` template and merge source changes into `.po` catalogs, run with GNU Gettext available (included in the Nix shell):

```bash
sh po/update.sh
```

`Messages.sh` only extracts messages; `po/update.sh` also merges them into existing catalogs. After changing interface text, update the catalogs and review new or modified messages. The `translation_catalogs` test requires complete `pt_BR` coverage; new languages may start with partial translations.

Edit `po/pt_BR/plasma_applet_org.kde.plasma.windowtitleandbuttons.po` to revise the translation. To add another language, create `po/<language>/` and use `msginit` with the template in `po/`. Also translate `Name[<language>]` and `Description[<language>]` in `package/metadata.json`, which the widget picker uses. Reconfigure and build after adding a language.

Tests check that the template is current, all `pt_BR` messages are translated, and QML loads the catalog for controls, accessible names, and settings. They also check the English fallback. The translation test requires the `en_US.UTF-8` locale, provided by the Nix shell; enable that locale on other distributions before running the tests. After installation, preview the translation with:

```bash
LC_ALL=pt_BR.UTF-8 LANGUAGE=pt_BR plasmoidviewer -a org.kde.plasma.windowtitleandbuttons
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
