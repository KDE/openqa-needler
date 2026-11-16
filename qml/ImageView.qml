// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
// SPDX-FileCopyrightText: 2026 Harald Sitter <sitter@kde.org>

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

import org.kde.kirigami as Kirigami
import org.kde.ki18n

import org.kde.needler

// The screenshot view of the editor: image, drag&drop of a new PNG, zoom,
// the area rectangles and the image context menu.
Flickable {
    id: flick

    clip: true

    // Zoom factor of the screenshot view.
    property real zoom: 1.0

    required property NeedleDocument document
    required property var selectorModel
    // The editor page, used to create areas.
    required property var editorPage

    readonly property alias imageItem: imageItem

    // Ask the editor page to save.
    signal saveRequested()

    contentWidth: imageItem.width * imageItem.scale
    contentHeight: imageItem.height * imageItem.scale

    ScrollBar.horizontal: ScrollBar {}
    ScrollBar.vertical: ScrollBar {}

    function showImage(url) {
        image.source = ""
        image.source = url
    }

    Item {
        id: imageItem

        width: image.sourceSize.width
        height: image.sourceSize.height
        scale: flick.zoom

        Image {
            id: image
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            smooth: true

            onSourceSizeChanged: {
                // The image size was unknown when the areas were
                // created; clamp them now that it is known.
                for (let i = 0; i < flick.selectorModel.count; ++i) {
                    flick.editorPage.areaAt(i).clampGeometry()
                }
            }
        }

        DropArea {
            anchors.fill: parent
            onEntered: (drag) => {
                drag.accepted = false
                if (drag.urls.length !== 1 || !String(drag.urls[0]).endsWith(".png")) {
                    return
                }
                drag.accepted = true
                drag.action = Qt.CopyAction
            }
            onDropped: (drop) => {
                if (flick.document.copyImage(drop.urls[0], flick.document.pngUrl)) {
                    flick.showImage(flick.document.pngUrl)
                }
            }
        }

        // Below the areas so they keep receiving their own mouse
        // events; handles zoom and the image context menu.
        MouseArea {
            id: imageMouseArea

            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: true

            property int lastX: 0
            property int lastY: 0

            onWheel: (wheel) => {
                if (wheel.modifiers & Qt.ControlModifier) {
                    const steps = wheel.angleDelta.y / 120
                    flick.zoom = Math.min(8, Math.max(0.25, flick.zoom + steps * 0.25))
                    wheel.accepted = true
                    return
                }
                wheel.accepted = false
            }

            onPressed: (mouse) => {
                lastX = mouse.x
                lastY = mouse.y
                if (mouse.button === Qt.RightButton) {
                    imageContextMenu.x = mouse.x
                    imageContextMenu.y = mouse.y
                    imageContextMenu.open()
                    mouse.accepted = true
                }
            }
        }

        // The areas, on top of the image mouse area.
        Repeater {
            model: flick.selectorModel
        }

        Menu {
            id: imageContextMenu

            MenuItem {
                text: KI18n.i18nc("@action:menu", "Add area")
                icon.name: "list-add"
                onTriggered: {
                    const item = flick.editorPage.createArea()
                    item.x = Math.min(Math.round(imageMouseArea.lastX), Math.max(0, imageItem.width - item.width))
                    item.y = Math.min(Math.round(imageMouseArea.lastY), Math.max(0, imageItem.height - item.height))
                    flick.selectorModel.append(item)
                }
            }
            MenuItem {
                text: KI18n.i18nc("@action:button", "Save")
                icon.name: "document-save"
                onTriggered: flick.saveRequested()
            }
        }
    }
}
