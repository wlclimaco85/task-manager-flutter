// test/widgets/searchable_dropdown_test.dart
//
// Testes de widget para SearchableDropdownField.
// Valida renderização, filtro de busca, seleção de item,
// opção nullable e estado de lista vazia.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/searchable_dropdown.dart';

// Dados de teste reutilizáveis
const _items = [
  {'id': '1', 'nome': 'Empresa Alpha'},
  {'id': '2', 'nome': 'Empresa Beta'},
  {'id': '3', 'nome': 'Empresa Gamma'},
  {'id': '4', 'nome': 'Outra Empresa Delta'},
];

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('SearchableDropdownField — renderização básica', () {
    testWidgets('widget renderiza sem erro com lista vazia', (tester) async {
      await tester.pumpWidget(_wrap(
        SearchableDropdownField(
          label: 'Empresa',
          items: const [],
          valueField: 'id',
          displayField: 'nome',
          onChanged: (_) {},
        ),
      ));
      expect(find.byType(SearchableDropdownField), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('widget renderiza com itens e exibe hint quando sem seleção',
        (tester) async {
      await tester.pumpWidget(_wrap(
        SearchableDropdownField(
          label: 'Empresa',
          items: _items,
          valueField: 'id',
          displayField: 'nome',
          onChanged: (_) {},
          hintText: '— Selecione uma empresa —',
        ),
      ));
      expect(find.text('— Selecione uma empresa —'), findsOneWidget);
    });

    testWidgets('widget exibe label corretamente', (tester) async {
      await tester.pumpWidget(_wrap(
        SearchableDropdownField(
          label: 'Parceiro',
          items: _items,
          valueField: 'id',
          displayField: 'nome',
          onChanged: (_) {},
        ),
      ));
      expect(find.text('Parceiro'), findsOneWidget);
    });

    testWidgets('widget exibe label com asterisco quando isRequired=true',
        (tester) async {
      await tester.pumpWidget(_wrap(
        SearchableDropdownField(
          label: 'Empresa',
          items: _items,
          valueField: 'id',
          displayField: 'nome',
          onChanged: (_) {},
          isRequired: true,
        ),
      ));
      expect(find.text('Empresa *'), findsOneWidget);
    });

    testWidgets('widget exibe valor selecionado quando value é fornecido',
        (tester) async {
      await tester.pumpWidget(_wrap(
        SearchableDropdownField(
          label: 'Empresa',
          items: _items,
          valueField: 'id',
          displayField: 'nome',
          value: '2',
          onChanged: (_) {},
        ),
      ));
      expect(find.text('Empresa Beta'), findsOneWidget);
    });
  });

  group('SearchableDropdownField — abertura do diálogo e filtro', () {
    testWidgets('toque abre o diálogo de busca', (tester) async {
      await tester.pumpWidget(_wrap(
        SearchableDropdownField(
          label: 'Empresa',
          items: _items,
          valueField: 'id',
          displayField: 'nome',
          onChanged: (_) {},
        ),
      ));
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      // O diálogo abre e exibe o campo de busca
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('campo de busca filtra opções — case insensitive', (tester) async {
      await tester.pumpWidget(_wrap(
        SearchableDropdownField(
          label: 'Empresa',
          items: _items,
          valueField: 'id',
          displayField: 'nome',
          onChanged: (_) {},
        ),
      ));
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // Digita texto em minúsculo; "alpha" deve encontrar "Empresa Alpha"
      await tester.enterText(find.byType(TextField), 'alpha');
      await tester.pump();

      expect(find.text('Empresa Alpha'), findsOneWidget);
      expect(find.text('Empresa Beta'), findsNothing);
      expect(find.text('Empresa Gamma'), findsNothing);
    });

    testWidgets('campo de busca filtra opções — case insensitive maiúsculo',
        (tester) async {
      await tester.pumpWidget(_wrap(
        SearchableDropdownField(
          label: 'Empresa',
          items: _items,
          valueField: 'id',
          displayField: 'nome',
          onChanged: (_) {},
        ),
      ));
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'BETA');
      await tester.pump();

      expect(find.text('Empresa Beta'), findsOneWidget);
      expect(find.text('Empresa Alpha'), findsNothing);
    });

    testWidgets('lista vazia exibe mensagem "Nenhum resultado"', (tester) async {
      await tester.pumpWidget(_wrap(
        SearchableDropdownField(
          label: 'Empresa',
          items: _items,
          valueField: 'id',
          displayField: 'nome',
          onChanged: (_) {},
        ),
      ));
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'xyzabcdef_inexistente');
      await tester.pump();

      expect(find.text('Nenhum resultado'), findsOneWidget);
    });
  });

  group('SearchableDropdownField — seleção de item', () {
    testWidgets('selecionar item fecha o diálogo e chama onChanged', (tester) async {
      String? valorSelecionado;

      await tester.pumpWidget(_wrap(
        StatefulBuilder(
          builder: (context, setState) => SearchableDropdownField(
            label: 'Empresa',
            items: _items,
            valueField: 'id',
            displayField: 'nome',
            value: valorSelecionado,
            onChanged: (v) => setState(() => valorSelecionado = v),
          ),
        ),
      ));

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // Toca em "Empresa Gamma"
      await tester.tap(find.text('Empresa Gamma'));
      await tester.pumpAndSettle();

      // Diálogo deve ter fechado
      expect(find.byType(Dialog), findsNothing);
      // onChanged deve ter sido chamado com o id correto
      expect(valorSelecionado, equals('3'));
    });

    testWidgets('selecionar item atualiza o texto exibido no campo', (tester) async {
      String? valorSelecionado;

      await tester.pumpWidget(_wrap(
        StatefulBuilder(
          builder: (context, setState) => SearchableDropdownField(
            label: 'Empresa',
            items: _items,
            valueField: 'id',
            displayField: 'nome',
            value: valorSelecionado,
            onChanged: (v) => setState(() => valorSelecionado = v),
          ),
        ),
      ));

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Empresa Alpha'));
      await tester.pumpAndSettle();

      expect(find.text('Empresa Alpha'), findsOneWidget);
    });
  });

  group('SearchableDropdownField — nullable', () {
    testWidgets('botão de limpar aparece quando nullable=true', (tester) async {
      await tester.pumpWidget(_wrap(
        SearchableDropdownField(
          label: 'Empresa',
          items: _items,
          valueField: 'id',
          displayField: 'nome',
          onChanged: (_) {},
          nullable: true,
          nullLabel: '— Nenhum —',
        ),
      ));
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      expect(find.text('— Nenhum —'), findsOneWidget);
    });

    testWidgets('botão de limpar NÃO aparece quando nullable=false', (tester) async {
      await tester.pumpWidget(_wrap(
        SearchableDropdownField(
          label: 'Empresa',
          items: _items,
          valueField: 'id',
          displayField: 'nome',
          onChanged: (_) {},
          nullable: false,
        ),
      ));
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      expect(find.text('— Nenhum —'), findsNothing);
    });

    testWidgets('clicar em limpar chama onChanged com null', (tester) async {
      String? valorSelecionado = '1';

      await tester.pumpWidget(_wrap(
        StatefulBuilder(
          builder: (context, setState) => SearchableDropdownField(
            label: 'Empresa',
            items: _items,
            valueField: 'id',
            displayField: 'nome',
            value: valorSelecionado,
            onChanged: (v) => setState(() => valorSelecionado = v),
            nullable: true,
            nullLabel: '— Nenhum —',
          ),
        ),
      ));

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('— Nenhum —'));
      await tester.pumpAndSettle();

      expect(valorSelecionado, isNull);
    });
  });

  group('SearchableDropdownField — estado desabilitado', () {
    testWidgets('campo desabilitado não abre diálogo ao tocar', (tester) async {
      await tester.pumpWidget(_wrap(
        SearchableDropdownField(
          label: 'Empresa',
          items: _items,
          valueField: 'id',
          displayField: 'nome',
          onChanged: (_) {},
          enabled: false,
        ),
      ));

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // Nenhum Dialog deve ter aberto
      expect(find.byType(Dialog), findsNothing);
    });
  });
}
