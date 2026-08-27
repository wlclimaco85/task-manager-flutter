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

  group('SearchableDropdownField — busca server-side (onSearch)', () {
    // Regressão do bug de produção: popup "Município de Prestação" (NFSe)
    // carregava só um lote local (antes: 5000 de 5571 cidades) e filtrava
    // no cliente, então cidades fora do lote (ex: "Uberaba") nunca eram
    // encontradas. Com onSearch, a busca digitada vai para o servidor.
    const _loteLocal = [
      {'id': '1', 'nome': 'Abadia dos Dourados'},
      {'id': '2', 'nome': 'Abaeté'},
    ];

    testWidgets(
        'com onSearch definido, encontra item que NÃO está no lote local (ex: Uberaba)',
        (tester) async {
      var chamadaRecebida = '';
      await tester.pumpWidget(_wrap(
        SearchableDropdownField(
          label: 'Município de Prestação',
          items: _loteLocal,
          valueField: 'id',
          displayField: 'nome',
          onChanged: (_) {},
          onSearch: (q) async {
            chamadaRecebida = q;
            return [
              {'id': '9999', 'nome': 'Uberaba'},
            ];
          },
        ),
      ));

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // Antes de digitar, mostra o lote local (não contém Uberaba)
      expect(find.text('Uberaba'), findsNothing);

      await tester.enterText(find.byType(TextField), 'uberaba');
      // Aguarda o debounce (350ms) + o Future do onSearch
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(chamadaRecebida, 'uberaba');
      expect(find.text('Uberaba'), findsOneWidget);
      // O lote local não deve mais aparecer — resultado veio do servidor
      expect(find.text('Abadia dos Dourados'), findsNothing);
    });

    testWidgets('onSearch sem resultado exibe "Nenhum resultado"', (tester) async {
      await tester.pumpWidget(_wrap(
        SearchableDropdownField(
          label: 'Município de Prestação',
          items: _loteLocal,
          valueField: 'id',
          displayField: 'nome',
          onChanged: (_) {},
          onSearch: (q) async => [],
        ),
      ));

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'cidade-inexistente-xyz');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('Nenhum resultado'), findsOneWidget);
    });

    testWidgets('limpar o campo de busca volta a exibir o lote local',
        (tester) async {
      await tester.pumpWidget(_wrap(
        SearchableDropdownField(
          label: 'Município de Prestação',
          items: _loteLocal,
          valueField: 'id',
          displayField: 'nome',
          onChanged: (_) {},
          onSearch: (q) async => [
            {'id': '9999', 'nome': 'Uberaba'},
          ],
        ),
      ));

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'uberaba');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('Uberaba'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Abadia dos Dourados'), findsOneWidget);
      expect(find.text('Abaeté'), findsOneWidget);
    });

    testWidgets('selecionar resultado da busca server-side chama onChanged com o id correto',
        (tester) async {
      String? valorSelecionado;

      await tester.pumpWidget(_wrap(
        StatefulBuilder(
          builder: (context, setState) => SearchableDropdownField(
            label: 'Município de Prestação',
            items: _loteLocal,
            valueField: 'id',
            displayField: 'nome',
            value: valorSelecionado,
            onChanged: (v) => setState(() => valorSelecionado = v),
            onSearch: (q) async => [
              {'id': '9999', 'nome': 'Uberaba'},
            ],
          ),
        ),
      ));

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'uberaba');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Uberaba'));
      await tester.pumpAndSettle();

      expect(valorSelecionado, equals('9999'));
      // Regressão do bug original: o rótulo exibido no campo (já fechado o
      // diálogo) precisa refletir a cidade escolhida via busca remota — não
      // pode voltar a mostrar "— Selecione —" mesmo com o id correto internamente.
      expect(find.text('Uberaba'), findsOneWidget);
    });

    testWidgets(
        'onItemSelected recebe o item completo retornado pela busca remota '
        '(inclusive campos extras não presentes no lote local, ex: codigoServicoMunicipal)',
        (tester) async {
      Map<String, dynamic>? itemRecebido;

      await tester.pumpWidget(_wrap(
        SearchableDropdownField(
          label: 'Município de Prestação',
          items: _loteLocal,
          valueField: 'id',
          displayField: 'nome',
          onChanged: (_) {},
          onItemSelected: (item) => itemRecebido = item,
          onSearch: (q) async => [
            {'id': '9999', 'nome': 'Uberaba', 'codigoServicoMunicipal': '101'},
          ],
        ),
      ));

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'uberaba');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Uberaba'));
      await tester.pumpAndSettle();

      expect(itemRecebido, isNotNull);
      expect(itemRecebido!['id'], '9999');
      expect(itemRecebido!['nome'], 'Uberaba');
      expect(itemRecebido!['codigoServicoMunicipal'], '101');
    });

    testWidgets(
        'quando value já vem preenchido (ex: editar NFSe existente) e items '
        'chega depois de forma assíncrona (ex: fora do lote inicial), o '
        'label é resolvido assim que items chegar — não fica preso em '
        '"— Selecione —"',
        (tester) async {
      // Reproduz o fluxo real de nfse_detail_screen.dart: _initCabecalho()
      // já define o _cidadeId de forma síncrona a partir do registro, mas
      // _loadDropdowns()/_garantirCidadeSelecionadaNaLista() só popula
      // _cidades (via setState) depois, de forma assíncrona.
      var items = <Map<String, dynamic>>[];

      await tester.pumpWidget(_wrap(
        StatefulBuilder(
          builder: (context, setState) => Column(
            children: [
              SearchableDropdownField(
                label: 'Município de Prestação',
                items: items,
                valueField: 'id',
                displayField: 'nome',
                value: '9999', // já selecionado, mas ainda não está em items
                onChanged: (_) {},
              ),
              TextButton(
                key: const Key('carregar'),
                onPressed: () => setState(() {
                  items = [
                    {'id': '9999', 'nome': 'Uberaba'},
                  ];
                }),
                child: const Text('carregar'),
              ),
            ],
          ),
        ),
      ));

      // Antes de items chegar: sem label resolvido (não pode quebrar).
      expect(find.text('Uberaba'), findsNothing);

      // Simula a chegada assíncrona da lista de cidades contendo o item
      // já selecionado (ex: _garantirCidadeSelecionadaNaLista).
      await tester.tap(find.byKey(const Key('carregar')));
      await tester.pumpAndSettle();

      expect(find.text('Uberaba'), findsOneWidget);
    });

    testWidgets('onItemSelected recebe null ao limpar a seleção', (tester) async {
      Map<String, dynamic>? itemRecebido = {'id': '1', 'nome': 'x'};

      await tester.pumpWidget(_wrap(
        SearchableDropdownField(
          label: 'Município de Prestação',
          items: _loteLocal,
          valueField: 'id',
          displayField: 'nome',
          value: '1',
          nullable: true,
          onChanged: (_) {},
          onItemSelected: (item) => itemRecebido = item,
        ),
      ));

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('— Nenhum —'));
      await tester.pumpAndSettle();

      expect(itemRecebido, isNull);
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

  // Card #503 (UI/UX Audit NF-e): QA apontou em vários ciclos que
  // nfe_saida_create_screen.dart (web/windows) declarava e atribuía
  // _formKey ao Form, mas NUNCA chamava .validate() -- os campos
  // obrigatórios (SearchableDropdownField com isRequired:true, ex.:
  // "Destinatário") já implementam validação real via FormField (esta
  // classe), mas nunca tinham a chance de mostrar o erro inline porque
  // validate() nunca rodava. O fix chama _formKey.currentState!.validate()
  // no início de _salvar(); este grupo prova que o mecanismo de validação
  // que esse fix agora ativa realmente funciona.
  group('SearchableDropdownField — integração real com Form.validate()', () {
    testWidgets(
        'Form.validate() exibe erro inline quando campo isRequired está vazio',
        (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(_wrap(
        Form(
          key: formKey,
          child: SearchableDropdownField(
            label: 'Destinatário',
            items: _items,
            valueField: 'id',
            displayField: 'nome',
            onChanged: (_) {},
            isRequired: true,
          ),
        ),
      ));

      final valido = formKey.currentState!.validate();
      await tester.pump();

      expect(valido, isFalse);
      expect(find.text('Destinatário é obrigatório'), findsOneWidget);
    });

    testWidgets(
        'Form.validate() NÃO mostra erro quando campo isRequired já tem valor',
        (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(_wrap(
        Form(
          key: formKey,
          child: SearchableDropdownField(
            label: 'Destinatário',
            items: _items,
            valueField: 'id',
            displayField: 'nome',
            value: '2',
            onChanged: (_) {},
            isRequired: true,
          ),
        ),
      ));

      final valido = formKey.currentState!.validate();
      await tester.pump();

      expect(valido, isTrue);
      expect(find.text('Destinatário é obrigatório'), findsNothing);
    });
  });
}
