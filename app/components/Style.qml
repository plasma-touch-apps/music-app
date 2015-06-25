/*
 * Copyright (C) 2013, 2014, 2015
 *      Andrew Hayzen <ahayzen@gmail.com>
 *      Daniel Holm <d.holmen@gmail.com>
 *      Victor Thompson <victor.thompson@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.3
import Ubuntu.Components 1.1


QtObject {
    property QtObject addtoPlaylist: QtObject {
        property color backgroundColor: UbuntuColors.coolGrey;
        property color labelColor: common.black;
        property color labelSecondaryColor: "#AAA";
        property color progressBackgroundColor: common.black;
        property color progressForegroundColor: UbuntuColors.orange;
        property color progressHandleColor: common.white;
    }

    property QtObject common: QtObject {
        property color black: "#000000";
        property color white: "#FFFFFF";
        property color music: "#FFFFFF";
        property color subtitle: "#999999";
        property color expandedColor: "#000000";
        property int albumSize: units.gu(10);
        property int itemHeight: units.gu(12);
        property int expandHeight: units.gu(7);
        property int expandedItem: units.gu(2);
        property int expandedTopMargin: units.gu(13.5);
        property int expandedLeftMargin: units.gu(2);
    }

    property QtObject dialog: QtObject {
        property color confirmButtonColor: UbuntuColors.green;
        property color confirmRemoveButtonColor: UbuntuColors.red;
        property color cancelButtonColor: UbuntuColors.coolGrey;
        property color normalTextFieldColor: common.white
    }

    property QtObject libraryEmpty: QtObject {
        property color backgroundColor: UbuntuColors.coolGrey;
        property color labelColor: common.white;
    }

    property QtObject listView: QtObject {
        property color highlightColor: common.white;
    }

    property QtObject mainView: QtObject{
        property color backgroundColor: "#1e1e23"
        property color footerColor: backgroundColor
        property color headerColor: backgroundColor
    }

    property QtObject nowPlaying: QtObject {
        property color backgroundColor: "#1d1d1d"
        property color foregroundColor: "#454545"
        property color labelColor: common.white;
        property color labelSecondaryColor: "#AAA";
        property color progressBackgroundColor: common.black;
        property color progressForegroundColor: UbuntuColors.orange;
        property color progressHandleColor: common.white;
    }

    property QtObject playerControls: QtObject {
        property color backgroundColor: "#0f0f0f";
        property color labelColor: common.white;
        property color progressBackgroundColor: common.black;
        property color progressForegroundColor: UbuntuColors.orange;
    }

    property QtObject popover: QtObject {
        property color labelColor: UbuntuColors.coolGrey;
    }

    property QtObject playlist: QtObject {
        property int infoHeight: units.gu(14);
        property int playlistItemHeight: units.gu(10);
        property int playlistAlbumSize: units.gu(8);
    }

    property QtObject toolbar: QtObject {
        property color fullBackgroundColor: "#0f0f0f";
        property color fullInnerPlayCircleColor: "#0d0d0d";
        property color fullOuterPlayCircleColor: "#363636";
        property color fullProgressBackgroundColor: "#252525";
        property color fullProgressTroughColor: UbuntuColors.orange;
    }

    property QtObject albums: QtObject {
        property int itemHeight: units.gu(4);
    }

    property QtObject artists: QtObject {
        property int itemHeight: units.gu(12.5);
    }
    
    Component.onCompleted: Theme.palette.normal.field=styleMusic.dialog.normalTextFieldColor
}
