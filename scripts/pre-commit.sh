#!/usr/bin/env bash

dart format --set-exit-if-changed lib manual_test test
dart run import_sorter:main lib\/* test\/* manual_test\/*
# dart analyze --fatal-infos --fatal-warnings || { echo "analyze failed"; exit 1; }
dart fix --apply
dart analyze
# dart test # TODO: enable when tests are added