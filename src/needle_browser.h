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
    Q_PROPERTY(QString readableDir READ readableDir NOTIFY dirChanged STORED false)
    Q_PROPERTY(QList<QVariant> needles READ needles NOTIFY needlesChanged)

public:
    explicit NeedleBrowser(QObject *parent = nullptr);

    void setDir(const QUrl &dir);

    [[nodiscard]] QList<QVariant> needles() const;

    /*! Validate the selected PNG and suggest a needle name and folder. */
    Q_INVOKABLE void prepareNeedleCreation(const QUrl &imageUrl);

    /*! Create a needle then browse its folder and emit needleCreated().
     *  Emits errorOccurred() on failure. */
    Q_INVOKABLE void createNeedle(const QUrl &jsonUrl, const QUrl &imageUrl);

Q_SIGNALS:
    void dirChanged();
    void needlesChanged();
    void errorOccurred(const QString &message);
    void needleCreationPrepared(const QUrl &folder, const QUrl &jsonUrl);
    void needleCreated(const QUrl &jsonUrl);

private:
    /*! Check the image contents, including that the PNG can be decoded. */
    bool validatePng(const QString &imagePath);

    /*! Rescan the directory and rebuild the needle list. */
    void rescan();

    /*! Normalise the user-visible directory so we aren't providing a
     *  file:// URL. */
    QString readableDir() const;

    QUrl m_dir;
    QList<QVariant> m_needles;
};
