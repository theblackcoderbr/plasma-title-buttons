if(NOT DEFINED BUILD_DIR OR NOT DEFINED STAGING_DIR)
    message(FATAL_ERROR "BUILD_DIR and STAGING_DIR are required")
endif()

# DESTDIR mantém até destinos absolutos dentro da área de teste. A instalação
# não dispara compilação e não toca na instalação da sessão do usuário.
file(REMOVE_RECURSE "${STAGING_DIR}")
execute_process(
    COMMAND "${CMAKE_COMMAND}" -E env "DESTDIR=${STAGING_DIR}"
        "${CMAKE_COMMAND}" --install "${BUILD_DIR}" --prefix /usr
    RESULT_VARIABLE result
)
if(NOT result EQUAL 0)
    message(FATAL_ERROR "Package installation failed: ${result}")
endif()

set(package "${STAGING_DIR}/usr/share/plasma/plasmoids/org.kde.plasma.windowtitleandbuttons")
foreach(file IN ITEMS metadata.json contents/ui/main.qml contents/config/main.xml
        contents/plugin/qmldir contents/plugin/windowtitleandbuttonsplugin.qmltypes
        contents/plugin/libwindowtitleandbuttonsplugin.so
        contents/plugin/libwindowtitleandbuttonspluginplugin.so
        contents/locale/pt_BR/LC_MESSAGES/plasma_applet_org.kde.plasma.windowtitleandbuttons.mo)
    if(NOT EXISTS "${package}/${file}")
        message(FATAL_ERROR "Missing installed file: ${package}/${file}")
    endif()
endforeach()
execute_process(
    COMMAND "${CMAKE_COMMAND}" -E compare_files
        "${package}/contents/locale/pt_BR/LC_MESSAGES/plasma_applet_org.kde.plasma.windowtitleandbuttons.mo"
        "${STAGING_DIR}/usr/share/locale/pt_BR/LC_MESSAGES/plasma_applet_org.kde.plasma.windowtitleandbuttons.mo"
    RESULT_VARIABLE result
)
if(NOT result EQUAL 0)
    message(FATAL_ERROR "Installed translation catalogs differ or are missing")
endif()
