// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
// SPDX-FileCopyrightText: 2026 Harald Sitter <sitter@kde.org>

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQml.Models

import org.kde.kirigami as Kirigami
import org.kde.ki18n

import org.kde.needler

// The main editor page: sidebar on the left, screenshot with areas on the
// right. The parts live in EditorSidebar.qml, ImageView.qml and
// EditorDialogs.qml; this file only holds the shared state and load/save.
Kirigami.Page {
    id: root

    padding: 0
    title: String(document.baseName).length > 0
           ? KI18n.i18nc("@title:window", "%1 Needler", document.baseName)
           : KI18n.i18nc("@title:window", "Needler")

    // The needle document. Exposed so the window can bind its title to the
    // loaded needle.
    readonly property NeedleDocument document: NeedleDocument {
        onErrorOccurred: (title, message, details, canRetrySave) => dialogs.showError(title, message, details, canRetrySave)
        onMissingMasterTag: dialogs.showMissingMasterTag()
    }

    // Exposed for the sidebar and the image view.
    readonly property alias selectorModel: areasModel

    // The currently selected area, whose properties are shown in the sidebar.
    property var selectedArea: null

    actions: [
        Kirigami.Action {
            text: KI18n.i18nc("@action:intoolbar", "Add Area")
            icon.name: "list-add"
            displayHint: Kirigami.DisplayHint.KeepVisible
            enabled: imageView.imageItem.width > 0 && imageView.imageItem.height > 0
            onTriggered: imageView.addArea()
        }
    ]

    // Keep Save local to the active editor with a Shortcut object.
    Shortcut {
        sequences: [StandardKey.Save]
        enabled: root.isCurrentPage && root.document.baseName.length > 0
        onActivated: root.save()
    }

    /**
     * @returns {var} the area item at the given index in the model
     */
    function areaAt(i) {
        return areasModel.get(i)
    }

    /**
     * @returns {var} a new area item parented to the image
     */
    function createArea() {
        return areaComponent.createObject(imageView.imageItem, {
            "imageArea": imageView.imageItem,
            "selectorModel": areasModel,
            "editorPage": root
        })
    }

    Component {
        id: areaComponent
        AreaItem {}
    }

    ObjectModel {
        id: areasModel

        function removeObject(obj) {
            for (let i = 0; i < areasModel.count; ++i) {
                const item = root.areaAt(i)
                if (item === obj) {
                    areasModel.remove(i)
                    return
                }
            }
        }

        // Sets all but the passed item as not clickable and the passed one
        // as clickable. openQA clicks the last area in the area array, so the
        // click area is moved to the end when saving.
        function setClickArea(obj) {
            for (let i = 0; i < areasModel.count; ++i) {
                const item = root.areaAt(i)
                item.clickArea = (item === obj)
            }
        }
    }

    function load(url) {
        const areasJson = document.load(url)
        if (areasJson.length === 0) {
            return
        }
        console.log("needler: loaded", document.baseName, "with", JSON.parse(areasJson).length, "areas")
        areasModel.clear()
        const areas = JSON.parse(areasJson)
        for (let i = 0; i < areas.length; ++i) {
            const item = root.createArea()
            item.fromObject(areas[i])
            if (i === areas.length - 1) {
                // Legacy convention: the last area is the click area.
                item.clickArea = true
            }
            areasModel.append(item)
        }
        imageView.showImage(document.pngUrl)
    }

    function save() {
        // If the base name isn't in the tags we raise a warning first.
        if (document.baseName.length > 0 && Array.from(document.tags).indexOf(document.baseName) < 0) {
            dialogs.showMissingMasterTag()
            return
        }
        const areas = []
        let clickArea = null
        for (let i = 0; i < areasModel.count; ++i) {
            const item = root.areaAt(i)
            if (item.clickArea) {
                clickArea = item
                continue
            }
            areas.push(item.toObject())
        }
        if (clickArea !== null) {
            areas.push(clickArea.toObject())
        }
        document.save(JSON.stringify(areas))
    }

    EditorDialogs {
        id: dialogs
        document: root.document
        onSaveRequested: root.save()
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        EditorSidebar {
            // Fixed-width sidebar; maximumWidth keeps the layout from ever
            // growing it beyond the intended panel size.
            Layout.preferredWidth: Kirigami.Units.gridUnit * 16
            Layout.maximumWidth: Kirigami.Units.gridUnit * 16

            editorPage: root
            onSaveRequested: root.save()
        }

        Kirigami.Separator {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
        }

        ScrollView {
            id: imageScrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            padding: 0
            clip: true

            rightPadding: effectiveScrollBarWidth
            bottomPadding: effectiveScrollBarHeight

            background: Rectangle {
                Kirigami.Theme.colorSet: Kirigami.Theme.View
                Kirigami.Theme.inherit: false
                color: Kirigami.Theme.backgroundColor
            }

            ImageView {
                id: imageView

                document: root.document
                selectorModel: areasModel
                editorPage: root
                onSaveRequested: root.save()
            }
        }
    }
}
