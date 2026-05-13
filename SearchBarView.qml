import QtQuick
import QtQuick.Controls
import QtQuick.Layouts 1.15
import QtQuick.Controls.Basic

Rectangle {
    id: root
    height: 40
    radius: height / 4
    color: "#ffffff"
    border.width: 1
    border.color: textField.focus ? "#4a90e2" : "transparent"

    property alias text: textField.text
    signal accepted(string text)
    signal cleared()

    RowLayout {
        width: parent.width - 5
        height: parent.height - 3
        anchors.centerIn: parent
        spacing: 5

        Image {
            Layout.leftMargin: 5
            Layout.maximumWidth: 18
            Layout.maximumHeight: 18
            source: "qrc:/resource/search.svg"
            width: 18
            height: 18
            opacity: textField.focus ? 0.9 : 0.6
            clip: true
            fillMode: Image.PreserveAspectFit
            smooth: true
            antialiasing: true
        }
        TextField {
            id: textField
            Layout.fillWidth: true
            placeholderText: "搜索圣经地点..."
            font.pixelSize: 16
            placeholderTextColor: "#ccCCCCCC"
            color: "#000000"
            onAccepted: root.accepted(text)
            background: Rectangle {
                width: textField.width - 10
                height: textField.height - 5
                radius: height / 4
                color: "white"
                border.width: 0
            }
        }
        Image {
            Layout.rightMargin: 5
            Layout.maximumWidth: 18
            Layout.maximumHeight: 18
            source: "qrc:/resource/cancel.svg"
            width: 18
            height: 18
            clip: true
            fillMode: Image.PreserveAspectFit
            smooth: true
            antialiasing: true
            visible: textField.focus
            MouseArea {
               anchors.fill: parent
               onClicked: {
                   textField.focus = false
                   textField.text = ""
                   root.cleared()
               }
            }
        }
    }
}

