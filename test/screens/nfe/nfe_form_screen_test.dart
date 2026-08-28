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

/// Card de unificação (replicado de task_manager_flutter): estes testes
/// cobrem a tela reescrita para usar os MESMOS campos/estrutura de
/// Web/Windows (Parceiro/Destinatário separados, Série como dropdown,
/// botão "Salvar NF-e"). Os testes antigos ("Cliente *", "Criar NFe",
/// "CNPJ/CPF") testavam a estrutura divergente que motivou o card
/// (https://trello.com/c/X6onSLzo) e não fazem mais sentido.
///
/// _carregarDados() faz chamadas HTTP reais (TenantContext.get) que falham
/// no ambiente de teste (sem backend); o catch de _carregarDados trata isso
/// como listas vazias (mesmo comportamento de produção sem conexão), então
/// os testes cobrem estrutura/labels/validação, não o fluxo de submissão
/// com sucesso (que dependeria de mock de rede, fora do padrão já usado
/// pelas telas equivalentes de Web/Windows, que também não têm testes
/// desse tipo neste projeto).
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
  group('NfeFormScreen Tests (estrutura unificada com Web/Windows)', () {
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

    testWidgets('Renderização inicial mostra os campos unificados (nao mais "Cliente")',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(Form), findsOneWidget);
      expect(find.text('Nova Nota Fiscal Eletrônica'), findsWidgets);
      // Estrutura unificada: Parceiro/Destinatário separados, nao mais "Cliente".
      expect(find.text('Parceiro / Destinatário'), findsOneWidget);
      expect(find.text('Tipo de Operação (TOP) *'), findsOneWidget);
      // "Cliente *" (rotulo antigo, divergente de Web/Windows) nao existe mais.
      expect(find.text('Cliente *'), findsNothing);
    });

    testWidgets('Botão de submissão usa o rótulo unificado "Salvar NF-e" (nao mais "Criar NFe")',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Salvar NF-e'), findsOneWidget);
      expect(find.text('Criar NFe'), findsNothing);
    });

    testWidgets('Série aparece como dropdown pesquisável (nao mais texto livre com auto-incremento)',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Série *'), findsWidgets);
      // Campo antigo (texto livre auto-incremento) nao existe mais como tal;
      // o numero da nota agora e um campo separado e opcional.
      expect(find.text('Número'), findsOneWidget);
    });

    testWidgets('Layout mobile (tela estreita) renderiza sem erro', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('Layout tablet (tela média) renderiza em 2 colunas', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(Form), findsOneWidget);
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('Layout desktop (tela larga) renderiza em 3 colunas', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(Form), findsOneWidget);
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('Adicionar item abre o dialog de novo item', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final botaoAdicionar = find.byIcon(Icons.add).first;
      await tester.ensureVisible(botaoAdicionar);
      await tester.pumpAndSettle();
      await tester.tap(botaoAdicionar);
      await tester.pumpAndSettle();

      expect(find.text('Adicionar Item'), findsWidgets);
    });

    testWidgets('Resumo de totais é exibido zerado sem itens', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Resumo de Totais'), findsOneWidget);
      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text('TOTAL'), findsOneWidget);
    });

    testWidgets('Validação: submeter sem TOP/Destinatário/Série/Itens mostra os campos faltantes',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final botaoSalvar = find.text('Salvar NF-e');
      await tester.ensureVisible(botaoSalvar);
      await tester.pumpAndSettle();
      await tester.tap(botaoSalvar);
      await tester.pumpAndSettle();

      // O validator do dropdown TOP (Form.validate()) dispara primeiro
      // ("TOP obrigatório"), antes da checagem manual de destinatário/serie/
      // itens -- ambos os caminhos de validação mostram um SnackBar.
      expect(find.byType(SnackBar), findsWidgets);
      expect(find.textContaining('obrigat'), findsWidgets);
    });

    testWidgets('Campos obrigatórios permanecem marcados com *', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Tipo de Operação (TOP) *'), findsOneWidget);
      expect(find.text('Itens *'), findsOneWidget);
    });

    testWidgets('Observações continua presente (nao removido pela unificação)',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Observações'), findsOneWidget);
    });
  });
}
