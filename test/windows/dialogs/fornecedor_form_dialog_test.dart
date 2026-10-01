import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/auth_utility.dart';
import 'package:task_manager_flutter/models/empresa_model.dart';
import 'package:task_manager_flutter/models/login_model.dart';
import 'package:task_manager_flutter/models/parceiro_model.dart';
import 'package:task_manager_flutter/windows/dialogs/fornecedor_form_dialog.dart';

void main() {
  setUp(() {
    AuthUtility.userInfo = LoginModel(
      token: 'fake-token',
      login: Login(
        id: 1,
        email: 'test@contabilidade.com',
        nome: 'Usuario Teste',
        empresa: Empresa(id: 10, nome: 'Empresa Matriz Teste'),
        parceiro: Parceiro(id: 200, nome: 'Escritorio Contabil Teste'),
      ),
    );
  });

  tearDown(() {
    AuthUtility.userInfo = null;
    AuthUtility.empresasAcesso = [];
  });

  testWidgets(
      'FornecedorFormDialog exibe vinculo obrigatorio de Empresa e Parceiro e botao Buscar endereco pelo CEP',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    Map<String, dynamic>? payloadSalvo;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FornecedorFormDialog(
            item: const {
              'nome': 'CLIENTE TESTE',
              'razaoSocial': 'CLIENTE TESTE LTDA',
              'cnpj': '10310346000140',
              'cep': '38010-000',
            },
            customSaveHandler: (payload) async {
              payloadSalvo = payload;
              return true;
            },
            onSaved: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verifica título da seção de vínculo obrigatório
    expect(find.text('Vínculo Obrigatório (Empresa e Parceiro) *'), findsOneWidget);

    // 2. Dropdown de Empresa com empresa ativa pré-selecionada
    expect(find.byKey(const Key('dropdown_empresa_fornecedor')), findsOneWidget);
    expect(find.textContaining('10 - Empresa Matriz Teste'), findsOneWidget);

    // 3. Dropdown de Parceiro com parceiro ativo pré-selecionado
    expect(find.byKey(const Key('dropdown_parceiro_fornecedor')), findsOneWidget);
    expect(find.textContaining('200 - Escritorio Contabil Teste'), findsOneWidget);

    // 4. Campo de CEP e botão explícito Buscar endereço pelo CEP
    expect(find.byKey(const Key('input_cep_fornecedor')), findsOneWidget);
    final btnBuscarCep = find.byKey(const Key('btn_buscar_cep_fornecedor'));
    expect(btnBuscarCep, findsOneWidget);
    expect(find.text('Buscar endereço pelo CEP'), findsOneWidget);

    // 5. Salva e valida que empresa e parceiro vinculados constam no payload
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(payloadSalvo, isNotNull);
    expect(payloadSalvo!['empresaId'], 10);
    expect(payloadSalvo!['empresa'], isNotNull);
    expect(payloadSalvo!['empresa']['id'], 10);
    expect(payloadSalvo!['parceiroId'], 200);
    expect(payloadSalvo!['parceiro'], isNotNull);
    expect(payloadSalvo!['parceiro']['id'], 200);
    expect(payloadSalvo!['cnpj'], '10310346000140');
  });

  testWidgets('FornecedorFormDialog bloqueia salvar se nao houver empresa ou parceiro selecionados',
      (tester) async {
    // Sem login pré-definido e sem item prévio
    AuthUtility.userInfo = null;

    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    bool saveChamado = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FornecedorFormDialog(
            customSaveHandler: (payload) async {
              saveChamado = true;
              return true;
            },
            onSaved: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tenta salvar sem preencher nada
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    // Custom save handler NÃO deve ter sido chamado devido à validação
    expect(saveChamado, isFalse);
  });
}
