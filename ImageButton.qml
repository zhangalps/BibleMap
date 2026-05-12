import QtQuick 2.15

Rectangle {
    id: baseView
    width: 28
    height: 28
    property string iconPath:""
    radius: height / 2
    color: "transparent"

    signal imgClicked
    Image {
        id: srcImage
        anchors.fill: parent
        anchors.margins: height / 4.5
        anchors.centerIn: parent
        source: iconPath
        fillMode: Image.PreserveAspectFit
        smooth: true
        antialiasing: true
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onCanceled: {
            baseView.color = "transparent"
        }
        onEntered: {
            baseView.color = "#60e5e7eb"
        }
        onExited: {
            baseView.color = "transparent"
        }
        onPressed: {
            baseView.color = "#e5e7eb"
        }
        onReleased: {
            baseView.color = "transparent"
        }
        onClicked: {
            imgClicked()
            baseView.color = "transparent"
        }
    }
}
