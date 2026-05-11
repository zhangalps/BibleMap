import QtQuick
import QtQuick.Window
import QtQuick.Controls

Window {
    visible: true
    width: 400
    height: 600
    title: "Bible Map App"

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: "BibleMapView.qml"
    }
}
