import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/sessoes_screen.dart';

/// Sistema > Sessões (bug de produção 2026-09-11): tela pra ver usuários
/// com sessão ativa e o tempo de ociosidade, e matar sessão manualmente.
/// Igual ao padrão já usado em importacao_fiscal_automacao_screen_test.dart
/// deste repositório: NetworkCaller aqui não é injetável, então o teste
/// cobre a estrutura estática da tela (AppBar, botões, banner de regras) e
/// o estado de erro (chamada de rede real falha no ambiente de teste,
/// caindo naturalmente no catch -- comportamento real e testável sem mock).
void main() {
  Widget wrap() => const MaterialApp(home: SessoesScreen());

  testWidgets('renderiza AppBar, botão Matar todas e banner de regras',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.text('Sessões'), findsOneWidget);
    expect(find.text('Matar todas'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
    expect(
      find.textContaining('meia-noite todas as sessões são encerradas'),
      findsOneWidget,
    );
  });

  testWidgets('mostra erro e botao de tentar novamente quando a rede falha',
      (tester) async {
    // No ambiente de teste, chamadas HTTP reais sempre falham (o binding de
    // teste nao permite rede real) -- cai no estado de erro da tela, seja
    // via exception (catch) ou via resposta sem sucesso (else), dependendo
    // de como NetworkCaller trata a falha internamente. Os 2 casos mostram
    // "Tentar novamente", que e' o que interessa provar aqui.
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Tentar novamente'), findsOneWidget);
  });

  testWidgets('botao Matar todas abre dialog de confirmacao', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Matar todas'));
    await tester.pumpAndSettle();

    expect(find.text('Matar TODAS as sessões'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
  });
}
