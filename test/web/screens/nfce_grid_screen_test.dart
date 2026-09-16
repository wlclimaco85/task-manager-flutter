import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/web/screens/nfce_grid_screen.dart';
import 'package:task_manager_flutter/customization/dynamic_grid_windows_screen.dart';
import 'package:task_manager_flutter/models/nfce_model.dart';
import 'package:task_manager_flutter/config/screen_field_overrides.dart';

void main() {
  testWidgets(
      'WebNfceGridScreen renders DynamicGridWindowsScreen with correct actions',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: WebNfceGridScreen(
          hasPermission: (String permission) => true,
        ),
      ),
    ));

    await tester.pump();

    // Verifica que o DynamicGridWindowsScreen foi montado
    expect(find.byType(DynamicGridWindowsScreen<NfceModel>), findsOneWidget);

    // Extrai o widget e verifica propriedades
    final dynamicGrid = tester.widget<DynamicGridWindowsScreen<NfceModel>>(
      find.byType(DynamicGridWindowsScreen<NfceModel>),
    );

    expect(dynamicGrid.tituloOverride, equals('NFC-e / Cupons'));
    expect(dynamicGrid.telaNome, equals('nfce'));
    expect(dynamicGrid.fetchEndpointOverride, contains('/api/v1/nfce'));
    expect(dynamicGrid.createEndpointOverride, contains('/api/v1/nfce'));

    // Valida que customActions nao e null e tem as opcoes fiscais da linha.
    expect(dynamicGrid.customActions, isNotNull);

    final actions = dynamicGrid.customActions!();
    expect(
      actions.map((a) => a.label),
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

    expect(actions.length, equals(8));

    // Drena eventuais timers de log/erro de rede assíncronos
    await tester.pump(const Duration(seconds: 2));
  });

  test('NfceModel preserva campos usados pela grid de cupons', () {
    final model = NfceModel.fromJson({
      'id': 24,
      'empresaId': 1,
      'empresaNome': 'Empresa Smoke Test',
      'parceiroId': 1751,
      'chaveAcesso': '31260919364209000162650010000000231131271224',
      'numero': 23,
      'serie': 1,
      'uf': 'MG',
      'ambiente': 'HOMOLOGACAO',
      'statusSefaz': 'CONTINGENCIA',
      'codigoRetorno': '107',
      'motivoRejeicao': 'SEFAZ indisponivel',
      'xmlEnviadoDisponivel': true,
      'xmlAutorizadoDisponivel': false,
      'danfeUrl': '/api/v1/nfce/24/danfe.pdf',
      'vendaId': 49,
      'dataEmissao': '2026-09-16T10:15:00',
      'dataContingencia': '2026-09-16T10:16:00',
      'tpEmis': 9,
      'justificativaContingencia': 'SEFAZ indisponivel',
      'modelo': '65',
    });

    final json = model.toJson();

    expect(json['empresaId'], 1);
    expect(json['empresaNome'], 'Empresa Smoke Test');
    expect(json['parceiroId'], 1751);
    expect(json['uf'], 'MG');
    expect(json['ambiente'], 'HOMOLOGACAO');
    expect(json['xmlEnviadoDisponivel'], isTrue);
    expect(json['xmlAutorizadoDisponivel'], isFalse);
    expect(json['vendaId'], 49);
    expect(json['modelo'], '65');
  });

  test('overrides da grid NFC-e incluem parceiro e artefatos fiscais', () {
    final fields = kScreenFieldOverrides['nfce']!
        .map((field) => field.fieldName)
        .toList();

    expect(
      fields,
      containsAll([
        'empresaId',
        'empresaNome',
        'parceiroId',
        'chaveAcesso',
        'ambiente',
        'statusSefaz',
        'xmlEnviadoDisponivel',
        'xmlAutorizadoDisponivel',
        'danfeUrl',
      ]),
    );
  });
}
