// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
// SPDX-FileCopyrightText: 2026 Harald Sitter <sitter@kde.org>

pragma ComponentBehavior: Bound

import QtQuick

import org.kde.kirigami as Kirigami
import org.kde.ki18n

import org.kde.needler

Kirigami.ApplicationWindow {
    id: root

    width: Kirigami.Units.gridUnit * 40
    height: Kirigami.Units.gridUnit * 40
    visible: true
    title: root.editorPage !== null && String(root.editorPage.document.baseName).length > 0
           ? KI18n.i18nc("@title:window", "%1 - Needler", root.editorPage.document.baseName)
           : KI18n.i18nc("@title:window", "Needler")

    // The editor page is created on demand (a needle was passed as argument or
    // picked in the browser).
    property EditorPage editorPage: null

    NeedleBrowser {
        id: needleBrowser
    }

    Component {
        id: editorComponent
        EditorPage {}
    }

    pageStack.initialPage: BrowserPage {
        browser: needleBrowser
        onOpenNeedle: (jsonUrl) => root.openEditor(jsonUrl)
    }

    function openEditor(url) {
        if (root.editorPage === null) {
            root.editorPage = pageStack.push(editorComponent)
        }
        root.editorPage.load(url)
    }

    Component.onCompleted: {
        if (Application.arguments.length < 2) { // [binary, file]
            return;
        }
        root.openEditor(Application.arguments[1])
    }
}
