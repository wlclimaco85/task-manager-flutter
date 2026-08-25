// test/web/screens/details/parceiro_detail_screen_test.dart
//
// Testes de widget para o gate de carregamento de Modulo Servicos em
// WebParceiroDetailScreen (bug de producao: campo "Modulo Servicos" vazio
// ao reabrir o registro, porque o form so le o item UMA vez e o fetch
// assincrono de /api/parceiro-modulo chegava tarde demais).
//
// Nao ha backend disponivel no ambiente de teste: chamadas HTTP feitas em
// initState (NetworkCaller().getRequest) falham rapidamente e sao
// capturadas pelo try/catch ja existente em _preCarregarModulos, entao o
// caminho de "falha de rede" e o unico exercitavel de ponta a ponta aqui
// (mesmo padrao ja usado em test/windows/screens/details/nfse_detail_screen_test.dart).
// O caminho de "sucesso" (modulos carregam e aparecem selecionados) nao tem
// como ser coberto por widget test sem um seam de injecao de HTTP client em
// NetworkCaller (hoje ele chama http.get() direto, sem DI) -- documentado
// no relatorio da tarefa, nao fabricamos mock.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/web/screens/details/parceiro_detail_screen.dart';

bool _alwaysAllow(String permission) => true;

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  Widget buildScreen(Map<String, dynamic> item) {
    return MaterialApp(
      home: WebParceiroDetailScreen(item: item, hasPermission: _alwaysAllow),
    );
  }

  group('WebParceiroDetailScreen — gate de Modulo Servicos', () {
    testWidgets(
        'id null (parceiro novo): nao dispara fetch, libera o gate imediatamente e nao mostra erro',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildScreen({}));
      await _settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets(
        'id presente + falha de rede: tela nao trava e mostra aviso de erro (sem excecao nao tratada)',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildScreen({'id': 42, 'nome': 'Parceiro X'}));
      await _settle(tester);

      expect(tester.takeException(), isNull);
      expect(
        find.textContaining('Modulo Servicos'),
        findsWidgets,
        reason:
            'aviso de falha ao carregar Modulo Servicos deve aparecer (SnackBar)',
      );
    });
  });
}
