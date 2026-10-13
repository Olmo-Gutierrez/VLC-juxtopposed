/*****************************************************************************
 * Copyright (C) 2021 VLC authors and VideoLAN
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * ( at your option ) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/
import QtQuick


import VLC.Widgets as Widgets
import VLC.Style
import VLC.Util

Widgets.IconToolButton {
    id: subtitleBtn

    // Figma Controls bar: 30 px slot = 24 px glyph + 3 px padding each side. Padding (not a wider
    // implicitWidth) keeps the glyph at 24 px, so it is not stretched
    leftPadding: VLCStyle.dp(3, VLCStyle.scale)
    rightPadding: VLCStyle.dp(3, VLCStyle.scale)

    text: VLCIcons.audiosub

    // Redesign: Figma subtitles icon. No action yet, so the button only shows the icon.
    contentItem: Image {
        source: "qrc:/icons/bar_subtitles.svg"
        width: VLCStyle.dp(24, VLCStyle.scale)
        height: VLCStyle.dp(24, VLCStyle.scale)
        sourceSize.width: width
        sourceSize.height: height
        smooth: true
    }

    description: qsTr("Subtitles")

    AccessibleCompat.id: "subtitleButton"
}
