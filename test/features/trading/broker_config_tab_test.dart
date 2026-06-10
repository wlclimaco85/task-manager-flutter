import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/features/trading/trading_dashboard_screen.dart';
import 'package:task_manager_flutter/features/trading/trading_models.dart';
import 'package:task_manager_flutter/features/trading/trading_repository.dart';
import 'package:task_manager_flutter/models/aplicativo_model.dart';
import 'package:task_manager_flutter/models/auth_utility.dart';
import 'package:task_manager_flutter/models/empresa_model.dart';
import 'package:task_manager_flutter/models/login_model.dart';
import 'package:task_manager_flutter/models/parceiro_model.dart';

class FakeTradingRepository extends TradingRepository {
  FakeTradingRepository({
    this.fetchResult,
    this.fetchError,
    this.saveResult,
    this.saveError,
  });

  final TradingBrokerConfig? fetchResult;
  final Object? fetchError;
  final TradingBrokerConfig? saveResult;
  final Object? saveError;

  int fetchCalls = 0;
  int saveCalls = 0;
  String? savedBrokerLogin;
  String? savedAccountId;
  String? savedAmbientePadrao;
  bool? savedAtivo;
  String? savedBrokerPassword;

  @override
  Future<TradingBrokerConfig?> fetchBrokerConfig() async {
    fetchCalls++;
    if (fetchError != null) throw fetchError!;
    return fetchResult;
  }

  @override
  Future<TradingBrokerConfig> saveBrokerConfig({
    required String brokerLogin,
    required String accountId,
    required String ambientePadrao,
    required bool ativo,
    String? brokerPassword,
  }) async {
    saveCalls++;
    savedBrokerLogin = brokerLogin;
    savedAccountId = accountId;
    savedAmbientePadrao = ambientePadrao;
    savedAtivo = ativo;
    savedBrokerPassword = brokerPassword;

    if (saveError != null) throw saveError!;
    return saveResult ??
        TradingBrokerConfig(
          id: 'fake-id',
          brokerLogin: brokerLogin,
          accountId: accountId,
          ambientePadrao: ambientePadrao,
          ativo: ativo,
          hasBrokerPassword: brokerPassword != null && brokerPassword.isNotEmpty,
          updatedAt: '2026-05-23T12:00:00Z',
        );
  }
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void _mockLoggedUser() {
  AuthUtility.userInfo = LoginModel(
    token: 'token-teste',
    login: Login(
      id: 10,
      empresa: Empresa(id: 321),
      parceiro: Parceiro(id: 77),
      aplicativo: Aplicativo(id: 9),
    ),
  );
}

void main() {
  setUp(_mockLoggedUser);

  tearDown(() {
    AuthUtility.userInfo = null;
  });

  group('BrokerConfigTab', () {
    testWidgets('carrega configuração existente com dados fake', (tester) async {
      final repo = FakeTradingRepository(
        fetchResult: const TradingBrokerConfig(
          id: '1',
          brokerLogin: 'demo-login',
          accountId: '12345',
          ambientePadrao: 'PRODUCAO',
          ativo: false,
          hasBrokerPassword: true,
          updatedAt: '2026-05-23T10:15:00Z',
        ),
      );

      await tester.pumpWidget(_wrap(BrokerConfigTab(repository: repo)));
      await tester.pumpAndSettle();

      expect(repo.fetchCalls, 1);
      expect(find.text('Configuração da Corretora / MT5'), findsOneWidget);
      expect(find.text('demo-login'), findsOneWidget);
      expect(find.text('12345'), findsOneWidget);
      expect(find.text('Nova senha da corretora (opcional)'), findsOneWidget);
      expect(find.textContaining('Senha já cadastrada com segurança no servidor'),
          findsOneWidget);
      expect(find.text('Configuração ativa'), findsOneWidget);
    });

    testWidgets('valida campos obrigatórios antes de salvar', (tester) async {
      final repo = FakeTradingRepository(fetchResult: null);

      await tester.pumpWidget(_wrap(BrokerConfigTab(repository: repo)));
      await tester.pumpAndSettle();

      // Garante que o botão esteja visível antes de tocar
      final salvarBtn = find.byKey(const Key('broker_config_salvar_btn'));
      await tester.ensureVisible(salvarBtn);
      await tester.pumpAndSettle();
      await tester.tap(salvarBtn);
      await tester.pumpAndSettle();

      expect(repo.saveCalls, 0);
      // Mensagens de validação aparecem como texto de erro — podem coexistir com o hintText
      expect(find.text('Informe o login da corretora'), findsAtLeastNWidgets(1));
      expect(find.text('Informe a senha da corretora'), findsAtLeastNWidgets(1));
      expect(find.text('Informe um accountId válido'), findsAtLeastNWidgets(1));
    });

    testWidgets('salva configuração com dados fake e exibe snackbar',
        (tester) async {
      final repo = FakeTradingRepository(
        fetchResult: const TradingBrokerConfig(
          id: '1',
          brokerLogin: 'login-antigo',
          accountId: '555',
          ambientePadrao: 'TESTE',
          ativo: true,
          hasBrokerPassword: true,
          updatedAt: '2026-05-22T10:00:00Z',
        ),
        saveResult: const TradingBrokerConfig(
          id: '2',
          brokerLogin: 'novo-login',
          accountId: '98765',
          ambientePadrao: 'PRODUCAO',
          ativo: false,
          hasBrokerPassword: true,
          updatedAt: '2026-05-23T12:00:00Z',
        ),
      );

      await tester.pumpWidget(_wrap(BrokerConfigTab(repository: repo)));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Login da corretora *'),
          'novo-login');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Nova senha da corretora (opcional)'),
          'senha-fake-123');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Conta / Account ID *'), '98765');

      // Seleciona o ambiente via Key do dropdown
      final dropdown = find.byKey(const Key('broker_config_ambiente_dropdown'));
      await tester.ensureVisible(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      // Seleciona PRODUCAO no menu aberto
      await tester.tap(find.text('PRODUCAO').last);
      await tester.pumpAndSettle();

      // Desativa o switch via Key
      final switchTile = find.byKey(const Key('broker_config_ativo_switch'));
      await tester.ensureVisible(switchTile);
      await tester.pumpAndSettle();
      await tester.tap(switchTile);
      await tester.pumpAndSettle();

      // Salva via Key do botão
      final salvarBtn = find.byKey(const Key('broker_config_salvar_btn'));
      await tester.ensureVisible(salvarBtn);
      await tester.pumpAndSettle();
      await tester.tap(salvarBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(repo.saveCalls, 1);
      expect(repo.savedBrokerLogin, 'novo-login');
      expect(repo.savedAccountId, '98765');
      expect(repo.savedAmbientePadrao, 'PRODUCAO');
      expect(repo.savedAtivo, false);
      expect(repo.savedBrokerPassword, 'senha-fake-123');
      expect(find.text('Configuração da corretora salva com sucesso.'),
          findsOneWidget);
      expect(find.textContaining('Atualizado em: 2026-05-23T12:00:00Z'),
          findsOneWidget);
    });

    testWidgets('exibe erro de carregamento quando fetch falha', (tester) async {
      final repo = FakeTradingRepository(fetchError: Exception('falha fake'));

      await tester.pumpWidget(_wrap(BrokerConfigTab(repository: repo)));
      await tester.pumpAndSettle();

      expect(find.textContaining('falha fake'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
    });
  });
}
