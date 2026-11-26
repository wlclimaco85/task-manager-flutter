import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_manager_flutter/auth_screens/login_modulos_publicos.dart';
import 'package:task_manager_flutter/auth_screens/login_screen.dart';

void main() {
  test('usa so o que o servidor devolve, sem nome repetido', () async {
    final client = MockClient((_) async => http.Response.bytes(
        utf8.encode(jsonEncode([
          {'nome': 'Comercial', 'descricao': 'Vendas'},
          {'nome': 'comercial ', 'descricao': 'Pedidos'},
          {'nome': 'Transporte', 'descricao': 'MDF-e'},
        ])),
        200));
    final lista = await carregarModulosPublicos(client: client);
    expect(lista.map((m) => m.nome), ['Comercial', 'Transporte']);
  });

  test('erro do servidor nao mostra modulo nenhum', () async {
    expect(await carregarModulosPublicos(client: MockClient((_) async => http.Response('x', 500))), isEmpty);
  });

  testWidgets('login mostra apenas os modulos carregados; sem modulos esconde a secao', (t) async {
    t.view.physicalSize = const Size(1280, 900);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    await t.pumpWidget(MaterialApp(
        home: LoginScreen(carregarModulos: () async => const [ModuloPublico('Transporte', 'MDF-e')])));
    await t.pump(const Duration(seconds: 1));
    expect(find.text('Transporte'), findsOneWidget);
    expect(find.text('GME'), findsNothing);
    expect(find.text('Projetos'), findsNothing);

    await t.pumpWidget(const SizedBox.shrink());
    await t.pumpWidget(MaterialApp(home: LoginScreen(carregarModulos: () async => const [])));
    await t.pump(const Duration(seconds: 1));
    expect(find.text('Módulos que podem ser contratados'), findsNothing);
    await t.pumpWidget(const SizedBox.shrink());
  });
}
