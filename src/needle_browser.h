// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
// SPDX-FileCopyrightText: 2026 Harald Sitter <sitter@kde.org>

#pragma once

#include <QList>
#include <QObject>
#include <QUrl>
#include <QVariant>
#include <qqmlregistration.h>

/*!
 * The needle file browser backend exposed to QML.
 *
 * Lists the needles (json+png pairs) in a persistent, configurable
 * directory so the app can start on a browser page instead of a file
 * picker when no needle was passed on the command line.
 */
class NeedleBrowser : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QUrl dir MEMBER m_dir WRITE setDir NOTIFY dirChanged)
    Q_PROPERTY(QList<QVariant> needles READ needles NOTIFY needlesChanged)

public:
    explicit NeedleBrowser(QObject *parent = nullptr);

    void setDir(const QUrl &dir);

    [[nodiscard]] QList<QVariant> needles() const;

Q_SIGNALS:
    void dirChanged();
    void needlesChanged();

private:
    /*! Rescan the directory and rebuild the needle list. */
    void rescan();

    QUrl m_dir;
    QList<QVariant> m_needles;
};
