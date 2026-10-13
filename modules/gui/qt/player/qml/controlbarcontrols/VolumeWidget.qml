/*****************************************************************************
 * Copyright (C) 2019 VLC authors and VideoLAN
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
import QtQuick.Layouts
import QtQuick.Templates as T

import VLC.MainInterface
import VLC.Widgets as Widgets
import VLC.Util
import VLC.Style
import VLC.Player

T.Pane {
    id: root

    property bool paintOnly: false

    readonly property color sliderColor: {
        const theme = volControl.colorContext
        return (root._player.volume > 1.0) ? theme.fg.negative : theme.fg.primary
    }

    readonly property var _player: paintOnly ? ({ muted: false, volume: .5 }) : Player
    readonly property int _maxvol: MainCtx.maxVolume
    readonly property real _fullvolpos: 100 / _maxvol
    readonly property real _maxvolpos: _maxvol / 100

    // Figma 'volume' component (244:184): the fill width, in px of the 89 px cone, for the volume variants
    // from 0 to 100 %. The cone is not linear in the volume: 100 % fills 63 px.
    readonly property var _fillTable: [[0, 0], [10, 7], [20, 14], [30, 20], [40, 26], [50, 33], [60, 41],
                                       [70, 48], [80, 53], [90, 58], [100, 63]]
    readonly property real _coneWidth: 89
    // The last stretch of the cone (63 px to 88 px, the Figma 100 % to 200 % variants) covers the volume
    // from 100 % up to the maximum volume of the application, so the end of the cone is the maximum
    readonly property real _fullPx: 63
    readonly property real _endPx: 88

    // Volume (1.0 = 100 %) -> slider position (fraction of the cone width)
    function _volumeToPosition(volume) {
        volume = Math.max(0, Math.min(volume, root._maxvolpos))
        if (volume > 1.0)
            return (root._fullPx + (root._endPx - root._fullPx) * (volume - 1.0) / Math.max(root._maxvolpos - 1.0, 0.01)) / root._coneWidth

        const percent = volume * 100
        const t = root._fillTable
        for (let i = 1; i < t.length; ++i) {
            if (percent <= t[i][0])
                return (t[i - 1][1] + (t[i][1] - t[i - 1][1]) * (percent - t[i - 1][0]) / (t[i][0] - t[i - 1][0])) / root._coneWidth
        }
        return root._fullPx / root._coneWidth
    }

    // Slider position (fraction of the cone width) -> volume (1.0 = 100 %), the inverse of the above
    function _positionToVolume(position) {
        const px = Math.max(0, Math.min(root._endPx, position * root._coneWidth))
        if (px > root._fullPx)
            return 1.0 + (root._maxvolpos - 1.0) * (px - root._fullPx) / (root._endPx - root._fullPx)

        const t = root._fillTable
        for (let i = 1; i < t.length; ++i) {
            if (px <= t[i][1])
                return (t[i - 1][0] + (t[i][0] - t[i - 1][0]) * (px - t[i - 1][1]) / (t[i][1] - t[i - 1][1])) / 100
        }
        return 1.0
    }

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    contentWidth: volumeWidget.implicitWidth
    contentHeight: volumeWidget.implicitHeight

    Keys.priority: Keys.AfterItem
    Keys.onPressed: (event) => Navigation.defaultKeyAction(event)

    RowLayout {
        id: volumeWidget

        anchors.fill: parent
        spacing: 0

        Widgets.IconToolButton{
            id: volumeBtn

            focus: true
            paintOnly: root.paintOnly
            text: {
                if (_player.muted)
                    return VLCIcons.volume_muted
                else if (_player.volume === 0)
                    return VLCIcons.volume_zero
                else if (_player.volume < .33)
                    return VLCIcons.volume_low
                else if (_player.volume <= .66)
                    return VLCIcons.volume_medium
                else
                    return VLCIcons.volume_high
            }
            // Figma volume states (Icon set): high / medium / low / muted
            contentItem: Image {
                readonly property string _name: _player.muted || _player.volume === 0 ? "muted"
                                                : _player.volume < .33 ? "low"
                                                : _player.volume <= .66 ? "medium" : "high"
                source: "qrc:/icons/bar_volume_" + _name + ".svg"
                width: VLCStyle.dp(24, VLCStyle.scale)
                height: VLCStyle.dp(24, VLCStyle.scale)
                sourceSize.width: width
                sourceSize.height: height
                smooth: true
            }

            description: qsTr("Mute")

            AccessibleCompat.id: "muteButton"

            onClicked: Player.muted = !Player.muted

            Accessible.onIncreaseAction: {
                Player.muted = false
                Player.setVolumeUp()
            }

            Accessible.onDecreaseAction: {
                Player.muted = false
                Player.setVolumeDown()
            }

            Navigation.parentItem: root
            Navigation.rightItem: volControl
        }

        Widgets.SliderExt {
            id: volControl

            // FIXME: use VLCStyle
            implicitWidth: VLCStyle.dp(88, VLCStyle.scale)

            // WARNING: Directly setting the insets break handle and background positioning.
            Binding on topInset {
                when: MainCtx.usingTouch
                value: VLCStyle.touchHandlerMargin
            }
            Binding on bottomInset {
                when: MainCtx.usingTouch
                value: VLCStyle.touchHandlerMargin
            }

            Layout.fillHeight: true
            // Figma volume group: 8 px between the 24 px icon and the 88 px cone, no space after
            Layout.leftMargin: VLCStyle.margin_xsmall

            property bool _inhibitPlayerVolumeUpdate: false

            // FIXME: Currently we are not updating the ShiftModifier status while dragging. This
            //        could be fixed with a custom Slider based on a MouseArea.
            property bool _shiftPressed: false

            property real _clamp: 0.01

            property bool _keyPressed: false

            property bool filterEvents: false

            color: root.sliderColor

            // Figma volume has no drag handle: keep the level visible without the default handle
            handle: Item {
                visible: false
            }

            // Figma 'volume' (Controls instance 491:1733): a cone-shaped track (89x28) with the
            // gradient level drawn on top and clipped to the current volume.
            background: Item {
                id: volumeBackground

                x: volControl.leftPadding
                y: volControl.topPadding + (volControl.availableHeight - height) / 2
                width: VLCStyle.dp(89, VLCStyle.scale)
                height: VLCStyle.dp(28, VLCStyle.scale)

                Image {
                    anchors.fill: parent
                    source: "qrc:/icons/bar_volume_track.svg"
                    smooth: true
                }

                Item {
                    id: volumeLevel

                    width: volumeBackground.width * volControl.position
                    height: volumeBackground.height
                    clip: true

                    Image {
                        width: volumeBackground.width
                        height: volumeBackground.height
                        source: "qrc:/icons/bar_volume_fill.svg"
                        smooth: true
                    }
                }
            }

            // The slider position is the fraction of the cone width; the volume comes from the Figma fill table
            // and is capped at the maximum volume in _adjustPlayerVolume
            from: 0
            to: 1
            opacity: _player.muted ? 0.5 : 1

            enabled: !root.paintOnly // disables event handling depending on this

            toolTipTextProvider: function (value) {
                // the real value i.e 'Player.volume' bounds can be different
                // from bounds of this widget and we want to show the current
                // volume here, so directly use Player.volume instead of "value"

                return Math.round(Player.volume * 100) + "%"
            }

            // Figma volume: the stock tooltip is replaced by the 'audio value' box (121 x 37) above the cone
            toolTipVisible: false

            Rectangle {
                id: audioValue

                FontLoader {
                    id: audioValueFont
                    source: "qrc:/Inter-Regular.ttf"
                }

                anchors.horizontalCenter: parent.horizontalCenter
                y: -height - VLCStyle.dp(8, VLCStyle.scale)
                width: VLCStyle.dp(121, VLCStyle.scale)
                height: VLCStyle.dp(37, VLCStyle.scale)
                radius: VLCStyle.dp(6, VLCStyle.scale)
                // Figma 'audio value': #0E0E0E at 95 %
                color: "#F20E0E0E"
                z: 1

                visible: volControl.pointerOver || volControl.visualFocus || volControl.pressed

                // Figma: Inter Regular 14 px, the number #969696 and the % sign #6B6B6B
                Text {
                    anchors.centerIn: parent
                    textFormat: Text.RichText
                    text: "<font color=\"#969696\">" + Math.round(Player.volume * 100) + " </font>"
                          + "<font color=\"#6B6B6B\">%</font>"
                    font.family: audioValueFont.name
                    font.pixelSize: 14
                }
            }

            Accessible.name: qsTr("Volume")
            AccessibleCompat.id: "volumeSlider"

            Keys.onPressed: (event) => {
                if (KeyHelper.matchOk(event)) {
                    event.accepted = true

                    _keyPressed = true
                } else {
                    Navigation.defaultKeyAction(event)
                }
            }

            Keys.onReleased: (event) => {
                if (_keyPressed === false)
                    return

                _keyPressed = false

                if (KeyHelper.matchOk(event)) {
                    Player.muted = !Player.muted
                }
            }

            function _syncVolumeWithPlayer() {
                volControl._inhibitPlayerVolumeUpdate = true
                volControl.value = root._volumeToPosition(_player.volume)
                volControl._inhibitPlayerVolumeUpdate = false
            }

            function _adjustPlayerVolume() {
                Player.muted = false

                // The cone reaches 200 %, the player is limited to the maximum volume
                let value = Math.min(root._positionToVolume(volControl.value), root._maxvolpos)

                // NOTE: We are clamping the value to make it easier to restore the default volume.
                if (_shiftPressed === false) {
                    if (Math.abs(value - 1.0) < _clamp)
                        value = 1.0
                    else
                        _clamp = 0.01
                }

                Player.volume = value

                volControl.value = root._volumeToPosition(value)
            }

            Component.onCompleted: {
                root.paintOnlyChanged.connect(_syncVolumeWithPlayer)
                volControl._syncVolumeWithPlayer()
            }

            Connections {
                target: Player
                enabled: !paintOnly

                function onVolumeChanged() { volControl._syncVolumeWithPlayer() }
            }

            Binding on Widgets.PointingToolTipAttached.visible {
                when: sliderMouseArea.pressed
                value: true
            }

            Navigation.leftItem: volumeBtn
            Navigation.parentItem: root

            Keys.onUpPressed: (event) => {
                Player.muted = false
                Player.setVolumeUp()
            }

            Keys.onDownPressed: (event) => {
                Player.muted = false
                Player.setVolumeDown()
            }

            Keys.priority: Keys.BeforeItem

            onValueChanged: {
                if (paintOnly)
                    return

                if (!volControl._inhibitPlayerVolumeUpdate) {
                    if (filterEvents) {
                        Qt.callLater(volControl._adjustPlayerVolume)
                    } else {
                        volControl._adjustPlayerVolume()
                        filterEvents = true
                    }
                }
            }

            Rectangle{
                id: tickmark

                parent: volControl.background

                x : parent.width * root._volumeToPosition(1.0)
                width: VLCStyle.dp(1, VLCStyle.scale)
                height: parent.height
                radius: VLCStyle.dp(2, VLCStyle.scale)
                // Figma volume has no 100% tick mark; keep the mouse area, hide the line
                visible: false

                // FIXME: tick mark is not visible when it's over slider
                color: root.sliderColor

                // NOTE: This is a helper to select the default volume when clicking on the
                //       tickmark. We apply a higher clamp value to achieve that behavior on
                //       the Slider.
                MouseArea {
                    anchors.fill: parent

                    anchors.margins: -(VLCStyle.dp(4, VLCStyle.scale))

                    onPressed: (mouse) => {
                        mouse.accepted = false

                        if (mouse.modifiers === Qt.ShiftModifier)
                            return

                        volControl._clamp = 0.1
                    }
                }
            }

            MouseArea {
                id: sliderMouseArea

                anchors.fill: parent

                acceptedButtons: (Qt.LeftButton | Qt.RightButton)

                onPressed: (mouse) => {
                    if (root.paintOnly) {
                        mouse.accepted = true
                        return
                    }

                    volControl._shiftPressed = (mouse.modifiers === Qt.ShiftModifier)

                    if (mouse.button === Qt.LeftButton) {
                        mouse.accepted = false

                        return
                    }

                    volControl.filterEvents = false
                    adjustVolume(mouse)
                }

                onPositionChanged: (mouse) => {
                    if (mouse.buttons & Qt.RightButton)
                        adjustVolume(mouse)
                }

                onWheel: (wheel) => {

                    if ((Math.abs(wheel.pixelDelta.x) % 120 > 0) || (Math.abs(wheel.pixelDelta.y) % 120 > 0)) {
                        let delta = 0
                        if (Math.abs(wheel.pixelDelta.x) > Math.abs(wheel.pixelDelta.y))
                            delta = wheel.pixelDelta.x
                        else
                            delta = wheel.pixelDelta.y

                        if (wheel.inverted)
                            delta = -delta
                        volControl.value += 0.001 * delta
                    }
                    else
                        wheelToVLC.qmlWheelEvent(wheel)

                    wheel.accepted = true
                }

                function adjustVolume(mouse) {
                    mouse.accepted = true

                    const pos = mouse.x * root._maxvolpos / width

                    if (pos < 0.25)
                        volControl.value = 0
                    else if (pos < 0.75)
                        volControl.value = 0.5
                    else if (pos < 1.125)
                        volControl.value = 1
                    else
                        volControl.value = 1.25
                }

                WheelToVLCConverter {
                    id: wheelToVLC

                    function handle(steps: int) {
                        if (steps > 0)
                            Player.setVolumeUp(steps)
                        else
                            Player.setVolumeDown(-steps)
                    }

                    Component.onCompleted: {
                        wheelUpDown.connect(wheelToVLC.handle)
                        wheelLeftRight.connect(wheelToVLC.handle)
                    }
                }
            }
        }
    }
}
