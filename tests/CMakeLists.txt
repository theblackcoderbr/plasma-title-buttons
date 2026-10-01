# SPDX-License-Identifier: GPL-3.0-only
# SPDX-FileCopyrightText: 2026 Arthur Celestino

find_package(Qt6 ${QT_MIN_VERSION} REQUIRED COMPONENTS Test)
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
