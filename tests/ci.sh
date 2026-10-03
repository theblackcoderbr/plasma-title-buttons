#!/usr/bin/env bash
set -euo pipefail

project_directory=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
cd "$project_directory"
mkdir -p build-ci/logs

# O mesmo comando é usado localmente e no runner; pipefail preserva falhas
# mesmo quando a saída é copiada para os artefatos de diagnóstico.
actionlint .github/workflows/ci.yml 2>&1 | tee build-ci/logs/workflow.log
shellcheck tests/ci.sh 2>&1 | tee build-ci/logs/shellcheck.log
cmake -B build-ci -S . -G Ninja -DBUILD_TESTING=ON \
    -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX="$HOME/.local" \
    2>&1 | tee build-ci/logs/configure.log
cmake --build build-ci --parallel 2 2>&1 | tee build-ci/logs/build.log
ctest --test-dir build-ci --parallel 1 --output-on-failure --no-tests=error \
    --output-junit junit.xml 2>&1 | tee build-ci/logs/tests.log
