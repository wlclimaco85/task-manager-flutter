import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/core/responsive/responsive_helper.dart';
import 'package:task_manager_flutter/models/nfe/nfe_model.dart';
import 'package:task_manager_flutter/models/nfe/nfe_status.dart';
import 'package:task_manager_flutter/widgets/nfe/nfe_card.dart';

void main() {
  group('NfeCard Widget', () {
    final testNfe = NfeModel(
      id: 1,
      numero: '123456',
      serie: '1',
      statusNfe: NfeStatus.autorizada,
      dataHora: DateTime.now(),
      valores: NfeValores(
        subtotal: 1000.00,
        desconto: 0,
        icms: 100.00,
        pis: 10.00,
        cofins: 20.00,
        ipi: 0,
        csll: 0,
        inss: 0,
        frete: 50.00,
        seguro: 5.00,
        total: 1185.00,
      ),
      emitente: NfePessoa(
        cnpjCpf: '11.222.333/0001-81',
        razaoSocial: 'Empresa Emitente LTDA',
        endereco: 'Rua A, 123',
        cidade: 'São Paulo',
        uf: 'SP',
      ),
      tomador: NfePessoa(
        cnpjCpf: '11.444.555/0001-81',
        razaoSocial: 'Cliente LTDA',
        endereco: 'Rua B, 456',
        cidade: 'Rio de Janeiro',
        uf: 'RJ',
      ),
      nfeTomador: null,
    );

    testWidgets('renderiza todos os elementos principais', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NfeCard(
              nfe: testNfe,
              breakpoint: Breakpoint.desktop,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('NF-e 123456'), findsOneWidget);
      expect(find.text('Série 1'), findsOneWidget);
      expect(find.text('Cliente: Cliente LTDA'), findsOneWidget);
      expect(find.text('CNPJ: 11.444.555/0001-81'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('renderiza botões em desktop', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NfeCard(
              nfe: testNfe,
              breakpoint: Breakpoint.desktop,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(OutlinedButton), findsWidgets);
      expect(find.text('Detalhes'), findsOneWidget);
      expect(find.text('Reimprimir'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('renderiza PopupMenuButton em mobile', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NfeCard(
              nfe: testNfe,
              breakpoint: Breakpoint.mobile,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(PopupMenuButton), findsOneWidget);
    });

    testWidgets('executa callback onDetails ao clicar', (WidgetTester tester) async {
      // Arrange
      bool detailsClicked = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NfeCard(
              nfe: testNfe,
              breakpoint: Breakpoint.desktop,
              onDetails: () => detailsClicked = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Detalhes'));
      await tester.pumpAndSettle();

      // Assert
      expect(detailsClicked, isTrue);
    });

    testWidgets('exibe valores formatados', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NfeCard(
              nfe: testNfe,
              breakpoint: Breakpoint.desktop,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('R\$ 1.185,00'), findsOneWidget);
    });

    testWidgets('não renderiza botão cancelar se status é cancelada',
        (WidgetTester tester) async {
      // Arrange
      final canceledNfe = testNfe.copyWith(statusNfe: NfeStatus.cancelada);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NfeCard(
              nfe: canceledNfe,
              breakpoint: Breakpoint.desktop,
            ),
          ),
        ),
      );

      // Assert
      expect(find.widgetWithText(OutlinedButton, 'Cancelar'), findsNothing);
    });

    testWidgets('renderiza com dark theme', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: NfeCard(
              nfe: testNfe,
              breakpoint: Breakpoint.desktop,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(NfeCard), findsOneWidget);
    });
  });
}
