import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_manager_flutter/windows/screens/manifestacao_destinatario_screen.dart';

/// Testes de widget da tela de Manifestação do Destinatário (Windows) COM
/// dados reais mockados via `http.runWithClient` (mesma técnica usada em
/// test/services/manifestacao_caller_test.dart e no equivalente web). Os
/// testes existentes em manifestacao_destinatario_screen_test.dart só
/// exercitam o caminho de erro (sem rede); estes cobrem o caminho de
/// sucesso — os gaps reais apontados pelo QA na 3ª reprovação (card P2-502).
void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  Map<String, dynamic> pendente({
    required String chave,
    required String tipo,
    String justificativa = '-',
    String status = 'PENDENTE',
  }) =>
      {
        'nfeChave': chave,
        'tipoEvento': tipo,
        'justificativa': justificativa,
        'status': status,
      };

  Map<String, dynamic> historico({
    required String chave,
    required String tipo,
    required String status,
    String protocolo = '123456789',
    String data = '2026-08-20T10:00:00',
    String? erro,
  }) =>
      {
        'nfeChave': chave,
        'tipoEvento': tipo,
        'status': status,
        'protocolo': protocolo,
        'dataEvento': data,
        if (erro != null) 'erro': erro,
      };

  group(
      'ManifestacaoDestinatarioScreen (Windows) - pendências com dados reais',
      () {
    testWidgets(
        'lista populada mostra DataTable com badges dos 4 tipos e contagem',
        (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('pendentes')) {
          return http.Response(
            jsonEncode({
              'data': [
                pendente(chave: '1' * 44, tipo: 'CIENCIA'),
                pendente(chave: '2' * 44, tipo: 'CONFIRMACAO'),
                pendente(chave: '3' * 44, tipo: 'DESCONHECIMENTO'),
                pendente(chave: '4' * 44, tipo: 'NAO_REALIZADA'),
              ]
            }),
            200,
          );
        }
        return http.Response(jsonEncode({'data': []}), 200);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(wrap(const ManifestacaoDestinatarioScreen()));
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }, () => mockClient);

      expect(find.text('4 pendência(s)'), findsOneWidget);
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('Ciência da Emissão'), findsOneWidget);
      expect(find.text('Confirmação da Operação'), findsOneWidget);
      expect(find.text('Desconhecimento da Operação'), findsOneWidget);
      expect(find.text('Operação não Realizada'), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsNWidgets(4));
    });

    testWidgets('badge de status ENVIADO e ERRO usam ícone/cor corretos',
        (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('pendentes')) {
          return http.Response(
            jsonEncode({
              'data': [
                pendente(chave: '5' * 44, tipo: 'CIENCIA', status: 'ENVIADO'),
                pendente(chave: '6' * 44, tipo: 'CIENCIA', status: 'ERRO'),
              ]
            }),
            200,
          );
        }
        return http.Response(jsonEncode({'data': []}), 200);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(wrap(const ManifestacaoDestinatarioScreen()));
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }, () => mockClient);

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets(
        'semantics dos badges de tipo/status não duplicam o texto anunciado (WR-01 do code review)',
        (tester) async {
      // Trava a regressão de a11y encontrada no code review: sem
      // `excludeSemantics: true` no Semantics wrapper, o Icon.semanticLabel
      // e o Text filhos também geram conteúdo de semantics, fazendo o
      // leitor de tela anunciar o texto duplicado (ex:
      // "Status: Enviado\nEnviado\nEnviado" em vez de só "Status: Enviado").
      final handle = tester.ensureSemantics();
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('pendentes')) {
          return http.Response(
            jsonEncode({
              'data': [
                pendente(chave: '1' * 44, tipo: 'CIENCIA', status: 'ENVIADO'),
              ]
            }),
            200,
          );
        }
        return http.Response(jsonEncode({'data': []}), 200);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(wrap(const ManifestacaoDestinatarioScreen()));
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }, () => mockClient);

      final tipoSemantics =
          tester.getSemantics(find.text('Ciência da Emissão'));
      expect(tipoSemantics.label, 'Tipo de Manifestação: Ciência da Emissão');
      expect('\n'.allMatches(tipoSemantics.label).length, 0,
          reason: 'label não deve ter texto duplicado por nó filho');

      final statusSemantics = tester.getSemantics(find.text('Enviado'));
      expect(statusSemantics.label, 'Status: Enviado');
      expect('\n'.allMatches(statusSemantics.label).length, 0,
          reason: 'label não deve ter texto duplicado por nó filho');

      handle.dispose();
    });

    testWidgets('chave de 44 dígitos é exibida formatada em blocos de 4',
        (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('pendentes')) {
          return http.Response(
            jsonEncode({
              'data': [pendente(chave: '1' * 44, tipo: 'CIENCIA')]
            }),
            200,
          );
        }
        return http.Response(jsonEncode({'data': []}), 200);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(wrap(const ManifestacaoDestinatarioScreen()));
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }, () => mockClient);

      expect(find.text(List.filled(11, '1111').join(' ')), findsOneWidget);
    });

    testWidgets('lista vazia mostra estado "Nenhuma pendência encontrada"',
        (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'data': []}), 200);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(wrap(const ManifestacaoDestinatarioScreen()));
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }, () => mockClient);

      expect(find.text('Nenhuma pendência encontrada.'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('botão Recarregar refaz a chamada de pendências',
        (tester) async {
      var chamadas = 0;
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('pendentes')) chamadas++;
        return http.Response(jsonEncode({'data': []}), 200);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(wrap(const ManifestacaoDestinatarioScreen()));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(chamadas, 1);

        await tester.tap(find.widgetWithText(ElevatedButton, 'Recarregar'));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(chamadas, 2);
      }, () => mockClient);
    });
  });

  group('ManifestacaoDestinatarioScreen (Windows) - histórico com dados reais',
      () {
    testWidgets(
        'troca para aba Histórico carrega e mostra DataTable com protocolo/data',
        (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('historico')) {
          return http.Response(
            jsonEncode({
              'data': [
                historico(
                    chave: '7' * 44,
                    tipo: 'CIENCIA',
                    status: 'ENVIADO',
                    protocolo: '999888777'),
              ]
            }),
            200,
          );
        }
        return http.Response(jsonEncode({'data': []}), 200);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(wrap(const ManifestacaoDestinatarioScreen()));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        await tester.tap(find.text('Histórico'));
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }, () => mockClient);

      expect(find.text('1 manifestação(ões)'), findsOneWidget);
      expect(find.text('999888777'), findsOneWidget);
    });

    testWidgets('histórico vazio mostra "Nenhuma manifestação realizada"',
        (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'data': []}), 200);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(wrap(const ManifestacaoDestinatarioScreen()));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        await tester.tap(find.text('Histórico'));
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }, () => mockClient);

      expect(find.text('Nenhuma manifestação realizada.'), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets(
        'item de histórico com erro mostra Tooltip com a mensagem no badge de status',
        (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('historico')) {
          return http.Response(
            jsonEncode({
              'data': [
                historico(
                    chave: '8' * 44,
                    tipo: 'CIENCIA',
                    status: 'ERRO',
                    erro: 'Rejeição SEFAZ 999'),
              ]
            }),
            200,
          );
        }
        return http.Response(jsonEncode({'data': []}), 200);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(wrap(const ManifestacaoDestinatarioScreen()));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        await tester.tap(find.text('Histórico'));
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }, () => mockClient);

      final tooltipFinder = find.byType(Tooltip);
      expect(tooltipFinder, findsOneWidget);
      final tooltip = tester.widget<Tooltip>(tooltipFinder);
      expect(tooltip.message, 'Rejeição SEFAZ 999');
    });
  });

  group(
      'ManifestacaoDestinatarioScreen (Windows) - fluxo completo de submissão (POST real mockado)',
      () {
    testWidgets(
        'submissão bem-sucedida mostra SnackBar de sucesso e recarrega as duas listas',
        (tester) async {
      var getPendentesCount = 0;
      var getHistoricoCount = 0;
      var postCount = 0;

      final mockClient = MockClient((request) async {
        final url = request.url.toString();
        if (request.method == 'POST' && url.contains('manifestacao')) {
          postCount++;
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['nfeChave'], '1' * 44);
          expect(body['tipoEvento'], 'CIENCIA');
          return http.Response(jsonEncode({'status': 'ENVIADO'}), 200);
        }
        if (url.contains('pendentes')) {
          getPendentesCount++;
          return http.Response(jsonEncode({'data': []}), 200);
        }
        if (url.contains('historico')) {
          getHistoricoCount++;
          return http.Response(jsonEncode({'data': []}), 200);
        }
        return http.Response('{}', 404);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(wrap(const ManifestacaoDestinatarioScreen()));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        getPendentesCount = 0;
        getHistoricoCount = 0;

        await tester
            .tap(find.widgetWithText(ElevatedButton, 'Nova Manifestação'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, '1' * 44);
        await tester.tap(find.widgetWithText(ElevatedButton, 'Confirmar'));
        // pump() em vez de pumpAndSettle: o SnackBar tem timer de
        // auto-dismiss e pumpAndSettle(duration) avança frames até o timer
        // esgotar, fazendo o SnackBar desaparecer antes da asserção.
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
      }, () => mockClient);

      expect(postCount, 1);
      expect(find.text('Manifestação registrada com sucesso'),
          findsOneWidget);
      expect(getPendentesCount, 1);
      expect(getHistoricoCount, 1);
    });

    testWidgets(
        'submissão com erro do backend mostra SnackBar com a mensagem de erro e NÃO recarrega listas',
        (tester) async {
      var getCount = 0;

      final mockClient = MockClient((request) async {
        final url = request.url.toString();
        if (request.method == 'POST' && url.contains('manifestacao')) {
          return http.Response(
              jsonEncode({'error': 'NFe já manifestada anteriormente'}), 400);
        }
        getCount++;
        return http.Response(jsonEncode({'data': []}), 200);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(wrap(const ManifestacaoDestinatarioScreen()));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        getCount = 0;

        await tester
            .tap(find.widgetWithText(ElevatedButton, 'Nova Manifestação'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, '2' * 44);
        await tester.tap(find.widgetWithText(ElevatedButton, 'Confirmar'));
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
      }, () => mockClient);

      expect(find.text('NFe já manifestada anteriormente'), findsOneWidget);
      expect(getCount, 0);
    });
  });
}
