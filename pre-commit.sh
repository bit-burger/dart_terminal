#!/usr/bin/env bash

dart format --set-exit-if-changed lib manual_test test || { echo "format failed"; exit 1; }
dart run import_sorter:main lib\/* test\/* manual_test\/* --no-comments --exit-if-changed || { echo "import_sorter failed"; exit 1; }
# dart analyze --fatal-infos --fatal-warnings || { echo "analyze failed"; exit 1; }
dart fix --apply
dart analyze || { echo "analyze failed"; exit 1; }
dart test || { echo "Tests failed"; exit 1; }