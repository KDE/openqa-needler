// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
// SPDX-FileCopyrightText: 2026 Harald Sitter <sitter@kde.org>

#include "needle_document.h"

#include "needle.h"

#include <QFile>

#include <KLocalizedString>

using namespace Qt::StringLiterals;

NeedleDocument::NeedleDocument(QObject *parent)
    : QObject(parent)
    , m_tagsModel(this)
{
}

QStringList NeedleDocument::tags() const
{
    return m_tagsModel.stringList();
}

void NeedleDocument::setTags(const QStringList &tags)
{
    if (m_tagsModel.stringList() == tags) {
        return;
    }

    m_tagsModel.setStringList(tags);
    Q_EMIT tagsChanged();
}

QStringListModel *NeedleDocument::tagsModel()
{
    return &m_tagsModel;
}

void NeedleDocument::addTag(const QString &tag)
{
    if (tag.isEmpty()) {
        return;
    }

    const int row = m_tagsModel.rowCount();
    m_tagsModel.insertRow(row);
    m_tagsModel.setData(m_tagsModel.index(row), tag);
    Q_EMIT tagsChanged();
}

void NeedleDocument::removeTagAt(int index)
{
    if (m_tagsModel.removeRow(index)) {
        Q_EMIT tagsChanged();
    }
}

QString NeedleDocument::load(const QUrl &url)
{
    const QString local = url.toLocalFile();
    if (local.isEmpty()) {
        Q_EMIT errorOccurred(
            i18nc("@title:window", "Could Not Open Needle"),
            i18nc("@info", "This needle is not a local file. Download its JSON file and PNG image to the same folder, then open the local copy."),
            url.toDisplayString(),
            false);
        return {};
    }
    const QString base = needle::basePath(local);
    QString error;
    const auto loadedNeedle = needle::loadFromBase(base, &error);
    if (!loadedNeedle.has_value()) {
        Q_EMIT errorOccurred(
            i18nc("@title:window", "Could Not Open Needle"),
            i18nc("@info", "Could not open %1. Check that the file exists, is readable, and contains valid needle data, then open it again.", local),
            error,
            false);
        return {};
    }

    const QString areasJson = needle::areasToJson(loadedNeedle->area);

    m_base = base;
    m_fileUrl = QUrl::fromLocalFile(base + u".json"_s);
    m_baseName = needle::baseName(base);
    m_pngUrl = QUrl::fromLocalFile(base + u".png"_s);
    m_needleProperties = loadedNeedle->properties;
    Q_EMIT fileUrlChanged();
    Q_EMIT baseNameChanged();
    Q_EMIT pngUrlChanged();
    setTags(loadedNeedle->tags);
    Q_EMIT needlePropertiesChanged();
    Q_EMIT loaded();

    return areasJson;
}

bool NeedleDocument::save(const QString &areasJson)
{
    QString error;
    const auto areas = needle::parseAreas(areasJson, &error);
    if (!areas.has_value()) {
        Q_EMIT errorOccurred(i18nc("@title:window", "Could Not Save Needle"),
                             i18nc("@info", "The needle contains invalid area data. Check each area's size, position, and type, then save again."),
                             error,
                             false);
        return false;
    }

    needle::Needle needle{
        .area = *areas,
        .properties = m_needleProperties,
        .tags = tags(),
    };

    if (!needle.hasMasterTag(needle::baseName(m_base))) {
        Q_EMIT missingMasterTag();
        return false;
    }

    if (!needle::saveToBase(m_base, needle, &error)) {
        Q_EMIT errorOccurred(
            i18nc("@title:window", "Could Not Save Needle"),
            i18nc("@info",
                  "Could not save %1. Check that the file and its folder are writable and that there is enough free disk space, then retry saving.",
                  m_fileUrl.toLocalFile()),
            error,
            true);
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
