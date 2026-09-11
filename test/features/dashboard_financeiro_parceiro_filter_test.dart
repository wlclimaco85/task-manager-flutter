import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dashboard financeiro web preserva parceiro logado e bloqueia empresa e parceiro no filtro', () {
    final source = File('lib/web/screens/dashboard_financeiro_screen.dart').readAsStringSync();

    expect(source, contains('parceiroId: _parceiroId'));
    expect(source, contains('_parceiroId = pegarParceiroLogada()'));
    expect(source, contains("hint: 'Empresa'"));
    expect(source, contains("hint: 'Parceiro'"));
    expect(source, contains('enabled: false'));
  });

  test('dashboard financeiro mobile preserva parceiro logado e bloqueia empresa e parceiro no filtro', () {
    final source = File('lib/mobile/screens/dashboard_financeiro_screen.dart').readAsStringSync();

    expect(source, contains('parceiroId: _parceiroId'));
    expect(source, contains('_parceiroId = pegarParceiroLogada()'));
    expect(source, contains("hint: 'Empresa'"));
    expect(source, contains("hint: 'Parceiro'"));
    expect(source, contains('enabled: false'));
  });

  test('dashboard comercial mercadorias inclui parceiro e mantem empresa e parceiro bloqueados', () {
    final source = File('lib/widgets/comercial/dashboard_comercial_mercadorias_screen.dart').readAsStringSync();

    expect(source, contains('parceiroId: _parceiroId'));
    expect(source, contains('_parceiroId = pegarParceiroLogada()'));
    expect(source, contains("_inputDecoration('Empresa')"));
    expect(source, contains("_inputDecoration('Parceiro')"));
    expect(source, contains('onChanged: null'));
  });
}
