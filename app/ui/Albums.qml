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
import Ubuntu.MediaScanner 0.1
import "../components"
import "../components/Delegates"
import "../components/Flickables"
import "../components/HeadState"


MusicPage {
    id: albumsPage
    objectName: "albumsPage"
    title: i18n.tr("Albums")
    searchable: true
    searchResultsCount: albumsModelFilter.count
    state: "default"
    states: [
        SearchableHeadState {
            thisPage: albumsPage
            searchEnabled: albumsModelFilter.count > 0
        },
        SearchHeadState {
            id: searchHeader
            thisPage: albumsPage
        }
    ]

    // Hack for autopilot otherwise Albums appears as MusicPage
    // due to bug 1341671 it is required that there is a property so that
    // qml doesn't optimise using the parent type
    property bool bug1341671workaround: true

    CardView {
        id: albumCardView
        model: SortFilterModel {
            id: albumsModelFilter
            property alias rowCount: albumsModel.rowCount
            model: AlbumsModel {
                id: albumsModel
                store: musicStore
            }
            sort.property: "title"
            sort.order: Qt.AscendingOrder
            sortCaseSensitivity: Qt.CaseInsensitive
            filter.property: "title"
            filter.pattern: new RegExp(searchHeader.query, "i")
            filterCaseSensitivity: Qt.CaseInsensitive
        }
        delegate: Card {
            id: albumCard
            coverSources: [{art: model.art}]
            objectName: "albumsPageGridItem" + index
            primaryText: model.title != "" ? model.title : i18n.tr("Unknown Album")
            secondaryText: model.artist != "" ? model.artist : i18n.tr("Unknown Artist")

            onClicked: {
                mainPageStack.push(Qt.resolvedUrl("SongsView.qml"),
                                   {
                                       "album": model.title,
                                       "artist": model.artist,
                                       "covers": [{art: model.art}],
                                       "isAlbum": true,
                                       "genre": undefined,
                                       "title": i18n.tr("Album"),
                                       "line1": model.artist,
                                       "line2": model.title
                                   })
            }
        }
    }
}
