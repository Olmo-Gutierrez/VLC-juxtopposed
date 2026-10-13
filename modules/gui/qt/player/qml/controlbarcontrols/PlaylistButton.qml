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


import VLC.MainInterface
import VLC.Widgets as Widgets
import VLC.Style
import VLC.Util


Widgets.IconToolButton {
    id: playlistBtn

    text: VLCIcons.playlist

    // Redesign: queue icon (three lines with dot bullets) instead of the playlist glyph.
    // The icon button only renders font glyphs, so this label is replaced by an image.
    contentItem: Image {
        source: "qrc:/icons/queue.svg"
        width: VLCStyle.dp(24, VLCStyle.scale)
        height: VLCStyle.dp(24, VLCStyle.scale)
        sourceSize.width: width
        sourceSize.height: height
        smooth: true
    }
    onClicked: {
        MainCtx.playqueuePanel.visible = !MainCtx.playqueuePanel.visible
        if (MainCtx.playqueuePanel.visible && MainCtx.playqueuePanel.docked) {
            playlistWidget.gainFocus(playlistBtn)
        }
    }
    checked: MainCtx.playqueuePanel.visible

    description: qsTr("Play Queue")

    AccessibleCompat.id: "playqueueButton"
}
