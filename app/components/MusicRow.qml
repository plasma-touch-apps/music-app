/*
 * Copyright (C) 2013, 2014
 *      Andrew Hayzen <ahayzen@gmail.com>
 *      Nekhelesh Ramananthan <krnekhelesh@gmail.com>
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


Row {
    anchors {
        left: parent.left
        leftMargin: units.gu(2)
        right: parent.right
        rightMargin: units.gu(2)
    }
    height: units.gu(7)

    property alias column: columnComponent.sourceComponent
    property real coverSize: styleMusic.common.albumSize
    property var imageSource

    spacing: units.gu(2)

    Image {
        id: image
        anchors {
            verticalCenter: parent.verticalCenter
        }
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        height: width
        source: imageSource !== undefined && imageSource !== ""
                ? (imageSource.art !== undefined
                   ? imageSource.art
                   : "image://albumart/artist=" + imageSource.author + "&album=" + imageSource.album)
                : ""
        sourceSize.height: height
        sourceSize.width: width
        width: units.gu(6)

        onStatusChanged: {
            if (status === Image.Error) {
                source = Qt.resolvedUrl("../graphics/music-app-cover@30.png")
            }
        }
        visible: imageSource !== undefined
    }

    Loader {
        id: columnComponent
        anchors {
            verticalCenter: parent.verticalCenter
        }
        width: imageSource === undefined ? parent.width - parent.spacing
                                         : parent.width - image.width - parent.spacing

        onSourceComponentChanged: {
            for (var i=0; i < item.children.length; i++) {
                item.children[i].elide = Text.ElideRight
                item.children[i].height = units.gu(2)
                item.children[i].maximumLineCount = 1
                item.children[i].wrapMode = Text.NoWrap
                item.children[i].verticalAlignment = Text.AlignVCenter

                // binds to width so it is updated when screen size changes
                item.children[i].width = Qt.binding(function () { return width; })
            }
        }
    }
}
