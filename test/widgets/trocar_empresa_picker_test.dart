// test/widgets/trocar_empresa_picker_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_manager_flutter/services/login_empresa_acesso_caller.dart';
import 'package:task_manager_flutter/widgets/trocar_empresa_picker.dart';

void main() {
  final originalClient = LoginEmpresaAcessoCaller.client;

  tearDown(() {
    LoginEmpresaAcessoCaller.client = originalClient;
  });

  Widget harness(Widget Function(BuildContext) builder) {
    return MaterialApp(
      home: Builder(builder: (context) => Scaffold(body: builder(context))),
    );
  }

  testWidgets(
      '(a) <=1 empresa aprovada NAO abre o picker — mostrarSeNecessario retorna null sem exibir dialog',
      (tester) async {
    int? resultado;
    late BuildContext capturedContext;

    await tester.pumpWidget(harness((context) {
      capturedContext = context;
      return const SizedBox.shrink();
    }));

    resultado = await TrocarEmpresaPicker.mostrarSeNecessario(
      capturedContext,
      [EmpresaAcessoOption(empresaId: 1, nome: 'Empresa Unica', status: 'APROVADO')],
      empresaAtualId: 1,
    );
    await tester.pumpAndSettle();

    expect(resultado, isNull);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets(
      '(a) lista vazia tambem NAO abre o picker',
      (tester) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(harness((context) {
      capturedContext = context;
      return const SizedBox.shrink();
    }));

    final resultado = await TrocarEmpresaPicker.mostrarSeNecessario(
      capturedContext,
      const [],
      empresaAtualId: 1,
    );
    await tester.pumpAndSettle();

    expect(resultado, isNull);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets(
      '(b) >1 empresa aprovada abre o picker, permite escolher e chama o caller',
      (tester) async {
    LoginEmpresaAcessoCaller.client = MockClient((request) async {
      expect(request.method, 'PUT');
      return http.Response('', 200);
    });

    late BuildContext capturedContext;
    await tester.pumpWidget(harness((context) {
      capturedContext = context;
      return const SizedBox.shrink();
    }));

    final empresas = [
      EmpresaAcessoOption(empresaId: 1, nome: 'Empresa A', status: 'APROVADO'),
      EmpresaAcessoOption(empresaId: 2, nome: 'Empresa B', status: 'APROVADO'),
    ];

    final future = TrocarEmpresaPicker.mostrarSeNecessario(
      capturedContext,
      empresas,
      empresaAtualId: 1,
    );
    await tester.pumpAndSettle();

    // Dialog deve estar visivel com o dropdown de selecao.
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byKey(const Key('trocar_empresa_dropdown')), findsOneWidget);

    // Seleciona a Empresa B (diferente da atual) no dropdown.
    await tester.tap(find.byKey(const Key('trocar_empresa_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Empresa B').last);
    await tester.pumpAndSettle();

    // Confirma a troca.
    await tester.tap(find.text('Acessar'));
    await tester.pumpAndSettle();

    final resultado = await future;
    expect(resultado, 2);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('(b) erro do backend mantem o dialog aberto com mensagem',
      (tester) async {
    LoginEmpresaAcessoCaller.client = MockClient((request) async {
      return http.Response('erro', 403);
    });

    late BuildContext capturedContext;
    await tester.pumpWidget(harness((context) {
      capturedContext = context;
      return const SizedBox.shrink();
    }));

    final empresas = [
      EmpresaAcessoOption(empresaId: 1, nome: 'Empresa A', status: 'APROVADO'),
      EmpresaAcessoOption(empresaId: 2, nome: 'Empresa B', status: 'APROVADO'),
    ];

    // Nao aguardamos o future aqui de proposito — so queremos observar o
    // estado do dialog apos a tentativa de troca falhar.
    // ignore: unawaited_futures
    TrocarEmpresaPicker.mostrarSeNecessario(
      capturedContext,
      empresas,
      empresaAtualId: 1,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('trocar_empresa_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Empresa B').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Acessar'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
  });
}
