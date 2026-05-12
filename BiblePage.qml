import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore

Item {
    id: root
    
    // Properties passed from Map page or Settings
    property string bookName: "Gen"
    property int chapterNum: 1
    property int targetVerse: 1
    property string bookName_cn: dbManager.getBookName(bookName)

    Settings {
        id: pageSettings
        category: "BibleReading"
        property string lastBook: "Gen"
        property int lastChapter: 1
        property int lastVerse: 1
    }

    function forceLoadVerses(book, chapter, verse) {
        bookName = book;
        chapterNum = chapter;
        targetVerse = verse;
        bookName_cn = dbManager.getBookName(bookName);
        saveState();
        loadVerses();
    }

    function saveState() {
        pageSettings.lastBook = bookName;
        pageSettings.lastChapter = chapterNum;
        pageSettings.lastVerse = targetVerse;
        if (typeof appSettings !== "undefined") {
            appSettings.lastBook = bookName;
            appSettings.lastChapter = chapterNum;
            appSettings.lastVerse = targetVerse;
        }
    }

    // Load initial state
    Component.onCompleted: {
        bookName = pageSettings.lastBook;
        chapterNum = pageSettings.lastChapter;
        targetVerse = pageSettings.lastVerse;
        bookName_cn = dbManager.getBookName(bookName);
        loadVerses();
    }

    function loadVerses() {
        var verses = dbManager.getVerses(bookName, chapterNum);
        verseModel.clear();
        var targetIndex = 0;
        for (var i = 0; i < verses.length; i++) {
            verseModel.append(verses[i]);
            if (verses[i].verse === targetVerse) {
                targetIndex = i;
            }
        }
        
        scrollToTimer.targetIndex = targetIndex;
        scrollToTimer.start();
        saveState();
    }

    function nextChapter() {
        var maxCh = dbManager.getChapterCount(bookName);
        if (chapterNum < maxCh) {
            chapterNum++;
            targetVerse = 1;
            bookName_cn = dbManager.getBookName(bookName);
            loadVerses();
        } else {
            // Next book
            var allBooks = dbManager.getAllBooks();
            for (var i = 0; i < allBooks.length - 1; i++) {
                if (allBooks[i].short_name === bookName) {
                    forceLoadVerses(allBooks[i+1].short_name, 1, 1);
                    break;
                }
            }
        }
    }

    function prevChapter() {
        if (chapterNum > 1) {
            chapterNum--;
            targetVerse = 1;
            bookName_cn = dbManager.getBookName(bookName);
            loadVerses();
        } else {
            // Prev book
            var allBooks = dbManager.getAllBooks();
            for (var i = 1; i < allBooks.length; i++) {
                if (allBooks[i].short_name === bookName) {
                    var prevBook = allBooks[i-1].short_name;
                    var maxCh = dbManager.getChapterCount(prevBook);
                    forceLoadVerses(prevBook, maxCh, 1);
                    break;
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        Rectangle {
            Layout.fillWidth: true
            height: 60
            color: "white"
            
            Rectangle {
                width: parent.width
                height: 1
                color: "#eeeeee"
                anchors.bottom: parent.bottom
            }
            
            RowLayout {
                anchors.centerIn: parent
                spacing: 5
                Text {
                    text: bookName_cn + " 第 " + chapterNum + " 章"
                    font.pixelSize: 18
                    color: "#333333"
                }
                Text {
                    text: "▼"
                    font.pixelSize: 12
                    color: "#888888"
                }
            }
            
            TapHandler {
                onTapped: {
                    selectorPopup.openPopup();
                }
            }
        }

        // Verse List
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: verseList
                anchors.fill: parent
                clip: true
                spacing: 10
                
                model: ListModel { id: verseModel }
                
                delegate: Item {
                    width: ListView.view.width
                    height: verseRow.implicitHeight + 20
                    
                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.min(parent.width - 40, 800)
                        height: parent.height
                        radius: 8
                        color: model.verse === targetVerse ? "#FEF5CD" : "transparent"
                        
                        RowLayout {
                            id: verseRow
                            anchors.fill: parent
                            anchors.margins: 15
                            spacing: 15
                            
                            Text {
                                text: model.verse
                                color: "#4A78E8"
                                font.pixelSize: 18
                                font.bold: true
                                Layout.alignment: Qt.AlignTop
                            }
                            
                            Text {
                                id: verseText
                                text: model.content
                                wrapMode: Text.WordWrap
                                font.pixelSize: 18
                                lineHeight: 1.6
                                color: "#444444"
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignTop
                            }
                        }
                        
                        TapHandler {
                            onTapped: {
                                targetVerse = model.verse;
                                saveState();
                            }
                        }
                    }
                }
                
                footer: Item {
                    width: ListView.view.width
                    height: 80
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 20
                        ActionButtuon {
                            content: "上一章"
                            width: 80
                            height: 40
                            onClicked: prevChapter()
                        }
                        ActionButtuon {
                            content: "下一章"
                            width: 80
                            height: 40
                            onClicked: nextChapter()
                        }
                    }
                }
            }
            
            // Swipe detection
            DragHandler {
                target: null
                xAxis.enabled: true
                yAxis.enabled: false
                onActiveChanged: {
                    if (!active) {
                        if (translation.x < -80) {
                            nextChapter()
                        } else if (translation.x > 80) {
                            prevChapter()
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: scrollToTimer
        interval: 100
        property int targetIndex: 0
        onTriggered: {
            verseList.positionViewAtIndex(targetIndex, ListView.Center);
        }
    }

    // Selector Popup
    Popup {
        id: selectorPopup
        width: parent.width
        height: parent.height * 0.8
        y: parent.height - height
        modal: true
        focus: true
        padding: 0
        
        background: Rectangle {
            color: "white"
            radius: 20
            Rectangle {
                width: parent.width
                height: 20
                color: "white"
                anchors.bottom: parent.bottom
            }
        }
        
        property int currentTab: 0 // 0: Book, 1: Chapter, 2: Verse
        property string selBook: root.bookName
        property int selChapter: root.chapterNum
        property int selVerse: 1
        
        function openPopup() {
            selBook = root.bookName;
            selChapter = root.chapterNum;
            currentTab = 0;
            loadBooks();
            selectorPopup.open();
        }
        
        function loadBooks() {
            bookModel.clear();
            var allBooks = dbManager.getAllBooks();
            for(var i=0; i<allBooks.length; i++){
                bookModel.append(allBooks[i]);
            }
        }
        
        function loadChapters() {
            chapterModel.clear();
            var count = dbManager.getChapterCount(selBook);
            for(var i=1; i<=count; i++) {
                chapterModel.append({num: i});
            }
        }
        
        function loadVerses() {
            verseNumModel.clear();
            var count = dbManager.getVerseCount(selBook, selChapter);
            for(var i=1; i<=count; i++) {
                verseNumModel.append({num: i});
            }
        }

        ColumnLayout {
            anchors.fill: parent
            
            // Header
            Rectangle {
                Layout.fillWidth: true
                height: 50
                color: "#f5f5f5"
                radius: 20
                Rectangle {
                    width: parent.width
                    height: 20
                    color: "#f5f5f5"
                    anchors.bottom: parent.bottom
                }
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    Item { Layout.fillWidth: true }
                    Text { text: "选择经文"; font.pixelSize: 18; }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "关闭"
                        color: "#2C68E6"
                        font.pixelSize: 16
                        TapHandler { onTapped: selectorPopup.close() }
                    }
                }
            }
            
            // Tabs
            RowLayout {
                Layout.fillWidth: true
                height: 40
                spacing: 0
                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    color: selectorPopup.currentTab === 0 ? "white" : "#eeeeee"
                    Text { anchors.centerIn: parent; text: "卷"; font.pixelSize: 16; }
                    TapHandler { onTapped: selectorPopup.currentTab = 0 }
                }
                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    color: selectorPopup.currentTab === 1 ? "white" : "#eeeeee"
                    Text { anchors.centerIn: parent; text: "章"; font.pixelSize: 16; }
                    TapHandler { 
                        onTapped: {
                            if(selectorPopup.selBook !== "") {
                                selectorPopup.currentTab = 1;
                                selectorPopup.loadChapters();
                            }
                        }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    color: selectorPopup.currentTab === 2 ? "white" : "#eeeeee"
                    Text { anchors.centerIn: parent; text: "节"; font.pixelSize: 16;}
                    TapHandler { 
                        onTapped: {
                            if(selectorPopup.selBook !== "" && selectorPopup.selChapter > 0) {
                                selectorPopup.currentTab = 2;
                                selectorPopup.loadVerses();
                            }
                        }
                    }
                }
            }
            
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: selectorPopup.currentTab
                
                // Book list
                ListView {
                    id: bookListView
                    clip: true
                    model: ListModel { id: bookModel }
                    section.property: "is_nt"
                    section.criteria: ViewSection.FullString
                    section.delegate: Rectangle {
                        width: ListView.view.width
                        height: 30
                        color: "#e0e0e0"
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 15
                            text: section === "true" ? "新约" : "旧约"
                            font.pixelSize: 16
                            font.bold: true
                        }
                    }
                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 50
                        color: selectorPopup.selBook === model.short_name ? "#e6f0ff" : "white"
                        border.color: "#eee"
                        border.width: 1
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 20
                            text: model.name_cn
                            font.pixelSize: 16
                            color: selectorPopup.selBook === model.short_name ? "#2C68E6" : "#333"
                        }
                        TapHandler {
                            onTapped: {
                                selectorPopup.selBook = model.short_name;
                                selectorPopup.selChapter = 1;
                                selectorPopup.loadChapters();
                                selectorPopup.currentTab = 1;
                            }
                        }
                    }
                }
                
                // Chapter grid
                GridView {
                    clip: true
                    cellWidth: width / 5
                    cellHeight: 50
                    model: ListModel { id: chapterModel }
                    delegate: Item {
                        width: GridView.view.cellWidth
                        height: GridView.view.cellHeight
                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width - 10
                            height: parent.height - 10
                            radius: 5
                            color: selectorPopup.selChapter === model.num ? "#2C68E6" : "#f5f5f5"
                            Text {
                                anchors.centerIn: parent
                                text: model.num
                                font.pixelSize: 16
                                color: selectorPopup.selChapter === model.num ? "white" : "#333"
                            }
                        }
                        TapHandler {
                            onTapped: {
                                selectorPopup.selChapter = model.num;
                                selectorPopup.selVerse = 1;
                                selectorPopup.loadVerses();
                                selectorPopup.currentTab = 2;
                            }
                        }
                    }
                }
                
                // Verse grid
                GridView {
                    clip: true
                    cellWidth: width / 5
                    cellHeight: 50
                    model: ListModel { id: verseNumModel }
                    delegate: Item {
                        width: GridView.view.cellWidth
                        height: GridView.view.cellHeight
                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width - 10
                            height: parent.height - 10
                            radius: 5
                            color: "#f5f5f5"
                            Text {
                                anchors.centerIn: parent
                                text: model.num
                                font.pixelSize: 16
                                color: "#333"
                            }
                        }
                        TapHandler {
                            onTapped: {
                                selectorPopup.close();
                                root.forceLoadVerses(selectorPopup.selBook, selectorPopup.selChapter, model.num);
                            }
                        }
                    }
                }
            }
        }
    }
}
