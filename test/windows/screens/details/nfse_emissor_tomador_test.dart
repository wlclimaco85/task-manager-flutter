import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_manager_flutter/models/auth_utility.dart';
import 'package:task_manager_flutter/models/login_model.dart';
import 'package:task_manager_flutter/widgets/searchable_dropdown.dart';
import 'package:task_manager_flutter/windows/screens/details/nfse_detail_screen.dart';

void main() {
  testWidgets('Windows separa emissor do tomador e carrega defaults do emissor',
      (tester) async {
    AuthUtility.userInfo = LoginModel(
      login: Login.fromJson({
        'id': 972,
        'empresa': {'id': 20005, 'nome': 'Abraco Contabilidade'},
        'parceiro': {
          'id': 1557,
          'nome': 'DAMAIO JOSE MARTINS JUNIOR LTDA',
        },
      }),
    );
    addTearDown(() => AuthUtility.userInfo = null);

    final requests = <Uri>[];
    final client = MockClient((request) async {
      requests.add(request.url);
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
                        'ibge': 3170107,
                      }
                    },
                  },
                  {'id': 1808, 'nome': 'Tomador de teste', 'cpf': '123'},
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

    expect(
        requests.any((uri) => uri.path.endsWith('/api/parceiro/1557')), isTrue);
    final municipio = tester.widget<SearchableDropdownField>(
      find.byWidgetPredicate((widget) =>
          widget is SearchableDropdownField && widget.label.contains('Munic')),
    );
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
    expect(tomador.items.any((item) => item['id'] == '1808'), isTrue);
    expect(
      tester
          .widgetList<TextFormField>(find.byType(TextFormField))
          .any((field) => field.controller?.text == '3170107'),
      isTrue,
    );
  });
}
