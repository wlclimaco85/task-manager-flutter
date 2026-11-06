import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/nfse_auditoria_timeline_dialog.dart';

Widget _app(NfseAuditoriaTimelineDialog dialog) => MaterialApp(
      home: Scaffold(body: Builder(builder: (ctx) {
        return TextButton(
          onPressed: () => showDialog<void>(context: ctx, builder: (_) => dialog),
          child: const Text('abrir'),
        );
      })),
    );

void main() {
  testWidgets('mostra mensagem quando a nota nao tem eventos', (tester) async {
    await tester.pumpWidget(_app(NfseAuditoriaTimelineDialog(
      nfseId: '15',
      numero: '96',
      carregador: (_) async => [],
    )));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Auditoria da NFS-e'), findsOneWidget);
    expect(find.text('NFS-e nº 96'), findsOneWidget);
    expect(find.text('Nenhum evento de auditoria registrado para esta nota.'), findsOneWidget);
  });

  testWidgets('mostra criacao, faturamento e cancelamento com quem e de onde', (tester) async {
    await tester.pumpWidget(_app(NfseAuditoriaTimelineDialog(
      nfseId: '15',
      numero: '96',
      carregador: (_) async => [
        {
          'acao': 'FATURADA',
          'dataEvento': '2026-11-05T20:39:51',
          'usuarioId': 42,
          'usuarioNome': 'Washington Climaco',
          'origem': 'SISTEMA',
          'detalhe': 'Mensalidade 3 faturada.',
        },
        {
          'acao': 'CANCELADA',
          'dataEvento': '2026-11-06T09:10:00',
          'usuarioId': null,
          'origem': 'PORTAL_NACIONAL',
          'detalhe': 'Evento de cancelamento encontrado no Portal Nacional (HTTP 200)',
        },
        {
          'acao': 'FINANCEIRO_DESFEITO',
          'dataEvento': '2026-11-06T09:10:02',
          'usuarioId': null,
          'origem': 'SISTEMA',
          'detalhe': 'Titulos cancelados.',
        },
      ],
    )));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Nota faturada'), findsOneWidget);
    expect(find.text('05/11/2026 às 20:39'), findsOneWidget);
    expect(find.text('Washington Climaco'), findsOneWidget);
    expect(find.text('Cancelamento'), findsOneWidget);
    expect(find.text('Origem: Portal Nacional'), findsOneWidget);
    expect(find.text('Automático'), findsWidgets);
    expect(find.text('Financeiro desfeito'), findsOneWidget);
  });

  testWidgets('mostra erro com opcao de tentar de novo', (tester) async {
    await tester.pumpWidget(_app(NfseAuditoriaTimelineDialog(
      nfseId: '15',
      numero: '96',
      carregador: (_) async => throw Exception('sem conexao'),
    )));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível carregar a auditoria.'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
  });
}
