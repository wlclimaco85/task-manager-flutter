import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/defaults_importacao_empresa_model.dart';
import 'package:task_manager_flutter/services/defaults_importacao_service.dart';
import 'package:task_manager_flutter/web/screens/defaults_importacao_screen.dart';

/// Fake que substitui as chamadas HTTP reais por dados em memória — evita
/// depender de rede/TenantContext nos testes de widget.
class _FakeDefaultsImportacaoService implements DefaultsImportacaoService {
  final List<Map<String, dynamic>> empresasFake;
  final Map<int, DefaultsImportacaoEmpresa> defaultsPorEmpresa;
  final bool falharBusca;
  final bool falharSalvar;
  DefaultsImportacaoEmpresa? ultimoSalvo;
  int? ultimaEmpresaSalva;

  _FakeDefaultsImportacaoService({
    required this.empresasFake,
    this.defaultsPorEmpresa = const {},
    this.falharBusca = false,
    this.falharSalvar = false,
  });

  @override
  Future<List<Map<String, dynamic>>> empresas() async => empresasFake;

  @override
  Future<DefaultsImportacaoEmpresa> buscar(int empresaId) async {
    if (falharBusca) {
      throw const DefaultsImportacaoException('erro ao buscar',
          statusCode: 500);
    }
    return defaultsPorEmpresa[empresaId] ??
        DefaultsImportacaoEmpresa.vazio(empresaId);
  }

  @override
  Future<DefaultsImportacaoEmpresa> salvar(
      int empresaId, DefaultsImportacaoEmpresa dados) async {
    if (falharSalvar) {
      throw const DefaultsImportacaoException('erro ao salvar',
          statusCode: 500);
    }
    ultimaEmpresaSalva = empresaId;
    ultimoSalvo = dados;
    return dados.copyWith(empresaId: empresaId);
  }

  @override
  Future<List<Map<String, dynamic>>> contasBancarias(String? empresaId) async => [
        {'id': '10', 'nome': 'Conta Corrente Principal'},
      ];

  @override
  Future<List<Map<String, dynamic>>> contasCaixa(String? empresaId) async => [
        {'id': '20', 'nome': 'Caixa Loja'},
      ];

  @override
  Future<List<Map<String, dynamic>>> centrosCusto(String? empresaId) async => [
        {'id': '30', 'nome': 'Administrativo'},
      ];
}

Widget _wrap(DefaultsImportacaoService service) {
  return MaterialApp(home: DefaultsImportacaoScreen(service: service));
}

void main() {
  group('DefaultsImportacaoScreen', () {
    testWidgets('abre a tela e mostra o seletor de empresa', (tester) async {
      final service = _FakeDefaultsImportacaoService(empresasFake: [
        {'id': '1', 'nome': 'Empresa A'},
        {'id': '2', 'nome': 'Empresa B'},
      ]);

      await tester.pumpWidget(_wrap(service));
      await tester.pumpAndSettle();

      expect(find.text('Defaults de Importação'), findsOneWidget);
      expect(find.byKey(const Key('defaults_importacao_empresa')),
          findsOneWidget);
      // Sem empresa selecionada ainda -> pede para escolher, sem mostrar form.
      expect(
          find.text(
              'Selecione uma empresa para configurar os defaults de importação.'),
          findsOneWidget);
      expect(find.byKey(const Key('defaults_importacao_salvar')), findsNothing);
    });

    testWidgets(
        'selecionar empresa carrega os dropdowns e o toggle de baixa automática',
        (tester) async {
      final service = _FakeDefaultsImportacaoService(empresasFake: [
        {'id': '1', 'nome': 'Empresa A'},
      ], defaultsPorEmpresa: {
        1: const DefaultsImportacaoEmpresa(
          empresaId: 1,
          contaBancariaId: 10,
          contaBancariaNome: 'Conta Corrente Principal',
          baixarAutomaticoNoVencimento: true,
        ),
      });

      await tester.pumpWidget(_wrap(service));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('defaults_importacao_empresa')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Empresa A').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('defaults_importacao_conta_bancaria')),
          findsOneWidget);
      expect(find.byKey(const Key('defaults_importacao_conta_caixa')),
          findsOneWidget);
      expect(find.byKey(const Key('defaults_importacao_centro_custo')),
          findsOneWidget);

      final toggle = tester.widget<SwitchListTile>(
          find.byKey(const Key('defaults_importacao_baixar_automatico')));
      expect(toggle.value, isTrue);
    });

    testWidgets('salvar com sucesso chama o service e mostra confirmação',
        (tester) async {
      final service = _FakeDefaultsImportacaoService(empresasFake: [
        {'id': '1', 'nome': 'Empresa A'},
      ]);

      await tester.pumpWidget(_wrap(service));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('defaults_importacao_empresa')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Empresa A').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('defaults_importacao_salvar')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(service.ultimaEmpresaSalva, 1);
      expect(find.text('Defaults de importação salvos com sucesso.'),
          findsOneWidget);
    });

    testWidgets('erro ao carregar empresas mostra mensagem de erro',
        (tester) async {
      final service = _ServicoQueFalhaAoListarEmpresas();

      await tester.pumpWidget(_wrap(service));
      await tester.pumpAndSettle();

      expect(find.textContaining('Falha ao carregar empresas'), findsOneWidget);
    });

    testWidgets('erro ao salvar mostra mensagem sem quebrar a tela',
        (tester) async {
      final service = _FakeDefaultsImportacaoService(empresasFake: [
        {'id': '1', 'nome': 'Empresa A'},
      ], falharSalvar: true);

      await tester.pumpWidget(_wrap(service));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('defaults_importacao_empresa')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Empresa A').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('defaults_importacao_salvar')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.textContaining('Falha ao salvar'), findsOneWidget);
      // Continua funcional -- botao de salvar segue disponivel.
      expect(find.byKey(const Key('defaults_importacao_salvar')), findsOneWidget);
    });
  });
}

class _ServicoQueFalhaAoListarEmpresas implements DefaultsImportacaoService {
  @override
  Future<List<Map<String, dynamic>>> empresas() async {
    throw Exception('rede indisponível');
  }

  @override
  Future<DefaultsImportacaoEmpresa> buscar(int empresaId) =>
      throw UnimplementedError();

  @override
  Future<DefaultsImportacaoEmpresa> salvar(
          int empresaId, DefaultsImportacaoEmpresa dados) =>
      throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> contasBancarias(String? empresaId) =>
      throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> contasCaixa(String? empresaId) =>
      throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> centrosCusto(String? empresaId) =>
      throw UnimplementedError();
}
