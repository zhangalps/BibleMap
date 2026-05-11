import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtLocation
import QtPositioning

Item {
    id: root
    property var allPlaces: []
    property var aijiPath: [
        QtPositioning.coordinate(30.8010, 31.8410),  // 兰塞 (Rameses) - 出发地
        QtPositioning.coordinate(30.5500, 32.0900),  // 疏割 (Succoth)
        QtPositioning.coordinate(29.9800, 32.5500),  // 伊坦/红海边 (Etham / near Suez)
        QtPositioning.coordinate(29.1000, 33.1000),  // 以琳 (Elim)
        QtPositioning.coordinate(28.5390, 33.9750),  // 西奈山 (Mount Sinai / Jebel Musa)
        QtPositioning.coordinate(29.5300, 34.9900),  // 以旬迦别 (Ezion-Geber / 亚喀巴)
        QtPositioning.coordinate(30.6400, 34.4200),  // 加低斯巴尼亚 (Kadesh-barnea)
        QtPositioning.coordinate(31.7680, 35.7190),  // 尼波山 (Mount Nebo)
        QtPositioning.coordinate(31.8600, 35.4600)   // 耶利哥 (Jericho) - 进入迦南地
    ]
    property var jPath:[
        QtPositioning.coordinate(31.7050, 35.2020),  // 伯利恒 (Bethlehem) - 降生
        QtPositioning.coordinate(30.0444, 31.2357),  // 逃往埃及 (Flight to Egypt - 以开罗区域为代表)
        QtPositioning.coordinate(32.7020, 35.3030),  // 拿撒勒 (Nazareth) - 童年与成长
        QtPositioning.coordinate(31.8360, 35.5460),  // 约旦河外伯大尼 (Jordan River Baptism site) - 受洗
        QtPositioning.coordinate(31.8700, 35.3900),  // 犹大旷野 (Judean Wilderness) - 受试探
        QtPositioning.coordinate(32.7400, 35.3300),  // 迦拿 (Cana) - 变水为酒
        QtPositioning.coordinate(32.8800, 35.5700),  // 迦百农/加利利海 (Capernaum / Sea of Galilee) - 主要传道区
        QtPositioning.coordinate(33.2400, 35.6900),  // 凯撒利亚·腓立比 (Caesarea Philippi)
        QtPositioning.coordinate(31.7780, 35.2350)   // 耶路撒冷 (Jerusalem) - 受难、复活与升天
    ]
    property var paulPath:[
        QtPositioning.coordinate(36.2020, 36.1600),  // 安提阿 (Antioch) - 传道起点
        QtPositioning.coordinate(37.8710, 32.4840),  // 以哥念 (Iconium / 今土耳其科尼亚)
        QtPositioning.coordinate(37.9400, 27.3400),  // 以弗所 (Ephesus)
        QtPositioning.coordinate(39.7500, 26.1600),  // 特罗亚 (Troas)
        QtPositioning.coordinate(41.0120, 24.2840),  // 腓立比 (Philippi) - 进入马其顿
        QtPositioning.coordinate(40.6400, 22.9440),  // 帖撒罗尼迦 (Thessalonica)
        QtPositioning.coordinate(37.9830, 23.7270),  // 雅典 (Athens)
        QtPositioning.coordinate(37.9060, 22.8780),  // 哥林多 (Corinth)
        QtPositioning.coordinate(31.7780, 35.2350),  // 耶路撒冷 (Jerusalem) - 被捕
        QtPositioning.coordinate(32.5010, 34.8980),  // 凯撒利亚 (Caesarea Maritima) - 囚禁与审判
        QtPositioning.coordinate(34.9310, 24.8210),  // 克里特岛佳澳 (Fair Havens, Crete)
        QtPositioning.coordinate(35.8840, 14.4150),  // 马耳他 (Malta) - 遭遇海难
        QtPositioning.coordinate(37.0750, 15.2860),  // 叙拉古 (Syracuse, Sicily)
        QtPositioning.coordinate(41.9020, 12.4960)   // 罗马 (Rome) - 终点
    ]
    property string pathColor: "#ff00000"

    Plugin {
        id: mapPlugin
        name: "osm"
    }

    function performSearch() {
        var keyword = searchInput.text.trim();
        if (keyword.length > 0) {
            var results = dbManager.searchPlaces(keyword);
            if (results.length > 0) {
                var place = results[0];
                bible_map.map.center = QtPositioning.coordinate(place.lat, place.lon);
                bible_map.map.zoomLevel = 12;
                updateMarkers();
                openPopup(place.id, place.name_cn);
            }
        }
    }

    function updateMarkers() {
        if (!bible_map || !bible_map.map || bible_map.map.width === 0) return;
        if (!root.allPlaces || root.allPlaces.length === 0) return;

        var topLeft = bible_map.map.toCoordinate(Qt.point(0, 0));
        var bottomRight = bible_map.map.toCoordinate(Qt.point(bible_map.map.width, bible_map.map.height));

        if (topLeft.isValid && bottomRight.isValid) {
            var minLat = Math.min(topLeft.latitude, bottomRight.latitude);
            var maxLat = Math.max(topLeft.latitude, bottomRight.latitude);
            var minLon = Math.min(topLeft.longitude, bottomRight.longitude);
            var maxLon = Math.max(topLeft.longitude, bottomRight.longitude);
            var zoom = bible_map.map.zoomLevel;
            
            var limit = 20;
            if (zoom > 14) limit = 1000;
            else if (zoom > 11) limit = 500;
            else if (zoom > 8) limit = 200;
            else if (zoom > 5) limit = 100;

            var candidates = [];
            for (var i = 0; i < root.allPlaces.length; i++) {
                var p = root.allPlaces[i];
                if (p.lat >= minLat && p.lat <= maxLat && p.lon >= minLon && p.lon <= maxLon) {
                    candidates.push(p);
                }
            }

            if (candidates.length > limit) {
                candidates = candidates.slice(0, limit);
            }

            var visiblePlaces = [];
            for (var i = 0; i < candidates.length; i++) {
                var p = candidates[i];
                // Keep original coordinates and use overlapIndex from backend
                var placeForModel = {
                    id: p.id,
                    name_cn: p.name_cn,
                    lat: p.lat,
                    lon: p.lon,
                    type: p.type,
                    overlapIndex: p.overlapIndex || 0
                };
                visiblePlaces.push(placeForModel);
            }

            placeModel.clear();
            for (var i = 0; i < visiblePlaces.length; i++) {
                placeModel.append(visiblePlaces[i]);
            }
        }
    }

    function openPopup(placeId, placeName) {
        var refs = dbManager.getPlaceRefs(placeId);
        refModel.clear();
        for (var i = 0; i < refs.length; i++) {
            refModel.append(refs[i]);
        }
        console.log("placeName:::" + placeName)
        placePopupTitle.text = placeName;
        placePopup.open();
    }

    function getPath(type){
        var pathList = []
        switch(type) {
        case 0:
            pathColor = "#ff0000"
            pathList = aijiPath;
            break;
        case 1:
            pathColor = "#0000ff"
            pathList = jPath;
            break;
        case 2:
            pathColor = "#00ff00"
            pathList = paulPath;
            break;
        }
        return pathList
    }

    ListModel {
        id: placeModel
    }

    property int currentRoute: 0

    MapComponent {
        id: bible_map
        // anchors.fill: parent
        anchors{
        top: parent.top
        }
        height: parent.height
        width: parent.width
        map.plugin: mapPlugin
        map.center: QtPositioning.coordinate(31.778, 35.235) // 耶路撒冷
        map.zoomLevel: 7
        Behavior on height {
            NumberAnimation {
                duration: 300
                easing.type: Easing.InOutQuad
            }
        }

        // Search Bar overlay
        RowLayout {
            z: 2
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.margins: 20
            width: Math.min(parent.width - 40, 600)
            height: 48
            spacing: 10
            
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 24
                color: "white"
                border.color: "#e0e0e0"
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 15
                    anchors.rightMargin: 15
                    spacing: 10
                    
                    Text { text: "\uD83D\uDD0D"; font.pixelSize: 18; color: "#888" }
                    
                    TextField {
                        id: searchInput
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        placeholderText: "搜索圣经地点..."
                        background: null
                        font.pixelSize: 16
                        verticalAlignment: TextInput.AlignVCenter
                        onAccepted: root.performSearch()
                    }
                }
            }
            
            Button {
                id: routeBtn
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
                background: Rectangle {
                    color: "#2C68E6"
                    radius: 24
                }
                contentItem: Text {
                    text: "\u2630" // Route icon placeholder
                    color: "white"
                    font.pixelSize: 20
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: routeMenu.open()
                
                Menu {
                    id: routeMenu
                    y: routeBtn.height + 10
                    width: 250
                    
                    Label {
                        text: "切换历史路线"
                        color: "#888"
                        padding: 15
                        font.pixelSize: 12
                    }
                    MenuItem {
                        text: "清除路线 / 自由探索"
                        onTriggered: { currentRoute = -1 }
                    }
                    MenuItem {
                        text: "\uD83D\uDD34 出埃及路线 (概略)"
                        onTriggered: { currentRoute = 0 }
                    }
                    MenuItem {
                        text: "\uD83D\uDD35 耶稣生平路线"
                        onTriggered: { currentRoute = 1 }
                    }
                    MenuItem {
                        text: "\uD83D\uDFE2 保罗第一次传道"
                        onTriggered: { currentRoute = 2 }
                    }
                }
            }
        }

        Timer {
            id: updateTimer
            interval: 500
            onTriggered: root.updateMarkers()
        }

        Connections {
            target: bible_map.map
            function onCenterChanged() { updateTimer.restart() }
            function onZoomLevelChanged() { updateTimer.restart() }
        }

        Component.onCompleted: {
            root.allPlaces = dbManager.getAllPlaces()
            updateTimer.restart()
        }

        MapItemView {
            model: placeModel
            parent: bible_map.map
            delegate: MapQuickItem {
                coordinate: QtPositioning.coordinate(model.lat, model.lon)
                // Shift visually by 30 pixels per overlapIndex (stacking them downwards)
                anchorPoint: Qt.point(sourceItem.width / 2, sourceItem.height - (model.overlapIndex * 30))
                sourceItem: Column {
                    spacing: 4
                    Rectangle {
                        width: 16
                        height: 16
                        radius: 8
                        color: "#FFB300" // Yellow circle
                        border.color: "white"
                        border.width: 3
                        anchors.horizontalCenter: parent.horizontalCenter
                        
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -10 // larger hit area
                            onClicked: {
                                root.openPopup(model.id, model.name_cn);
                            }
                        }
                    }
                    Rectangle {
                        color: "white"
                        radius: 4
                        width: placeLabel.implicitWidth + 8
                        height: placeLabel.implicitHeight + 4
                        anchors.horizontalCenter: parent.horizontalCenter
                        border.color: "#ddd"
                        Text {
                            id: placeLabel
                            anchors.centerIn: parent
                            text: model.name_cn
                            color: "#333"
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }
                }
            }
        }

        // Hardcoded Exodus path
        MapItemView {
            id: pathMapItem
            model: root.currentRoute >= 0 ? 1 : 0
            parent: bible_map.map
            delegate: MapPolyline {
                line.width: 5
                line.color: pathColor // Red for exodus
                opacity: 0.7
                path: getPath(root.currentRoute)
            }
        }

    }

    Rectangle {
        id: placePopup
        anchors {
            bottom: parent.bottom
        }
        color: "white"
        radius: 20
        width: parent.width
        height: parent.height * 0.5
        focus: true
        visible: false

        function close() {
            placePopup.visible = false
            bible_map.height = root.height
        }
        function open() {
            placePopup.visible = true
            bible_map.height = root.height- placePopup.height
        }
        MouseArea {
            anchors.fill: parent
            preventStealing: true
            hoverEnabled: true
        }

        ColumnLayout {
            id:verseLayout
            anchors.fill: parent
            anchors.margins: 20
            anchors.topMargin: 25
            spacing: 15


            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "\uD83D\uDCCD" // Pin emoji
                    font.pixelSize: 24
                }

                Text {
                    id: placePopupTitle
                    font.pixelSize: 22
                    font.bold: true
                    color: "#111"
                    Layout.fillWidth: true
                }

                Button {
                    text: "\u2715"
                    flat: true
                    font.pixelSize: 18
                    onClicked: placePopup.close()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: descText.implicitHeight + 20
                color: "#f8f9fa"
                radius: 8
                visible: false

                Text {
                    id: descText
                    anchors.fill: parent
                    anchors.margins: 10
                    text: "犹大的城邑，大卫的故乡，也是耶稣基督降生的地方。" // Mocked desc
                    wrapMode: Text.WordWrap
                    font.pixelSize: 14
                    color: "#555"
                }
            }

            RowLayout {
                Text { text: "\uD83D\uDCD6"; font.pixelSize: 16 }
                Text {
                    text: "发生在此处的经文"
                    font.pixelSize: 16
                    font.bold: true
                    color: "#333"
                }
            }
            ListView {
                interactive: true
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: ListModel { id: refModel }
                clip: true
                spacing: 10
                delegate: Rectangle {
                    width: ListView.view.width
                    height: refContent.implicitHeight + 20
                    border.color: "#eee"
                    border.width: 1
                    radius: 8

                    ColumnLayout {
                        id: refContent
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        Rectangle {
                            color: "#EAF2FF"
                            radius: 4
                            width: refTitle.implicitWidth + 16
                            height: refTitle.implicitHeight + 8

                            Text {
                                id: refTitle
                                anchors.centerIn: parent
                                text: dbManager.getBookName(model.book) + " " + model.chapter + ":" + model.verse
                                font.pixelSize: 12
                                font.bold: true
                                color: "#2C68E6"
                            }
                        }

                        Text {
                            text: model.content && model.content !== "" ? model.content : "点击阅读此节经文详情..."
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            font.pixelSize: 14
                            color: "#555"
                            lineHeight: 1.4
                            Text {
                                text:  "查看详情"
                                anchors {
                                    bottom: parent.bottom
                                    right: parent.right
                                }
                                font.pixelSize: 14
                                color: "#2C68E6"
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        propagateComposedEvents: false
                        onClicked: {
                            placePopup.close();
                            stackView.push("BiblePage.qml", {
                                               bookName: model.book,
                                               chapterNum: model.chapter,
                                               targetVerse: model.verse
                                           });
                        }
                    }
                }
            }
        }
    }

}
