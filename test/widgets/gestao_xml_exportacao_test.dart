import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/widgets/gestao_xml/gestao_xml_screen.dart';

http.Response _json(Object corpo, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(corpo)), status);

void main() {
  setUpAll(() => SharedPreferences.setMockInitialValues({}));

  Future<http.Response> servidor(String url) async {
    if (url.contains('/lote/clientes')) return _json({'clientes': []});
    if (url.contains('/lote')) {
      return _json({
        'limite': 2000,
        'tipos': [
          {'codigo': 'NFE', 'nome': 'NF-e', 'total': 3, 'semXml': 1},
          {'codigo': 'CTE', 'nome': 'CT-e', 'total': 0, 'semXml': 0},
        ]
      });
    }
    return _json({
      'porPagina': 20,
      'clientes': [],
      'contadores': {'notas': 1, 'semXml': 0, 'canceladas': 0, 'valorAutorizadas': 10},
      'itens': [
        {'id': 9, 'numero': '1', 'serie': '1', 'valor': 10, 'status': 'AUTORIZADA', 'tipo': 'SAIDA',
         'xmlAutorizado': true}
      ],
    });
  }

  Future<void> abrir(WidgetTester t, Widget tela, double largura) async {
    t.view.physicalSize = Size(largura, 2400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(home: tela));
    await t.pumpAndSettle();
  }

  Future<void> digitarEmail(WidgetTester t, String email, String repetido) async {
    await t.enterText(find.widgetWithText(TextField, 'E-mail do destinatário*'), email);
    await t.enterText(find.widgetWithText(TextField, 'Confirme o e-mail*'), repetido);
    await t.tap(find.text('Enviar para este e-mail'));
    await t.pumpAndSettle();
  }

  for (final largura in const [1366.0, 360.0]) {
    testWidgets('e-mail da seleção exige endereço repetido em ${largura.toInt()} px', (t) async {
      final pedidos = <String, dynamic>{};
      await abrir(
          t,
          GestaoXmlScreen(
            cabecalhoMobile: largura < 700,
            buscar: servidor,
            enviar: (url, corpo) async {
              pedidos[url] = jsonDecode(corpo);
              return _json({'enviadoPara': 'a@b.com'});
            },
          ),
          largura);

      await t.tap(find.text('Selecionar página'));
      await t.pumpAndSettle();
      await t.tap(find.text('Enviar por e-mail'));
      await t.pumpAndSettle();
      await digitarEmail(t, 'a@b.com', 'x@b.com');
      expect(find.text('Os e-mails não conferem.'), findsOneWidget);
      expect(pedidos, isEmpty);
      await digitarEmail(t, 'a@b.com', 'a@b.com');

      expect(pedidos.keys.single, contains('/api/gestao-xml/email'));
      expect(pedidos.values.single, {'ids': [9], 'destinatario': 'a@b.com'});
      expect(find.text('E-mail enviado para a@b.com.'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('exportar por período manda só os tipos com documento em ${largura.toInt()} px',
        (t) async {
      Map<String, dynamic>? pedido;
      var salvou = false;
      await abrir(
          t,
          GestaoXmlScreen(
            buscar: servidor,
            salvar: (_) async => salvou = true,
            enviar: (url, corpo) async {
              expect(url, contains('/api/gestao-xml/lote/zip'));
              pedido = jsonDecode(corpo) as Map<String, dynamic>;
              return http.Response('zip', 200);
            },
          ),
          largura);

      await t.tap(find.text('Exportar por período'));
      await t.pumpAndSettle();
      expect(t.widget<FilledButton>(find.widgetWithText(FilledButton, 'Baixar ZIP')).onPressed, isNull);
      for (final rotulo in ['Data inicial*', 'Data final*']) {
        await t.tap(find.text(rotulo));
        await t.pumpAndSettle();
        await t.tap(find.text('OK'));
        await t.pumpAndSettle();
      }
      expect(find.text('NF-e: 3 (1 sem XML)'), findsOneWidget);
      await t.ensureVisible(find.widgetWithText(FilledButton, 'Baixar ZIP'));
      await t.tap(find.widgetWithText(FilledButton, 'Baixar ZIP'));
      await t.pumpAndSettle();

      expect(pedido!['tipos'], ['NFE']);
      expect(pedido!.containsKey('clienteId'), isFalse);
      expect(salvou, isTrue);
      expect(find.text('ZIP gerado.'), findsWidgets);
      expect(t.takeException(), isNull);
    });
  }
}
