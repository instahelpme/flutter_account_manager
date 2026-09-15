#!/bin/sh

dart run pigeon --input pigeons/account_manager.dart
dart run build_runner build
dart format lib/ test/
dart run import_sorter:main --no-comments
flutter analyze