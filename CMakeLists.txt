# SPDX-License-Identifier: GPL-3.0-only
# SPDX-FileCopyrightText: 2026 Arthur Celestino

cmake_minimum_required(VERSION 3.20)

project(plasma-title-buttons LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

# Limite compartilhado de compilação e link para todos os alvos Ninja,
# inclusive quando invocado diretamente ou pelo alvo install.
set_property(GLOBAL APPEND PROPERTY JOB_POOLS applet_build=2)
set(CMAKE_JOB_POOL_COMPILE applet_build)
set(CMAKE_JOB_POOL_LINK applet_build)
set(CMAKE_AUTOGEN_PARALLEL 2)

option(BUILD_TESTING "Build isolated integration tests" OFF)

set(QT_MIN_VERSION "6.6.0")
set(KF6_MIN_VERSION "6.0.0")

find_package(ECM ${KF6_MIN_VERSION} REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(FeatureSummary)

find_package(Qt6 ${QT_MIN_VERSION} REQUIRED COMPONENTS
    Core
    Qml
    DBus
)

if(POLICY QTP0001)
    qt_policy(SET QTP0001 NEW)
endif()

find_package(KF6 ${KF6_MIN_VERSION} REQUIRED COMPONENTS
    Config
)

find_package(Plasma REQUIRED)
find_package(LibTaskManager REQUIRED)

set(TRANSLATION_DOMAIN "plasma_applet_org.kde.plasma.windowtitleandbuttons")
add_subdirectory(po)
add_subdirectory(src)

include(CTest)
if(BUILD_TESTING)
    add_subdirectory(tests)
endif()

# Instala o pacote do Plasmoid para o diretório padrão do Plasma 6
plasma_install_package(package org.kde.plasma.windowtitleandbuttons)

feature_summary(WHAT ALL INCLUDE_QUIET_PACKAGES FATAL_ON_MISSING_REQUIRED_PACKAGES)
