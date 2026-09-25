import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pipeline Android preserva contrato de build e credenciais', () {
    final fastfile = File('fastlane/Fastfile').readAsStringSync();
    final workflow = File(
      '.github/workflows/android-internal-release.yml',
    ).readAsStringSync();

    expect(fastfile, contains('File.expand_path("..", __dir__)'));
    expect(fastfile, contains('File.read(app_path("pubspec.yaml"))'));
    expect(fastfile, contains('ENV.delete("FLUTTER_BUILD_NAME")'));
    expect(fastfile, contains('ENV.delete("FLUTTER_BUILD_NUMBER")'));
    expect(fastfile, contains('Dir.chdir(app_root)'));
    expect(fastfile, contains('--dart-define=BACKEND_CONTEXT_PATH='));

    expect(workflow, contains('GOOGLE_PLAY_JSON_KEY_BASE64'));
    expect(workflow, contains('test -s fastlane/google-play-key.json'));
    expect(workflow, contains('test -s android/app/release-upload.jks'));
    expect(workflow, contains('APP_BUILD_NAME='));
    expect(workflow, contains('APP_BUILD_NUMBER='));
    expect(workflow, isNot(contains('echo "FLUTTER_BUILD_NAME=')));
    expect(workflow, isNot(contains('echo "FLUTTER_BUILD_NUMBER=')));
  });
}
