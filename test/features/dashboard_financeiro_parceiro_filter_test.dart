import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dashboard financeiro web preserva parceiro logado e bloqueia empresa', () {
    final source = File('lib/web/screens/dashboard_financeiro_screen.dart').readAsStringSync();

    expect(source, contains('parceiroId: _parceiroId'));
    expect(source, contains('_parceiroId = pegarParceiroLogada();'));
    expect(source, contains('enabled: _parceiroId == null'));
  });

  test('dashboard financeiro mobile preserva parceiro logado e bloqueia empresa', () {
    final source = File('lib/mobile/screens/dashboard_financeiro_screen.dart').readAsStringSync();

    expect(source, contains('parceiroId: _parceiroId'));
    expect(source, contains('_parceiroId = pegarParceiroLogada();'));
    expect(source, contains('enabled: _parceiroId == null'));
  });
}
