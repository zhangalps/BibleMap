import QtQuick 2.15
import QtQuick.Controls

Rectangle {
    id: root
    property color btnColor:"#4a90e2"
    property color textColor:"white"

    property alias content: btnText.text

    signal clicked()

    color: btnColor
    radius: 8
    Text {
        id: btnText
        anchors.centerIn: parent
        color: textColor
        font.pixelSize: 18
        horizontalAlignment: Text.AlignHCenter
    }
    MouseArea{
        anchors.fill: parent
        onClicked: {
            root.clicked()
        }
    }
}
