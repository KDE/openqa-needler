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
ColumnLayout {
    id: sidebar

    // The editor page owning the document, area model and selection.
    required property var editorPage

    // Ask the editor page to save.
    signal saveRequested()

    function addTag(tag) {
        const tags = Array.from(sidebar.editorPage.document.tags)
        tags.push(tag)
        sidebar.editorPage.document.tags = tags
    }

    function removeTagAt(i) {
        const tags = Array.from(sidebar.editorPage.document.tags)
        tags.splice(i, 1)
        sidebar.editorPage.document.tags = tags
    }

    Label {
        text: KI18n.i18nc("@title:group", "Properties")
        font.bold: true
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

    Label {
        text: KI18n.i18nc("@title:group", "Tags")
        font.bold: true
    }
    TextField {
        id: newTagField
        Layout.fillWidth: true
        placeholderText: KI18n.i18nc("@info:textfield", "Add new tag…")
        selectByMouse: true
        onAccepted: {
            if (text.length > 0) {
                sidebar.addTag(text)
                clear()
            }
        }
    }
    ListView {
        Layout.fillWidth: true
        Layout.preferredHeight: contentHeight
        clip: true
        model: sidebar.editorPage.document.tags
        ScrollBar.vertical: ScrollBar {}

        delegate: Kirigami.Chip {
            required property string modelData
            required property int index

            text: modelData
            icon.name: "tag-symbolic"
            width: ListView.view.width
            onRemoved: sidebar.removeTagAt(index)
        }
    }

    Label {
        text: KI18n.i18nc("@title:group", "Area")
        font.bold: true
        visible: sidebar.editorPage.selectedArea !== null
    }
    Kirigami.FormLayout {
        Layout.fillWidth: true
        visible: sidebar.editorPage.selectedArea !== null

        ComboBox {
            Kirigami.FormData.label: KI18n.i18nc("@label:form", "Type:")
            Layout.fillWidth: true
            model: ["match", "ocr", "exclude"]
            currentIndex: sidebar.editorPage.selectedArea ? Math.max(0, model.indexOf(sidebar.editorPage.selectedArea.areaType)) : 0
            onActivated: sidebar.editorPage.selectedArea.areaType = currentText
        }

        SpinBox {
            Kirigami.FormData.label: KI18n.i18nc("@label:form", "Similarity:")
            Layout.fillWidth: true
            from: 0
            to: 100
            value: sidebar.editorPage.selectedArea ? Math.round(sidebar.editorPage.selectedArea.matchThreshold) : 95
            onValueModified: {
                sidebar.editorPage.selectedArea.matchThreshold = value
                sidebar.editorPage.selectedArea.matchExplicit = true
            }
        }

        SpinBox {
            Kirigami.FormData.label: KI18n.i18nc("@label:form", "Margin:")
            Layout.fillWidth: true
            from: -1
            to: 999
            value: sidebar.editorPage.selectedArea ? sidebar.editorPage.selectedArea.margin : -1
            textFromValue: (value) => value < 0 ? KI18n.i18nc("@item:inlistbox", "default") : value.toString()
            onValueModified: sidebar.editorPage.selectedArea.margin = value
        }

        RowLayout {
            Kirigami.FormData.label: KI18n.i18nc("@label:form", "Click point:")
            Label {
                text: sidebar.editorPage.selectedArea && sidebar.editorPage.selectedArea.clickPoint !== null
                      ? KI18n.i18nc("@info", "%1, %2", sidebar.editorPage.selectedArea.clickPoint.xpos, sidebar.editorPage.selectedArea.clickPoint.ypos)
                      : KI18n.i18nc("@info", "none")
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
            Kirigami.FormData.label: KI18n.i18nc("@label:form", "Click target:")
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
            Kirigami.FormData.label: ""
            text: KI18n.i18nc("@action:button", "Delete area")
            icon.name: "edit-delete"
            onClicked: {
                sidebar.editorPage.selectorModel.removeObject(sidebar.editorPage.selectedArea)
                sidebar.editorPage.selectedArea = null
            }
        }
    }

    Item {
        Layout.fillHeight: true
    }

    RowLayout {
        Button {
            text: KI18n.i18nc("@action:button", "Save")
            icon.name: "document-save"
            onClicked: sidebar.saveRequested()
        }
        Button {
            text: KI18n.i18nc("@action:button", "Quit")
            icon.name: "application-exit"
            onClicked: Qt.quit()
        }
    }
}
