# SPDX-License-Identifier: GPL-3.0-only
# SPDX-FileCopyrightText: 2026 Arthur Celestino

{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "plasma-title-buttons-dev-shell";

  nativeBuildInputs = with pkgs; [
    cmake
    ninja
    pkg-config
    kdePackages.extra-cmake-modules
  ];

  buildInputs = with pkgs; [
    # Qt 6
    kdePackages.qtbase
    kdePackages.qtdeclarative
    kdePackages.qtsvg

    # KDE Frameworks 6 & Plasma 6
    kdePackages.libplasma
    kdePackages.kwindowsystem
    kdePackages.kcoreaddons
    kdePackages.ki18n
    kdePackages.kconfig
    kdePackages.kconfigwidgets
    kdePackages.plasma-workspace

    # Development and test tools
    kdePackages.plasma-sdk # provides plasmoidviewer
  ];

  # Padrão conservador do projeto: dois processos, independentemente do hardware.
  NIX_BUILD_CORES = 2;
  CMAKE_BUILD_PARALLEL_LEVEL = 2;

  shellHook = ''
    echo "=========================================================="

    export QML2_IMPORT_PATH="$HOME/.local/lib/qml:$HOME/.local/lib/qt-6/qml:$HOME/.local/lib64/qml:$PWD/build/src:$QML2_IMPORT_PATH"
    export QT_PLUGIN_PATH="$HOME/.local/lib/plugins:$QT_PLUGIN_PATH"
    export LD_LIBRARY_PATH="$HOME/.local/lib:$PWD/build/bin:$LD_LIBRARY_PATH"
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
