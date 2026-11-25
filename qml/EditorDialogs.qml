// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
// SPDX-FileCopyrightText: 2026 Harald Sitter <sitter@kde.org>

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.ki18n

import org.kde.openqa.needler

// The editor page's dialogs (error report, missing master tag).
Item {
    id: dialogs

    required property NeedleDocument document

    // Ask the editor page to save (after the master tag was added).
    signal saveRequested()

    function showError(title, message, details, canRetrySave) {
        errorDialog.title = title
        errorDialog.message = message
        errorDialog.details = details
        errorDialog.canRetrySave = canRetrySave

        errorDialog.open()
    }

    function showMissingMasterTag() {
        missingMasterTagDialog.open()
    }

    Kirigami.PromptDialog {
        id: missingMasterTagDialog
        title: KI18n.i18nc("@title:window", "Add Required Tag")
        subtitle: KI18n.i18nc("@info", "The needle needs the tag “%1” before it can be saved. Add the tag and save, or cancel to continue editing.", dialogs.document.baseName)
        standardButtons: Kirigami.Dialog.Cancel

        customFooterActions: [
            Kirigami.Action {
                text: KI18n.i18nc("@action:button", "Add Tag and Save")
                icon.name: "document-save"
                onTriggered: {
                    missingMasterTagDialog.close()
                    dialogs.document.addTag(dialogs.document.baseName)
                    dialogs.saveRequested()
                }
            }
        ]
    }

    Kirigami.Dialog {
        id: errorDialog

        property string message
        property string details
        property bool canRetrySave: false

        preferredWidth: Kirigami.Units.gridUnit * 28
        maximumWidth: preferredWidth
        padding: Kirigami.Units.largeSpacing

        standardButtons: Kirigami.Dialog.Close

        customFooterActions: [
            Kirigami.Action {
                text: KI18n.i18nc("@action:button", "Retry Save")
                icon.name: "document-save"
                visible: errorDialog.canRetrySave

                onTriggered: {
                    errorDialog.close()
                    dialogs.saveRequested()
                }
            }
        ]

        ColumnLayout {
            spacing: Kirigami.Units.largeSpacing

            Label {
                Layout.fillWidth: true

                text: errorDialog.message
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
            }

            // Keep diagnostics selectable for copying.
            Kirigami.SelectableLabel {
                Layout.fillWidth: true
                visible: errorDialog.details.length > 0

                text: errorDialog.details
                textFormat: Text.PlainText
                wrapMode: Text.WrapAnywhere
            }
        }
    }
}
