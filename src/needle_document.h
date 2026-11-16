// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
// SPDX-FileCopyrightText: 2026 Harald Sitter <sitter@kde.org>

#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QUrl>
#include <qqmlregistration.h>

/*!
 * The needle document backend exposed to QML.
 *
 * Owns the currently open needle: loading/parsing/validating the JSON
 * sidecar, writing it back canonically, and basic file operations for the
 * screenshot. The interactive area list itself lives in QML.
 */
class NeedleDocument : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QUrl fileUrl MEMBER m_fileUrl NOTIFY fileUrlChanged)
    Q_PROPERTY(QString baseName MEMBER m_baseName NOTIFY baseNameChanged)
    Q_PROPERTY(QUrl pngUrl MEMBER m_pngUrl NOTIFY pngUrlChanged)
    Q_PROPERTY(QStringList tags MEMBER m_tags NOTIFY tagsChanged)
    Q_PROPERTY(QStringList needleProperties MEMBER m_needleProperties NOTIFY needlePropertiesChanged)

public:
    explicit NeedleDocument(QObject *parent = nullptr);

    /*! Load the needle identified by \a url (either its .json or .png file).
     *
     * On success the tags/properties/url properties are updated, loaded()
     * is emitted, and the areas are returned as a JSON array string.
     * On failure errorOccurred() is emitted and an empty string returned. */
    Q_INVOKABLE [[nodiscard]] QString load(const QUrl &url);

    /*! Save the needle. \a areasJson is a JSON array of area objects as
     * edited in QML. Returns false (emitting missingMasterTag() or
     * errorOccurred()) on failure. */
    Q_INVOKABLE [[nodiscard]] bool save(const QString &areasJson);

    /*! Copy an image file, e.g. when dropping a new PNG onto the needle. */
    Q_INVOKABLE [[nodiscard]] bool copyImage(const QUrl &source, const QUrl &target);

Q_SIGNALS:
    void loaded();
    void saved();
    void errorOccurred(const QString &message);
    void missingMasterTag();
    void fileUrlChanged();
    void baseNameChanged();
    void pngUrlChanged();
    void tagsChanged();
    void needlePropertiesChanged();

private:
    /*! Base path (without extension) of the currently open needle. */
    QString m_base;
    QUrl m_fileUrl;
    QString m_baseName;
    QUrl m_pngUrl;
    QStringList m_tags;
    QStringList m_needleProperties;
};
