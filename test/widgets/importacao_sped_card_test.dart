import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/importacao_sped_card.dart';

// Card cUlANCTt - mesmo padrao de teste do importacao_sintegra_card_test.dart.
void main() {
  testWidgets('exige empresa antes de importar SPED', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ImportacaoSpedCard(
            baseUrl: 'http://localhost',
            carregarEmpresas: () async => [
              {'id': '1', 'nome': 'Empresa Smoke Test'},
            ],
            arquivoInicial: PlatformFile(
              name: 'sped.txt',
              size: 3,
              bytes: Uint8List.fromList([49, 48, 32]),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('importacao-sped-importar')));
    await tester.pump();

    expect(find.text('Selecione a empresa antes de importar.'), findsOneWidget);
  });

  testWidgets('exibe resumo retornado pela importacao SPED', (
    tester,
  ) async {
    String? empresaEnviada;
    String? arquivoEnviado;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ImportacaoSpedCard(
            baseUrl: 'http://localhost',
            empresaIdInicial: '1',
            carregarEmpresas: () async => [
              {'id': '1', 'nome': 'Empresa Smoke Test'},
            ],
            arquivoInicial: PlatformFile(
              name: 'sped.txt',
              size: 3,
              bytes: Uint8List.fromList([49, 48, 32]),
            ),
            importar: (empresaId, arquivo) async {
              empresaEnviada = empresaId;
              arquivoEnviado = arquivo.name;
              return {
                'notasEntrada': 1,
                'notasSaida': 0,
                'itens': 2,
                'produtosCriados': 1,
                'produtosAtualizados': 0,
                'parceirosCriados': 1,
                'parceirosAtualizados': 0,
                'tributacoes': 1,
                'financeirosPendentes': 1,
                'avisos': [
                  'Financeiro ficou pendente por falta de vencimento.',
                ],
                'ignorados': ['Registro 9900: 1 linha sem destino seguro.'],
              };
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('importacao-sped-importar')));
    await tester.pumpAndSettle();

    expect(empresaEnviada, '1');
    expect(arquivoEnviado, 'sped.txt');
    expect(find.byKey(const Key('importacao-sped-resumo')), findsOneWidget);
    expect(find.text('Entradas: 1'), findsOneWidget);
    expect(find.text('Itens: 2'), findsOneWidget);
    expect(find.text('Financeiro pendente: 1'), findsOneWidget);
    expect(
      find.text('Registro 9900: 1 linha sem destino seguro.'),
      findsOneWidget,
    );
  });
}
