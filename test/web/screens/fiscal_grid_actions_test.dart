import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/customization/dynamic_grid_windows_screen.dart';
import 'package:task_manager_flutter/models/nfce_model.dart';
import 'package:task_manager_flutter/web/screens/nfce_grid_screen.dart';
import 'package:task_manager_flutter/web/screens/nfe_grid_screen.dart';
import 'package:task_manager_flutter/web/screens/nfse_screen.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  void ignoreKnownFilterOverflow() {
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      final message = details.exceptionAsString();
      if (message.contains('A RenderFlex overflowed')) return;
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);
  }

  Future<void> setWideSurface(WidgetTester tester) async {
    ignoreKnownFilterOverflow();
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('NF-e saida exposes fiscal row actions and bulk actions with status check', (tester) async {
    await setWideSurface(tester);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: WebNfeGridScreen(entrada: false))),
    );
    await tester.pump();

    final grid = tester.widget<DynamicGridWindowsScreen<Map<String, dynamic>>>(
      find.byType(DynamicGridWindowsScreen<Map<String, dynamic>>),
    );

    // Header buttons
    expect(find.byIcon(Icons.help_outline), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(find.byIcon(Icons.download), findsOneWidget);

    // Custom Actions
    expect(
      grid.customActions!().map((a) => a.label),
      containsAllInOrder([
        'Consultar status',
        'Emitir',
        'Cancelar',
        'Carta de Correção',
        'Histórico de eventos',
        'Imprimir DANFE',
        'Exportar XML',
      ]),
    );

    // Bulk Actions
    final bulk = grid.bulkActions!;
    expect(bulk.map((b) => b.label), [
      'Gerar PDF',
      'Enviar',
      'Cancelar',
      'Baixar XML',
    ]);

    // Status Validation on Bulk Actions
    final cancelAction = bulk.firstWhere((b) => b.label == 'Cancelar');
    final emitirAction = bulk.firstWhere((b) => b.label == 'Enviar');

    // Cancel only allowed if ALL are AUTORIZADA
    expect(cancelAction.isEnabled!([{'status': 'AUTORIZADA'}]), isTrue);
    expect(cancelAction.isEnabled!([{'status': 'PENDENTE'}]), isFalse);
    expect(cancelAction.isEnabled!([{'status': 'AUTORIZADA'}, {'status': 'CANCELADA'}]), isFalse);

    // Enviar allowed only for unissued/rejected
    expect(emitirAction.isEnabled!([{'status': 'PENDENTE'}]), isTrue);
    expect(emitirAction.isEnabled!([{'status': 'REJEITADA'}]), isTrue);
    expect(emitirAction.isEnabled!([{'status': 'AUTORIZADA'}]), isFalse);
    expect(emitirAction.isEnabled!([{'status': 'CANCELADA'}]), isFalse);

    // Drena eventuais timers de rede/log assíncronos
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('NF-e entrada exposes fiscal row actions and bulk actions with status check', (tester) async {
    await setWideSurface(tester);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: WebNfeGridScreen(entrada: true))),
    );
    await tester.pump();

    final grid = tester.widget<DynamicGridWindowsScreen<Map<String, dynamic>>>(
      find.byType(DynamicGridWindowsScreen<Map<String, dynamic>>),
    );

    // Header buttons
    expect(find.byIcon(Icons.help_outline), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(find.byIcon(Icons.download), findsOneWidget);

    // Custom Actions
    expect(
      grid.customActions!().map((a) => a.label),
      containsAllInOrder([
        'Consultar status',
        'Importar XML',
        'Aceitar',
        'Recusar',
        'DANFE',
        'XML',
      ]),
    );

    // Bulk Actions for Entrada
    final bulk = grid.bulkActions!;
    expect(bulk.map((b) => b.label), [
      'Aceitar',
      'Recusar',
      'Gerar PDF',
      'Baixar XML',
    ]);

    final aceitarAction = bulk.firstWhere((b) => b.label == 'Aceitar');
    final recusarAction = bulk.firstWhere((b) => b.label == 'Recusar');

    expect(aceitarAction.isEnabled!([{'status': 'PENDENTE'}]), isTrue);
    expect(aceitarAction.isEnabled!([{'status': 'CANCELADA'}]), isFalse);
    expect(recusarAction.isEnabled!([{'status': 'CRIADA'}]), isTrue);
    expect(recusarAction.isEnabled!([{'status': 'ACEITA'}]), isFalse);

    // Drena eventuais timers de rede/log assíncronos
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('NFS-e exposes fiscal row actions and header buttons', (tester) async {
    await setWideSurface(tester);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: NfseScreen())),
    );
    await tester.pump();

    final grid = tester.widget<DynamicGridWindowsScreen<Map<String, dynamic>>>(
      find.byType(DynamicGridWindowsScreen<Map<String, dynamic>>),
    );

    // Header buttons
    expect(find.byIcon(Icons.help_outline), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(find.byIcon(Icons.download), findsOneWidget);

    // Custom Actions
    expect(
      grid.customActions!().map((a) => a.label),
      containsAllInOrder([
        'Consultar status',
        'Cancelar',
        'Auditoria',
      ]),
    );

    // Bulk Actions
    final bulk = grid.bulkActions!;
    final cancelAction = bulk.firstWhere((b) => b.label == 'Cancelar');
    final enviarAction = bulk.firstWhere((b) => b.label == 'Enviar');

    expect(cancelAction.isEnabled!([{'status': 'AUTORIZADA'}]), isTrue);
    expect(cancelAction.isEnabled!([{'status': 'PENDENTE'}]), isFalse);
    expect(enviarAction.isEnabled!([{'status': 'DIGITACAO'}]), isTrue);
    expect(enviarAction.isEnabled!([{'status': 'AUTORIZADA'}]), isFalse);

    // Drena eventuais timers de rede/log assíncronos
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('NFC-e exposes fiscal row actions, header buttons and bulk actions with status check', (tester) async {
    await setWideSurface(tester);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: WebNfceGridScreen(hasPermission: _allPerms))),
    );
    await tester.pump();

    final grid = tester.widget<DynamicGridWindowsScreen<NfceModel>>(
      find.byType(DynamicGridWindowsScreen<NfceModel>),
    );

    // Header buttons
    expect(find.byIcon(Icons.help_outline), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(find.byIcon(Icons.download), findsOneWidget);

    // Custom Actions
    expect(
      grid.customActions!().map((a) => a.label),
      containsAllInOrder([
        'Consultar status',
        'Cancelar',
        'Cancelar por substituição',
        'Contingência / EPEC',
        'Inutilizar numeração',
        'Gerar PDF',
        'Baixar XML',
        'Enviar e-mail',
      ]),
    );

    // Bulk Actions
    final bulk = grid.bulkActions!;
    expect(bulk.map((b) => b.label), [
      'Imprimir Cupom / DANFE',
      'Transmitir NFC-e',
      'Cancelar',
      'Reenviar Contingência',
      'Baixar XML',
    ]);

    final cancelAction = bulk.firstWhere((b) => b.label == 'Cancelar');
    final contingenciaAction = bulk.firstWhere((b) => b.label == 'Reenviar Contingência');
    final emitirAction = bulk.firstWhere((b) => b.label == 'Transmitir NFC-e');

    const nfceAutorizada = NfceModel(id: 1, statusSefaz: 'AUTORIZADA');
    const nfcePendente = NfceModel(id: 2, statusSefaz: 'PENDENTE');
    const nfceContingencia = NfceModel(id: 3, statusSefaz: 'CONTINGENCIA');

    expect(cancelAction.isEnabled!([nfceAutorizada]), isTrue);
    expect(cancelAction.isEnabled!([nfcePendente]), isFalse);

    expect(contingenciaAction.isEnabled!([nfceContingencia]), isTrue);
    expect(contingenciaAction.isEnabled!([nfceAutorizada]), isFalse);

    expect(emitirAction.isEnabled!([nfcePendente]), isTrue);
    expect(emitirAction.isEnabled!([nfceAutorizada]), isFalse);

    // Drena eventuais timers de rede/log assíncronos
    await tester.pump(const Duration(seconds: 2));
  });

  test('NF-e historico normaliza cancelamento e carta de correcao', () {
    final eventos = nfeHistoricoEventos({
      'cancelamentos': [
        {'protocolo': '123', 'motivo': 'Cancelamento homologado'}
      ],
      'cartasCorrecao': [
        {'protocoloEvento': '456', 'correcao': 'Texto da correcao'}
      ],
    });

    expect(eventos, hasLength(2));
    expect(eventos.first['tipo'], 'Cancelamento');
    expect(eventos.last['tipo'], 'Carta de Correção');
  });
}

bool _allPerms(String perm) => true;
