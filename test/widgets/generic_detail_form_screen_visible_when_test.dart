// test/widgets/generic_detail_form_screen_visible_when_test.dart
//
// Testes da função pura avaliarVisibleWhen, usada para decidir se um campo
// de formulário dinâmico deve ser exibido conforme o atributo visibleWhen
// (formato "<fieldName>==<valor>") recebido do backend.

import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/generic_detail_form_screen.dart';

void main() {
  group('avaliarVisibleWhen', () {
    test('expressao nula retorna true (sempre visível)', () {
      expect(avaliarVisibleWhen(null, {}), isTrue);
    });

    test('expressao vazia retorna true (sempre visível)', () {
      expect(avaliarVisibleWhen('', {}), isTrue);
    });

    test('isServico==false com isServico=false retorna true', () {
      expect(
        avaliarVisibleWhen('isServico==false', {'isServico': false}),
        isTrue,
      );
    });

    test('isServico==false com isServico=true retorna false', () {
      expect(
        avaliarVisibleWhen('isServico==false', {'isServico': true}),
        isFalse,
      );
    });

    test('isServico==true com isServico=true retorna true', () {
      expect(
        avaliarVisibleWhen('isServico==true', {'isServico': true}),
        isTrue,
      );
    });

    test('isServico==true com isServico=false retorna false', () {
      expect(
        avaliarVisibleWhen('isServico==true', {'isServico': false}),
        isFalse,
      );
    });

    test('isServico==false com isServico ausente retorna true (default false)', () {
      expect(avaliarVisibleWhen('isServico==false', {}), isTrue);
    });

    test('isServico==true com isServico ausente retorna false (default false)', () {
      expect(avaliarVisibleWhen('isServico==true', {}), isFalse);
    });

    test('tipo_estabelecimento==FILIAL com tipo_estabelecimento=FILIAL retorna true', () {
      expect(
        avaliarVisibleWhen('tipo_estabelecimento==FILIAL', {'tipo_estabelecimento': 'FILIAL'}),
        isTrue,
      );
    });

    test('tipo_estabelecimento==FILIAL com tipo_estabelecimento=MATRIZ retorna false', () {
      expect(
        avaliarVisibleWhen('tipo_estabelecimento==FILIAL', {'tipo_estabelecimento': 'MATRIZ'}),
        isFalse,
      );
    });

    test('tipo_estabelecimento==FILIAL resolve alias tipoEstabelecimento em camelCase', () {
      expect(
        avaliarVisibleWhen('tipo_estabelecimento==FILIAL', {'tipoEstabelecimento': 'FILIAL'}),
        isTrue,
      );
    });

    test('tipoEstabelecimento==FILIAL resolve alias tipo_estabelecimento em snake_case', () {
      expect(
        avaliarVisibleWhen('tipoEstabelecimento==FILIAL', {'tipo_estabelecimento': 'FILIAL'}),
        isTrue,
      );
    });

    test('comparacao de string eh case-insensitive (FILIAL == filial)', () {
      expect(
        avaliarVisibleWhen('tipo_estabelecimento==FILIAL', {'tipo_estabelecimento': 'filial'}),
        isTrue,
      );
    });
  });
}
