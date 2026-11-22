// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
// SPDX-FileCopyrightText: 2026 Harald Sitter <sitter@kde.org>

#include "needle_browser.h"

#include "needle.h"

#include <algorithm>
#include <ranges>

#include <QCoreApplication>
#include <QDir>
#include <QDirListing>
#include <QFile>
#include <QFileInfo>
#include <QImageReader>
#include <QStandardPaths>
#include <QVariantMap>

#include <KConfigGroup>
#include <KLocalizedString>
#include <KSharedConfig>
#include <KShell>

using namespace Qt::StringLiterals;

namespace
{

inline KSharedConfig::Ptr openConfig()
{
    return KSharedConfig::openConfig(u"org.kde.openqa.needler.conf"_s);
}

QUrl loadPersistedDir()
{
    auto config = openConfig();
    auto group = config->group(u"Browser"_s);
    const QString dir = group.readEntry("Directory", QString());
    if (dir.isEmpty()) {
        return {};
    }
    return QUrl::fromLocalFile(dir);
}

void persistDir(const QUrl &dir)
{
    const QString local = dir.toLocalFile();
    if (local.isEmpty()) {
        return;
    }
    auto config = openConfig();
    auto group = config->group(u"Browser"_s);
    group.writeEntry("Directory", local);
    config->sync();
}

} // namespace

NeedleBrowser::NeedleBrowser(QObject *parent)
    : QObject(parent)
    , m_dir(loadPersistedDir())
{
    rescan();
}

void NeedleBrowser::setDir(const QUrl &dir)
{
    persistDir(dir);
    m_dir = dir;
    rescan();
    Q_EMIT dirChanged();
    Q_EMIT needlesChanged();
}

QList<QVariant> NeedleBrowser::needles() const
{
    return m_needles;
}

bool NeedleBrowser::validatePng(const QString &imagePath)
{
    if (imagePath.isEmpty()) {
        Q_EMIT errorOccurred(i18nc("@info needle creation error", "Choose a local PNG image."));
        return false;
    }

    QImageReader reader(imagePath);
    reader.setDecideFormatFromContent(true);

    if (reader.format() != "png") {
        Q_EMIT errorOccurred(i18nc("@info %1 is the image path", "The image %1 is not a PNG image. Choose a PNG image for the needle.", imagePath));
        return false;
    }

    if (reader.read().isNull()) {
        Q_EMIT errorOccurred(i18nc("@info %1 is the image path, %2 is the error message",
                                   "Could not read the image %1: %2\n\nChoose a readable PNG image, or export the image as PNG again.",
                                   imagePath,
                                   reader.errorString()));
        return false;
    }

    return true;
}

void NeedleBrowser::prepareNeedleCreation(const QUrl &imageUrl)
{
    const QString imagePath = imageUrl.toLocalFile();

    if (!validatePng(imagePath)) {
        return;
    }

    const QFileInfo imageInfo(imagePath);
    const QDir folder(m_dir.toLocalFile().isEmpty() ? imageInfo.absolutePath() : m_dir.toLocalFile());
    const QUrl jsonUrl = QUrl::fromLocalFile(folder.filePath(imageInfo.completeBaseName() + u".json"_s));

    Q_EMIT needleCreationPrepared(QUrl::fromLocalFile(folder.absolutePath()), jsonUrl);
}

void NeedleBrowser::createNeedle(const QUrl &jsonUrl, const QUrl &imageUrl)
{
    QString jsonPath = jsonUrl.toLocalFile();
    const QString imagePath = imageUrl.toLocalFile();

    if (jsonPath.isEmpty() || imagePath.isEmpty()) {
        Q_EMIT errorOccurred(i18nc("@info needle creation error", "Choose a local file for the needle and its image."));
        return;
    }

    if (QFileInfo(jsonPath).suffix().isEmpty()) {
        jsonPath += u".json"_s;
    }

    if (QFileInfo(jsonPath).suffix() != u"json"_s || QFileInfo(jsonPath).completeBaseName().isEmpty()) {
        Q_EMIT errorOccurred(i18nc("@info needle creation error", "Choose a needle file name ending in .json."));
        return;
    }

    if (!validatePng(imagePath)) {
        return;
    }

    const QString base = needle::basePath(jsonPath);
    const QString pngPath = base + u".png"_s;
    const bool reuseImage = QFileInfo(imagePath).canonicalFilePath() == QFileInfo(pngPath).canonicalFilePath();

    QFile jsonFile(jsonPath);

    if (!jsonFile.open(QIODevice::WriteOnly | QIODevice::NewOnly)) {
        Q_EMIT errorOccurred(
            i18nc("@info %1 is the needle JSON path, %2 is the error message",
                  "Could not create %1: %2\n\nChoose a new file name in a writable folder. Existing needle files cannot be replaced when creating a needle.",
                  jsonPath,
                  jsonFile.errorString()));
        return;
    }

    if (!reuseImage) {
        QFile sourceImage(imagePath);

        if (!sourceImage.copy(pngPath)) {
            jsonFile.remove();

            Q_EMIT errorOccurred(
                i18nc("@info %1 is the destination image path, %2 is the error message",
                      "Could not copy the image to %1: %2\n\nChoose a new needle name in a writable folder, and check that the source image is readable.",
                      pngPath,
                      sourceImage.errorString()));
            return;
        }
    }

    const needle::Needle newNeedle{.area = {}, .properties = {}, .tags = {needle::baseName(base)}};
    const QByteArray json = needle::toJson(newNeedle).toUtf8();

    if (jsonFile.write(json) != json.size() || !jsonFile.flush()) {
        const QString error = jsonFile.errorString();
        jsonFile.remove();

        if (!reuseImage) {
            QFile::remove(pngPath);
        }

        Q_EMIT errorOccurred(i18nc(
            "@info %1 is the needle JSON path, %2 is the error message",
            "Could not write the needle %1: %2\n\nCheck that the folder is writable and that there is enough free disk space, then create the needle again.",
            jsonPath,
            error));
        return;
    }
    jsonFile.close();

    setDir(QUrl::fromLocalFile(QFileInfo(jsonPath).absolutePath()));
    Q_EMIT needleCreated(QUrl::fromLocalFile(jsonPath));
}

QString NeedleBrowser::readableDir() const
{
    return KShell::tildeCollapse(m_dir.toLocalFile());
}

void NeedleBrowser::rescan()
{
    m_needles.clear();
    const QString localDir = m_dir.toLocalFile();
    if (localDir.isEmpty()) {
        return;
    }
    QStringList bases;
    const QDirListing listing(localDir, QDirListing::IteratorFlag::FilesOnly);
    for (const QDirListing::DirEntry &entry : listing) {
        if (entry.suffix() != "json"_L1) {
            continue;
        }
        const QString base = needle::basePath(entry.absoluteFilePath());
        if (QFileInfo::exists(base + ".png"_L1)) {
            bases.append(base);
        }
    }
    m_needles.reserve(bases.size());
    std::ranges::sort(bases);
    for (const QString &base : std::as_const(bases)) {
        m_needles.emplace_back(QVariantMap{
            {u"name"_s, needle::baseName(base)},
            {u"jsonUrl"_s, QUrl::fromLocalFile(base + ".json"_L1)},
            {u"pngUrl"_s, QUrl::fromLocalFile(base + ".png"_L1)},
        });
    }
}
