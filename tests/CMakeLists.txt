# SPDX-License-Identifier: GPL-3.0-only
# SPDX-FileCopyrightText: 2026 Arthur Celestino

find_package(Qt6 ${QT_MIN_VERSION} REQUIRED COMPONENTS Test Quick)
find_package(KF6 ${KF6_MIN_VERSION} REQUIRED COMPONENTS I18n)
find_program(DBUS_RUN_SESSION_EXECUTABLE dbus-run-session REQUIRED)

add_executable(kwinsettings_test
    kwinsettings_test.cpp
    ../src/kwinsettings.cpp
    ../src/kwinsettings.h
)
target_include_directories(kwinsettings_test PRIVATE ../src)
target_link_libraries(kwinsettings_test PRIVATE Qt6::Test Qt6::Quick Qt6::DBus KF6::ConfigCore KF6::I18n)
target_compile_definitions(kwinsettings_test PRIVATE CONFIG_QML_PATH="${PROJECT_SOURCE_DIR}/package/contents/ui/configGeneral.qml")

# Nunca usa o KWin ou o kwinrc da sessão real do usuário.
add_test(NAME kwinsettings COMMAND ${DBUS_RUN_SESSION_EXECUTABLE} --config-file=${CMAKE_CURRENT_SOURCE_DIR}/dbus-session.conf -- $<TARGET_FILE:kwinsettings_test>)
set_tests_properties(kwinsettings PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=offscreen;QT_QUICK_BACKEND=software")

add_executable(windowcontroller_test
    windowcontroller_test.cpp
    ../src/windowcontroller.cpp
    ../src/windowcontroller.h
    ../src/kwinsettings.cpp
    ../src/kwinsettings.h
)
target_include_directories(windowcontroller_test PRIVATE ../src)
target_link_libraries(windowcontroller_test PRIVATE Qt6::Test Qt6::Quick Qt6::DBus KF6::ConfigCore PW::LibTaskManager)
add_test(NAME windowcontroller COMMAND ${DBUS_RUN_SESSION_EXECUTABLE} --config-file=${CMAKE_CURRENT_SOURCE_DIR}/dbus-session.conf -- $<TARGET_FILE:windowcontroller_test>)
set_tests_properties(windowcontroller PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=offscreen;QT_QUICK_BACKEND=software")

add_executable(translations_test translations_test.cpp ../src/kwinsettings.cpp ../src/kwinsettings.h)
target_include_directories(translations_test PRIVATE ../src)
target_link_libraries(translations_test PRIVATE Qt6::Test Qt6::Quick Qt6::DBus KF6::ConfigCore KF6::I18n)
target_compile_definitions(translations_test PRIVATE
    APPLET_TRANSLATION_DOMAIN="${TRANSLATION_DOMAIN}"
    TRANSLATIONS_PATH="${PROJECT_BINARY_DIR}/po"
    PACKAGE_PATH="${PROJECT_SOURCE_DIR}/package"
)
add_dependencies(translations_test translations)
add_test(NAME translations COMMAND ${DBUS_RUN_SESSION_EXECUTABLE} --config-file=${CMAKE_CURRENT_SOURCE_DIR}/dbus-session.conf -- $<TARGET_FILE:translations_test>)
# Gettext desabilita traduções na localidade C, mesmo com LANGUAGE definido.
set_tests_properties(translations PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=offscreen;QT_QUICK_BACKEND=software;LC_ALL=en_US.UTF-8")

find_program(GETTEXT_XGETTEXT_EXECUTABLE xgettext REQUIRED)
find_program(GETTEXT_MSGCMP_EXECUTABLE msgcmp REQUIRED)
add_test(NAME translation_catalogs COMMAND ${CMAKE_COMMAND} -E env
    "XGETTEXT=${GETTEXT_XGETTEXT_EXECUTABLE}" "MSGCMP=${GETTEXT_MSGCMP_EXECUTABLE}"
    sh "${CMAKE_CURRENT_SOURCE_DIR}/check-translations.sh")

add_executable(installedplugin_test installedplugin_test.cpp)
target_link_libraries(installedplugin_test PRIVATE Qt6::Gui Qt6::Qml)
add_dependencies(installedplugin_test windowtitleandbuttonspluginplugin translations)
set(TEST_STAGING_DIR "${PROJECT_BINARY_DIR}/test-install")
add_test(NAME install_package COMMAND ${CMAKE_COMMAND}
    "-DBUILD_DIR=${PROJECT_BINARY_DIR}" "-DSTAGING_DIR=${TEST_STAGING_DIR}"
    -P "${CMAKE_CURRENT_SOURCE_DIR}/install-package.cmake")
set_tests_properties(install_package PROPERTIES FIXTURES_SETUP installed_package TIMEOUT 60)
add_test(NAME installed_plugin COMMAND ${DBUS_RUN_SESSION_EXECUTABLE}
    --config-file=${CMAKE_CURRENT_SOURCE_DIR}/dbus-session.conf -- $<TARGET_FILE:installedplugin_test>
    "${TEST_STAGING_DIR}/usr/share/plasma/plasmoids/org.kde.plasma.windowtitleandbuttons/contents/plugin")
set_tests_properties(installed_plugin PROPERTIES
    FIXTURES_REQUIRED installed_package TIMEOUT 30
    ENVIRONMENT "QT_QPA_PLATFORM=offscreen;QT_QUICK_BACKEND=software")
set_tests_properties(windowcontroller kwinsettings translations translation_catalogs PROPERTIES TIMEOUT 120)
