#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-only
# SPDX-FileCopyrightText: 2026 Arthur Celestino
set -eu

catalog_directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
podir="$catalog_directory" sh "$catalog_directory/../Messages.sh"
for catalog in "$catalog_directory"/*/plasma_applet_org.kde.plasma.windowtitleandbuttons.po; do
    [ -f "$catalog" ] || continue
    # Textos alterados ficam pendentes em vez de receber traduções aproximadas.
    "${MSGMERGE:-msgmerge}" --update --backup=none --no-fuzzy-matching --no-wrap \
        "$catalog" "$catalog_directory/plasma_applet_org.kde.plasma.windowtitleandbuttons.pot"
done
