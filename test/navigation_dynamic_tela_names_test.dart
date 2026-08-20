import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nomes canonicos das telas dinamicas', () {
    const canonicalNames = [
      'projeto_etapa',
      'projeto_recurso',
      'projeto_apontamento',
      'projeto_medicao',
      'cargo_recurso',
      'precificacao',
      'custo_direto',
      'mao_de_obra',
      'precificacao_servico',
      'condicao_pagamento',
      'proposta_comercial',
    ];

    const forbiddenNames = [
      'projeto_etapa_screen',
      'projeto_recurso_screen',
      'projeto_apontamento_screen',
      'projeto_medicao_screen',
      'cargo_recurso_screen',
      'precificacao_screen',
      'precificacao_custo_direto_screen',
      'precificacao_mao_de_obra',
      'precificacao_servico_screen',
      'precificacao_condicao_pagamento_screen',
      'proposta_comercial_screen',
    ];

    for (final path in [
      'lib/web/screens/bottom_navbar_screen.dart',
      'lib/windows/screens/bottom_navbar_screen.dart',
      'lib/mobile/screens/bottom_navbar_screen.dart',
    ]) {
      test('$path usa ids esperados pelo backend', () {
        final source = File(path).readAsStringSync();

        for (final name in canonicalNames) {
          expect(source, contains("telaNome: '$name'"));
        }

        for (final name in forbiddenNames) {
          expect(source, isNot(contains("telaNome: '$name'")));
        }
      });
    }
  });
}
