// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
// SPDX-FileCopyrightText: 2026 Harald Sitter <sitter@kde.org>

#include "needle_document.h"

#include "needle.h"

#include <QFile>

using namespace Qt::StringLiterals;

NeedleDocument::NeedleDocument(QObject *parent)
    : QObject(parent)
{
}

QString NeedleDocument::load(const QUrl &url)
{
    const QString local = url.toLocalFile();
    if (local.isEmpty()) {
        Q_EMIT errorOccurred(u"not a local file: %1"_s.arg(url.toDisplayString()));
        return {};
    }
    const QString base = needle::basePath(local);
    QString error;
    const auto loadedNeedle = needle::loadFromBase(base, &error);
    if (!loadedNeedle.has_value()) {
        Q_EMIT errorOccurred(error);
        return {};
    }

    const QString areasJson = needle::areasToJson(loadedNeedle->area);

    m_base = base;
    m_fileUrl = QUrl::fromLocalFile(base + u".json"_s);
    m_baseName = needle::baseName(base);
    m_pngUrl = QUrl::fromLocalFile(base + u".png"_s);
    m_tags = loadedNeedle->tags;
    m_needleProperties = loadedNeedle->properties;
    Q_EMIT fileUrlChanged();
    Q_EMIT baseNameChanged();
    Q_EMIT pngUrlChanged();
    Q_EMIT tagsChanged();
    Q_EMIT needlePropertiesChanged();
    Q_EMIT loaded();

    return areasJson;
}

bool NeedleDocument::save(const QString &areasJson)
{
    QString error;
    const auto areas = needle::parseAreas(areasJson, &error);
    if (!areas.has_value()) {
        Q_EMIT errorOccurred(u"invalid areas JSON: %1"_s.arg(error));
        return false;
    }

    needle::Needle needle{
        .area = *areas,
        .properties = m_needleProperties,
        .tags = m_tags,
    };

    if (!needle.hasMasterTag(needle::baseName(m_base))) {
        Q_EMIT missingMasterTag();
        return false;
    }

    if (!needle::saveToBase(m_base, needle, &error)) {
        Q_EMIT errorOccurred(error);
        return false;
    }

    Q_EMIT saved();
    return true;
}

bool NeedleDocument::copyImage(const QUrl &source, const QUrl &target)
{
    const QString sourceFile = source.toLocalFile();
    const QString targetFile = target.toLocalFile();
    if (sourceFile.isEmpty() || targetFile.isEmpty()) {
        return false;
    }
    QFile::remove(targetFile);
    return QFile::copy(sourceFile, targetFile);
}
