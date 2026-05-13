import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtLocation
import QtPositioning

Item {
    id: root
    property var allPlaces: []
    property string pathColor: "#ff00000"
    property int highlightedPlaceId: -2
    property var currentPolylinePath: []

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
                root.highlightedPlaceId = place.id;
                console.log(" place_id:" + place.id)
                bible_map.map.center = QtPositioning.coordinate(place.lat, place.lon);
                bible_map.map.zoomLevel = 12;
                openPopup(place.id, place.name_cn, false);
            } else {
                root.highlightedPlaceId = -2;
            }
        } else {
            root.highlightedPlaceId = -2;
        }
    }

    function openClusterPopup(subPlaces, title) {
        placePopup.isClusterMode = true;
        placePopup.cameFromCluster = true;
        placePopup.clusterTitle = title;
        clusterModel.clear();
        for (var i = 0; i < subPlaces.length; i++) {
            clusterModel.append(subPlaces[i]);
        }
        placePopupTitle.text = title;
        placePopup.open();
    }

    function openPopup(placeId, placeName, fromCluster) {
        placePopup.isClusterMode = false;
        placePopup.cameFromCluster = (fromCluster === true);
        var refs = dbManager.getPlaceRefs(placeId);
        refModel.clear();
        for (var i = 0; i < refs.length; i++) {
            refModel.append(refs[i]);
        }
        placePopupTitle.text = placeName;
        placePopup.open();
    }

    function generateSmoothPath(coords) {
        if (coords.length < 2) return coords;
        var result = [];
        var p = [];
        
        p.push(coords[0]);
        for (var i = 0; i < coords.length; i++) {
            p.push(coords[i]);
        }
        p.push(coords[coords.length - 1]);

        var segments = 20;
        for (var i = 1; i < p.length - 2; i++) {
            var p0 = p[i - 1];
            var p1 = p[i];
            var p2 = p[i + 1];
            var p3 = p[i + 2];

            for (var j = 0; j <= segments; j++) {
                var t = j / segments;
                if (j === segments && i < p.length - 3) continue;

                var t2 = t * t;
                var t3 = t2 * t;

                var lat = 0.5 * ((2 * p1.latitude) +
                                 (-p0.latitude + p2.latitude) * t +
                                 (2 * p0.latitude - 5 * p1.latitude + 4 * p2.latitude - p3.latitude) * t2 +
                                 (-p0.latitude + 3 * p1.latitude - 3 * p2.latitude + p3.latitude) * t3);
                                 
                var lon = 0.5 * ((2 * p1.longitude) +
                                 (-p0.longitude + p2.longitude) * t +
                                 (2 * p0.longitude - 5 * p1.longitude + 4 * p2.longitude - p3.longitude) * t2 +
                                 (-p0.longitude + 3 * p1.longitude - 3 * p2.longitude + p3.longitude) * t3);

                result.push(QtPositioning.coordinate(lat, lon));
            }
        }
        return result;
    }

    function updateRoute() {
        var routeIds = [];
        root.pathColor = "transparent";
        var routeName = "";

        if (currentRoute === 0) {
            routeIds = [1020, 1158, 1076, 387, 900, 442, 702, 893, 675]; // 出埃及
            root.pathColor = "#ff0000";
            routeName = "出埃及路线";
        } else if (currentRoute === 1) {
            routeIds = [231, 381, 920, 198, 1278, 283, 286, 278, 678]; // 耶稣生平
            root.pathColor = "#0000ff";
            routeName = "耶稣生平路线";
        } else if (currentRoute === 2) {
            routeIds = [76, 636, 415, 1230, 980, 1205, 130, 321, 678, 277, 753, 804, 1166, 1056]; // 保罗传道
            root.pathColor = "#00ff00";
            routeName = "保罗传道路线";
        }

        if (currentRoute >= 0) {
            // Ensure all route places from subPlaces are in placeModel
            for (var j = 0; j < routeIds.length; j++) {
                var rId = routeIds[j];
                var found = false;
                for (var k = 0; k < placeModel.count; k++) {
                    if (placeModel.get(k).id === rId) {
                        found = true; break;
                    }
                }
                if (!found) {
                    for (var i = 0; i < root.allPlaces.length; i++) {
                        var p = root.allPlaces[i];
                        if (p.isCluster && p.subPlaces) {
                            for (var s = 0; s < p.subPlaces.length; s++) {
                                if (p.subPlaces[s].id === rId) {
                                    placeModel.append({
                                        id: p.subPlaces[s].id,
                                        name_cn: p.subPlaces[s].name_cn,
                                        lat: p.subPlaces[s].lat,
                                        lon: p.subPlaces[s].lon,
                                        type: p.subPlaces[s].type,
                                        isCluster: false,
                                        minZoom: p.subPlaces[s].minZoom || 12,
                                        inCurrentRoute: false,
                                        routeOrder: 0
                                    });
                                    found = true;
                                    break;
                                }
                            }
                        }
                        if (found) break;
                    }
                }
            }
        }

        // Update placeModel to only show route markers
        for (var i = 0; i < placeModel.count; i++) {
            var item = placeModel.get(i);
            var idx = routeIds.indexOf(item.id);
            if (currentRoute >= 0 && idx >= 0) {
                placeModel.setProperty(i, "inCurrentRoute", true);
                placeModel.setProperty(i, "routeOrder", idx + 1);
            } else {
                placeModel.setProperty(i, "inCurrentRoute", false);
                placeModel.setProperty(i, "routeOrder", 0);
            }
        }
        
        // Build polyline path
        var currentPath = [];
        if (currentRoute >= 0) {
            for (var j = 0; j < routeIds.length; j++) {
                var rId = routeIds[j];
                for (var k = 0; k < placeModel.count; k++) {
                    if (placeModel.get(k).id === rId) {
                        currentPath.push(QtPositioning.coordinate(placeModel.get(k).lat, placeModel.get(k).lon));
                        break;
                    }
                }
            }
            if (routeBannerText) {
                routeBannerText.text = "当前路线：" + routeName;
            }
        }
        root.currentPolylinePath = generateSmoothPath(currentPath);
        
        // Center the map
        if (currentRoute >= 0 && currentPath.length > 0) {
            bible_map.map.center = currentPath[0];
            bible_map.map.zoomLevel = 6;
        }
    }

    ListModel {
        id: placeModel
    }

    property int currentRoute: -1
    onCurrentRouteChanged: {
        updateRoute();
    }

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
        Row {
            id: searchRow
            z: 2
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.margins: 20
            width: Math.min(parent.width - 40, 600)
            height: 48
            spacing: 10

            SearchBarView{
                id: searchInput
                width: parent.width - routeBtn.width - 10

                height: 42
                onAccepted: root.performSearch()
                onTextChanged: {
                    if (text.trim().length === 0) {
                        root.highlightedPlaceId = -2;
                    }
                }
                onCleared: {
                    root.highlightedPlaceId = -2;
                }
            }
            
            ActionButtuon {
                id: routeBtn
                property bool closeMenu: false
                anchors.verticalCenter: searchInput.verticalCenter
                width: 52
                height: 32
                content: "路线"
                onClicked: {
                    routeMenu.open()
                }
                
                Menu {
                    id: routeMenu
                    y: routeBtn.height + 10
                    width: 150
                    onOpened: {
                        routeBtn.closeMenu = true
                    }

                    onClosed: {
                        routeBtn.closeMenu = false
                    }
                    
                    Label {
                        text: "切换历史路线"
                        color: "#888"
                        padding: 5
                        font.pixelSize: 12
                    }

                    Action {
                        text: "清除路线 / 自由探索"
                        onTriggered: { currentRoute = -1 }
                    }

                    Action {
                        text: "出埃及路线 (概略)"
                        onTriggered: { currentRoute = 0 }
                    }
                    Action {
                        text: "耶稣生平路线"
                        onTriggered: { currentRoute = 1 }
                    }
                    Action {
                        text: "保罗第一次传道"
                        onTriggered: { currentRoute = 2 }
                    }
                }
            }
        }

        // Route Banner
        Rectangle {
            id: routeBanner
            visible: root.currentRoute >= 0
            anchors.top: searchRow.bottom
            anchors.topMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter
            width: routeBannerRow.width + 40
            height: 40
            color: "#EAF2FF"
            radius: 20
            border.color: "#2C68E6"
            border.width: 1
            z: 2
            
            RowLayout {
                id: routeBannerRow
                anchors.centerIn: parent
                spacing: 10
                
                Text {
                    id: routeBannerText
                    text: "当前路线"
                    font.pixelSize: 14
                    color: "#2C68E6"
                    // font.bold: true
                }
                
                Rectangle {
                    width: 1
                    height: 20
                    color: "#A0BFF8"
                }
                
                Text {
                    text: "退出模式 x"
                    font.pixelSize: 14
                    color: "#E91E63"
                    // font.bold: true
                    
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -10
                        onClicked: {
                            root.currentRoute = -1;
                        }
                    }
                }
            }
        }

        Component.onCompleted: {
            console.log("map zoom min:" + bible_map.map.minimumZoomLevel + " max:" + bible_map.map.maximumZoomLevel)
            root.allPlaces = dbManager.getAllPlaces()
            placeModel.clear()
            for (var i = 0; i < root.allPlaces.length; i++) {
                placeModel.append({
                                      id: root.allPlaces[i].id,
                                      name_cn: root.allPlaces[i].name_cn,
                                      lat: root.allPlaces[i].lat,
                                      lon: root.allPlaces[i].lon,
                                      type: root.allPlaces[i].type,
                                      isCluster: root.allPlaces[i].isCluster || false,
                                      minZoom: root.allPlaces[i].minZoom || 12,
                                      inCurrentRoute: false,
                                      routeOrder: 0
                                  })
            }
        }

        MapItemView {
            model: placeModel
            parent: bible_map.map
            delegate: MapQuickItem {
                coordinate: QtPositioning.coordinate(model.lat, model.lon)
                anchorPoint: Qt.point(sourceItem.width / 2, sourceItem.height)
                visible: root.currentRoute >= 0 ? model.inCurrentRoute : (bible_map.map.zoomLevel >= (model.minZoom || 12))
                sourceItem: Column {
                    spacing: 4
                    Rectangle {
                        width: model.inCurrentRoute ? 24 : (model.id === root.highlightedPlaceId ? 22 : 16)
                        height: model.inCurrentRoute ? 24 : (model.id === root.highlightedPlaceId ? 22 : 16)
                        radius: width / 2
                        color: model.inCurrentRoute ? root.pathColor : (model.id === root.highlightedPlaceId ? "#E91E63" : (model.isCluster ? "#FF5722" : "#FFB300"))
                        border.color: "white"
                        border.width: 3
                        anchors.horizontalCenter: parent.horizontalCenter
                        
                        Text {
                            anchors.centerIn: parent
                            text: model.routeOrder || ""
                            color: "white"
                            font.pixelSize: 12
                            // font.bold: true
                            visible: model.inCurrentRoute
                        }
                        
                        TapHandler {
                            margin: 10 // larger hit area
                            onTapped: {
                                if (model.isCluster) {
                                    var origSubPlaces = [];
                                    for (var i = 0; i < root.allPlaces.length; i++) {
                                        var p = root.allPlaces[i];
                                        if (p.isCluster && p.lat === model.lat && p.lon === model.lon) {
                                            origSubPlaces = p.subPlaces;
                                            break;
                                        }
                                    }
                                    root.openClusterPopup(origSubPlaces, model.name_cn);
                                } else {
                                    root.openPopup(model.id, model.name_cn, false);
                                }
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
                            // font.bold: true
                        }
                    }
                }
            }
        }

        // Dynamic Route Polyline
        MapItemView {
            model: root.currentRoute >= 0 ? 1 : 0
            parent: bible_map.map
            delegate: MapPolyline {
                line.width: 5
                line.color: root.pathColor
                opacity: 0.7
                path: root.currentPolylinePath
            }
        }

    }

    Rectangle {
        id: placePopup
        property bool isClusterMode: false
        property bool cameFromCluster: false
        property string clusterTitle: ""
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

                ImageButton {
                    iconPath: "qrc:/resource/back.svg"
                    width: 40
                    height: 40
                    visible: !placePopup.isClusterMode && placePopup.cameFromCluster
                    onImgClicked: {
                        placePopup.isClusterMode = true;
                        placePopupTitle.text = placePopup.clusterTitle;
                    }
                }

                Text {
                    text: "*️" // Pin emoji
                    visible: placePopup.isClusterMode || !placePopup.cameFromCluster
                    font.pixelSize: 24
                }

                Text {
                    id: placePopupTitle
                    font.pixelSize: 22
                    // font.bold: true
                    color: "#111"
                    Layout.fillWidth: true
                }

                ImageButton {
                    iconPath: "qrc:/resource/cancel.svg"
                    width: 40
                    height: 40
                    onImgClicked: placePopup.close()
                }
            }

            RowLayout {
                visible: !placePopup.isClusterMode
                Text { text: "#"; font.pixelSize: 16 }
                Text {
                    text: "发生在此处的经文"
                    font.pixelSize: 16
                    // font.bold: true
                    color: "#333"
                }
            }

            ListView {
                id: refListView
                visible: !placePopup.isClusterMode
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
                                // font.bold: true
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
                            window.openBibleAt(model.book, model.chapter, model.verse);
                        }
                    }
                }
            }

            ListView {
                id: clusterListView
                visible: placePopup.isClusterMode
                interactive: true
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: ListModel { id: clusterModel }
                clip: true
                spacing: 10
                delegate: Rectangle {
                    width: ListView.view.width
                    height: 60
                    border.color: "#eee"
                    border.width: 1
                    radius: 8
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 15
                        Text {
                            text: "*"
                            font.pixelSize: 18
                        }
                        Text {
                            text: model.name_cn
                            font.pixelSize: 16
                            // font.bold: true
                            color: "#333"
                            Layout.fillWidth: true
                        }
                        Text {
                            text: "查看经文 >"
                            font.pixelSize: 14
                            color: "#2C68E6"
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.openPopup(model.id, model.name_cn, true);
                        }
                    }
                }
            }
        }
    }

}
