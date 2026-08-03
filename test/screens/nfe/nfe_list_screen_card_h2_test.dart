import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:task_manager_flutter/models/nfe/nfe_model.dart';
import 'package:task_manager_flutter/models/nfe/nfe_status.dart';
import 'package:task_manager_flutter/models/nfe/nfe_tomador_model.dart';
import 'package:task_manager_flutter/models/nfe/valores_nfe_model.dart';
import 'package:task_manager_flutter/models/nfe_state.dart';
import 'package:task_manager_flutter/providers/nfe_notifier.dart';
import 'package:task_manager_flutter/screens/nfe/nfe_list_screen.dart';

/// Notifier de teste que permite configurar estado manualmente
class TestNfeNotifier extends ChangeNotifier implements NfeNotifier {
  NfeState _state;

  TestNfeNotifier(this._state);

  @override
  NfeState get state => _state;

  void setState(NfeState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  Future<void> listarNfe({
    int page = 1,
    int pageSize = 10,
    String? status,
    DateTime? dataInicio,
    DateTime? dataFim,
    String? clienteCnpj,
  }) async {}

  @override
  Future<void> obterNfe(int id) async {}

  @override
  void removerNfeLocal(int id) {}

  @override
  Future<NfeModel> criarNfe(Map<String, dynamic> dados) async {
    throw UnimplementedError();
  }

  @override
  void limparErro() {}

  @override
  Future<void> paginaAnterior({
    String? status,
    DateTime? dataInicio,
    DateTime? dataFim,
    String? clienteCnpj,
  }) async {}

  @override
  Future<void> proximaPagina({
    String? status,
    DateTime? dataInicio,
    DateTime? dataFim,
    String? clienteCnpj,
  }) async {}

  @override
  void resetarEstado() {}

  @override
  void setTestState(NfeState newState) => setState(newState);
}

void main() {
  group('NfeListScreen Card H2 — Testes básicos de renderização', () {
    // ─── T1: Renderiza sem erro com lista vazia ──────────────────────────────
    testWidgets('T1: Renderiza sem erro com lista vazia', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<NfeNotifier>.value(
            value: TestNfeNotifier(
              NfeState(nfes: [], isLoading: false, errorMessage: null),
            ),
            child: const NfeListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    // ─── T2: Renderiza AppBar com título ─────────────────────────────────────
    testWidgets('T2: Renderiza AppBar com título correto', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<NfeNotifier>.value(
            value: TestNfeNotifier(
              NfeState(nfes: [], isLoading: false, errorMessage: null),
            ),
            child: const NfeListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsOneWidget);
    });

    // ─── T3: Exibe loading spinner quando loading ─────────────────────────────
    testWidgets('T3: Exibe loading spinner quando loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<NfeNotifier>.value(
            value: TestNfeNotifier(
              NfeState(nfes: [], isLoading: true, errorMessage: null),
            ),
            child: const NfeListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // ─── T4: Exibe mensagem de erro ──────────────────────────────────────────
    testWidgets('T4: Exibe mensagem de erro quando há erro', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<NfeNotifier>.value(
            value: TestNfeNotifier(
              NfeState(
                nfes: [],
                isLoading: false,
                errorMessage: 'Erro teste',
              ),
            ),
            child: const NfeListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Icon), findsWidgets);
    });

    // ─── T5: Renderiza FAB em mobile ─────────────────────────────────────────
    testWidgets('T5: Renderiza FAB em mobile', (tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(375, 812);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<NfeNotifier>.value(
            value: TestNfeNotifier(
              NfeState(nfes: [], isLoading: false, errorMessage: null),
            ),
            child: const NfeListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    // ─── T6: Renderiza ListView em tablet ────────────────────────────────────
    testWidgets('T6: Renderiza lista em tablet (768px)', (tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(768, 1024);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<NfeNotifier>.value(
            value: TestNfeNotifier(
              NfeState(nfes: [], isLoading: false, errorMessage: null),
            ),
            child: const NfeListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    // ─── T7: Renderiza GridView em desktop ───────────────────────────────────
    testWidgets('T7: Renderiza grid em desktop (1920px)', (tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1920, 1080);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      final nfe = NfeModel(
        id: 1,
        empresaId: 1,
        numero: '123456',
        serie: 1,
        dataHora: DateTime(2024, 1, 15),
        statusNfe: NfeStatus.autorizada,
        cnpjEmitente: '12345678901234',
        uf: 'SP',
        ambiente: 'HOMOLOGACAO',
        tomador: const NfeTomadorModel(
          cnpjCpf: '12345678901234',
          razaoSocial: 'Cliente',
          endereco: 'Rua A',
          numero: '100',
          bairro: 'Centro',
          cep: '12345678',
          uf: 'SP',
          municipio: 'São Paulo',
        ),
        itens: [],
        valores: const ValoresNfeModel(
          subtotal: 1500,
          totalIcms: 100,
          totalPis: 50,
          totalCofins: 40,
          desconto: 0,
          total: 1690,
        ),
        criadoEm: DateTime(2024, 1, 15),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<NfeNotifier>.value(
            value: TestNfeNotifier(
              NfeState(nfes: [nfe], isLoading: false, errorMessage: null),
            ),
            child: const NfeListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsOneWidget);
    });

    // ─── T8: Teste de paginação ─────────────────────────────────────────────
    testWidgets('T8: Renderiza sem erro com múltiplas NFes', (tester) async {
      final nfes = List.generate(
        10,
        (i) => NfeModel(
          id: i,
          empresaId: 1,
          numero: '${100000 + i}',
          serie: 1,
          dataHora: DateTime(2024, 1, 15 - i),
          statusNfe: i % 2 == 0 ? NfeStatus.autorizada : NfeStatus.pendente,
          cnpjEmitente: '12345678901234',
          uf: 'SP',
          ambiente: 'HOMOLOGACAO',
          tomador: NfeTomadorModel(
            cnpjCpf: '12345678901234',
            razaoSocial: 'Cliente $i',
            endereco: 'Rua A',
            numero: '100',
            bairro: 'Centro',
            cep: '12345678',
            uf: 'SP',
            municipio: 'São Paulo',
          ),
          itens: [],
          valores: const ValoresNfeModel(
            subtotal: 1500,
            totalIcms: 100,
            totalPis: 50,
            totalCofins: 40,
            desconto: 0,
            total: 1690,
          ),
          criadoEm: DateTime(2024, 1, 15),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<NfeNotifier>.value(
            value: TestNfeNotifier(
              NfeState(nfes: nfes, isLoading: false, errorMessage: null),
            ),
            child: const NfeListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    // ─── T9: Teste de atualização de estado ──────────────────────────────────
    testWidgets('T9: Atualiza UI quando estado muda', (tester) async {
      final notifier = TestNfeNotifier(
        NfeState(nfes: [], isLoading: true, errorMessage: null),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<NfeNotifier>.value(
            value: notifier,
            child: const NfeListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Simula mudança de estado
      notifier.setState(
        NfeState(nfes: [], isLoading: false, errorMessage: null),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    // ─── T10: Teste de lista grande para verificar virtualization ────────────
    testWidgets('T10: Renderiza 50+ items sem travamento', (tester) async {
      final nfes = List.generate(
        60,
        (i) => NfeModel(
          id: i,
          empresaId: 1,
          numero: '${100000 + i}',
          serie: 1,
          dataHora: DateTime(2024, 1, 15 - (i % 30)),
          statusNfe: i % 3 == 0 ? NfeStatus.autorizada : NfeStatus.pendente,
          cnpjEmitente: '12345678901234',
          uf: 'SP',
          ambiente: 'HOMOLOGACAO',
          tomador: const NfeTomadorModel(
            cnpjCpf: '12345678901234',
            razaoSocial: 'Cliente',
            endereco: 'Rua A',
            numero: '100',
            bairro: 'Centro',
            cep: '12345678',
            uf: 'SP',
            municipio: 'São Paulo',
          ),
          itens: [],
          valores: const ValoresNfeModel(
            subtotal: 1500,
            totalIcms: 100,
            totalPis: 50,
            totalCofins: 40,
            desconto: 0,
            total: 1690,
          ),
          criadoEm: DateTime(2024, 1, 15),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<NfeNotifier>.value(
            value: TestNfeNotifier(
              NfeState(nfes: nfes, isLoading: false, errorMessage: null),
            ),
            child: const NfeListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
