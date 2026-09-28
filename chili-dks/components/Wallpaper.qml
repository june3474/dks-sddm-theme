/*
 *   Copyright 2018 Marian Arlt <marianarlt@icloud.com>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 3 or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import QtQuick
import Qt5Compat.GraphicalEffects

// Background of one screen.
FocusScope {
    id: backgroundComponent

    property alias imageSource: backgroundImage.source
    property bool configBlur: config.blur == "true"

    // The picture, cropped to fill the screen.
    Image {
        id: backgroundImage

        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop

        clip: true
        focus: true
        smooth: true
    }

    // Blurred copy over the picture; no blur unless theme.conf sets blur=true.
    RecursiveBlur {
        id: backgroundBlur

        anchors.fill: backgroundImage
        source: backgroundImage
        radius: configBlur ? config.recursiveBlurRadius : 0
        loops: configBlur ? config.recursiveBlurLoops : 0
    }

    // Clicking the background takes the focus off the controls.
    MouseArea {
        anchors.fill: parent
        onClicked: container.focus = true
    }
}
