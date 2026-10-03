#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-only
# SPDX-FileCopyrightText: 2026 Arthur Celestino
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$project_root"
catalog_directory=${podir:-"$project_root/po"}
mkdir -p "$catalog_directory"
temporary_directory=$(mktemp -d)
trap 'rm -rf "$temporary_directory"' EXIT HUP INT TERM

# Caminhos relativos e ordem estável evitam diferenças entre máquinas.
find package/contents src -type f \( -name '*.qml' -o -name '*.js' -o -name '*.cpp' -o -name '*.h' \) \
    | LC_ALL=C sort > "$temporary_directory/sources"
"${XGETTEXT:-xgettext}" \
    --language=C++ --from-code=UTF-8 --add-location=file --no-wrap \
    --keyword --keyword=i18n:1 --keyword=i18nc:1c,2 \
    --keyword=i18np:1,2 --keyword=i18ncp:1c,2,3 \
    --keyword=i18nd:2 --keyword=i18ndc:2c,3 \
    --keyword=i18ndp:2,3 --keyword=i18ndcp:2c,3,4 \
    --flag=i18n:1:kde-format --flag=i18nc:2:kde-format \
    --flag=i18np:1:kde-format --flag=i18np:2:kde-format \
    --flag=i18ncp:2:kde-format --flag=i18ncp:3:kde-format \
    --add-comments=i18n --package-name=plasma-title-buttons \
    --copyright-holder='Arthur Celestino' \
    --files-from="$temporary_directory/sources" \
    --output="$temporary_directory/messages.pot"
mv "$temporary_directory/messages.pot" "$catalog_directory/plasma_applet_org.kde.plasma.windowtitleandbuttons.pot"
