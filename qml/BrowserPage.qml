// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
// SPDX-FileCopyrightText: 2026 Harald Sitter <sitter@kde.org>

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.ki18n
import org.kde.kirigamiaddons.formcard as FormCard

import org.kde.needler

// The dumb file browser shown when the app was started without a needle
// argument: lists the needles in the persistent needle directory.
Kirigami.ScrollablePage {
    id: browserPage

    title: KI18n.i18nc("@title:page", "Needles")

    required property NeedleBrowser browser

    // Open the given needle (json URL) in the editor.
    signal openNeedle(url jsonUrl)

    // NOTE: in a ScrollablePage the content item is sized by its child, so
    // the child must set its width explicitly (anchors.fill would collapse).
    ColumnLayout {
        width: browserPage.width
        Layout.margins: Kirigami.Units.largeSpacing

        RowLayout {
            Layout.fillWidth: true

            Label {
                text: KI18n.i18nc("@label:form", "Needle directory:")
            }
            TextField {
                id: dirField
                Layout.fillWidth: true
                text: String(browserPage.browser.dir)
                selectByMouse: true
                onAccepted: browserPage.browser.dir = text
            }
            Button {
                text: KI18n.i18nc("@action:button", "Choose…")
                icon.name: "folder-open"
                onClicked: folderDialog.open()
            }
        }

        FormCard.FormGridContainer {
            Layout.fillWidth: true

            Repeater {
                model: browserPage.browser.needles

                // FormGridContainer only collects delegates that are
                // QtQuick.Controls Controls, hence Control as the root.
                delegate: Control {
                    id: card

                    required property var modelData

                    // Fixed implicit size; deriving it from the children would
                    // be circular (the children fill the card).
                    implicitWidth: Kirigami.Units.gridUnit * 10
                    implicitHeight: Kirigami.Units.gridUnit * 6

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: Kirigami.Units.smallSpacing

                        Image {
                            id: preview
                            Layout.fillWidth: true
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 4
                            source: card.modelData.pngUrl
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                        }
                        Label {
                            id: nameLabel
                            Layout.fillWidth: true
                            text: card.modelData.name
                            elide: Text.ElideMiddle
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: browserPage.openNeedle(card.modelData.jsonUrl)
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }

    FolderDialog {
        id: folderDialog
        onAccepted: browserPage.browser.dir = selectedFolder
    }
}
