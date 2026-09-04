import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/importacao_sintegra_card.dart';

void main() {
  testWidgets('exige empresa antes de importar SINTEGRA', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ImportacaoSintegraCard(
            baseUrl: 'http://localhost',
            carregarEmpresas: () async => [
              {'id': '1', 'nome': 'Empresa Smoke Test'},
            ],
            arquivoInicial: PlatformFile(
              name: 'sintegra.txt',
              size: 3,
              bytes: Uint8List.fromList([49, 48, 32]),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('importacao-sintegra-importar')));
    await tester.pump();

    expect(find.text('Selecione a empresa antes de importar.'), findsOneWidget);
  });

  testWidgets('exibe resumo retornado pela importacao SINTEGRA', (
    tester,
  ) async {
    String? empresaEnviada;
    String? arquivoEnviado;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ImportacaoSintegraCard(
            baseUrl: 'http://localhost',
            empresaIdInicial: '1',
            carregarEmpresas: () async => [
              {'id': '1', 'nome': 'Empresa Smoke Test'},
            ],
            arquivoInicial: PlatformFile(
              name: 'sintegra.txt',
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
                'ignorados': ['Registro 60: 1 linha sem destino seguro.'],
              };
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('importacao-sintegra-importar')));
    await tester.pumpAndSettle();

    expect(empresaEnviada, '1');
    expect(arquivoEnviado, 'sintegra.txt');
    expect(find.byKey(const Key('importacao-sintegra-resumo')), findsOneWidget);
    expect(find.text('Entradas: 1'), findsOneWidget);
    expect(find.text('Itens: 2'), findsOneWidget);
    expect(find.text('Financeiro pendente: 1'), findsOneWidget);
    expect(
      find.text('Registro 60: 1 linha sem destino seguro.'),
      findsOneWidget,
    );
  });

  // Pedido explicito do usuario: erro inesperado na importacao mostra o
  // stack trace completo, com botao pra copiar.
  testWidgets('exibe trace completo e botao de copiar quando erro traz trace', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ImportacaoSintegraCard(
            baseUrl: 'http://localhost',
            empresaIdInicial: '1',
            carregarEmpresas: () async => [
              {'id': '1', 'nome': 'Empresa Smoke Test'},
            ],
            arquivoInicial: PlatformFile(
              name: 'sintegra.txt',
              size: 3,
              bytes: Uint8List.fromList([49, 48, 32]),
            ),
            importar: (empresaId, arquivo) async {
              throw ErroImportacaoComTrace(
                'falha simulada de parsing',
                'java.lang.RuntimeException: falha simulada de parsing\n\tat Foo.bar(Foo.java:1)',
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('importacao-sintegra-importar')));
    await tester.pumpAndSettle();

    expect(find.text('falha simulada de parsing'), findsOneWidget);
    expect(find.byKey(const Key('importacao-sintegra-trace')), findsOneWidget);
    expect(find.textContaining('RuntimeException'), findsOneWidget);
    expect(find.byKey(const Key('importacao-sintegra-copiar-erro')), findsOneWidget);
  });
}
