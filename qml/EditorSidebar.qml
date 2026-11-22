// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
// SPDX-FileCopyrightText: 2026 Harald Sitter <sitter@kde.org>

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.ki18n

import org.kde.needler

// The editor page's sidebar: needle properties, tags, the selected area's
// properties, and the save/quit buttons.
Page {
    id: sidebar

    Layout.fillHeight: true
    padding: 0
    background: null

    // The editor page owning the document, area model and selection.
    required property var editorPage

    // Ask the editor page to save.
    signal saveRequested()

    function addTag(tag) {
        sidebar.editorPage.document.addTag(tag)
    }

    function removeTagAt(i) {
        sidebar.editorPage.document.removeTagAt(i)
    }

    contentItem: Item {
        ColumnLayout {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Kirigami.Units.largeSpacing

            spacing: Kirigami.Units.smallSpacing

            Kirigami.ListSectionHeader {
                text: KI18n.i18nc("@title:group", "Properties")
                Layout.fillWidth: true
                topPadding: Kirigami.Units.largeSpacing
                leftPadding: 0
                rightPadding: 0
            }

            CheckBox {
                text: "workaround" // literal needle property key, not translated
                checked: Array.from(sidebar.editorPage.document.needleProperties).indexOf("workaround") >= 0
                onToggled: {
                    const props = Array.from(sidebar.editorPage.document.needleProperties)
                    const i = props.indexOf("workaround")
                    if (checked && i < 0) {
                        props.push("workaround")
                    } else if (!checked && i >= 0) {
                        props.splice(i, 1)
                    }
                    sidebar.editorPage.document.needleProperties = props
                }
            }

            Kirigami.ListSectionHeader {
                text: KI18n.i18nc("@title:group", "Tags")
                Layout.fillWidth: true
                leftPadding: 0
                rightPadding: 0
            }

            Kirigami.ActionTextField {
                id: newTagField
                Layout.fillWidth: true
                placeholderText: KI18n.i18nc("@info:placeholder", "Add new tag…")
                selectByMouse: true

                function addTag() {
                    const tag = text.trim()
                    if (tag.length === 0) {
                        return
                    }
                    sidebar.addTag(tag)
                    clear()
                }

                onAccepted: addTag()

                rightActions: Kirigami.Action {
                    text: KI18n.i18nc("@action:button", "Add tag")
                    icon.name: "list-add"
                    enabled: newTagField.text.trim().length > 0
                    onTriggered: newTagField.addTag()
                }
            }

            Flow {
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                spacing: Kirigami.Units.smallSpacing

                move: Transition {
                    NumberAnimation {
                        properties: "x,y"
                        duration: Kirigami.Units.longDuration
                        easing.type: Easing.OutCubic
                    }
                }

                Repeater {
                    model: sidebar.editorPage.document.tagsModel

                    delegate: Kirigami.Chip {
                        required property var model
                        required property int index

                        text: model.display
                        icon.name: "tag-symbolic"
                        onRemoved: sidebar.removeTagAt(index)
                    }
                }
            }

            Kirigami.ListSectionHeader {
                visible: sidebar.editorPage.selectedArea !== null
                text: KI18n.i18nc("@title:group", "Area")
                Layout.fillWidth: true
                leftPadding: 0
                rightPadding: 0
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                visible: sidebar.editorPage.selectedArea !== null

                Label {
                    text: KI18n.i18nc("@label:listbox", "Type:")
                }
                ComboBox {
                    Layout.fillWidth: true
                    model: ["match", "ocr", "exclude"]
                    currentIndex: sidebar.editorPage.selectedArea ? Math.max(0, model.indexOf(sidebar.editorPage.selectedArea.areaType)) : 0
                    onActivated: sidebar.editorPage.selectedArea.areaType = currentText
                }

                Label {
                    text: KI18n.i18nc("@label:spinbox", "Similarity:")
                }
                SpinBox {
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    value: sidebar.editorPage.selectedArea ? Math.round(sidebar.editorPage.selectedArea.matchThreshold) : 95
                    onValueModified: {
                        sidebar.editorPage.selectedArea.matchThreshold = value
                        sidebar.editorPage.selectedArea.matchExplicit = true
                    }
                }

                Label {
                    text: KI18n.i18nc("@label:spinbox", "Margin:")
                }
                SpinBox {
                    Layout.fillWidth: true
                    from: -1
                    to: 999
                    value: sidebar.editorPage.selectedArea ? sidebar.editorPage.selectedArea.margin : -1
                    textFromValue: (value) => value < 0 ? KI18n.i18nc("@item default margin setting", "default") : value.toString()
                    onValueModified: sidebar.editorPage.selectedArea.margin = value
                }

                Label {
                    text: KI18n.i18nc("@label", "Click point:")
                }
                RowLayout {
                    Layout.fillWidth: true

                    Label {
                        text: sidebar.editorPage.selectedArea && sidebar.editorPage.selectedArea.clickPoint !== null
                        ? KI18n.i18nc("@label click point coordinates, %1 is x, %2 is y", "%1, %2", sidebar.editorPage.selectedArea.clickPoint.xpos, sidebar.editorPage.selectedArea.clickPoint.ypos)
                        : KI18n.i18nc("@label no click point set", "none")
                    }
                    Button {
                        text: KI18n.i18nc("@action:button", "Set to center")
                        onClicked: sidebar.editorPage.selectedArea.clickPoint = { "xpos": sidebar.editorPage.selectedArea.width / 2, "ypos": sidebar.editorPage.selectedArea.height / 2 }
                    }
                    Button {
                        text: KI18n.i18nc("@action:button", "Clear")
                        onClicked: sidebar.editorPage.selectedArea.clickPoint = null
                    }
                }

                CheckBox {
                    text: KI18n.i18nc("@option:check", "Click target")
                    checked: sidebar.editorPage.selectedArea ? sidebar.editorPage.selectedArea.clickArea : false
                    onToggled: {
                        if (checked) {
                            sidebar.editorPage.selectorModel.setClickArea(sidebar.editorPage.selectedArea)
                        } else {
                            sidebar.editorPage.selectedArea.clickArea = false
                        }
                    }
                }

                Button {
                    text: KI18n.i18nc("@action:button", "Delete area")
                    icon.name: "edit-delete"
                    onClicked: {
                        sidebar.editorPage.selectorModel.removeObject(sidebar.editorPage.selectedArea)
                        sidebar.editorPage.selectedArea = null
                    }
                }
            }
        }
    }

    footer: ToolBar {
        position: ToolBar.Footer
        padding: Kirigami.Units.smallSpacing

        contentItem: RowLayout {
            Item {
                Layout.fillWidth: true
            }

            Button {
                text: KI18n.i18nc("@action:intoolbar", "Save")
                icon.name: "document-save"
                display: AbstractButton.TextBesideIcon
                onClicked: sidebar.saveRequested()
            }
        }
    }
}
