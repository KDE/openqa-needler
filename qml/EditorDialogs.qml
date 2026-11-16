// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
// SPDX-FileCopyrightText: 2026 Harald Sitter <sitter@kde.org>

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

import org.kde.kirigami as Kirigami
import org.kde.ki18n

import org.kde.needler

// The editor page's dialogs (error report, missing master tag).
Item {
    id: dialogs

    required property NeedleDocument document

    // Ask the editor page to save (after the master tag was added).
    signal saveRequested()

    function showError(message) {
        errorDialog.text = message
        errorDialog.open()
    }

    function showMissingMasterTag() {
        missingMasterTagDialog.open()
    }

    Dialog {
        id: missingMasterTagDialog
        title: KI18n.i18nc("@title:dialog", "Missing master tag")
        modal: true
        anchors.centerIn: parent
        standardButtons: Dialog.Yes | Dialog.No
        width: Math.min(dialogs.parent.width - 2 * Kirigami.Units.largeSpacing, Kirigami.Units.gridUnit * 28)

        contentItem: Label {
            text: KI18n.i18nc("@info:dialog", "All needles must be tagged with their base name, but this needle is missing the tag \"%1\". Should it be added automatically?", dialogs.document.baseName)
            wrapMode: Text.WordWrap
        }

        onAccepted: {
            const tags = Array.from(dialogs.document.tags)
            tags.push(dialogs.document.baseName)
            dialogs.document.tags = tags
            dialogs.saveRequested()
        }
    }

    Dialog {
        id: errorDialog
        property string text
        title: KI18n.i18nc("@title:dialog", "Error")
        modal: true
        anchors.centerIn: parent
        standardButtons: Dialog.Ok
        // width: Math.min(dialogs.parent.width - 2 * Kirigami.Units.largeSpacing, Kirigami.Units.gridUnit * 28)

        // SelectableLabel so the error text can be selected and copied,
        // e.g. to paste it into a bug report.
        contentItem: Kirigami.SelectableLabel {
            text: errorDialog.text
            wrapMode: Text.WordWrap
        }
    }
}
