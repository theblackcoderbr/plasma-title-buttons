# SPDX-License-Identifier: GPL-3.0-only
# SPDX-FileCopyrightText: 2026 Arthur Celestino

{ pkgs ? import ./nix/pkgs.nix }:

pkgs.mkShell {
  name = "plasma-title-buttons-dev-shell";

  nativeBuildInputs = with pkgs; [
    cmake
    ninja
    pkg-config
    actionlint # valida o workflow do GitHub Actions
    shellcheck # valida o script compartilhado de CI
    gettext # extração, atualização e compilação dos catálogos de tradução
    dbus # dbus-run-session para testes isolados da sessão real
    kdePackages.extra-cmake-modules
  ];

  buildInputs = with pkgs; [
    # Qt 6
    kdePackages.qtbase
    kdePackages.qtdeclarative

    # KDE Frameworks 6 & Plasma 6
    kdePackages.libplasma
    kdePackages.kirigami
    kdePackages.qqc2-desktop-style
    kdePackages.ki18n
    kdePackages.kconfig
    kdePackages.plasma-workspace

    # Development and test tools
    kdePackages.plasma-sdk # provides plasmoidviewer
  ];

  # Padrão conservador do projeto: dois processos, independentemente do hardware.
  NIX_BUILD_CORES = 2;
  CMAKE_BUILD_PARALLEL_LEVEL = 2;

  # Os testes de tradução precisam de en_US.UTF-8, mesmo sob hosts com locale C.
  LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";

  shellHook = ''
    echo "=========================================================="

    # Expõe os módulos de execução dos inputs e suas dependências propagadas:
    # os executáveis de teste não recebem os wrappers Qt dos pacotes Nix.
    qtShellQmlPath=
    qtShellPluginPath=
    for qtDependency in "''${pkgsHostTarget[@]}"; do
      addToSearchPath qtShellQmlPath "$qtDependency/lib/qt-6/qml"
      addToSearchPath qtShellPluginPath "$qtDependency/lib/qt-6/plugins"
    done
    export QML_IMPORT_PATH="$qtShellQmlPath:$QML_IMPORT_PATH"
    export QML2_IMPORT_PATH="$QML_IMPORT_PATH:$QML2_IMPORT_PATH"
    export QT_PLUGIN_PATH="$qtShellPluginPath:$QT_PLUGIN_PATH"
    export XDG_DATA_DIRS="$HOME/.local/share:$XDG_DATA_DIRS"

    build-applet() {
      cmake -B build -S . -G Ninja \
        -DCMAKE_BUILD_TYPE=Debug \
        -DCMAKE_INSTALL_PREFIX="$HOME/.local" || return $?
      cmake --build build --parallel 2 || return $?
      # Instala somente os artefatos já compilados, sem disparar outro build.
      cmake --install build
    }

    run-test() {
      plasmoidviewer -a org.kde.plasma.windowtitleandbuttons
    }
  '';
}
