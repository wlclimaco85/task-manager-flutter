import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_manager_flutter/models/auth_utility.dart';
import 'package:task_manager_flutter/models/empresa_model.dart';
import 'package:task_manager_flutter/models/login_model.dart';
import 'package:task_manager_flutter/models/parceiro_model.dart';
import 'package:task_manager_flutter/utils/dropdown_helpers.dart';
import 'package:task_manager_flutter/widgets/searchable_dropdown.dart';
import 'package:task_manager_flutter/web/screens/details/nfse_detail_screen.dart';
import 'package:task_manager_flutter/web/screens/nfse_screen.dart';

void main() {
  testWidgets('Web: cria item de servico com campo Produto (Servico)',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp(
        home: NfseDetailScreen(item: const {'id': 501, 'status': 'PENDENTE'})));
    await tester.pump();

    expect(find.text('NFSe #501'), findsOneWidget);
    expect(find.text('Itens (Serviços)'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Novo'));
    await tester.pump();

    expect(find.text('Produto (Serviço)'), findsOneWidget);
    expect(find.text('Descrição'), findsOneWidget);
    expect(find.text('Quantidade'), findsOneWidget);
    expect(find.text('Vl. Unitário'), findsOneWidget);
    expect(find.text('Vl. Total'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
  });

  test('busca de produtos da NFSe envia isServico=true', () {
    final query = DropdownHelpers.buildProdutosContabeisBuscaQuery(
      busca: 'consultoria',
      pagina: 0,
      empresaId: '1',
      parceiroId: '1751',
      isServico: true,
    );

    expect(query, contains('isServico=true'));
    expect(query, contains('nome=consultoria'));
    expect(query, contains('empId=1'));
    expect(query, contains('parceiroId=1751'));
  });

  test('extrai municipio e ambiente dos dados da empresa emissora', () {
    final defaults = resolveNfseEmpresaDefaults({
      'ambiente': 'HOMOLOGACAO',
      'cidade': {'id': 31, 'nome': 'Uberaba', 'codigoServicoMunicipal': '1701'},
      'estado': {'sigla': 'MG'},
    });

    expect(defaults.municipio, 'Uberaba');
    expect(defaults.cidadeId, '31');
    expect(defaults.ambiente, 'HOMOLOGACAO');
    expect(defaults.codigoServicoMunicipal, '1701');
  });

  test('extrai municipio e ambiente do tomador para nova NFS-e', () {
    final defaults = resolveNfseTomadorDefaults({
      'ambiente': '2 - Homologação',
      'cidade': {'id': 31001, 'nome': 'Uberaba'},
    });

    expect(defaults.municipio, 'Uberaba');
    expect(defaults.cidadeId, '31001');
    expect(defaults.ambiente, 'HOMOLOGACAO');
  });

  test('aceita cidade aninhada no endereco do tomador', () {
    final defaults = resolveNfseTomadorDefaults({
      'ambiente': 'PRODUCAO',
      'cidade': 'Uberaba',
      'endereco': {
        'cidade': {'id': 123, 'nome': 'Uberaba'}
      },
    });

    expect(defaults.municipio, 'Uberaba');
    expect(defaults.cidadeId, '123');
    expect(defaults.ambiente, 'PRODUCAO');
  });

  testWidgets('carrega municipio e ambiente do tomador real ao abrir NFS-e',
      (tester) async {
    final requisicoes = <Uri>[];
    AuthUtility.userInfo = LoginModel(
      login: Login(
        id: 972,
        empresa: Empresa(id: 1, nome: 'Empresa Smoke Test'),
        parceiro: Parceiro(
          id: 1805,
          nome:
              'Abraco Contabilidade Contabilidade Martins & Abrahao Arabe LTDA',
        ),
      ),
    );
    addTearDown(() => AuthUtility.userInfo = null);

    final client = MockClient((request) async {
      requisicoes.add(request.url);
      if (request.url.path.endsWith('/api/parceiro/1805')) {
        return http.Response(
          jsonEncode({
            'data': {
              'id': 1805,
              'nome':
                  'Abraco Contabilidade Contabilidade Martins & Abrahao Arabe LTDA',
              'cidade': 'Uberaba',
              'estado': 'MG',
              'ambiente': 'HOMOLOGACAO',
            }
          }),
          200,
        );
      }
      if (request.url.path.endsWith('/api/cidade') &&
          request.url.queryParameters['nome'] == 'Uberaba') {
        return http.Response(
          jsonEncode({
            'data': {
              'dados': [
                {'id': 10968, 'nome': 'Uberaba'}
              ]
            }
          }),
          200,
        );
      }
      if (request.url.path.endsWith('/api/empresa/1')) {
        return http.Response(
          jsonEncode({
            'data': {'id': 1, 'nome': 'Empresa Smoke Test'}
          }),
          200,
        );
      }
      return http.Response(jsonEncode({'data': []}), 200);
    });

    await http.runWithClient(() async {
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      await tester.pumpWidget(MaterialApp(
        home: NfseDetailScreen(item: const {}),
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
    }, () => client);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    expect(requisicoes.any((uri) => uri.path.endsWith('/api/parceiro/1805')),
        isTrue,
        reason: 'GET parceiro nao observado: $requisicoes');
    expect(
        requisicoes.any((uri) =>
            uri.path.endsWith('/api/cidade') &&
            uri.queryParameters['nome'] == 'Uberaba'),
        isTrue);
    expect(find.text('Uberaba'), findsOneWidget);
    expect(find.text('HOMOLOGACAO'), findsOneWidget);
  });

  testWidgets(
      'NFS-e separa parceiro emissor do tomador e aplica defaults do emissor',
      (tester) async {
    AuthUtility.userInfo = LoginModel(
      login: Login.fromJson({
        'id': 972,
        'empresa': {'id': 1, 'nome': 'Empresa Smoke Test'},
        'parceiro': {
          'id': 1557,
          'nome': 'DAMAIO JOSE MARTINS JUNIOR LTDA',
        },
      }),
    );
    addTearDown(() => AuthUtility.userInfo = null);

    final requisicoes = <Uri>[];
    final client = MockClient((request) async {
      requisicoes.add(request.url);
      if (request.url.path.endsWith('/api/parceiro/1557')) {
        return http.Response('{}', 403);
      }
      if (request.url.path.endsWith('/api/parceiro')) {
        return http.Response(
            jsonEncode({
              'data': {
                'dados': [
                  {
                    'id': 1557,
                    'nome': 'DAMAIO JOSE MARTINS JUNIOR LTDA',
                    'cidade': 'Uberaba',
                    'ambiente': '2 - Homologacao',
                    'endereco': {
                      'cidade': {
                        'id': 10968,
                        'nome': 'Uberaba',
                        'ibge': 3170107
                      }
                    },
                  }
                ]
              }
            }),
            200);
      }
      return http.Response(jsonEncode({'data': []}), 200);
    });

    await http.runWithClient(() async {
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      await tester.pumpWidget(MaterialApp(
        home: NfseDetailScreen(item: const {}),
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
    }, () => client);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final municipioFinder = find.byWidgetPredicate((widget) =>
        widget is SearchableDropdownField && widget.label.contains('Munic'));
    final municipio = tester.widget<SearchableDropdownField>(municipioFinder);
    expect(requisicoes.any((uri) => uri.path.endsWith('/api/parceiro/1557')),
        isTrue);
    expect(requisicoes.any((uri) => uri.path.endsWith('/api/parceiro')), isTrue,
        reason: 'O cadastro completo do tomador deve vir da lista da API');
    expect(municipio.value, '10968');
    expect(find.text('HOMOLOGACAO'), findsOneWidget);
    expect(find.text('Parceiro Emissor'), findsOneWidget);
    expect(find.text('DAMAIO JOSE MARTINS JUNIOR LTDA'), findsOneWidget);
    expect(
        find.byWidgetPredicate((widget) =>
            widget is SearchableDropdownField && widget.label == 'Empresa'),
        findsNothing);
    expect(
        find.byWidgetPredicate((widget) =>
            widget is SearchableDropdownField &&
            widget.label == 'Parceiro Emissor'),
        findsNothing);
    final tomador = tester.widget<SearchableDropdownField>(
      find.byWidgetPredicate((widget) =>
          widget is SearchableDropdownField && widget.label == 'Tomador'),
    );
    expect(tomador.enabled, isTrue);
    expect(tomador.value, isNull);
    expect(find.text('3170107'), findsOneWidget);
  });

  testWidgets('sem parceiro de sessao usa somente empresa como escopo',
      (tester) async {
    AuthUtility.userInfo = LoginModel(
      login: Login(
        id: 972,
        empresa: Empresa(id: 1, nome: 'Empresa Smoke Test'),
      ),
    );
    addTearDown(() => AuthUtility.userInfo = null);
    final requisicoes = <Uri>[];
    final client = MockClient((request) async {
      requisicoes.add(request.url);
      if (request.url.path.endsWith('/api/empresa/1')) {
        return http.Response(
            jsonEncode({
              'data': {
                'id': 1,
                'nome': 'Empresa Smoke Test',
                'ambiente': 'PRODUCAO',
                'cidade': {'id': 31, 'nome': 'Uberaba', 'ibge': 3170107},
              }
            }),
            200);
      }
      return http.Response(jsonEncode({'data': []}), 200);
    });

    await http.runWithClient(() async {
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      await tester.pumpWidget(MaterialApp(
        home: NfseDetailScreen(item: const {}),
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
    }, () => client);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    expect(find.text('Parceiro Emissor'), findsNothing);
    expect(find.text('Empresa Smoke Test'), findsOneWidget);
    expect(find.text('PRODUCAO'), findsOneWidget);
    final tomador = tester.widget<SearchableDropdownField>(
      find.byWidgetPredicate((widget) =>
          widget is SearchableDropdownField && widget.label == 'Tomador'),
    );
    expect(tomador.enabled, isTrue);
    expect(tomador.value, isNull);
    final chamadasDeEscopo = requisicoes.where((uri) =>
        uri.path.endsWith('/api/parceiro') ||
        uri.path.endsWith('/api/nfe-serie') ||
        uri.path.endsWith('/api/produto-contabil'));
    expect(chamadasDeEscopo, isNotEmpty);
    for (final uri in chamadasDeEscopo) {
      expect(uri.queryParameters['empId'], '1');
      expect(uri.queryParameters.containsKey('parceiro'), isFalse);
      expect(uri.queryParameters.containsKey('parceiroId'), isFalse);
      expect(uri.queryParameters.containsKey('parcId'), isFalse);
      expect(uri.queryParameters.containsKey('clienteId'), isFalse);
    }
  });

  test('disponibiliza ações de grade apenas nos estados fiscais válidos', () {
    expect(nfsePodeConfirmarStatus('RASCUNHO'), isTrue);
    expect(nfsePodeConfirmarStatus('PENDENTE'), isTrue);
    expect(nfsePodeConfirmarStatus('AUTORIZADA'), isFalse);
    expect(nfsePodeEnviarStatus('CONFIRMADA'), isTrue);
    expect(nfsePodeEnviarStatus('PENDENTE'), isFalse);
    expect(nfsePodeGerarPdfStatus('AUTORIZADA'), isTrue);
    expect(nfsePodeGerarPdfStatus('REJEITADA'), isFalse);
    expect(nfsePodeCancelarStatus('AUTORIZADA'), isTrue);
    expect(nfsePodeCancelarStatus('CONFIRMADA'), isFalse);
  });

  test('nao inventa municipio ou ambiente quando empresa nao os possui', () {
    final defaults = resolveNfseEmpresaDefaults(const {});

    expect(defaults.municipio, isNull);
    expect(defaults.cidadeId, isNull);
    expect(defaults.ambiente, isNull);
  });
}
