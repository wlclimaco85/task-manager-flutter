import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/finance/gerar_contas_pagar_dialog.dart';

Future<List<Map<String, dynamic>>> _categoriasFake() async => [
      {'value': '5', 'label': 'Fornecedores'},
      {'value': '8', 'label': 'Impostos'},
    ];

Future<List<Map<String, dynamic>>> _contasFake() async => [
      {'value': 7, 'label': 'Banco X - 1234'},
    ];

Future<List<Map<String, dynamic>>> _listaVaziaFake() async => [];

Future<List<Map<String, dynamic>>> _falhaFake() async =>
    throw Exception('sem conexão');

void main() {
  group('GerarContasPagarResultado', () {
    test('guarda categoriaFinanceiraId e contaBancariaId informados', () {
      const resultado = GerarContasPagarResultado(
        categoriaFinanceiraId: 5,
        contaBancariaId: 7,
      );

      expect(resultado.categoriaFinanceiraId, 5);
      expect(resultado.contaBancariaId, 7);
    });

    test('permite ambos os campos nulos (fluxo compativel com o antigo)', () {
      const resultado = GerarContasPagarResultado();

      expect(resultado.categoriaFinanceiraId, isNull);
      expect(resultado.contaBancariaId, isNull);
    });
  });

  group('GerarContasPagarDialog', () {
    testWidgets('mostra indicador de carregamento antes das listas resolverem',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GerarContasPagarDialog.testavel(
            nfeId: 42,
            quantidadeDuplicatas: 3,
            loadCategorias: _categoriasFake,
            loadContas: _contasFake,
          ),
        ),
      ));

      // Antes do primeiro pump assentar os Futures, o dialogo esta no
      // estado de carregamento.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final botaoGerar = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Gerar'));
      expect(botaoGerar.onPressed, isNull);
    });

    testWidgets('apos carregar com sucesso, exibe os dropdowns e habilita o botao Gerar',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GerarContasPagarDialog.testavel(
            nfeId: 42,
            quantidadeDuplicatas: 3,
            loadCategorias: _categoriasFake,
            loadContas: _contasFake,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Categoria Financeira (opcional)'), findsOneWidget);
      expect(find.text('Conta Bancária (opcional)'), findsOneWidget);
      final botaoGerar = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Gerar'));
      expect(botaoGerar.onPressed, isNotNull);
    });

    testWidgets('selecionar categoria e conta e confirmar retorna o resultado preenchido',
        (tester) async {
      GerarContasPagarResultado? resultado;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                resultado = await showDialog<GerarContasPagarResultado>(
                  context: ctx,
                  builder: (_) => GerarContasPagarDialog.testavel(
                    nfeId: 42,
                    quantidadeDuplicatas: 3,
                    loadCategorias: _categoriasFake,
                    loadContas: _contasFake,
                  ),
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Categoria Financeira (opcional)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Impostos').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Conta Bancária (opcional)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Banco X - 1234').last);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Gerar'));
      await tester.pumpAndSettle();

      expect(resultado, isNotNull);
      expect(resultado!.categoriaFinanceiraId, 8);
      expect(resultado!.contaBancariaId, 7);
    });

    testWidgets('confirmar sem selecionar categoria/conta retorna resultado com campos nulos',
        (tester) async {
      GerarContasPagarResultado? resultado;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                resultado = await showDialog<GerarContasPagarResultado>(
                  context: ctx,
                  builder: (_) => GerarContasPagarDialog.testavel(
                    nfeId: 42,
                    quantidadeDuplicatas: 3,
                    loadCategorias: _listaVaziaFake,
                    loadContas: _listaVaziaFake,
                  ),
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Gerar'));
      await tester.pumpAndSettle();

      expect(resultado, isNotNull);
      expect(resultado!.categoriaFinanceiraId, isNull);
      expect(resultado!.contaBancariaId, isNull);
    });

    testWidgets('quando o carregamento falha, mostra aviso mas mantem o botao Gerar habilitado',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GerarContasPagarDialog.testavel(
            nfeId: 42,
            quantidadeDuplicatas: 3,
            loadCategorias: _falhaFake,
            loadContas: _contasFake,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
          find.textContaining('Não foi possível carregar'), findsOneWidget);
      final botaoGerar = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Gerar'));
      expect(botaoGerar.onPressed, isNotNull);
    });

    testWidgets('cancelar fecha o dialogo sem retornar resultado', (tester) async {
      GerarContasPagarResultado? resultado = const GerarContasPagarResultado(
          categoriaFinanceiraId: 1); // valor sentinela p/ garantir que foi sobrescrito p/ null
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                resultado = await showDialog<GerarContasPagarResultado>(
                  context: ctx,
                  builder: (_) => GerarContasPagarDialog.testavel(
                    nfeId: 42,
                    quantidadeDuplicatas: 3,
                    loadCategorias: _categoriasFake,
                    loadContas: _contasFake,
                  ),
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(resultado, isNull);
    });
  });
}
