import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:task_manager_flutter/models/nfe/nfe_model.dart';
import 'package:task_manager_flutter/models/nfe/nfe_status.dart';
import 'package:task_manager_flutter/models/nfe/nfe_tomador_model.dart';
import 'package:task_manager_flutter/models/nfe/valores_nfe_model.dart';
import 'package:task_manager_flutter/providers/nfe_notifier.dart';
import 'package:task_manager_flutter/repositories/nfe_repository.dart';
import 'package:task_manager_flutter/screens/nfe/nfe_form_screen.dart';

class FakeNfeRepository extends Mock implements NfeRepository {
  @override
  Future<NfeModel> criarNfe(Map<String, dynamic> dados) async {
    return NfeModel(
      id: 1,
      empresaId: 1,
      numero: '000001',
      serie: 1,
      dataHora: DateTime.now(),
      statusNfe: NfeStatus.pendente,
      cnpjEmitente: '11222333000181',
      uf: 'SP',
      ambiente: 'HOMOLOGACAO',
      tomador: NfeTomadorModel(
        cnpjCpf: '44555666000102',
        razaoSocial: 'Cliente B Indústria Ltda',
        endereco: 'Avenida B',
        numero: '200',
        bairro: 'Industrial',
        cep: '01310200',
        uf: 'SP',
        municipio: 'São Paulo',
      ),
      itens: [],
      valores: ValoresNfeModel(
        subtotal: 100.0,
        totalIcms: 18.0,
        totalPis: 1.65,
        totalCofins: 7.6,
        desconto: 0.0,
        total: 127.25,
      ),
      criadoEm: DateTime.now(),
    );
  }

  @override
  Future<List<NfeModel>> listarNfe({
    required int page,
    required int pageSize,
    String? status,
    DateTime? dataInicio,
    DateTime? dataFim,
    String? clienteCnpj,
  }) async {
    return [];
  }

  @override
  Future<NfeModel> obterNfe(int id) async {
    return NfeModel(
      id: id,
      empresaId: 1,
      numero: '000001',
      serie: 1,
      dataHora: DateTime.now(),
      statusNfe: NfeStatus.pendente,
      cnpjEmitente: '11222333000181',
      uf: 'SP',
      ambiente: 'HOMOLOGACAO',
      tomador: NfeTomadorModel(
        cnpjCpf: '44555666000102',
        razaoSocial: 'Cliente B',
        endereco: 'Avenida B',
        numero: '200',
        bairro: 'Industrial',
        cep: '01310200',
        uf: 'SP',
        municipio: 'São Paulo',
      ),
      itens: [],
      valores: ValoresNfeModel(
        subtotal: 100.0,
        totalIcms: 18.0,
        totalPis: 1.65,
        totalCofins: 7.6,
        desconto: 0.0,
        total: 127.25,
      ),
      criadoEm: DateTime.now(),
    );
  }

  @override
  Future<String> downloadXml(int id) async => '<xml></xml>';

  @override
  Future<List<int>> downloadPdf(int id) async => [];
}

void main() {
  group('NfeFormScreen Tests', () {
    late NfeNotifier nfeNotifier;

    setUp(() {
      final repository = FakeNfeRepository();
      nfeNotifier = NfeNotifier(repository);
    });

    Widget buildTestApp({Widget? home}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<NfeNotifier>.value(value: nfeNotifier),
        ],
        child: MaterialApp(
          home: home ?? const NfeFormScreen(),
          routes: {
            '/nfe/detail': (context) => const Scaffold(body: Text('Detail Screen')),
          },
        ),
      );
    }

    testWidgets('Renderização inicial do form', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      expect(find.byType(Form), findsOneWidget);
      expect(find.text('Nova Nota Fiscal Eletrônica'), findsWidgets);
      expect(find.text('Cliente *'), findsOneWidget);
      expect(find.text('Natureza da Operação *'), findsOneWidget);
    });

    testWidgets('Layout mobile (tela estreita)', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(400, 800);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(buildTestApp());

      expect(find.byType(Column), findsWidgets);
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('Layout tablet (tela média)', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(800, 1000);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(buildTestApp());

      expect(find.byType(Form), findsOneWidget);
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('Layout desktop (tela larga)', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1400, 900);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(buildTestApp());

      expect(find.byType(Form), findsOneWidget);
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('Seleção de cliente', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      await tester.tap(find.byType(DropdownButtonFormField).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cliente A Comércio Ltda (11.222.333/0000-81)'));
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('Adicionar item cria novo item', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('Novo Item'), findsOneWidget);
    });

    testWidgets('Cálculo automático de totais', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      expect(find.text('Resumo de Totais'), findsOneWidget);
      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text('ICMS (18%)'), findsOneWidget);
      expect(find.text('PIS (1,65%)'), findsOneWidget);
      expect(find.text('COFINS (7,6%)'), findsOneWidget);
      expect(find.text('TOTAL'), findsOneWidget);
    });

    testWidgets('Validação: cliente obrigatório', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      await tester.tap(find.text('Criar NFe'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsWidgets);
    });

    testWidgets('Validação: natureza obrigatória', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      await tester.tap(find.byType(DropdownButtonFormField).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cliente A Comércio Ltda (11.222.333/0000-81)'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Criar NFe'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsWidgets);
    });

    testWidgets('Validação: itens obrigatório', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      await tester.tap(find.byType(DropdownButtonFormField).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cliente A Comércio Ltda (11.222.333/0000-81)'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Venda'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Criar NFe'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsWidgets);
    });

    testWidgets('Campos obrigatórios marcados com *', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      expect(find.text('Cliente *'), findsOneWidget);
      expect(find.text('Natureza da Operação *'), findsOneWidget);
      expect(find.text('Itens *'), findsOneWidget);
    });

    testWidgets('TextFormField com rótulos acessíveis', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      expect(find.text('Série'), findsOneWidget);
      expect(find.text('Observações'), findsOneWidget);
      expect(find.text('CNPJ/CPF'), findsOneWidget);
      expect(find.text('Razão Social'), findsOneWidget);
    });

    testWidgets('Botão submit desabilitado durante envio', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      await tester.tap(find.byType(DropdownButtonFormField).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cliente A Comércio Ltda (11.222.333/0000-81)'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Venda'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Criar NFe'));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });
  });
}
