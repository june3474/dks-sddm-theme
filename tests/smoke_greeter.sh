#!/usr/bin/env bash
# Loads the theme in the real SDDM greeter (test mode, offscreen) and fails on
# any QML load problem or when SDDM falls back to its embedded theme.
set -u

here=$(cd "$(dirname "$0")" && pwd)
theme=${THEME_DIR:-$here/../chili-dks}
seconds=${GREETER_SECONDS:-8}
log=$(mktemp)
trap 'rm -f "$log"' EXIT

# -k: a greeter whose main thread is stuck in a loop ignores SIGTERM and has to be killed (status 137).
QT_QPA_PLATFORM=offscreen timeout -k 3 "$seconds" sddm-greeter-qt6 --test-mode --theme "$theme" >"$log" 2>&1
status=$?

fail=0

# The greeter never exits on its own; timeout(1) stopping it with SIGTERM (124) is the healthy outcome.
if [ "$status" -eq 137 ]; then
    echo "FAIL: greeter did not react to SIGTERM (main thread stuck, most likely in a loop)"
    fail=1
elif [ "$status" -ne 124 ]; then
    echo "FAIL: greeter exited with status $status before the timeout"
    fail=1
fi

require() {
    if ! grep -qE -- "$1" "$log"; then
        echo "FAIL: expected /$1/ in greeter output"
        fail=1
    fi
}

# Tolerated output:
#  - qtvirtualkeyboard is optional; its Loader failing is not a theme error.
#  - The theme anchors items that live inside layouts (ActionButton, the keyboard Loader). Qt warns about it, but
#    that design predates the Qt 6 port.
tolerated='module "QtQuick.VirtualKeyboard"|Detected anchors on an item that is managed by a layout'
forbid() {
    if grep -vE -- "$tolerated" "$log" | grep -nE -- "$1"; then
        echo "FAIL: found /$1/ in greeter output"
        fail=1
    fi
}

require 'Loading file://.*/Main\.qml'
require 'Adding view for'
forbid 'Fallback to embedded theme'
forbid 'is not installed|is not a type|TypeError|ReferenceError|Unable to assign|Cannot (read|assign|call)'
forbid '\.qml:[0-9]+'

if [ "$fail" -ne 0 ]; then
    echo "--- greeter output ---"
    cat "$log"
    exit 1
fi
echo "PASS: greeter loaded $theme without QML errors"
