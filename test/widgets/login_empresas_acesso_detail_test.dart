import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/empresa_acesso_model.dart';
import 'package:task_manager_flutter/widgets/login_empresas_acesso_detail.dart';

void main() {
  testWidgets(
      'detalhe de login mostra acessos aprovados e pendentes e solicita outra empresa',
      (tester) async {
    int? loginSolicitado;
    int? empresaSolicitada;
    int? loginCarregadoParaEmpresas;
    var chamadasDeCarga = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LoginEmpresasAcessoDetail(
            loginId: 42,
            loginTemParceiro: false,
            carregarAcessos: (loginId) async {
              chamadasDeCarga++;
              return [
                const EmpresaAcesso(
                  loginId: 42,
                  empresaId: 1,
                  empresaNome: 'Empresa Smoke Test',
                  status: 'APROVADO',
                  ativa: true,
                ),
                const EmpresaAcesso(
                  id: 9,
                  loginId: 42,
                  empresaId: 2,
                  empresaNome: 'Empresa Pendente',
                  status: 'PENDENTE',
                  ativa: false,
                ),
              ];
            },
            carregarEmpresas: (loginId) async {
              loginCarregadoParaEmpresas = loginId;
              return [
                {'value': 1, 'label': 'Empresa Smoke Test'},
                {'value': 2, 'label': 'Empresa Pendente'},
                {'value': 3, 'label': 'Empresa Nova'},
              ];
            },
            solicitarAcesso: (loginId, empresaId) async {
              loginSolicitado = loginId;
              empresaSolicitada = empresaId;
              return true;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Empresas com acesso'), findsOneWidget);
    expect(find.text('Empresa Smoke Test'), findsOneWidget);
    expect(find.text('Ativa'), findsOneWidget);
    expect(find.text('Aprovado'), findsOneWidget);
    expect(find.text('Empresa Pendente'), findsOneWidget);
    expect(find.text('Pendente'), findsOneWidget);

    await tester.tap(find.byKey(const Key('login-empresa-acesso-solicitar')));
    await tester.pumpAndSettle();

    expect(loginSolicitado, 42);
    expect(loginCarregadoParaEmpresas, 42);
    expect(empresaSolicitada, 3);
    expect(chamadasDeCarga, 2);
  });

  testWidgets('login com parceiro nao libera solicitacao multiempresa',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LoginEmpresasAcessoDetail(
            loginId: 42,
            loginTemParceiro: true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('Login com parceiro vinculado nao usa acesso multi-empresa.'),
      findsOneWidget,
    );
    expect(find.text('Solicitar acesso a outra empresa'), findsNothing);
  });
}
