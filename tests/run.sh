#!/usr/bin/env bash
# Runs the greeter smoke test, then every QtQuickTest suite (tst_*.qml) in this directory.
#
# Rendering-dependent checks (e.g. the avatar mask) are skipped on the default offscreen platform because its
# software renderer cannot draw ShaderEffect. Run them on a GPU platform instead:
#   QT_QPA_PLATFORM=xcb tests/run.sh
set -u

here=$(cd "$(dirname "$0")" && pwd)
qmltestrunner=${QMLTESTRUNNER:-$(qmake6 -query QT_INSTALL_BINS)/qmltestrunner}
export QT_QPA_PLATFORM=${QT_QPA_PLATFORM:-offscreen}

status=0
"$here/smoke_greeter.sh" || status=1
"$qmltestrunner" -input "$here" || status=1
exit $status
