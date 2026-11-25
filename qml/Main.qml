// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
// SPDX-FileCopyrightText: 2026 Harald Sitter <sitter@kde.org>

pragma ComponentBehavior: Bound

import QtQuick

import org.kde.kirigami as Kirigami
import org.kde.kirigami.layouts as KirigamiLayouts
import org.kde.ki18n

import org.kde.kirigamiaddons.formcard as FormCard

import org.kde.openqa.needler
import org.kde.openqa.needler.about

Kirigami.ApplicationWindow {
    id: root

    width: Kirigami.Units.gridUnit * 40
    height: Kirigami.Units.gridUnit * 40
    visible: true

    title: root.editorPage !== null
        && pageStack.currentItem === root.editorPage
        ? root.editorPage.document.baseName
        : ""

    globalDrawer: Kirigami.GlobalDrawer {
        isMenu: true
        enabled: true
        handleVisible: false
        actions: [
            Kirigami.Action {
                text: KI18n.i18nc("@action:inmenu", "Quit")
                icon.name: "gtk-quit"
                shortcut: StandardKey.Quit
                onTriggered: Qt.quit()
            },

            Kirigami.Action {
                text: KI18n.i18nc("@action:inmenu", "About")
                icon.name: "help-about"
                onTriggered: {
                    if (root.pageStack.layers.depth === 1) {
                        root.pageStack.layers.push(aboutComponent)
                    }
                }
            }
        ]
    }

    Component {
        id: aboutComponent

        FormCard.AboutPage {
            aboutData: About
        }
    }

    pageStack.columnView.columnResizeMode: KirigamiLayouts.ColumnView.SingleColumn
    pageStack.globalToolBar.showNavigationButtons: Kirigami.ApplicationHeaderStyle.ShowBackButton

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
        id: browserPage
        browser: needleBrowser
        onOpenNeedle: (jsonUrl) => root.openEditor(jsonUrl)
        onFolderOpened: root.pageStack.currentIndex = 0
    }

    // Keep New and Open available throughout the window, including in the editor.
    Shortcut {
        sequences: [StandardKey.New]
        onActivated: browserPage.createNeedle()
    }

    Shortcut {
        sequences: [StandardKey.Open]
        onActivated: browserPage.openFolder()
    }

    function openEditor(url) {
        if (pageStack.depth > 1) {
            root.editorPage = pageStack.get(pageStack.depth - 1)
            pageStack.currentIndex = pageStack.depth - 1
        } else {
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
