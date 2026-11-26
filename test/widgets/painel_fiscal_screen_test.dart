import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:task_manager_flutter/utils/role_permission_catalog.dart';
import 'package:task_manager_flutter/widgets/painel_fiscal/painel_fiscal_screen.dart';

String _iso(int dia) {
  final h = DateTime.now();
  return DateTime(h.year, h.month, dia).toIso8601String().substring(0, 10);
}

Map<String, dynamic> _empresa(int id, String nome, int? indice, String nivel, int vencidos) => {
      'id': id,
      'nome': nome,
      'indice': indice,
      'nivel': nivel,
      'parcial': false,
      'vencidos': vencidos,
      'motivo': vencidos > 0 ? '2 guia(s) vencida(s)' : '',
      'selos': ['Certificado em ordem'],
      'componentes': [
        {'codigo': 'GUIA', 'rotulo': 'Guias', 'peso': 30, 'nota': 50, 'avaliados': 2},
        {'codigo': 'ALVARA', 'rotulo': 'Alvarás e documentos', 'peso': 10, 'nota': null, 'avaliados': 0},
      ],
    };

Map<String, dynamic> painelDeExemplo({bool vazio = false}) {
  final item = {
    'tipo': 'OBRIGACAO',
    'id': 1,
    'parceiroId': 1,
    'empresa': 'Mercado Central Ltda',
    'titulo': 'DCTFWeb mensal',
    'vencimento': _iso(10),
    'situacao': 'VENCIDO',
    'etiqueta': null,
    'valor': null,
  };
  return {
    'carteira': {'indice': 72, 'nivel': 'ATENCAO', 'avaliadas': 2, 'total': 3, 'parciais': 1},
    'progresso': {
      'obrigacoes': {'feitas': 8, 'total': 12},
      'guias': {'feitas': 3, 'total': 6},
    },
    'cards': {
      'certificadosVencidos': 1,
      'certificadosAVencer': 2,
      'certificadosAusentes': 1,
      'empresasComOcorrencia': 1,
      'guiasVencidas': 2,
      'guiasVencidasValor': 1520.5,
      'guiasVencidasSemValor': 1,
    },
    'empresas': vazio
        ? []
        : [
            _empresa(1, 'Mercado Central Ltda', 42, 'RISCO', 3),
            _empresa(2, 'Padaria Bom Dia', 96, 'EM_DIA', 0),
            _empresa(3, 'Oficina Nova', null, 'SEM_DADOS', 0),
          ],
    'missoes': [
      {...item, 'motivo': 'Vencido há 16 dia(s)', 'prioridade': 1}
    ],
    'itens': [item],
    'filtros': {
      'empresas': [
        {'id': 1, 'nome': 'Mercado Central Ltda', 'regimeId': 3}
      ],
      'regimes': [
        {'id': 3, 'descricao': 'Simples Nacional'}
      ],
    },
  };
}

http.Response _ok(Map<String, dynamic> corpo) =>
    http.Response.bytes(utf8.encode(jsonEncode(corpo)), 200);

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR', null));

  Future<void> abrir(WidgetTester t, Size tamanho, Future<http.Response> Function(String) buscar) async {
    t.view.physicalSize = tamanho;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(home: PainelFiscalScreen(buscar: buscar)));
    await t.pumpAndSettle();
  }

  for (final tamanho in const [Size(1366, 3000), Size(820, 3400), Size(360, 4200)]) {
    testWidgets('mostra o painel sem estourar em ${tamanho.width.toInt()} px', (t) async {
      final urls = <String>[];
      await abrir(t, tamanho, (url) async {
        urls.add(url);
        return _ok(painelDeExemplo());
      });

      expect(find.text('Saúde da carteira'), findsOneWidget);
      expect(find.text('Próximas missões'), findsOneWidget);
      expect(find.text('Ainda não disponível'), findsOneWidget);
      expect(find.text('Todas as empresas'), findsOneWidget);
      expect(Uri.parse(urls.single).queryParameters.containsKey('clienteId'), isFalse);
      expect(Uri.parse(urls.single).queryParameters.containsKey('regimeId'), isFalse);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('tocar na empresa do ranking filtra o painel por ela', (t) async {
    final urls = <String>[];
    await abrir(t, const Size(1366, 3000), (url) async {
      urls.add(url);
      return _ok(painelDeExemplo());
    });

    await t.tap(find.text('Padaria Bom Dia'));
    await t.pumpAndSettle();

    expect(Uri.parse(urls.last).queryParameters['clienteId'], '2');
    expect(find.text('Voltar à carteira'), findsOneWidget);
  });

  testWidgets('sem permissão mostra o aviso e nenhum contador', (t) async {
    await abrir(t, const Size(360, 800), (_) async => http.Response('', 403));

    expect(find.textContaining('Você não tem acesso'), findsOneWidget);
    expect(find.text('Guias vencidas'), findsNothing);
    expect(find.text('Tentar novamente'), findsOneWidget);
  });

  testWidgets('carteira vazia explica o motivo', (t) async {
    await abrir(t, const Size(360, 800), (_) async => _ok(painelDeExemplo(vazio: true)));

    expect(find.textContaining('Nenhuma empresa-cliente'), findsOneWidget);
  });

  test('painel fiscal aparece no Controle de Acesso', () {
    final ids = RolePermissionCatalog.groups().expand((g) => g.entries).map((e) => e.menuItemId);
    expect(ids, contains('painel_fiscal'));
  });
}
