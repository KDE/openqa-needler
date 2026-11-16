// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
// SPDX-FileCopyrightText: 2026 Harald Sitter <sitter@kde.org>

#include <QApplication>
#include <QQmlApplicationEngine>

#include <KLocalizedQmlContext>
#include <KirigamiAppDefaults>

using namespace Qt::StringLiterals;

int main(int argc, char **argv)
{
    QApplication app(argc, argv);

    KirigamiAppDefaults::apply(&app);

    QQmlApplicationEngine engine;
    std::ignore = KLocalization::setupLocalizedContext(&engine);
    engine.loadFromModule(u"org.kde.needler", u"Main");

    return app.exec();
}
