#!/bin/sh
# SPDX-License-Identifier: BSD-2-Clause
# SPDX-FileCopyrightText: 2026 Harald Sitter <sitter@kde.org>

$XGETTEXT src/*.cpp src/*.h qml/*.qml -o "$podir/openqa-needler.pot"
