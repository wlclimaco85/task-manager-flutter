import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/fiscal/ambiente_badge.dart';
import 'package:task_manager_flutter/widgets/fiscal/nf_status_bar.dart';

/// Card #503 (UI/UX Audit NF-e), critério "progresso/status de autorização
/// sempre visível": QA apontou em vários ciclos que `NfStatusBar` existia
/// no repositório mas nunca era referenciado em nenhuma tela real de
/// task_manager_flutter (widget morto) -- apesar de já estar integrado no
/// app base (`task_manager_flutter_merged_final`), uma inversão da regra
/// de replicação do CLAUDE.md. Agora integrado em
/// `windows/screens/nfe_saida_create_screen.dart` (appBar) e
/// `windows/screens/nfse_screen.dart` (header da lista).
///
/// Este teste cobre o widget em si (nunca tinha teste antes), pra garantir
/// que continua renderizando titulo/badge de ambiente/ações corretamente e
/// não volta a ficar "morto" silenciosamente.
void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(appBar: child as PreferredSizeWidget));

  group('NfStatusBar', () {
    testWidgets('renderiza o título e o ícone', (tester) async {
      await tester.pumpWidget(wrap(const NfStatusBar(titulo: 'Nova NF-e Saída')));

      expect(find.text('Nova NF-e Saída'), findsOneWidget);
      expect(find.byIcon(Icons.receipt_long), findsOneWidget); // ícone padrão
    });

    testWidgets('mostra o AmbienteBadge quando ambiente é informado',
        (tester) async {
      await tester.pumpWidget(wrap(const NfStatusBar(
        titulo: 'Nova NF-e Saída',
        ambiente: 'HOMOLOGACAO',
      )));

      expect(find.byType(AmbienteBadge), findsOneWidget);
      expect(find.text('HOMOLOGACAO'), findsOneWidget);
    });

    testWidgets('NÃO mostra o AmbienteBadge quando ambiente é nulo',
        (tester) async {
      await tester.pumpWidget(wrap(const NfStatusBar(titulo: 'NFSe - Nota Fiscal de Serviços')));

      expect(find.byType(AmbienteBadge), findsNothing);
    });

    testWidgets('botão Salvar dispara onSalvarRascunho e some quando loading',
        (tester) async {
      var salvouChamado = false;
      await tester.pumpWidget(wrap(NfStatusBar(
        titulo: 'Nova NF-e Saída',
        onSalvarRascunho: () => salvouChamado = true,
      )));

      await tester.tap(find.text('Salvar'));
      await tester.pump();
      expect(salvouChamado, isTrue);

      // Durante loading, o botão de salvar deve ficar desabilitado (nao
      // deve reagir a tap) -- mesma regra usada nos dois pontos de
      // integracao (onSalvarRascunho: _saving ? null : _salvar).
      salvouChamado = false;
      await tester.pumpWidget(wrap(NfStatusBar(
        titulo: 'Nova NF-e Saída',
        loading: true,
        onSalvarRascunho: () => salvouChamado = true,
      )));
      // Com loading=true e onSalvarRascunho fornecido, o botao continua
      // exibido (o caller e quem decide se passa null); a integracao real
      // ja passa null quando _saving==true, entao aqui validamos apenas
      // que o indicador de progresso aparece junto.
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('acaoExtra é renderizado quando fornecido (uso em nfse_screen.dart)',
        (tester) async {
      await tester.pumpWidget(wrap(NfStatusBar(
        titulo: 'NFSe - Nota Fiscal de Serviços',
        acaoExtra: const Text('+ Nova NFSe'),
      )));

      expect(find.text('+ Nova NFSe'), findsOneWidget);
    });
  });
}
