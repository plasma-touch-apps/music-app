/*
 * Copyright (C) 2015
 *      Andrew Hayzen <ahayzen@gmail.com>
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

PageHeadState {
    id: selectionState
    actions: [
        Action {
            iconName: "select"
            text: i18n.tr("Select All")
            onTriggered: {
                if (listview.selectedItems.length === listview.model.count) {
                    listview.clearSelection()
                } else {
                    listview.selectAll()
                }
            }
        },
        Action {
            enabled: listview !== null ? listview.selectedItems.length > 0 : false
            iconName: "add-to-playlist"
            text: i18n.tr("Add to playlist")
            onTriggered: {
                var items = []

                for (var i=0; i < listview.selectedItems.length; i++) {
                    items.push(makeDict(listview.model.get(listview.selectedItems[i], listview.model.RoleModelData)));
                }

                mainPageStack.push(Qt.resolvedUrl("../../ui/AddToPlaylist.qml"),
                                   {"chosenElements": items})

                listview.closeSelection()
            }
        },
        Action {
            enabled: listview !== null ? listview.selectedItems.length > 0 : false
            iconName: "add"
            text: i18n.tr("Add to queue")
            visible: addToQueue

            onTriggered: {
                var items = []

                for (var i=0; i < listview.selectedItems.length; i++) {
                    items.push(listview.model.get(listview.selectedItems[i], listview.model.RoleModelData));
                }

                trackQueue.appendList(items)

                listview.closeSelection()
            }
        },
        Action {
            enabled: listview !== null ? listview.selectedItems.length > 0 : false
            iconName: "delete"
            text: i18n.tr("Delete")
            visible: removable

            onTriggered: {
                removed(listview.selectedItems)

                listview.closeSelection()
            }
        }

    ]
    backAction: Action {
        text: i18n.tr("Cancel selection")
        iconName: "back"
        onTriggered: {
            listview.clearSelection()
            listview.state = "normal"
        }
    }
    head: thisPage.head
    name: "selection"

    PropertyChanges {
        target: thisPage.head
        backAction: selectionState.backAction
        actions: selectionState.actions
    }

    property bool addToQueue: true
    property ListView listview
    property bool removable: false
    property Page thisPage

    signal removed(var selectedItems)
}
