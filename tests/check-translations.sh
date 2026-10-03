#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-only
# SPDX-FileCopyrightText: 2026 Arthur Celestino
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
temporary_directory=$(mktemp -d)
trap 'rm -rf "$temporary_directory"' EXIT HUP INT TERM
domain=plasma_applet_org.kde.plasma.windowtitleandbuttons
podir="$temporary_directory" sh "$project_root/Messages.sh"

# Compara as mensagens, ignorando datas e comentários de cabeçalho.
"${MSGCMP:-msgcmp}" --use-untranslated "$project_root/po/$domain.pot" "$temporary_directory/$domain.pot"
"${MSGCMP:-msgcmp}" --use-untranslated "$temporary_directory/$domain.pot" "$project_root/po/$domain.pot"
# pt_BR é a tradução completa mantida pelo projeto; novos idiomas podem começar parciais.
"${MSGCMP:-msgcmp}" "$project_root/po/pt_BR/$domain.po" "$temporary_directory/$domain.pot"
