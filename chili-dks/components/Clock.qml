/*
 *   Based on SddmComponents/Clock.qml
 *   Copyright (c) 2013 Abdurrahman AVCI <abdurrahmanavci@gmail.com>
 *
 *   Changed for Qt 6: the date is formatted with the locale's long format again. SDDM's Clock still passes
 *   Qt.DefaultLocaleLongDate to Qt.formatDate(), which Qt 6 removed, so it falls back to the short numeric date.
 *
 *   Permission is hereby granted, free of charge, to any person
 *   obtaining a copy of this software and associated documentation
 *   files (the "Software"), to deal in the Software without restriction,
 *   including without limitation the rights to use, copy, modify, merge,
 *   publish, distribute, sublicense, and/or sell copies of the Software,
 *   and to permit persons to whom the Software is furnished to do so,
 *   subject to the following conditions:
 *
 *   The above copyright notice and this permission notice shall be included
 *   in all copies or substantial portions of the Software.
 *
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 *   OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 *   THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
 *   OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 *   ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
 *   OR OTHER DEALINGS IN THE SOFTWARE.
 */

import QtQuick

// Time with the date under it, at the top left of the screen.
Column {
    id: container

    property date dateTime: new Date()
    property color color: "white"
    property alias timeFont: time.font
    property alias dateFont: date.font

    // Not drawn: keeps the time current.
    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: container.dateTime = new Date()
    }

    // Time (hh:mm).
    Text {
        id: time
        anchors.horizontalCenter: parent.horizontalCenter

        color: container.color

        text: Qt.formatTime(container.dateTime, "hh:mm")

        font.pointSize: 72
    }

    // Long date under the time.
    Text {
        id: date
        anchors.horizontalCenter: parent.horizontalCenter

        color: container.color

        text: container.dateTime.toLocaleDateString(Qt.locale(), Locale.LongFormat)

        font.pointSize: 24
    }
}
