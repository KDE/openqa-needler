// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
// SPDX-FileCopyrightText: 2026 Harald Sitter <sitter@kde.org>

#include "needle.h"

#include <algorithm>

#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>

using namespace Qt::StringLiterals;

namespace needle
{

namespace
{

QJsonObject areaToJsonObject(const Area &area)
{
    QJsonObject object;
    object.insert(u"xpos"_s, area.xpos);
    object.insert(u"ypos"_s, area.ypos);
    object.insert(u"width"_s, area.width);
    object.insert(u"height"_s, area.height);
    object.insert(u"type"_s, areaTypeName(area.type));
    if (area.matchThreshold.has_value()) {
        object.insert(u"match"_s, *area.matchThreshold);
    }
    if (area.margin.has_value()) {
        object.insert(u"margin"_s, *area.margin);
    }
    if (area.clickPoint.has_value()) {
        QJsonObject clickObject;
        clickObject.insert(u"xpos"_s, area.clickPoint->xpos);
        clickObject.insert(u"ypos"_s, area.clickPoint->ypos);
        if (area.clickPoint->id.has_value()) {
            clickObject.insert(u"id"_s, *area.clickPoint->id);
        }
        object.insert(u"click_point"_s, clickObject);
    }
    return object;
}

/*! Numeric fields are occasionally written as strings in existing needles
   (e.g. `"match": "90"`), which os-autoinst tolerates. Accept both and
   normalize to a number. */
bool numberFromValue(const QJsonValue &value, double *number, QString *error, const QString &field)
{
    if (value.isDouble()) {
        *number = value.toDouble();
        return true;
    }
    if (value.isString()) {
        bool ok = false;
        const double parsed = value.toString().trimmed().toDouble(&ok);
        if (ok) {
            *number = parsed;
            return true;
        }
    }
    if (error) {
        *error = u"field `%1` must be a number"_s.arg(field);
    }
    return false;
}

bool intFieldFromObject(const QJsonObject &object, const QString &name, qint32 *field, QString *error)
{
    const QJsonValue value = object.value(name);
    if (!value.isDouble()) {
        if (error) {
            *error = u"missing or invalid field `%1`"_s.arg(name);
        }
        return false;
    }
    *field = static_cast<qint32>(value.toDouble());
    return true;
}

std::optional<Area> areaFromObject(const QJsonObject &object, QString *error)
{
    Area area;
    if (!intFieldFromObject(object, u"xpos"_s, &area.xpos, error) //
        || !intFieldFromObject(object, u"ypos"_s, &area.ypos, error) //
        || !intFieldFromObject(object, u"width"_s, &area.width, error) //
        || !intFieldFromObject(object, u"height"_s, &area.height, error)) {
        return std::nullopt;
    }

    const QJsonValue typeValue = object.value(u"type"_s);
    if (!typeValue.isString()) {
        if (error) {
            *error = u"missing or invalid field `type`"_s;
        }
        return std::nullopt;
    }
    const auto type = areaTypeFromName(typeValue.toString());
    if (!type.has_value()) {
        if (error) {
            *error = u"unknown area type `%1`"_s.arg(typeValue.toString());
        }
        return std::nullopt;
    }
    area.type = *type;

    if (object.contains(u"match"_s)) {
        double matchThreshold = 0;
        if (!numberFromValue(object.value(u"match"_s), &matchThreshold, error, u"match"_s)) {
            return std::nullopt;
        }
        area.matchThreshold = matchThreshold;
    }
    if (object.contains(u"margin"_s)) {
        const QJsonValue marginValue = object.value(u"margin"_s);
        if (!marginValue.isDouble()) {
            if (error) {
                *error = u"field `margin` must be a number"_s;
            }
            return std::nullopt;
        }
        area.margin = static_cast<qint32>(marginValue.toDouble());
    }
    if (object.contains(u"click_point"_s)) {
        const QJsonValue clickValue = object.value(u"click_point"_s);
        if (!clickValue.isObject()) {
            if (error) {
                *error = u"field `click_point` must be an object"_s;
            }
            return std::nullopt;
        }
        const QJsonObject clickObject = clickValue.toObject();
        ClickPoint clickPoint;
        if (!numberFromValue(clickObject.value(u"xpos"_s), &clickPoint.xpos, error, u"click_point.xpos"_s) //
            || !numberFromValue(clickObject.value(u"ypos"_s), &clickPoint.ypos, error, u"click_point.ypos"_s)) {
            return std::nullopt;
        }
        const QJsonValue idValue = clickObject.value(u"id"_s);
        if (!idValue.isUndefined() && !idValue.isNull()) {
            if (!idValue.isString()) {
                if (error) {
                    *error = u"field `click_point.id` must be a string"_s;
                }
                return std::nullopt;
            }
            clickPoint.id = idValue.toString();
        }
        area.clickPoint = clickPoint;
    }
    return area;
}

bool stringListFromValue(const QJsonValue &value, const QString &name, QStringList *list, QString *error)
{
    if (value.isUndefined() || value.isNull()) {
        return true;
    }
    if (!value.isArray()) {
        if (error) {
            *error = u"field `%1` must be an array"_s.arg(name);
        }
        return false;
    }
    for (const QJsonValue &element : value.toArray()) {
        if (!element.isString()) {
            if (error) {
                *error = u"field `%1` must only contain strings"_s.arg(name);
            }
            return false;
        }
        list->append(element.toString());
    }
    return true;
}

std::optional<Needle> needleFromObject(const QJsonObject &object, QString *error)
{
    Needle needle;
    const QJsonValue areaValue = object.value(u"area"_s);
    if (!areaValue.isUndefined() && !areaValue.isNull()) {
        if (!areaValue.isArray()) {
            if (error) {
                *error = u"field `area` must be an array"_s;
            }
            return std::nullopt;
        }
        for (const QJsonValue &element : areaValue.toArray()) {
            if (!element.isObject()) {
                if (error) {
                    *error = u"field `area` must only contain objects"_s;
                }
                return std::nullopt;
            }
            const auto area = areaFromObject(element.toObject(), error);
            if (!area.has_value()) {
                return std::nullopt;
            }
            needle.area.append(*area);
        }
    }
    if (!stringListFromValue(object.value(u"properties"_s), u"properties"_s, &needle.properties, error) //
        || !stringListFromValue(object.value(u"tags"_s), u"tags"_s, &needle.tags, error)) {
        return std::nullopt;
    }
    return needle;
}

}

bool Needle::hasMasterTag(QStringView baseName) const
{
    return std::ranges::any_of(tags, [&](const QString &tag) {
        return tag == baseName;
    });
}

std::optional<Needle> parse(const QString &json, QString *error)
{
    QJsonParseError parseError{};
    const QJsonDocument document = QJsonDocument::fromJson(json.toUtf8(), &parseError);
    if (parseError.error != QJsonParseError::NoError || !document.isObject()) {
        if (error) {
            *error = parseError.error != QJsonParseError::NoError ? QString::fromUtf8(parseError.errorString().toUtf8()) : u"not a JSON object"_s;
        }
        return std::nullopt;
    }
    return needleFromObject(document.object(), error);
}

QString toJson(const Needle &needle)
{
    QJsonArray areaArray;
    for (const Area &area : needle.area) {
        areaArray.append(areaToJsonObject(area));
    }
    QJsonObject object;
    object.insert(u"area"_s, areaArray);
    object.insert(u"properties"_s, QJsonArray::fromStringList(needle.properties));
    object.insert(u"tags"_s, QJsonArray::fromStringList(needle.tags));
    return QString::fromUtf8(QJsonDocument(object).toJson(QJsonDocument::Indented)) + u'\n';
}

QString areasToJson(const QList<Area> &areas)
{
    QJsonArray array;
    for (const Area &area : areas) {
        array.append(areaToJsonObject(area));
    }
    return QString::fromUtf8(QJsonDocument(array).toJson(QJsonDocument::Compact));
}

std::optional<QList<Area>> parseAreas(const QString &json, QString *error)
{
    QJsonParseError parseError{};
    const QJsonDocument document = QJsonDocument::fromJson(json.toUtf8(), &parseError);
    if (parseError.error != QJsonParseError::NoError || !document.isArray()) {
        if (error) {
            *error = parseError.error != QJsonParseError::NoError ? QString::fromUtf8(parseError.errorString().toUtf8()) : u"not a JSON array"_s;
        }
        return std::nullopt;
    }
    QList<Area> areas;
    for (const QJsonValue &element : document.array()) {
        if (!element.isObject()) {
            if (error) {
                *error = u"area entries must be objects"_s;
            }
            return std::nullopt;
        }
        const auto area = areaFromObject(element.toObject(), error);
        if (!area.has_value()) {
            return std::nullopt;
        }
        areas.append(*area);
    }
    return areas;
}

std::optional<Needle> loadFromBase(const QString &base, QString *error)
{
    const QString jsonPath = base + u".json"_s;
    QFile file(jsonPath);
    if (!file.open(QIODevice::ReadOnly)) {
        if (error) {
            *error = u"failed to read %1: %2"_s.arg(jsonPath, file.errorString());
        }
        return std::nullopt;
    }
    QString parseError;
    const auto needle = parse(QString::fromUtf8(file.readAll()), &parseError);
    if (!needle.has_value()) {
        if (error) {
            *error = u"failed to parse %1: %2"_s.arg(jsonPath, parseError);
        }
        return std::nullopt;
    }
    return needle;
}

bool saveToBase(const QString &base, const Needle &needle, QString *error)
{
    const QString jsonPath = base + u".json"_s;
    QFile file(jsonPath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        if (error) {
            *error = u"failed to write %1: %2"_s.arg(jsonPath, file.errorString());
        }
        return false;
    }
    const QByteArray contents = toJson(needle).toUtf8();
    if (file.write(contents) != contents.size()) {
        if (error) {
            *error = u"failed to write %1: %2"_s.arg(jsonPath, file.errorString());
        }
        return false;
    }
    return true;
}

QString basePath(QStringView path)
{
    const qsizetype dot = path.lastIndexOf(u'.');
    const qsizetype slash = path.lastIndexOf(u'/');
    if (dot >= 0 && (slash < 0 || dot > slash)) {
        return path.first(dot).toString();
    }
    return path.toString();
}

QString baseName(QStringView path)
{
    const QString base = basePath(path);
    const qsizetype slash = base.lastIndexOf(u'/');
    return slash >= 0 ? base.mid(slash + 1) : base;
}

QString areaTypeName(AreaType type)
{
    switch (type) {
    case AreaType::Match:
        return u"match"_s;
    case AreaType::Ocr:
        return u"ocr"_s;
    case AreaType::Exclude:
        return u"exclude"_s;
    }
    return {};
}

std::optional<AreaType> areaTypeFromName(QStringView name)
{
    if (name == u"match"_s) {
        return AreaType::Match;
    }
    if (name == u"ocr"_s) {
        return AreaType::Ocr;
    }
    if (name == u"exclude"_s) {
        return AreaType::Exclude;
    }
    return std::nullopt;
}

}
