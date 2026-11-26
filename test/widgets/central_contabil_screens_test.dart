import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/utils/menu_config.dart';
import 'package:task_manager_flutter/widgets/diagnostico_esocial/diagnostico_esocial_screen.dart';
import 'package:task_manager_flutter/widgets/gestao_xml/gestao_xml_screen.dart';

http.Response _ok(Object corpo) => http.Response.bytes(utf8.encode(jsonEncode(corpo)), 200);

final _diagnostico = {
  'funcionarios': [
    {
      'id': 1,
      'nome': 'Ana Souza',
      'cpf': '***.982.247-**',
      'matricula': '10',
      'ativo': true,
      'contratanteId': 3,
      'contratante': 'Mercado Central Ltda',
      'impede': [
        {'codigo': 'CBO', 'campo': 'CBO', 'problema': 'CBO ausente ou sem 6 dígitos', 'correcao': 'Informe o CBO.'}
      ],
      'revisar': [],
    },
    {
      'id': 2,
      'nome': 'Bruno Lima',
      'cpf': '***.111.222-**',
      'matricula': '11',
      'ativo': true,
      'contratanteId': null,
      'contratante': null,
      'impede': [],
      'revisar': [],
    },
  ]
};

final _xml = {
  'itens': [
    {
      'id': 1, 'chave': '3' * 44, 'numero': '123', 'serie': '1', 'emissao': '2026-11-12T10:00:00',
      'valor': 1250.0, 'status': 'AUTORIZADA', 'tipo': 'SAIDA', 'emitente': 'Mercado Central Ltda',
      'destinatario': 'Padaria Bom Dia', 'xmlAutorizado': true, 'xmlAssinado': false, 'xmlCancelamento': false,
    },
    {
      'id': 2, 'chave': null, 'numero': '124', 'serie': '1', 'emissao': null, 'valor': null,
      'status': 'CANCELADA', 'tipo': 'ENTRADA', 'emitente': null, 'destinatario': null,
      'xmlAutorizado': false, 'xmlAssinado': false, 'xmlCancelamento': false,
    },
  ],
  'contadores': {'notas': 2, 'semXml': 1, 'canceladas': 1, 'valorAutorizadas': 1250.0},
  'pagina': 0,
  'porPagina': 20,
  'clientes': [
    {'id': 3, 'nome': 'Mercado Central Ltda'}
  ],
};

void main() {
  Future<void> abrir(WidgetTester t, Size tamanho, Widget tela) async {
    t.view.physicalSize = tamanho;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(home: tela));
    await t.pumpAndSettle();
  }

  for (final tamanho in const [Size(1366, 2400), Size(820, 2600), Size(360, 3200)]) {
    testWidgets('diagnóstico não estoura em ${tamanho.width.toInt()} px', (t) async {
      await abrir(t, tamanho, DiagnosticoEsocialScreen(buscar: (_) async => _ok(_diagnostico)));

      expect(find.text('50%'), findsOneWidget);
      expect(find.text('Ana Souza'), findsOneWidget);
      expect(find.textContaining('Ela não transmite eventos'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('gestão de XML não estoura em ${tamanho.width.toInt()} px', (t) async {
      await abrir(t, tamanho, GestaoXmlScreen(buscar: (_) async => _ok(_xml)));

      expect(find.textContaining('Somente NF-e'), findsOneWidget);
      expect(find.textContaining('NF-e 123'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('selecionar a página ignora nota sem XML e envia só as válidas no ZIP', (t) async {
    String? corpo;
    Uint8List? salvo;
    await abrir(
        t,
        const Size(1366, 2400),
        GestaoXmlScreen(
          buscar: (_) async => _ok(_xml),
          enviar: (_, c) async {
            corpo = c;
            return http.Response.bytes([80, 75], 200);
          },
          salvar: (b) async => salvo = b,
        ));

    await t.tap(find.text('Selecionar página'));
    await t.pumpAndSettle();
    await t.tap(find.text('Baixar ZIP'));
    await t.pumpAndSettle();

    expect(jsonDecode(corpo!)['ids'], [1]);
    expect(salvo, [80, 75]);
    expect(find.text('ZIP gerado.'), findsOneWidget);
  });

  testWidgets('falha no ZIP avisa e mantém a seleção', (t) async {
    await abrir(
        t,
        const Size(1366, 2400),
        GestaoXmlScreen(
            buscar: (_) async => _ok(_xml), enviar: (_, __) async => http.Response('', 500)));

    await t.tap(find.text('Selecionar página'));
    await t.pumpAndSettle();
    await t.tap(find.text('Baixar ZIP'));
    await t.pumpAndSettle();

    expect(find.textContaining('Sua seleção foi mantida'), findsOneWidget);
    expect(find.text('1 selecionada(s)'), findsOneWidget);
  });

  testWidgets('sem permissão não mostra dados', (t) async {
    await abrir(t, const Size(360, 800),
        DiagnosticoEsocialScreen(buscar: (_) async => http.Response('', 403)));

    expect(find.textContaining('Você não tem acesso'), findsOneWidget);
    expect(find.text('Verificações'), findsNothing);
  });

  test('telas fiscais ficam como subitem de Contábil', () {
    final contabil = MenuConfig.groups.firstWhere((g) => g.id == 'contabil').items.map((i) => i.id);
    expect(contabil,
        containsAll(['painel_fiscal', 'escrituracao_fiscal', 'diagnostico_esocial', 'gestao_xml']));
    final comercial = MenuConfig.groups.firstWhere((g) => g.id == 'comercial').items.map((i) => i.id);
    expect(comercial, isNot(contains('painel_fiscal')));
  });
}
