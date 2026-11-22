// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
// SPDX-FileCopyrightText: 2026 Harald Sitter <sitter@kde.org>

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.ki18n

import org.kde.needler

// The dumb file browser shown when the app was started without a needle
// argument: lists the needles in the persistent needle directory.
Kirigami.Page {
    id: browserPage
    padding: 0

    title: KI18n.i18nc("@title:window", "Needles")

    required property NeedleBrowser browser

    property string searchText: ""
    readonly property bool hasDirectory: browser.readableDir.length > 0

    // Open the given needle (json URL) in the editor.
    signal openNeedle(url jsonUrl)
    signal folderOpened()

    function createNeedle() {
        imageDialog.open()
    }

    function openFolder() {
        folderDialog.open()
    }

    actions: [
        Kirigami.Action {
            id: createNeedleAction
            text: KI18n.i18nc("@action", "Create Needle…")
            icon.name: "document-new"
            onTriggered: browserPage.createNeedle()
        },
        Kirigami.Action {
            id: openFolderAction
            text: KI18n.i18nc("@action", "Open Folder…")
            icon.name: "folder-open"
            onTriggered: browserPage.openFolder()
        },
        Kirigami.Action {
            separator: true
            visible: browserPage.browser.needles.length > 0
        },
        Kirigami.Action {
            text: KI18n.i18nc("@action", "Search")
            icon.name: "search"
            displayHint: Kirigami.DisplayHint.KeepVisible
            visible: browserPage.browser.needles.length > 0

            displayComponent: Kirigami.SearchField {
                width: Kirigami.Units.gridUnit * 12
                text: browserPage.searchText
                onTextChanged: browserPage.searchText = text
            }
        }
    ]

    Kirigami.Action {
        id: clearSearchAction
        text: KI18n.i18nc("@action:button", "Clear Search")
        icon.name: "edit-clear"
        onTriggered: browserPage.searchText = ""
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        RowLayout {
            visible: browserPage.hasDirectory
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing

            Label {
                text: KI18n.i18nc("@label:textbox", "Needle folder:")
            }
            Kirigami.ActionTextField {
                id: dirField
                Layout.fillWidth: true

                text: browserPage.browser.readableDir
                selectByMouse: true
                onAccepted: browserPage.browser.dir = text

                rightActions: Kirigami.Action {
                    text: KI18n.i18nc("@action:button", "Choose folder")
                    icon.name: "folder-open"
                    onTriggered: folderDialog.open()
                }
            }
        }

        Kirigami.Separator {
            visible: browserPage.hasDirectory
            Layout.fillWidth: true
        }

        ScrollView {
            id: needleScrollView
            visible: needleRepeater.count > 0
            Layout.fillWidth: true
            Layout.fillHeight: true

            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            Flickable {
                id: needleFlickable
                width: needleScrollView.availableWidth
                height: needleScrollView.availableHeight
                clip: true

                contentWidth: width
                contentHeight: needleFlow.height

                Flow {
                    id: needleFlow

                    readonly property real cardWidth: Kirigami.Units.gridUnit * 15
                    readonly property int columns: Math.max(1, Math.min(
                        needleRepeater.count,
                        Math.floor((needleFlickable.width - 2 * padding + spacing)
                        / (cardWidth + spacing))
                    ))

                    width: Math.min(needleFlickable.width,
                                    columns * cardWidth + (columns - 1) * spacing + 2 * padding)
                    height: implicitHeight
                    anchors.horizontalCenter: parent.horizontalCenter

                    padding: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.largeSpacing

                    move: Transition {
                        NumberAnimation {
                            properties: "x,y"
                            duration: Kirigami.Units.longDuration
                            easing.type: Easing.OutCubic
                        }
                    }

                    Repeater {
                        id: needleRepeater
                        model: browserPage.browser.needles.filter(needle =>
                            needle.name.toLowerCase().includes(browserPage.searchText.toLowerCase())
                        )

                        delegate: Kirigami.AbstractCard {
                            id: card
                            required property var modelData

                            width: Kirigami.Units.gridUnit * 15
                            height: Kirigami.Units.gridUnit * 9

                            showClickFeedback: true
                            onClicked: browserPage.openNeedle(modelData.jsonUrl)

                            contentItem: Item {
                                implicitWidth: Kirigami.Units.gridUnit * 10
                                implicitHeight: Kirigami.Units.gridUnit * 6

                                ColumnLayout {
                                    anchors.fill: parent
                                    spacing: Kirigami.Units.largeSpacing

                                    Image {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        source: card.modelData.pngUrl
                                        fillMode: Image.PreserveAspectCrop
                                        smooth: true
                                        clip: true
                                    }

                                    Label {
                                        Layout.fillWidth: true
                                        text: card.modelData.name
                                        elide: Text.ElideMiddle
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            visible: needleRepeater.count === 0
            Layout.fillWidth: true
            Layout.fillHeight: true

            Kirigami.PlaceholderMessage {
                anchors.centerIn: parent
                width: Math.min(parent.width - 4 * Kirigami.Units.largeSpacing,
                                Kirigami.Units.gridUnit * 24)

                icon.name: !browserPage.hasDirectory ? "document-open-folder-symbolic"
                    : browserPage.browser.needles.length === 0 ? "folder-symbolic" : "edit-find-symbolic"

                text: !browserPage.hasDirectory
                    ? KI18n.i18nc("@info empty needle browser", "Open a needle folder")
                    : browserPage.browser.needles.length === 0
                        ? KI18n.i18nc("@info empty needle browser", "No needles found")
                        : KI18n.i18nc("@info empty needle browser", "No matching needles")

                explanation: !browserPage.hasDirectory
                    ? KI18n.i18nc("@info empty needle browser", "Choose a folder containing openQA needles to browse and edit them.")
                    : browserPage.browser.needles.length === 0
                        ? KI18n.i18nc("@info empty needle browser, %1 is the selected folder path", "No needles were found in %1. Create a needle from an image or open another folder.", browserPage.browser.readableDir)
                        : KI18n.i18nc("@info empty needle browser", "Try a different search or clear the search to show all needles.")

                helpfulAction: !browserPage.hasDirectory ? openFolderAction
                    : browserPage.browser.needles.length === 0 ? createNeedleAction : clearSearchAction
            }
        }
    }

    FolderDialog {
        id: folderDialog
        onAccepted: {
            browserPage.browser.dir = selectedFolder
            browserPage.folderOpened()
        }
    }

    FileDialog {
        id: imageDialog
        title: KI18n.i18nc("@title:window", "Choose a Needle Image")

        fileMode: FileDialog.OpenFile
        nameFilters: [KI18n.i18nc("@item:inlistbox", "PNG images (*.png)")]

        onAccepted: browserPage.browser.prepareNeedleCreation(selectedFile)
    }

    FileDialog {
        id: needleDialog
        title: KI18n.i18nc("@title:window", "Create Needle")

        acceptLabel: KI18n.i18nc("@action:button", "Create")
        fileMode: FileDialog.SaveFile
        defaultSuffix: "json"
        nameFilters: [KI18n.i18nc("@item:inlistbox", "Needle files (*.json)")]

        onAccepted: browserPage.browser.createNeedle(selectedFile, imageDialog.selectedFile)
    }

    Connections {
        target: browserPage.browser

        function onNeedleCreationPrepared(folder: url, jsonUrl: url) {
            needleDialog.currentFolder = folder
            needleDialog.selectedFile = jsonUrl
            needleDialog.open()
        }

        function onNeedleCreated(jsonUrl: url) {
            browserPage.searchText = ""
            browserPage.openNeedle(jsonUrl)
        }

        function onErrorOccurred(message: string) {
            errorDialog.subtitle = message
            errorDialog.open()
        }
    }

    Kirigami.PromptDialog {
        id: errorDialog

        title: KI18n.i18nc("@title:window", "Could Not Create Needle")
        standardButtons: Kirigami.Dialog.Close

        customFooterActions: [
            Kirigami.Action {
                text: KI18n.i18nc("@action:button", "Try Again…")
                icon.name: "document-new"
                onTriggered: {
                    errorDialog.close()
                    browserPage.createNeedle()
                }
            }
        ]
    }
}
