import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/nfe_importacoes_grid.dart';

/// Pedido explicito do usuario: a tela de Importar XML precisa de uma grid
/// padrao mostrando o que ja foi importado, com status, e delete so
/// permitido enquanto a NF-e Entrada ainda nao tiver sido confirmada (senao
/// e preciso excluir a Entrada antes).
///
/// listarOverride injeta os dados sem bater em rede real (ver
/// NfeImportacoesGrid.listarOverride, existe so para teste).
void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  final itemRascunho = <String, dynamic>{
    'id': 10,
    'numero': '8130',
    'serie': '1',
    'chave': '35260812345678000199550010000081301000081301',
    'valorTotal': '300.00',
    'status': 'RASCUNHO_IMPORTACAO',
  };
  final itemConfirmado = <String, dynamic>{
    'id': 11,
    'numero': '8131',
    'serie': '1',
    'chave': '35260812345678000199550010000081311000081311',
    'valorTotal': '150.00',
    'status': 'AUTORIZADA',
  };

  testWidgets('item RASCUNHO_IMPORTACAO mostra badge Rascunho e botão '
      'Confirmar Entrada; item AUTORIZADA mostra badge Entrada Criada e '
      'NÃO mostra o botão de confirmar', (tester) async {
    await tester.pumpWidget(wrap(NfeImportacoesGrid(
      listarOverride: () async => [itemRascunho, itemConfirmado],
    )));
    await tester.pumpAndSettle();

    expect(find.text('Rascunho'), findsOneWidget);
    expect(find.text('Entrada Criada'), findsOneWidget);
    // Só o item rascunho oferece "Confirmar Entrada".
    expect(find.text('Confirmar Entrada'), findsOneWidget);
    // Os dois itens aparecem na tabela (chave truncada como texto).
    expect(find.textContaining('8130/1'), findsOneWidget);
    expect(find.textContaining('8131/1'), findsOneWidget);
  });

  testWidgets('lista vazia mostra mensagem "Nenhum XML importado ainda."',
      (tester) async {
    await tester.pumpWidget(wrap(NfeImportacoesGrid(
      listarOverride: () async => [],
    )));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum XML importado ainda.'), findsOneWidget);
  });

  testWidgets('falha ao carregar (listarOverride retorna null) mostra '
      'mensagem de erro, não a lista vazia', (tester) async {
    await tester.pumpWidget(wrap(NfeImportacoesGrid(
      listarOverride: () async => null,
    )));
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível carregar as importações.'),
        findsOneWidget);
  });

  testWidgets('botão de excluir existe para os dois status '
      '(o backend é quem decide se pode ou não)', (tester) async {
    await tester.pumpWidget(wrap(NfeImportacoesGrid(
      listarOverride: () async => [itemRascunho, itemConfirmado],
    )));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
  });

  // BUG produção corrigido: excluir uma Entrada ja confirmada (AUTORIZADA)
  // nao e mais bloqueado pelo backend -- a tooltip antiga prometia
  // "exclusão bloqueada" pra esse item, o que nao e mais verdade e confundia
  // o usuario ("nao pode excluir, mas tambem nao aparece em NF-e Entrada
  // pra excluir por la"). A tooltip agora avisa o efeito colateral real
  // (reverte estoque/contas a pagar) em vez de prometer um bloqueio que nao
  // existe mais.
  testWidgets(
      'tooltip do item AUTORIZADA avisa sobre reversão de estoque/contas a '
      'pagar, NÃO promete mais "exclusão bloqueada"', (tester) async {
    await tester.pumpWidget(wrap(NfeImportacoesGrid(
      listarOverride: () async => [itemRascunho, itemConfirmado],
    )));
    await tester.pumpAndSettle();

    expect(
        find.byTooltip(
            'Excluir (reverte estoque e contas a pagar geradas)'),
        findsOneWidget);
    expect(find.byTooltip('Entrada já confirmada -- exclusão bloqueada'),
        findsNothing);
  });
}
