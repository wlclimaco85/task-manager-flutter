import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/utils/menu_config.dart';
import 'package:task_manager_flutter/widgets/captura_nfe/captura_nfe_screen.dart';
import 'package:task_manager_flutter/widgets/user_banners.dart';

http.Response _json(Object corpo, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(corpo)), status);

void main() {
  setUpAll(() => SharedPreferences.setMockInitialValues({}));

  final urls = <String>[];

  Future<http.Response> servidor(String url) async {
    urls.add(url);
    if (url.contains('/xml')) return http.Response('<nfe/>', 200);
    if (url.contains('/documentos')) {
      return _json({
        'temMais': !url.contains('pagina=1'),
        'itens': [
          {
            'id': url.contains('pagina=1') ? 2 : 1,
            'parceiroId': null,
            'nsu': '000000000000049',
            'tipo': 'RESUMO',
            'chave': '35261111222333000181550010000000011000000010',
            'emitenteCnpj': '99888777000166',
            'emitenteNome': 'Fornecedor de Materiais de Construção e Acabamentos Ltda',
            'valor': 10.5,
            'dhEmissao': '2026-11-20T10:00',
            'capturadoEm': '2026-11-27T10:00',
          }
        ]
      });
    }
    return _json({
      'cnpjs': [
        {'parceiroId': null, 'nome': 'Minha empresa', 'temCertificado': true,
         'certificadoValidade': '2099-01-01', 'ativo': false},
        {'parceiroId': 5, 'nome': 'Cliente sem certificado', 'temCertificado': false, 'ativo': false},
      ]
    });
  }

  Future<void> abrir(WidgetTester t, Widget tela, [double largura = 1366]) async {
    urls.clear();
    t.view.physicalSize = Size(largura, 2400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(home: tela));
    await t.pumpAndSettle();
  }

  for (final largura in const [1366.0, 360.0]) {
    testWidgets('ativar pede confirmação e envia parceiroId nulo em ${largura.toInt()} px', (t) async {
      final corpos = <Map<String, dynamic>>[];
      await abrir(
          t,
          CapturaNfeScreen(
            cabecalhoMobile: largura < 700,
            buscar: servidor,
            enviar: (url, corpo) async {
              expect(url, contains('/api/captura-dfe/config'));
              corpos.add(jsonDecode(corpo) as Map<String, dynamic>);
              return _json({'ativo': true});
            },
          ),
          largura);

      expect(find.byType(UserBannerAppBar), largura < 700 ? findsOneWidget : findsNothing);
      expect(find.textContaining('não importa a nota'), findsOneWidget);
      final chaves = t.widgetList<Switch>(find.byType(Switch)).toList();
      expect(chaves[1].onChanged, isNull); // sem certificado não liga

      await t.tap(find.byType(Switch).first);
      await t.pumpAndSettle();
      expect(corpos, isEmpty);
      await t.tap(find.text('Ativar captura'));
      await t.pumpAndSettle();

      expect(corpos.single.containsKey('parceiroId'), isTrue);
      expect(corpos.single['parceiroId'], isNull);
      expect(corpos.single['ativo'], true);
      expect(find.text('Captura ativada.'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('documentos: filtra pela empresa, carrega mais e baixa em ${largura.toInt()} px',
        (t) async {
      String? nome;
      await abrir(t, CapturaNfeScreen(buscar: servidor, salvar: (n, _) async => nome = n), largura);

      await t.tap(find.text('Ver documentos').first);
      await t.pumpAndSettle();
      expect(urls.last, contains('parceiroId=0'));
      expect(find.textContaining('apenas o resumo'), findsOneWidget);

      await t.tap(find.text('Carregar mais'));
      await t.pumpAndSettle();
      expect(urls.last, contains('pagina=1'));
      expect(find.text('Baixar XML do resumo'), findsNWidgets(2));
      expect(find.text('Carregar mais'), findsNothing);

      await t.tap(find.text('Baixar XML do resumo').first);
      await t.pumpAndSettle();
      expect(urls.last, contains('/documentos/1/xml'));
      expect(nome, '35261111222333000181550010000000011000000010-resumo.xml');
      expect(t.takeException(), isNull);
    });
  }

  for (final largura in const [1366.0, 360.0]) {
    testWidgets('ciência só vai à SEFAZ depois da confirmação em ${largura.toInt()} px', (t) async {
      final corpos = <Map<String, dynamic>>[];
      await abrir(
          t,
          CapturaNfeScreen(
            buscar: servidor,
            enviarCiencia: (url, corpo) async {
              expect(url, contains('/api/captura-dfe/ciencia'));
              corpos.add(jsonDecode(corpo) as Map<String, dynamic>);
              return _json({
                'resultados': [
                  {'id': 1, 'situacao': 'REJEITADA', 'mensagem': 'SEFAZ 596: Evento fora do prazo'}
                ]
              });
            },
          ),
          largura);
      await t.tap(find.text('Documentos capturados'));
      await t.pumpAndSettle();
      expect(find.textContaining('Dar ciência ('), findsNothing);

      await t.tap(find.text('Selecionar para ciência'));
      await t.pumpAndSettle();
      await t.tap(find.text('Dar ciência (1)'));
      await t.pumpAndSettle();
      expect(find.textContaining('não há como desfazer'), findsOneWidget);

      // Sem marcar a conferência o botão não envia.
      await t.tap(find.text('Enviar ciência'));
      await t.pumpAndSettle();
      expect(corpos, isEmpty);

      await t.tap(find.text('Conferi as notas e quero enviar a ciência'));
      await t.pumpAndSettle();
      final antes = urls.length;
      await t.tap(find.text('Enviar ciência'));
      await t.pumpAndSettle();

      expect(corpos.single['ids'], [1]);
      expect(find.text('0 de 1 registrada(s) na SEFAZ.'), findsOneWidget);
      expect(find.textContaining('SEFAZ 596: Evento fora do prazo'), findsOneWidget);
      await t.tap(find.text('Fechar'));
      await t.pumpAndSettle();
      expect(urls.length, greaterThan(antes)); // lista recarregada
      expect(find.textContaining('Dar ciência ('), findsNothing);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('cancelar não envia e falha de rede avisa para conferir antes de repetir', (t) async {
    var envios = 0;
    await abrir(
        t,
        CapturaNfeScreen(
          buscar: servidor,
          enviarCiencia: (_, __) async {
            envios++;
            throw Exception('sem rede');
          },
        ));
    await t.tap(find.text('Documentos capturados'));
    await t.pumpAndSettle();
    await t.tap(find.text('Selecionar para ciência'));
    await t.pumpAndSettle();

    await t.tap(find.text('Dar ciência (1)'));
    await t.pumpAndSettle();
    await t.tap(find.text('Cancelar'));
    await t.pumpAndSettle();
    expect(envios, 0);

    await t.tap(find.text('Dar ciência (1)'));
    await t.pumpAndSettle();
    await t.tap(find.text('Conferi as notas e quero enviar a ciência'));
    await t.pumpAndSettle();
    await t.tap(find.text('Enviar ciência'));
    await t.pumpAndSettle();
    expect(envios, 1);
    expect(find.textContaining('Atualize a lista antes de repetir'), findsOneWidget);
  });

  testWidgets('403 mostra falta de acesso sem tentar de novo', (t) async {
    await abrir(t, CapturaNfeScreen(buscar: (_) async => _json({}, 403)), 360);
    expect(find.textContaining('Você não tem acesso à Captura de NF-e'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsNothing);
  });

  test('tela está no menu Contábil', () {
    final contabil = MenuConfig.groups.firstWhere((g) => g.id == 'contabil');
    expect(contabil.items.map((i) => i.id), contains('captura_nfe'));
  });
}
