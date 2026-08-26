import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/smtp_config_tab.dart';

void main() {
  testWidgets('renderiza campos SMTP da empresa', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SmtpConfigTab(
            scope: SmtpConfigScope.empresa,
            id: 0,
            nome: 'Empresa Teste',
          ),
        ),
      ),
    );

    expect(find.textContaining('Empresa Teste'), findsOneWidget);
    expect(find.text('SMTP ativo'), findsOneWidget);
    expect(find.text('Host SMTP'), findsOneWidget);
    expect(find.text('Porta'), findsOneWidget);
    expect(find.text('Usuario'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Email remetente'), findsOneWidget);
    expect(find.text('Nome remetente'), findsOneWidget);
    expect(find.text('Autenticacao'), findsOneWidget);
    expect(find.text('STARTTLS'), findsOneWidget);
    expect(find.text('SSL'), findsOneWidget);
    expect(find.text('Salvar SMTP'), findsOneWidget);
  });

  testWidgets('renderiza campos SMTP do parceiro', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SmtpConfigTab(
            scope: SmtpConfigScope.parceiro,
            id: 0,
            nome: 'Parceiro Teste',
          ),
        ),
      ),
    );

    expect(find.textContaining('Parceiro Teste'), findsOneWidget);
    expect(find.text('SMTP ativo'), findsOneWidget);
    expect(find.text('Host SMTP'), findsOneWidget);
    expect(find.text('Salvar SMTP'), findsOneWidget);
  });
}
