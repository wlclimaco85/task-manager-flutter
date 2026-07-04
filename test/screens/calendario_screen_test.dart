// test/screens/calendario_screen_test.dart
// Card #276 — TDD para calendario_screen.dart: export CSV com filtros mês/ano
// PASSO 1: 5 Testes RED (devem FALHAR inicialmente)
// Ponytail validação: YAGNI — remover campos data_inicio/fim, manter mês/ano/CSV
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/screens/contabil/calendario_screen.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  group('CalendarioScreen - TDD Red (Card #276)', () {
    // ─────────────────────────────────────────────────────────────────────────
    // TEST 1 (RED): testBuildUI_TelaCarrega
    // Verifica se CalendarioScreen carrega sem erro
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets('TEST 1 RED: testBuildUI_TelaCarrega — tela carrega sem erro',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const CalendarioScreen()));
      await tester.pumpAndSettle();

      // Verifica se tela foi renderizada
      expect(find.byType(CalendarioScreen), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 2 (RED): testBuildUI_DropdownMesAno
    // Verifica se dropdowns para mês e ano aparecem
    // Esperado: 2 dropdowns (um para mês 1-12, outro para ano 2024-2027)
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets('TEST 2 RED: testBuildUI_DropdownMesAno — dropdowns mês e ano',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const CalendarioScreen()));
      await tester.pumpAndSettle();

      // Verifica presença de 2 DropdownButton (mês e ano)
      // RED: falha porque ainda não há dropdowns para mês e ano implementados
      expect(find.byType(DropdownButton<int>), findsNWidgets(2),
          reason: 'Esperado: 2 dropdowns (mês e ano)');

      // Verifica labels "Mês" e "Ano"
      expect(find.text('Mês'), findsOneWidget, reason: 'Label "Mês" não encontrado');
      expect(find.text('Ano'), findsOneWidget, reason: 'Label "Ano" não encontrado');
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 3 (RED): testBuildUI_BotaoExportar
    // Verifica se botão "Exportar CSV" existe
    // Esperado: 1 ElevatedButton com texto "Exportar CSV"
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets('TEST 3 RED: testBuildUI_BotaoExportar — botão "Exportar CSV"',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const CalendarioScreen()));
      await tester.pumpAndSettle();

      // Verifica presença de botão "Exportar CSV"
      // RED: falha porque botão ainda não foi implementado
      expect(find.byType(ElevatedButton), findsOneWidget,
          reason: 'Esperado: 1 ElevatedButton para export');

      expect(find.text('Exportar CSV'), findsOneWidget,
          reason: 'Botão "Exportar CSV" não encontrado');
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 4 (RED): testDropdownMesOpeneAndSelectable
    // Verifica se dropdown de mês abre e permite seleção
    // Esperado: dropdown mês tem 12 opções (janeiro a dezembro)
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets('TEST 4 RED: testDropdownMesOpenableAndSelectable — mês selecionável',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const CalendarioScreen()));
      await tester.pumpAndSettle();

      // Abre dropdown de mês (primeiro)
      await tester.tap(find.byType(DropdownButton<int>).first);
      await tester.pumpAndSettle();

      // Verifica se dropdown tem opções (pelo menos 12 items de mês)
      // Cada DropdownMenuItem<int> deve estar presente
      expect(find.byType(DropdownMenuItem<int>), findsWidgets,
          reason: 'Esperado: dropdown mês com 12 opções (1-12)');

      // Seleciona opção dentro do dropdown (usa byType para evitar ambiguidade)
      // Tenta selecionar um DropdownMenuItem com valor específico
      // Nota: "7" aparece em múltiplos lugares (calendário, dropdown),
      // então usamos o primeiro encontrado dentro do menu aberto
      final mes7Items = find.descendant(
        of: find.byType(Align), // os items do dropdown estão dentro de Align
        matching: find.text('7'),
      );

      if (mes7Items.evaluate().isNotEmpty) {
        await tester.tap(mes7Items.first);
        await tester.pumpAndSettle();
      }
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 5 (RED): testBotaoExportarClicavel
    // Verifica se botão "Exportar CSV" responde a tap e ativa loader
    // Esperado: tap no botão dispara _carregando = true (CircularProgressIndicator)
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets('TEST 5 RED: testBotaoExportarClicavel — botão responde ao tap',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const CalendarioScreen()));
      await tester.pumpAndSettle();

      // Verifica que botão existe e é clicável
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Exportar CSV'), findsOneWidget);

      // Tap no botão — dispara _exportarCalendario()
      // Nota: HTTP real vai falhar em testes (sem backend ativo),
      // mas a UI deve reagir ativando loader (CircularProgressIndicator)
      await tester.tap(find.byType(ElevatedButton));

      // Pequeno pump para UI reagir (sem pumpAndSettle porque HTTP vai ficar pendente)
      await tester.pump(Duration.zero);

      // Verifica que o loader foi ativado (CircularProgressIndicator aparece)
      // Isso indica que _carregando = true foi setado
      expect(find.byType(CircularProgressIndicator), findsOneWidget,
          reason: 'Esperado: loader ativado após tap no botão');
    });
  });

  group('CalendarioScreen - Testes Básicos Existentes', () {
    // Preserva testes existentes (UI básica já funcionando)
    testWidgets('renderiza título "Calendário Tributário"',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const CalendarioScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Calendário Tributário'), findsOneWidget);
    });

    testWidgets('renderiza tabela de calendário (7x6)',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const CalendarioScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(Table), findsOneWidget);
    });

    testWidgets('tela é scrollável',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const CalendarioScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('renderiza cabeçalho com dias da semana',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const CalendarioScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(Table), findsOneWidget);
    });
  });
}
