# SPDX-License-Identifier: GPL-3.0-only
# SPDX-FileCopyrightText: 2026 Arthur Celestino

set(PLUGIN_TARGET windowtitleandbuttonsplugin)

qt_add_qml_module(${PLUGIN_TARGET}
    URI "org.kde.plasma.private.windowtitleandbuttons"
    VERSION 1.0
    OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/org/kde/plasma/private/windowtitleandbuttons"
    SOURCES
        windowcontroller.h
        windowcontroller.cpp
        kwinsettings.h
        kwinsettings.cpp
)

# Garante prefixo 'lib' no módulo de plugin para que o QQmlEngine resolva 'libwindowtitleandbuttonspluginplugin.so'
# e configura o RPATH com $ORIGIN para carregar a biblioteca de suporte do mesmo diretório.
set_target_properties(${PLUGIN_TARGET}plugin PROPERTIES
    PREFIX "lib"
    INSTALL_RPATH "$ORIGIN"
)

set_target_properties(${PLUGIN_TARGET} PROPERTIES
    INSTALL_RPATH "$ORIGIN"
)

target_link_libraries(${PLUGIN_TARGET}
    PRIVATE
        Qt6::Core
        Qt6::Gui
        Qt6::Qml
        Qt6::DBus
        KF6::ConfigCore
        PW::LibTaskManager
)

# Instalação do módulo QML gerado no diretório de plugins QML do KDE
install(TARGETS ${PLUGIN_TARGET}
    DESTINATION "${KDE_INSTALL_QMLDIR}/org/kde/plasma/private/windowtitleandbuttons"
)

install(TARGETS ${PLUGIN_TARGET}
    DESTINATION "${CMAKE_INSTALL_LIBDIR}"
)

install(TARGETS ${PLUGIN_TARGET}plugin
    DESTINATION "${KDE_INSTALL_QMLDIR}/org/kde/plasma/private/windowtitleandbuttons"
)

install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/org/kde/plasma/private/windowtitleandbuttons/qmldir"
    "${CMAKE_CURRENT_BINARY_DIR}/org/kde/plasma/private/windowtitleandbuttons/${PLUGIN_TARGET}.qmltypes"
    DESTINATION "${KDE_INSTALL_QMLDIR}/org/kde/plasma/private/windowtitleandbuttons"
)

# Instalação direta no diretório do próprio Plasmoid (contents/plugin)
# Torna o widget autossuficiente e imune a reinicializações que limpem variáveis de ambiente como QML2_IMPORT_PATH
set(PLASMOID_PLUGIN_DIR "${KDE_INSTALL_DATADIR}/plasma/plasmoids/org.kde.plasma.windowtitleandbuttons/contents/plugin")

install(TARGETS ${PLUGIN_TARGET} ${PLUGIN_TARGET}plugin
    DESTINATION "${PLASMOID_PLUGIN_DIR}"
)

install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/org/kde/plasma/private/windowtitleandbuttons/qmldir"
    "${CMAKE_CURRENT_BINARY_DIR}/org/kde/plasma/private/windowtitleandbuttons/${PLUGIN_TARGET}.qmltypes"
    DESTINATION "${PLASMOID_PLUGIN_DIR}"
)
