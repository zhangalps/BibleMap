import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtCore

ApplicationWindow {
    id: window
    visible: true
    width: 400
    height: 600
    title: "Bible Map App"

    Settings {
        id: appSettings
        property string lastBook: "Gen"
        property int lastChapter: 1
        property int lastVerse: 1
    }

    property int currentTabIndex: 0

    function openBibleAt(book, chapter, verse) {
        appSettings.lastBook = book;
        appSettings.lastChapter = chapter;
        appSettings.lastVerse = verse;
        currentTabIndex = 1;
        if (biblePage.item) {
            biblePage.item.forceLoadVerses(book, chapter, verse);
        }
    }

    StackLayout {
        id: stackLayout
        anchors.fill: parent
        currentIndex: currentTabIndex

        BibleMapView {
            id: mapView
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        Loader {
            id: biblePage
            Layout.fillWidth: true
            Layout.fillHeight: true
            source: "BiblePage.qml"
        }
    }

    footer: Rectangle {
        width: parent.width
        height: 60
        color: "white"
        
        Rectangle {
            width: parent.width
            height: 1
            color: "#eeeeee"
            anchors.top: parent.top
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Column {
                    anchors.centerIn: parent
                    spacing: 4
                    Image {
                        source: currentTabIndex === 0 ? "qrc:/resource/map_selected.svg" : "qrc:/resource/map.svg"
                        width: 24
                        height: 24
                        sourceSize: Qt.size(24, 24)
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: "地图"
                        font.pixelSize: 12
                        color: currentTabIndex === 0 ? "#2C68E6" : "#888888"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
                TapHandler {
                    onTapped: currentTabIndex = 0
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Column {
                    anchors.centerIn: parent
                    spacing: 4
                    Image {
                        source: currentTabIndex === 1 ? "qrc:/resource/bible_selected.svg" : "qrc:/resource/bible.svg"
                        width: 24
                        height: 24
                        sourceSize: Qt.size(24, 24)
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: "圣经"
                        font.pixelSize: 12
                        color: currentTabIndex === 1 ? "#2C68E6" : "#888888"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
                TapHandler {
                    onTapped: currentTabIndex = 1
                }
            }
        }
    }
}
