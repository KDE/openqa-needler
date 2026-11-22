# SPDX-License-Identifier: BSD-2-Clause
# SPDX-FileCopyrightText: 2026 Harald Sitter <sitter@kde.org>

cmake_minimum_required(VERSION 4.4.3)
project(openqa-needler VERSION 2.0.0)

find_package(ECM 6.32.0 REQUIRED)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(KDEClangFormat)
include(KDEGitCommitHooks)
include(ECMInstallIcons)
include(ECMSetupVersion)
include(ECMDeprecationSettings)
include(FeatureSummary)
include(ECMQmlModule)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick QuickControls2 Widgets Qml QmlIntegration)
find_package(KF6 REQUIRED COMPONENTS Kirigami I18n KirigamiAddons Config CoreAddons)

add_executable(openqa-needler
    src/main.cpp
    src/needle.h
    src/needle.cpp
    src/needle_browser.h
    src/needle_browser.cpp
    src/needle_document.h
    src/needle_document.cpp
)

qt_add_qml_module(openqa-needler
    URI org.kde.needler
    RESOURCE_PREFIX /qt/qml
    QML_FILES
        qml/Main.qml
        qml/BrowserPage.qml
        qml/EditorPage.qml
        qml/EditorSidebar.qml
        qml/ImageView.qml
        qml/EditorDialogs.qml
        qml/AreaItem.qml
)

target_include_directories(openqa-needler PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)
target_compile_definitions(openqa-needler PRIVATE NEEDLER_VERSION="${PROJECT_VERSION}")

target_link_libraries(openqa-needler PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::QmlIntegration
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Widgets
    KF6::I18n
    KF6::I18nQml
    KF6::Kirigami
    KF6::ConfigCore
    KF6::CoreAddons
    KirigamiApp
)

install(TARGETS openqa-needler ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
install(FILES org.kde.needler.desktop DESTINATION ${KDE_INSTALL_APPDIR})

ki18n_install(po)

kde_configure_git_pre_commit_hook(CHECKS CLANG_FORMAT)

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)
