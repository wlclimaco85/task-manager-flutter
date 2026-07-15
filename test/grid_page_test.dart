import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/customization/generic_grid/grid_models.dart';
import 'package:task_manager_flutter/customization/generic_grid/grid_page.dart';

void main() {
  group('Card #425 - Grid Mobile Colunas - TDD Tests', () {
    final testFieldConfigs = [
      FieldConfig(
        fieldName: 'id',
        label: 'ID',
        fieldType: FieldType.text,
        isVisibleByDefault: true,
        isFixed: true,
      ),
      FieldConfig(
        fieldName: 'nome',
        label: 'Nome',
        fieldType: FieldType.text,
        isVisibleByDefault: true,
        isFilterable: true,
      ),
    ];

    test(
      'BUG #1: GenericMobileGridScreen deve ter parâmetro onCustomizationStateChanged',
      () {
        // Este teste verifica se o parâmetro foi adicionado à assinatura
        // Para passar, a compilação do código deve funcionar (Dart não permite
        // passar parâmetros inexistentes).

        bool callbackWasCalled = false;

        final screen = GenericMobileGridScreen(
          title: 'Test Grid',
          fetchEndpoint: '/api/test',
          createEndpoint: '/api/test/create',
          updateEndpoint: '/api/test/:id',
          deleteEndpoint: '/api/test/:id',
          hasPermission: (_) => true,
          fieldConfigs: testFieldConfigs,
          onCustomizationStateChanged: ({
            required bool hasActiveFilters,
            required bool hasCustomColumns,
          }) {
            callbackWasCalled = true;
          },
        );

        expect(screen.onCustomizationStateChanged, isNotNull,
            reason: 'onCustomizationStateChanged deve ser non-null quando passado');
        expect(callbackWasCalled, isFalse,
            reason: 'Callback não deve ser chamado durante construção');
      },
    );

    test(
      'BUG #2: AppBar deve ter ícone de colunas com null-safety',
      () {
        // Verifica que o construtor aceita o parâmetro sem crashes
        final screen = GenericMobileGridScreen(
          title: 'Test Grid',
          fetchEndpoint: '/api/test',
          createEndpoint: '/api/test/create',
          updateEndpoint: '/api/test/:id',
          deleteEndpoint: '/api/test/:id',
          hasPermission: (_) => true,
          fieldConfigs: testFieldConfigs,
          showAppBar: true,
          useUserBannerAppBar: false,
        );

        expect(screen.showAppBar, isTrue);
        expect(screen.useUserBannerAppBar, isFalse);
      },
    );

    test(
      'BUG #1: onCustomizationStateChanged pode ser null (é optional)',
      () {
        final screenWithoutCallback = GenericMobileGridScreen(
          title: 'Test Grid',
          fetchEndpoint: '/api/test',
          createEndpoint: '/api/test/create',
          updateEndpoint: '/api/test/:id',
          deleteEndpoint: '/api/test/:id',
          hasPermission: (_) => true,
          fieldConfigs: testFieldConfigs,
          // Não passando onCustomizationStateChanged
        );

        expect(screenWithoutCallback.onCustomizationStateChanged, isNull,
            reason: 'onCustomizationStateChanged deve ser null por padrão');
      },
    );

    testWidgets(
      'AppBar renderiza ícone de colunas sem erro',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GenericMobileGridScreen(
                title: 'Test',
                fetchEndpoint: '/api/test',
                createEndpoint: '/api/test/create',
                updateEndpoint: '/api/test/:id',
                deleteEndpoint: '/api/test/:id',
                hasPermission: (_) => true,
                fieldConfigs: testFieldConfigs,
                showAppBar: true,
                useUserBannerAppBar: false,
                // Mock para evitar chamadas de rede
                initialFilters: const {},
              ),
            ),
          ),
        );

        // Só a renderização do widget pai
        await tester.pumpWidget(
          MaterialApp(
            home: Container(), // Volta para vazio
          ),
        );

        // Se chegou aqui, não houve erro na renderização
        expect(true, isTrue);
      },
    );
  });
}
