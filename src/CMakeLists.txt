set(PLUGIN_TARGET windowtitleandbuttonsplugin)

qt_add_qml_module(${PLUGIN_TARGET}
    URI "org.kde.plasma.private.windowtitleandbuttons"
    VERSION 1.0
    OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/org/kde/plasma/private/windowtitleandbuttons"
    SOURCES
        windowcontroller.h
        windowcontroller.cpp
)

target_link_libraries(${PLUGIN_TARGET}
    PRIVATE
        Qt6::Core
        Qt6::Gui
        Qt6::Qml
        Qt6::Quick
        Qt6::DBus
        KF6::CoreAddons
        KF6::ConfigCore
        KF6::ConfigGui
        KF6::WindowSystem
        Plasma::Plasma
        PW::LibTaskManager
)

# Instalação do módulo QML gerado no diretório de plugins QML do KDE
install(TARGETS ${PLUGIN_TARGET}
    DESTINATION "${KDE_INSTALL_QMLDIR}/org/kde/plasma/private/windowtitleandbuttons"
)

install(TARGETS ${PLUGIN_TARGET}plugin
    DESTINATION "${KDE_INSTALL_QMLDIR}/org/kde/plasma/private/windowtitleandbuttons"
)

install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/org/kde/plasma/private/windowtitleandbuttons/qmldir"
    DESTINATION "${KDE_INSTALL_QMLDIR}/org/kde/plasma/private/windowtitleandbuttons"
)
