// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
// SPDX-FileCopyrightText: 2026 Harald Sitter <sitter@kde.org>

#include <QApplication>
#include <QQmlApplicationEngine>
#include <QUrl>
#include <QtQml>

#include <KAboutData>
#include <KLocalizedContext>
#include <KLocalizedQmlContext>
#include <KLocalizedString>
#include <KirigamiAppDefaults>

using namespace Qt::StringLiterals;

int main(int argc, char **argv)
{
    QApplication app(argc, argv);

    KLocalizedString::setApplicationDomain("openqa-needler");

    KirigamiAppDefaults::apply(&app);

    KAboutData aboutData(QStringLiteral("openqa-needler"),
                         i18nc("@title", "openQA Needler"),
                         QStringLiteral("1.0"),
                         i18nc("@info application description", "Edit openQA needles"),
                         KAboutLicense::GPL,
                         i18nc("@info:credit copyright notice", "(c) 2026"));

    aboutData.setDesktopFileName(QStringLiteral("org.kde.openqa.needler"));
    KAboutData::setApplicationData(aboutData);

    qmlRegisterSingletonType("org.kde.openqa.needler.about", 1, 0, "About", [](QQmlEngine *engine, QJSEngine *) -> QJSValue {
        return engine->toScriptValue(KAboutData::applicationData());
    });

    QQmlApplicationEngine engine;
    std::ignore = KLocalization::setupLocalizedContext(&engine);
    engine.loadFromModule(u"org.kde.openqa.needler", u"Main");

    return app.exec();
}
