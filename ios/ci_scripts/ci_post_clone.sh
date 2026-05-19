#!/bin/sh

# Falha se qualquer subcomando falhar
set -e

# Muda para a raiz do repositório clonado
cd $CI_PRIMARY_REPOSITORY_PATH

# Instala Flutter via git
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

# Baixa artefatos iOS
flutter precache --ios

# Instala dependências Dart/Flutter
flutter pub get

# Instala CocoaPods via Homebrew
HOMEBREW_NO_AUTO_UPDATE=1
brew install cocoapods

# Instala pods do iOS
cd ios && pod install

exit 0
