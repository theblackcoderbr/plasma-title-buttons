# SPDX-License-Identifier: GPL-3.0-only
# SPDX-FileCopyrightText: 2026 Arthur Celestino

find_package(Gettext REQUIRED)

# Um comando por catálogo: msgfmt participa do limite de dois jobs do build
# e valida os arquivos antes de gerar os binários instaláveis.
file(GLOB catalogs CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/*/${TRANSLATION_DOMAIN}.po")
set(compiled_catalogs)
foreach(catalog IN LISTS catalogs)
    get_filename_component(language_directory "${catalog}" DIRECTORY)
    get_filename_component(language "${language_directory}" NAME)
    set(locale_directory "${language}/LC_MESSAGES")
    set(output "${CMAKE_CURRENT_BINARY_DIR}/${locale_directory}/${TRANSLATION_DOMAIN}.mo")
    add_custom_command(
        OUTPUT "${output}"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_CURRENT_BINARY_DIR}/${locale_directory}"
        COMMAND ${GETTEXT_MSGFMT_EXECUTABLE} --check -o "${output}" "${catalog}"
        DEPENDS "${catalog}"
        JOB_POOL applet_build
        VERBATIM
    )
    list(APPEND compiled_catalogs "${output}")
    install(FILES "${output}" DESTINATION "${KDE_INSTALL_LOCALEDIR}/${locale_directory}")
    # Mantém a tradução junto ao widget quando seu pacote é copiado isoladamente.
    install(FILES "${output}" DESTINATION
        "${KDE_INSTALL_DATADIR}/plasma/plasmoids/org.kde.plasma.windowtitleandbuttons/contents/locale/${locale_directory}")
endforeach()
add_custom_target(translations ALL DEPENDS ${compiled_catalogs})
