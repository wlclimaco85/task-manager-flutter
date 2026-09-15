import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calendario financeiro nao indexa empresa quando payload traz texto', () {
    final source =
        File('lib/windows/screens/documento_screen.dart').readAsStringSync();

    expect(source, contains('_empresaIdValue'));
    expect(source, isNot(contains("item['empresa']?['id']")));
  });
}
