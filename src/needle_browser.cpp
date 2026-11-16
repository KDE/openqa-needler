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
#include <QStandardPaths>
#include <QVariantMap>

#include <KConfigGroup>
#include <KSharedConfig>

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
