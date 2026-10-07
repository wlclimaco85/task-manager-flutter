import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_manager_flutter/customization/dynamic_grid_windows_screen.dart';
import 'package:task_manager_flutter/models/auth_utility.dart';
import 'package:task_manager_flutter/web/screens/details/nfse_detail_screen.dart';

/// Pedido do usuario (2026-10-07): editar o item da NFS-e no proprio espaco da grid,
/// nunca no popup generico "Editar item".
void main() {
  testWidgets(
      'grid de itens nao oferece edicao em popup e o clique na linha abre o formulario no painel',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    AuthUtility.userInfo = null;

    final client = MockClient((request) async {
      if (request.method == 'GET' && request.url.path.endsWith('/api/nfse_item')) {
        return http.Response(
            jsonEncode({
              'data': {
                'dados': [
                  {
                    'id': 3,
                    'descricao': 'Servico contabilidade',
                    'quantidade': 1,
                    'valorUnitario': 810,
                    'valorTotal': 810,
                    'aliquotaIss': 2,
                    'valorIss': 16.2,
                  }
                ]
              }
            }),
            200);
      }
      return http.Response(jsonEncode({'data': []}), 200);
    });

    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(
        home: NfseDetailScreen(item: {'id': 3, 'status': 'CONFIRMADA'}),
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      final grid = tester.widget<DynamicGridWindowsScreen<Map<String, dynamic>>>(
        find.byWidgetPredicate((w) =>
            w is DynamicGridWindowsScreen<Map<String, dynamic>> &&
            w.telaNome == 'nfse_item'),
      );

      // Sem popup: nem criar nem editar pelo dialog generico.
      expect(grid.hasPermission('edit'), isFalse);
      expect(grid.hasPermission('create'), isFalse);
      expect(grid.hasPermission('delete'), isTrue);
      expect(grid.onItemTap, isNotNull);
      expect(find.text('Produto (Serviço)'), findsNothing);

      // Clique na linha -> formulario do item no proprio painel.
      grid.onItemTap!({'id': 3}, tester.element(find.byType(NfseDetailScreen)));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      // Aviso conhecido de ListTile sem Material (so' em teste), igual aos outros testes da tela.
      final aviso = tester.takeException();
      if (aviso != null) {
        expect(aviso.toString(),
            contains('ListTile background color or ink splashes may be invisible'));
      }

      expect(find.text('Produto (Serviço)'), findsWidgets);
      expect(find.byType(Dialog), findsNothing);

      await tester.pump(const Duration(seconds: 2));
    }, () => client);
  });
}
