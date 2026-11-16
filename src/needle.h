// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
// SPDX-FileCopyrightText: 2026 Harald Sitter <sitter@kde.org>

#pragma once

#include <QList>
#include <QString>
#include <QStringList>
#include <QStringView>

#include <optional>

/*!
 * \file needle.h
 * Data model of an openQA needle.
 *
 * A needle is a full screenshot in PNG format plus a JSON file with the same
 * base name describing which areas of the screenshot are relevant, which tags
 * select the needle, and optional properties.
 *
 * The format is documented at <https://open.qa/docs/#needles>.
 */

namespace needle
{

/*! The kind of an area. */
enum class AreaType {
    Match, /*!< Pixel matching area ("match"). */
    Ocr, /*!< Optical character recognition area ("ocr"). */
    Exclude, /*!< Area excluded from matching ("exclude"). */
};

/*! A click point inside an area, in coordinates relative to the area. */
struct ClickPoint {
    double xpos = 0;
    double ypos = 0;
    std::optional<QString> id;

    bool operator==(const ClickPoint &) const = default;
};

/*! A rectangular area of the needle screenshot. */
struct Area {
    qint32 xpos = 0;
    qint32 ypos = 0;
    qint32 width = 0;
    qint32 height = 0;
    AreaType type = AreaType::Match;
    /*! Similarity percentage (0-100) required for a match. Absent means the
       consumer default applies, so it is only written when explicitly set. */
    std::optional<double> matchThreshold;
    /*! Search margin around the area. Absent means the consumer default. */
    std::optional<qint32> margin;
    /*! Optional click point relative to the area's top-left corner. */
    std::optional<ClickPoint> clickPoint;

    bool operator==(const Area &) const = default;
};

/*! A needle: the areas to match, the selecting tags, and optional properties. */
struct Needle {
    QList<Area> area;
    QStringList properties;
    QStringList tags;

    /*! All needles must be tagged with their base name (the file name without
       extension). This is the "master tag". */
    bool hasMasterTag(QStringView baseName) const;

    bool operator==(const Needle &) const = default;
};

/*! Parse a needle from its JSON representation. On failure returns
   std::nullopt and sets \a error. */
std::optional<Needle> parse(const QString &json, QString *error = nullptr);

/*! Serialize the needle to JSON in QJsonDocument's indented format, with a
   trailing newline. */
QString toJson(const Needle &needle);

/*! Serialize areas to a compact JSON array string, as consumed by the QML
   area model. */
QString areasToJson(const QList<Area> &areas);

/*! Parse a JSON array of area objects (as produced by the QML area model).
   On failure returns std::nullopt and sets \a error. */
std::optional<QList<Area>> parseAreas(const QString &json, QString *error = nullptr);

/*! Load and parse the needle with the given base path (without extension).
   On failure returns std::nullopt and sets \a error. */
std::optional<Needle> loadFromBase(const QString &base, QString *error = nullptr);

/*! Write the needle to `<base>.json`. On failure returns false and sets
   \a error. */
bool saveToBase(const QString &base, const Needle &needle, QString *error = nullptr);

/*! Strip the extension from a path, yielding the base shared by the `.json`
   and `.png` files of a needle. */
QString basePath(QStringView path);

/*! The file name without extension and without directory. This is the master
   tag a needle must carry. */
QString baseName(QStringView path);

/*! The JSON name of an area type ("match", "ocr", "exclude"). */
QString areaTypeName(AreaType type);

/*! Parse an area type name. Returns std::nullopt when the name is unknown. */
std::optional<AreaType> areaTypeFromName(QStringView name);

} // namespace needle
