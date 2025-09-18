#!/bin/bash
# Run the Dart file passed as argument with VM service enabled and paused on start

if [ -z "$1" ]; then
  echo "Usage: $0 <dart_file.dart> [args...]"
  exit 1
fi

DART_FILE="$1"
shift

dart run --enable-vm-service --pause-isolates-on-start "$DART_FILE" "$@"
