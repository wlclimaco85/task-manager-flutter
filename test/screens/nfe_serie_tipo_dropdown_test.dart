import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/customization/dynamic_grid_windows_screen.dart';
import 'package:task_manager_flutter/web/screens/nfe_serie_grid_screen.dart';
import 'package:task_manager_flutter/web/screens/nfse_serie_grid_screen.dart';
import 'package:task_manager_flutter/widgets/generic_grid_windows_screen.dart';

void main() {
  group('NfeSerie e NfseSerie configuracao do campo tipo', () {
    testWidgets('WebNfeSerieGridScreen configura tipo com dropdownOptions e dropdownValueField=value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WebNfeSerieGridScreen(hasPermission: (_) => true),
        ),
      );

      final dynamicGridFinder = find.byType(DynamicGridWindowsScreen<Map<String, dynamic>>);
      expect(dynamicGridFinder, findsOneWidget);

      final dynamicGrid = tester.widget<DynamicGridWindowsScreen<Map<String, dynamic>>>(dynamicGridFinder);
      expect(dynamicGrid.fieldOverrides, isNotNull);

      final tipoConfig = dynamicGrid.fieldOverrides!.firstWhere((f) => f.fieldName == 'tipo');
      expect(tipoConfig.fieldType, equals(FieldType.dropdown));
      expect(tipoConfig.dropdownFutureBuilder, isNull,
          reason: 'dropdownFutureBuilder deve ser nulo para dropdown estatico evitar FK {id: ...}');
      expect(tipoConfig.dropdownValueField, equals('value'));
      expect(tipoConfig.dropdownDisplayField, equals('label'));
      expect(tipoConfig.dropdownOptions, isNotNull);

      final values = tipoConfig.dropdownOptions!.map((o) => o['value']).toList();
      expect(values, containsAll(['NF-e', 'NFS-e', 'NFC-e']));

      // Drena timer de debouncing de log/error do NetworkCaller (1.5s)
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('WebNfseSerieGridScreen configura tipo com dropdownOptions e dropdownValueField=value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WebNfseSerieGridScreen(hasPermission: (_) => true),
        ),
      );

      final dynamicGridFinder = find.byType(DynamicGridWindowsScreen<Map<String, dynamic>>);
      expect(dynamicGridFinder, findsOneWidget);

      final dynamicGrid = tester.widget<DynamicGridWindowsScreen<Map<String, dynamic>>>(dynamicGridFinder);
      expect(dynamicGrid.fieldOverrides, isNotNull);

      final tipoConfig = dynamicGrid.fieldOverrides!.firstWhere((f) => f.fieldName == 'tipo');
      expect(tipoConfig.fieldType, equals(FieldType.dropdown));
      expect(tipoConfig.dropdownFutureBuilder, isNull);
      expect(tipoConfig.dropdownValueField, equals('value'));
      expect(tipoConfig.dropdownDisplayField, equals('label'));
      expect(tipoConfig.dropdownOptions, isNotNull);

      final values = tipoConfig.dropdownOptions!.map((o) => o['value']).toList();
      expect(values, containsAll(['NF-e', 'NFS-e', 'NFC-e']));

      // Drena timer de debouncing de log/error do NetworkCaller (1.5s)
      await tester.pump(const Duration(seconds: 2));
    });

    test('Simula serializacao de form do GenericGridWindowsScreen para dropdown estatico', () {
      final config = FieldConfigWindows(
        label: 'Tipo da Série',
        fieldName: 'tipo',
        fieldType: FieldType.dropdown,
        dropdownOptions: const [
          {'value': 'NF-e', 'label': 'NF-e'},
          {'value': 'NFS-e', 'label': 'NFS-e'},
          {'value': 'NFC-e', 'label': 'NFC-e'},
        ],
        dropdownValueField: 'value',
        dropdownDisplayField: 'label',
      );

      const value = 'NF-e';
      final formData = <String, dynamic>{};

      if (config.fieldType == FieldType.dropdown && value.isNotEmpty) {
        if (config.dropdownFutureBuilder == null &&
            config.dropdownOptions != null &&
            config.dropdownOptions!.isNotEmpty) {
          formData[config.fieldName] = value;
        } else if (config.dropdownValueField == 'id') {
          final idVal = int.tryParse(value);
          formData[config.fieldName] = idVal != null ? {'id': idVal} : {'id': value};
        } else {
          final intVal = int.tryParse(value);
          formData[config.fieldName] = intVal ?? value;
        }
      }

      expect(formData['tipo'], isA<String>());
      expect(formData['tipo'], equals('NF-e'));
    });
  });
}
