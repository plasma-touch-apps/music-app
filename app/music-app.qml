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
import Ubuntu.MediaScanner 0.1
import Qt.labs.settings 1.0
import QtMultimedia 5.0
import QtQuick.LocalStorage 2.0
import QtGraphicalEffects 1.0
import "logic/stored-request.js" as StoredRequest
import "logic/meta-database.js" as Library
import "logic/playlists.js" as Playlists
import "components"
import "components/Helpers"
import "ui"

MainView {
    objectName: "music"
    applicationName: "com.ubuntu.music"
    id: mainView
    useDeprecatedToolbar: false

    backgroundColor: styleMusic.mainView.backgroundColor
    headerColor: styleMusic.mainView.headerColor

    // Startup settings
    Settings {
        id: startupSettings
        category: "StartupSettings"

        property bool firstRun: true
        property int queueIndex: 0
        property int tabIndex: -1

        onFirstRunChanged: {
            if (!firstRun) {
                StoredRequest.run()
            }
        }
    }

    // Global keyboard shortcuts
    focus: true
    Keys.onPressed: {
        if(event.key === Qt.Key_Escape) {
            if (mainPageStack.currentMusicPage.currentDialog !== null) {
                PopupUtils.close(mainPageStack.currentMusicPage.currentDialog)
            } else if (mainPageStack.currentMusicPage.searchable && mainPageStack.currentMusicPage.state === "search") {
                mainPageStack.currentMusicPage.state = "default"
            } else {
                mainPageStack.goBack();  // Esc      Go back
            }
        }
        else if(event.modifiers === Qt.AltModifier) {
            var position;

            switch (event.key) {
            case Qt.Key_Right:  //  Alt+Right   Seek forward +10secs
                position = player.position + 10000 < player.duration
                        ? player.position + 10000 : player.duration;
                player.seek(position);
                break;
            case Qt.Key_Left:  //   Alt+Left    Seek backwards -10secs
                position = player.position - 10000 > 0
                        ? player.position - 10000 : 0;
                player.seek(position);
                break;
            }
        }
        else if(event.modifiers === Qt.ControlModifier) {
            switch (event.key) {
            case Qt.Key_Left:   //  Ctrl+Left   Previous Song
                player.previousSong(true);
                break;
            case Qt.Key_Right:  //  Ctrl+Right  Next Song
                player.nextSong(true, true);
                break;
            case Qt.Key_Up:  //     Ctrl+Up     Volume up
                player.volume = player.volume + .1 > 1 ? 1 : player.volume + .1
                break;
            case Qt.Key_Down:  //   Ctrl+Down   Volume down
                player.volume = player.volume - .1 < 0 ? 0 : player.volume - .1
                break;
            case Qt.Key_R:  //      Ctrl+R      Repeat toggle
                player.repeat = !player.repeat
                break;
            case Qt.Key_F:  //      Ctrl+F      Show Search popup
                if (mainPageStack.currentMusicPage.searchable && mainPageStack.currentMusicPage.state === "default") {
                    mainPageStack.currentMusicPage.state = "search"
                    header.show()
                }

                break;
            case Qt.Key_J:  //      Ctrl+J      Jump to playing song
                tabs.pushNowPlaying()
                mainPageStack.currentPage.isListView = true
                break;
            case Qt.Key_N:  //      Ctrl+N      Show Now playing
                tabs.pushNowPlaying()
                break;
            case Qt.Key_P:  //      Ctrl+P      Toggle playing state
                player.toggle();
                break;
            case Qt.Key_Q:  //      Ctrl+Q      Quit the app
                Qt.quit();
                break;
            case Qt.Key_U:  //      Ctrl+U      Shuffle toggle
                player.shuffle = !player.shuffle
                break;
            }
        }
    }

    // Arguments during startup
    Arguments {
        id: args
        //defaultArgument.help: "Expects URI of the track to play." // should be used when bug is resolved
        //defaultArgument.valueNames: ["URI"] // should be used when bug is resolved
        // grab a file
        Argument {
            name: "url"
            help: "URI for track to run at start."
            required: false
            valueNames: ["track"]
        }
        // Debug/development mode
        Argument {
            name: "debug"
            help: "Start Music in a debug mode. Will show more output."
            required: false
        }
    }

    Action {
        id: nextAction
        text: i18n.tr("Next")
        keywords: i18n.tr("Next Track")
        onTriggered: player.nextSong()
    }
    Action {
        id: playsAction
        text: player.playbackState === MediaPlayer.PlayingState ?
                  i18n.tr("Pause") : i18n.tr("Play")
        keywords: player.playbackState === MediaPlayer.PlayingState ?
                      i18n.tr("Pause Playback") : i18n.tr("Continue or start playback")
        onTriggered: player.toggle()
    }
    Action {
        id: backAction
        text: i18n.tr("Back")
        keywords: i18n.tr("Go back to last page")
        onTriggered: mainPageStack.goBack();
    }

    // With a default Quit action only the first 4 actions are displayed
    // until the user searches for them within the HUD
    Action {
        id: prevAction
        text: i18n.tr("Previous")
        keywords: i18n.tr("Previous Track")
        onTriggered: player.previousSong()
    }
    Action {
        id: stopAction
        text: i18n.tr("Stop")
        keywords: i18n.tr("Stop Playback")
        onTriggered: player.stop()
    }

    actions: [nextAction, playsAction, prevAction, stopAction, backAction]

    UriHandlerHelper {
        id: uriHandler
    }

    ContentHubHelper {
        id: contentHub
    }

    UserMetricsHelper {
        id: userMetrics
    }

    // Design stuff
    Style { id: styleMusic }
    width: units.gu(100)
    height: units.gu(80)

    WorkerModelLoader {
        id: queueLoaderWorker
        canLoad: false
        model: trackQueue.model
        syncFactor: 10

        onPreLoadCompleteChanged: {
            if (preLoadComplete) {
                player.currentIndex = queueIndex

                if (list[queueIndex] !== undefined) {
                    player.setSource(list[queueIndex].filename)
                }
            }
        }
    }

    WorkerWaiter {
        id: waitForWorker
    }

    // Run on startup
    Component.onCompleted: {
        customdebug("Version "+appVersion) // print the curren version

        Library.createRecent()  // initialize recent

        // initialize playlists
        Playlists.initializePlaylist()

        if (!args.values.url) {
            // allow the queue loader to start
            queueLoaderWorker.canLoad = !Library.isQueueEmpty()
            queueLoaderWorker.list = Library.getQueue()
        }

        // everything else
        loading.visible = true

        // push the page to view
        mainPageStack.push(tabs)

        // if a tab index exists restore it, otherwise goto Recent if there are items otherwise go to Albums
        tabs.selectedTabIndex = startupSettings.tabIndex === -1
                ? (Library.isRecentEmpty() ? albumsTab.index : 0)
                : (startupSettings.tabIndex > tabs.count - 1
                   ? tabs.count - 1 : startupSettings.tabIndex)

        loadedUI = true;

        // Run post load
        tabs.ensurePopulated(tabs.selectedTab);

        // Display walkthrough on first run, even if the user has music
        if (firstRun) {
            mainPageStack.push(Qt.resolvedUrl("components/Walkthrough/FirstRunWalkthrough.qml"), {})
        }

        if (args.values.url) {
            uriHandler.process(args.values.url, true);
        }

        // TODO: Workaround for pad.lv/1356779, force the theme's backgroundText color
        // to work with the app's backgroundColor
        Theme.palette.normal.backgroundText = "#81888888"
    }

    // VARIABLES
    property string musicName: i18n.tr("Music")
    property string appVersion: '2.1'
    property bool toolbarShown: musicToolbar.visible
    property bool selectedAlbum: false
    property alias firstRun: startupSettings.firstRun
    property alias queueIndex: startupSettings.queueIndex

    signal listItemSwiping(int i)

    property bool wideAspect: width >= units.gu(70) && loadedUI
    property bool loadedUI: false  // property to detect if the UI has finished

    // FUNCTIONS

    // Custom debug funtion that's easier to shut off
    function customdebug(text) {
        var debug = true; // set to "0" for not debugging
        //if (args.values.debug) { // *USE LATER*
        if (debug) {
            console.debug(i18n.tr("Debug: ")+text);
        }
    }

    function addQueueFromModel(model)
    {
        // TODO: remove once playlists uses U1DB
        if (model.hasOwnProperty("linkLibraryListModel")) {
            model = model.linkLibraryListModel;
        }

        var items = []

        for (var i=0; i < model.rowCount; i++) {
            items.push(model.get(i, model.RoleModelData))
        }

        // Add model to queue storage
        trackQueue.appendList(items)
    }

    // Converts an duration in ms to a formated string ("minutes:seconds")
    function durationToString(duration) {
        var minutes = Math.floor((duration/1000) / 60);
        var seconds = Math.floor((duration/1000)) % 60;
        // Make sure that we never see "NaN:NaN"
        if (minutes.toString() == 'NaN')
            minutes = 0;
        if (seconds.toString() == 'NaN')
            seconds = 0;
        return minutes + ":" + (seconds<10 ? "0"+seconds : seconds);
    }

    // Make dictionary from model item
    function makeDict(model) {
        return {
            album: model.album,
            art: model.art,
            author: model.author,
            filename: model.filename,
            title: model.title
        };
    }

    function trackClicked(model, index, play, clear) {
        // Stop queue loading in the background
        queueLoaderWorker.canLoad = false

        if (queueLoaderWorker.processing > 0) {
            waitForWorker.workerStop(queueLoaderWorker, trackClicked, [model, index, play, clear])
            return;
        }

        // TODO: remove once playlists uses U1DB
        if (model.hasOwnProperty("linkLibraryListModel")) {
            model = model.linkLibraryListModel;
        }

        var file = Qt.resolvedUrl(model.get(index, model.RoleModelData).filename);

        play = play === undefined ? true : play  // default play to true
        clear = clear === undefined ? false : clear  // force clear and will ignore player.toggle()

        if (!clear) {
            // If same track and on Now playing page then toggle
            if ((mainPageStack.currentPage.title === i18n.tr("Now playing") || mainPageStack.currentPage.title === i18n.tr("Queue"))
                    && trackQueue.model.get(player.currentIndex) !== undefined
                    && Qt.resolvedUrl(trackQueue.model.get(player.currentIndex).filename) === file) {
                player.toggle()
                return;
            }
        }

        trackQueue.clear();  // clear the old model

        addQueueFromModel(model);

        if (play) {
            player.playSong(file, index);

            // Show the Now playing page and make sure the track is visible
            tabs.pushNowPlaying();
        }
        else {
            player.setSource(file);
        }
    }

    function trackQueueClick(index) {
        if (player.currentIndex === index) {
            player.toggle();
        }
        else {
            player.playSong(trackQueue.model.get(index).filename, index);
        }

        // Show the Now playing page and make sure the track is visible
        if (mainPageStack.currentPage.title !== i18n.tr("Queue")) {
            tabs.pushNowPlaying();
        }
    }

    function playRandomSong(shuffle)
    {
        trackQueue.clear();

        var now = new Date();
        var seed = now.getSeconds();
        var index = Math.floor(allSongsModel.rowCount * Math.random(seed));

        player.shuffle = shuffle === undefined ? true : shuffle;

        trackClicked(allSongsModel, index, true)
    }

    function shuffleModel(model)
    {
        var now = new Date();
        var seed = now.getSeconds();
        var index = Math.floor(model.count * Math.random(seed));

        player.shuffle = true;

        trackClicked(model, index, true)
    }

    // Load mediascanner store
    MediaStore {
        id: musicStore
    }

    SortFilterModel {
        id: allSongsModel
        objectName: "allSongsModel"
        property alias rowCount: allSongsModelModel.rowCount
        model: SongsModel {
            id: allSongsModelModel
            objectName: "allSongsModelModel"
            store: musicStore

            // if any tracks are removed from ms2 then check they are not in the queue
            onFilled: {
                var i
                var removed = []

                // Find tracks from the queue that aren't in ms2 anymore
                for (i=0; i < trackQueue.model.count; i++) {
                    if (musicStore.lookup(decodeURIComponent(trackQueue.model.get(i).filename)) === null) {
                        removed.push(i)
                    }
                }

                // If there are removed tracks then remove them from the queue and store
                if (removed.length > 0) {
                    console.debug("Removed queue:", JSON.stringify(removed))
                    trackQueue.removeQueueList(removed)
                }

                // Loop through playlists, getPlaylistTracks will remove any tracks that don't exist
                var playlists = Playlists.getPlaylists()

                for (i=0; i < playlists.length; i++) {
                    Playlists.getPlaylistTracks(playlists[i].name)
                }

                // TODO: improve in refactoring to be able detect when a track is removed
                // Update playlists page
                if (playlistsPage.visible) {
                    playlistModel.filterPlaylists()
                } else {
                    playlistsPage.changed = true
                }
            }
        }
        sort.property: "title"
        sort.order: Qt.AscendingOrder
        sortCaseSensitivity: Qt.CaseInsensitive
    }

    AlbumsModel {
        id: allAlbumsModel
        store: musicStore
        // if any tracks are removed from ms2 then check they are not in recent
        onFilled: {
            var albums = []
            var i
            var removed = []

            for (i=0; i < allAlbumsModel.count; i++) {
                albums.push(allAlbumsModel.get(i, allAlbumsModel.RoleTitle))
            }

            // Find albums from recent that aren't in ms2 anymore
            var recent = Library.getRecent()

            for (i=0; i < recent.length; i++) {
                if (recent[i].type === "album" && albums.indexOf(recent[i].data) === -1) {
                    removed.push(recent[i].data)
                }
            }

            // If there are removed tracks then remove them from recent
            if (removed.length > 0) {
                console.debug("Removed recent:", JSON.stringify(removed))
                Library.recentRemoveAlbums(removed)

                if (recentPage.visible) {
                    recentModel.filterRecent()
                } else {
                    recentPage.changed = true
                }
            }
        }
    }

    SongsModel {
        id: songsAlbumArtistModel
        store: musicStore
        onStatusChanged: {
            if (status === SongsModel.Ready) {
                // Play album it tracks exist
                if (rowCount > 0 && selectedAlbum) {
                    trackClicked(songsAlbumArtistModel, 0, true, true);

                    // Add album to recent list
                    Library.addRecent(songsAlbumArtistModel.get(0, SongsModel.RoleModelData).album, "album")
                    recentModel.filterRecent()
                } else if (selectedAlbum) {
                    console.debug("Unknown artist-album " + artist + "/" + album + ", skipping")
                }

                selectedAlbum = false;

                // Clear filter for artist and album
                songsAlbumArtistModel.albumArtist = ""
                songsAlbumArtistModel.album = ""
            }
        }
    }

    // WHERE THE MAGIC HAPPENS
    Player {
        id: player
    }

    // TODO: Used by playlisttracks move to U1DB
    LibraryListModel {
        id: albumTracksModel
    }

    // TODO: used by recent items move to U1DB
    LibraryListModel {
        id: recentModel
        property bool complete: false
        onPreLoadCompleteChanged: {
            complete = true;

            if (preLoadComplete)
            {
                loading.visible = false
                recentTabRepeater.loading = false
                recentTabRepeater.populated = true

                // Ensure any active tabs are insync as they use a copy of the repeater state
                for (var i=0; i < recentTabRepeater.count; i++) {
                    recentTabRepeater.itemAt(i).loading = false
                    recentTabRepeater.itemAt(i).populated = true
                }
            }
        }
    }

    // list of tracks on startup. This is just during development
    LibraryListModel {
        id: trackQueue
        objectName: "trackQueue"

        function append(listElement)
        {
            model.append(makeDict(listElement))
            Library.addQueueItem(listElement.filename)
        }

        function appendList(items)
        {
            for (var i=0; i < items.length; i++) {
                model.append(makeDict(items[i]))
            }

            Library.addQueueList(items)
        }

        function clear()
        {
            Library.clearQueue()
            model.clear()

            queueIndex = 0  // reset otherwise when you append and play 1 track it doesn't update correctly
        }

        // Optimised removeQueue for removing multiple tracks from the queue
        function removeQueueList(items)
        {
            var i;

            // Remove from the saved queue database
            Library.removeQueueList(items)

            // Sort the item indexes as loops below assume *numeric* sort
            items.sort(function(a,b) { return a - b })

            // Remove from the listmodel
            var startCount = trackQueue.model.count

            for (i=0; i < items.length; i++) {
                // use diff in count as sometimes the row is removed from the model
                trackQueue.model.remove(items[i] - (startCount - trackQueue.model.count));
            }

            // Update the currentIndex and playing status

            if (trackQueue.model.count === 0) {
                // Nothing in the queue so stop and pop the queue
                player.stop()
                mainPageStack.goBack()
            } else if (items.indexOf(player.currentIndex) > -1) {
                // Current track was removed

                var newIndex;

                // Find the first index that still exists before the currentIndex
                for (i=player.currentIndex - 1; i > -1; i--) {
                    if (items.indexOf(i) === -1) {
                        break;
                    }
                }

                newIndex = i;

                // Shuffle index down as tracks were removed before the current
                for (i=newIndex; i > -1; i--) {
                    if (items.indexOf(i) !== -1) {
                        newIndex--;
                    }
                }

                // Set this as the current track
                player.currentIndex = newIndex

                // Play the next track
                player.nextSong(player.isPlaying);
            } else {
                // Current track not in removed list
                // Check if the index needs to be shuffled down due to removals

                var before = 0

                for (i=0; i < items.length; i++) {
                    if (items[i] < player.currentIndex) {
                        before++;
                    }
                }

                // Update the index
                player.currentIndex -= before;
            }

            queueIndex = player.currentIndex;  // ensure saved index is up to date
        }
    }

    // TODO: list of playlists move to U1DB
    // create the listmodel to use for playlists
    LibraryListModel {
        id: playlistModel
        syncFactor: 1

        onPreLoadCompleteChanged: {
            if (preLoadComplete)
            {
                loading.visible = false
                playlistsTab.loading = false
                playlistsTab.populated = true
            }
        }
    }

    Loader {
        id: musicToolbar
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
        asynchronous: true
        source: "components/MusicToolbar.qml"
        visible: mainPageStack.currentPage.title !== i18n.tr("Now playing") &&
                 mainPageStack.currentPage.title !== i18n.tr("Queue") &&
                 mainPageStack.currentPage.title !== i18n.tr("Select playlist") &&
                 !firstRun
        z: 200  // put on top of everything else
    }

    PageStack {
        id: mainPageStack

        // Properties storing the current page info
        property Page currentMusicPage: null  // currentPage can be Tabs
        property bool popping: false

        /* Helper functions */

        // Go back up the stack if possible
        function goBack() {
            // Ensure in the case that goBack is called programmatically that any dialogs are closed
            if (mainPageStack.currentMusicPage.currentDialog !== null) {
                PopupUtils.close(mainPageStack.currentMusicPage.currentDialog)
            }

            if (depth > 1) {
                pop()
            }
        }

        // Pop a specific page in the stack
        function popPage(page) {
            var tmpPages = []

            // Ensure in the case that popPage is called programmatically that any dialogs are closed
            if (page.currentDialog !== undefined && page.currentDialog !== null) {
                PopupUtils.close(page.currentDialog)
            }

            popping = true

            while (currentPage !== page && depth > 0) {
                tmpPages.push(currentPage)
                pop()
            }

            if (depth > 0) {
                pop()
            }

            for (var i=tmpPages.length - 1; i > -1; i--) {
                push(tmpPages[i])
            }

            popping = false
        }

        // Set the current page, and any parent/stacks
        function setPage(childPage) {
            if (!popping) {
                currentMusicPage = childPage;
            }
        }

        Tabs {
            id: tabs
            anchors {
                fill: parent
            }

            property Tab lastTab: selectedTab

            onSelectedTabChanged: {
                // pause loading of the models in the old tab
                if (lastTab !== null && lastTab !== selectedTab) {
                    allowLoading(lastTab, false);
                }

                lastTab = selectedTab;

                ensurePopulated(selectedTab);
            }

            onSelectedTabIndexChanged: {
                if (loadedUI) {  // store the tab index if changed by the user
                    startupSettings.tabIndex = selectedTabIndex
                }
            }

            // Use a repeater to 'hide' the recent tab when the model is empty
            // A repeater is used because the Tabs component respects adds and
            // removes. Whereas replacing the list tabChildren does not appear
            // to respect removes and setting the page as active: false causes
            // the page to be blank but the action to still in the overflow
            Repeater {
                id: recentTabRepeater
                // If the model has not loaded and at startup the db was not empty
                // then show recent or
                // If the workerlist has been set and it has values then show recent
                model: (!recentModel.preLoadComplete && !startupRecentEmpty) ||
                       (recentModel.workerList !== undefined &&
                        recentModel.workerList.length > 0) ? 1 : 0
                delegate: Component {
                    // First tab is all music
                    Tab {
                        property bool populated: recentTabRepeater.populated
                        property var loader: [recentModel.filterRecent]
                        property bool loading: recentTabRepeater.loading
                        property var model: [recentModel, albumTracksModel]
                        id: recentTab
                        objectName: "recentTab"
                        anchors.fill: parent
                        title: page.title

                        // Tab content begins here
                        page: Recent {
                            id: recentPage
                        }
                    }
                }

                // Store the startup state of the db separately otherwise
                // it breaks the binding of model
                property bool startupRecentEmpty: Library.isRecentEmpty()

                // cached values of the recent model that are copied when
                // the tab is created
                property bool loading: false
                property bool populated: false

                onCountChanged: {
                    if (count === 0 && loadedUI) {
                        // Jump to the albums tab when recent is empty
                        tabs.selectedTabIndex = albumsTab.index
                    } else if (count > 0 && !loadedUI) {
                        // UI is still loading and recent tab has been inserted
                        // so move the selected index 'down' as the value is
                        // not auto updated - this is for the case of loading
                        // directly to the recent tab (otherwise the content
                        // appears as the second tab but the tabs think they are
                        // on the first tab)
                        tabs.selectedTabIndex -= 1
                    } else if (count > 0 && loadedUI) {
                        // tab inserted while the app is running so move the
                        // selected index 'up' to keep the same position
                        tabs.selectedTabIndex += 1
                    }
                }
            }

            // Second tab is arists
            Tab {
                property bool populated: true
                property var loader: []
                property bool loading: false
                property var model: []
                id: artistsTab
                objectName: "artistsTab"
                anchors.fill: parent
                title: page.title

                // tab content
                page: Artists {
                    id: artistsPage
                }
            }

            // third tab is albums
            Tab {
                property bool populated: true
                property var loader: []
                property bool loading: false
                property var model: []
                id: albumsTab
                objectName: "albumsTab"
                anchors.fill: parent
                title: page.title

                // Tab content begins here
                page: Albums {
                    id: albumsPage
                }
            }

            // forth tab is genres
            Tab {
                property bool populated: true
                property var loader: []
                property bool loading: false
                property var model: []
                id: genresTab
                objectName: "genresTab"
                anchors.fill: parent
                title: page.title

                // Tab content begins here
                page: Genres {
                    id: genresPage
                }
            }

            // fourth tab is all songs
            Tab {
                property bool populated: true
                property var loader: []
                property bool loading: false
                property var model: []
                id: songsTab
                objectName: "songsTab"
                anchors.fill: parent
                title: page.title

                // Tab content begins here
                page: Songs {
                    id: tracksPage
                }
            }


            // fifth tab is the playlists
            Tab {
                property bool populated: false
                property var loader: [playlistModel.filterPlaylists]
                property bool loading: false
                property var model: [playlistModel, albumTracksModel]
                id: playlistsTab
                objectName: "playlistsTab"
                anchors.fill: parent
                title: page.title

                // Tab content begins here
                page: Playlists {
                    id: playlistsPage
                }
            }

            // Set the models in the tab to allow/disallow loading
            function allowLoading(tabToLoad, state)
            {
                if (tabToLoad && tabToLoad.model !== undefined)
                {
                    for (var i=0; i < tabToLoad.model.length; i++)
                    {
                        tabToLoad.model[i].canLoad = state;
                    }
                }
            }

            function ensurePopulated(selectedTab)
            {
                if (selectedTab) {  // check not null or undefined
                    allowLoading(selectedTab, true);  // allow loading of the models

                    if (!selectedTab.populated && !selectedTab.loading && loadedUI) {
                        loading.visible = true
                        selectedTab.loading = true

                        if (selectedTab.loader !== undefined)
                        {
                            for (var i=0; i < selectedTab.loader.length; i++)
                            {
                                selectedTab.loader[i]();
                            }
                        }
                    }

                    loading.visible = selectedTab.loading || !selectedTab.populated
                }
            }

            function pushNowPlaying()
            {
                // only push if on a different page
                if (mainPageStack.currentPage.title !== i18n.tr("Now playing")
                        && mainPageStack.currentPage.title !== i18n.tr("Queue")) {
                    mainPageStack.push(Qt.resolvedUrl("ui/NowPlaying.qml"), {})
                }

                if (mainPageStack.currentPage.title === i18n.tr("Queue")) {
                    mainPageStack.currentPage.isListView = false;  // ensure full view
                }
            }
        } // end of tabs
    }

    Loader {
        id: emptyPageLoader
        // Do not be active if content-hub is importing due to the models resetting
        // this then causes the empty page loader to partially run then showing a blank header
        active: noMusic && !firstRun && !contentHub.processing
        anchors {
            fill: parent
        }
        source: "ui/LibraryEmptyState.qml"
        visible: active

        property bool noMusic: allSongsModel.rowCount === 0 && allSongsModelModel.status === SongsModel.Ready && loadedUI
    }

    LoadingSpinnerComponent {
        id: loading
    }
} // end of main view
