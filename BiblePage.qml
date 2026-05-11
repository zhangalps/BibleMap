import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    
    // Properties passed from Map page
    property string bookName: "Gen"
    property int chapterNum: 1
    property int targetVerse: 1
    property string bookName_cn: dbManager.getBookName(bookName)

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
                anchors.fill: parent
                anchors.margins: 10
                
                Button {
                    text: "\u2190" // left arrow
                    flat: true
                    font.pixelSize: 24
                    onClicked: stackView.pop()
                }
                
                Item { Layout.fillWidth: true } // Spacer
                
                Text {
                    text: bookName_cn + " 第 " + chapterNum + " 章"
                    font.pixelSize: 18
                    font.bold: true
                    color: "#333333"
                }
                
                Item { Layout.fillWidth: true } // Spacer
            }
        }

        // Verse List
        ListView {
            id: verseList
            Layout.fillWidth: true
            Layout.fillHeight: true
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
                }
            }
            
            // Handle swipe or buttons for next/prev chapter (simplified to buttons for now)
            footer: Item {
                width: ListView.view.width
                height: 80
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 20
                    Button {
                        text: "Previous Chapter"
                        onClicked: {
                            if (chapterNum > 1) {
                                chapterNum--
                                loadVerses()
                            }
                        }
                    }
                    Button {
                        text: "Next Chapter"
                        onClicked: {
                            chapterNum++
                            loadVerses()
                        }
                    }
                }
            }
        }
    }

    function loadVerses() {
        var verses = dbManager.getVerses(bookName_cn, chapterNum);
        verseModel.clear();
        var targetIndex = 0;
        for (var i = 0; i < verses.length; i++) {
            verseModel.append(verses[i]);
            if (verses[i].verse === targetVerse) {
                targetIndex = i;
            }
        }
        
        // Scroll to target verse
        // Use a timer to ensure ListView has populated
        scrollToTimer.targetIndex = targetIndex;
        scrollToTimer.start();
    }

    Timer {
        id: scrollToTimer
        interval: 100
        property int targetIndex: 0
        onTriggered: {
            verseList.positionViewAtIndex(targetIndex, ListView.Center);
        }
    }

    Component.onCompleted: {
        bookName_cn = dbManager.getBookName(bookName)
        console.log("book name:" + bookName_cn)
        loadVerses();
    }
}
