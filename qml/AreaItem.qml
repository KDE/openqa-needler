// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
// SPDX-FileCopyrightText: 2026 Harald Sitter <sitter@kde.org>

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.ki18n

// A rectangular area of the needle screenshot. Geometry is kept in the
// item's own x/y/width/height and serialized as xpos/ypos/width/height.
Rectangle {
    id: rect

    // The item displaying the needle screenshot, used to clamp the area
    // inside the image bounds.
    required property Item imageArea
    // The ObjectModel holding all areas, used for click-area and removal.
    required property var selectorModel
    // The editor page, used to select this area on click.
    required property var editorPage

    property string areaType: "match"
    property real matchThreshold: 95
    // Whether the needle JSON explicitly had a "match" value for this area.
    property bool matchExplicit: false
    // -1 means no explicit margin (consumer default applies).
    property int margin: -1
    // Click point relative to the area, or null.
    property var clickPoint: null
    // Whether this is the click target (serialized as last area in the array).
    property bool clickArea: false

    // Minimal width/height when resizing.
    property int minimumOffset: 12

    function fromObject(obj) {
        x = obj.xpos
        y = obj.ypos
        width = obj.width
        height = obj.height
        areaType = obj.type
        if ("match" in obj) {
            matchThreshold = obj.match
            matchExplicit = true
        } else {
            matchThreshold = 95
            matchExplicit = false
        }
        margin = ("margin" in obj) ? obj.margin : -1
        clickPoint = ("click_point" in obj) ? obj.click_point : null
    }

    function toObject() {
        const obj = {
            "xpos": Math.round(rect.x),
            "ypos": Math.round(rect.y),
            "width": Math.round(rect.width),
            "height": Math.round(rect.height),
            "type": rect.areaType
        }
        if (rect.matchExplicit) {
            obj.match = rect.matchThreshold
        }
        if (rect.margin >= 0) {
            obj.margin = rect.margin
        }
        if (rect.clickPoint !== null) {
            obj.click_point = {
                "xpos": rect.clickPoint.xpos,
                "ypos": rect.clickPoint.ypos
            }
            if (rect.clickPoint.id !== undefined) {
                obj.click_point.id = rect.clickPoint.id
            }
        }
        return obj
    }

    function dimensionHint() {
        dimensionText.text = Math.round(width) + "x" + Math.round(height)
        dimensionText.visible = true
    }

    function fillColor() {
        if (rect.clickArea) {
            return "gold"
        }
        switch (rect.areaType) {
        case "exclude": return "red"
        case "ocr": return "orange"
        default: return "green"
        }
    }

    x: 0
    y: 0
    width: 64
    height: 64

    color: "transparent"
    border.width: 2
    border.color: rect.clickArea ? "gold" : "black"

    // Clamp the area inside the image bounds. Only applies once the image
    // has a real size; before that the loaded coordinates are kept as-is.
    function clampGeometry() {
        const w = rect.imageArea.width
        const h = rect.imageArea.height
        if (w > 0) {
            const maxX = Math.max(0, w - minimumOffset)
            if (x < 0) {
                x = 0
            } else if (x > maxX) {
                x = maxX
            }
            const maxW = Math.max(minimumOffset, w - x)
            if (width > maxW) {
                width = maxW
            }
        }
        if (h > 0) {
            const maxY = Math.max(0, h - minimumOffset)
            if (y < 0) {
                y = 0
            } else if (y > maxY) {
                y = maxY
            }
            const maxH = Math.max(minimumOffset, h - y)
            if (height > maxH) {
                height = maxH
            }
        }
        x = Math.round(x)
        y = Math.round(y)
        width = Math.max(minimumOffset, Math.round(width))
        height = Math.max(minimumOffset, Math.round(height))
    }

    onXChanged: clampGeometry()
    onYChanged: clampGeometry()
    onWidthChanged: {
        clampGeometry()
        dimensionHint()
    }
    onHeightChanged: {
        clampGeometry()
        dimensionHint()
    }

    Rectangle {
        anchors.fill: parent
        color: rect.fillColor()
        opacity: 0.4
    }

    // Click point marker.
    Rectangle {
        visible: rect.clickPoint !== null
        x: rect.clickPoint ? rect.clickPoint.xpos - radius : 0
        y: rect.clickPoint ? rect.clickPoint.ypos - radius : 0
        width: 10
        height: 10
        radius: 5
        color: "gold"
        border.width: 1
        border.color: "black"
    }

    Text {
        id: dimensionText
        visible: false
        anchors.centerIn: parent
        color: "black"

        onVisibleChanged: {
            if (visible) {
                dimensionTimer.restart()
            }
        }

        Timer {
            id: dimensionTimer
            interval: 2500
            repeat: false
            onTriggered: dimensionText.visible = false
        }
    }

    MouseArea {
        id: areaMouseArea

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        preventStealing: true

        drag.target: rect
        drag.minimumX: 0
        drag.maximumX: Math.max(0, rect.imageArea.width - rect.width)
        drag.minimumY: 0
        drag.maximumY: Math.max(0, rect.imageArea.height - rect.height)

        ToolTip.delay: 1500
        ToolTip.visible: containsMouse
        ToolTip.text: KI18n.i18nc("@info:tooltip", "x: %1\ny: %2\nw: %3\nh: %4\ntype: %5", Math.round(rect.x), Math.round(rect.y), Math.round(rect.width), Math.round(rect.height), rect.areaType)

        onPressed: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                rect.editorPage.selectedArea = rect
            }
            if (mouse.button === Qt.RightButton) {
                contextMenu.x = mouse.x
                contextMenu.y = mouse.y
                contextMenu.open()
                mouse.accepted = true
            }
        }

        onDoubleClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                // match -> exclude -> ocr -> match
                switch (rect.areaType) {
                case "match": rect.areaType = "exclude"; break
                case "exclude": rect.areaType = "ocr"; break
                default: rect.areaType = "match"; break
                }
            }
        }
    }

    // Resize handles on all four edges.
    Repeater {
        model: [
            { edge: "top", axis: "y" },
            { edge: "bottom", axis: "y" },
            { edge: "left", axis: "x" },
            { edge: "right", axis: "x" }
        ]
        delegate: Rectangle {
            id: handle

            required property var modelData

            width: 12
            height: 12
            radius: 6
            color: Kirigami.Theme.highlightColor
            border.width: 1
            border.color: Kirigami.Theme.textColor

            anchors.horizontalCenter: modelData.edge === "left" ? rect.left
                                 : modelData.edge === "right" ? rect.right
                                 : rect.horizontalCenter
            anchors.verticalCenter: modelData.edge === "top" ? rect.top
                                 : modelData.edge === "bottom" ? rect.bottom
                                 : rect.verticalCenter

            MouseArea {
                anchors.fill: parent
                drag.target: handle
                drag.axis: handle.modelData.axis === "x" ? Drag.XAxis : Drag.YAxis
                preventStealing: true
                onMouseXChanged: {
                    if (!drag.active || handle.modelData.axis !== "x") {
                        return
                    }
                    if (handle.modelData.edge === "right") {
                        rect.width = rect.width + mouseX
                    } else {
                        rect.width = rect.width - mouseX
                        rect.x = rect.x + mouseX
                    }
                    if (rect.width < rect.minimumOffset) {
                        if (handle.modelData.edge === "right") {
                            rect.width = rect.minimumOffset
                        } else {
                            rect.x = rect.x + (rect.width - rect.minimumOffset)
                            rect.width = rect.minimumOffset
                        }
                    }
                }
                onMouseYChanged: {
                    if (!drag.active || handle.modelData.axis !== "y") {
                        return
                    }
                    if (handle.modelData.edge === "bottom") {
                        rect.height = rect.height + mouseY
                    } else {
                        rect.height = rect.height - mouseY
                        rect.y = rect.y + mouseY
                    }
                    if (rect.height < rect.minimumOffset) {
                        if (handle.modelData.edge === "bottom") {
                            rect.height = rect.minimumOffset
                        } else {
                            rect.y = rect.y + (rect.height - rect.minimumOffset)
                            rect.height = rect.minimumOffset
                        }
                    }
                }
            }
        }
    }

    Menu {
        id: contextMenu

        MenuItem {
            text: KI18n.i18nc("@action:menu", "Mark as click target")
            icon.name: "input-mouse"
            onTriggered: rect.selectorModel.setClickArea(rect)
        }
        MenuItem {
            text: KI18n.i18nc("@action:menu", "Delete")
            icon.name: "edit-delete"
            onTriggered: rect.selectorModel.removeObject(rect)
        }
    }

}
