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
import Ubuntu.Components.Popups 1.0

Dialog {
    id: dialogContentHubNotFound

    Label {
        color: styleMusic.common.black
        text: i18n.tr("Imported file not found")
    }

    Button {
        text: i18n.tr("Wait")
        onClicked: {
            PopupUtils.close(dialogContentHubNotFound)

            contentHubWaitForFile.dialog = PopupUtils.open(Qt.resolvedUrl("ContentHubWaitDialog.qml"), mainView)
            contentHubWaitForFile.start();
        }
    }

    Button {
        text: i18n.tr("Cancel")
        onClicked: PopupUtils.close(dialogContentHubNotFound)
    }
}
