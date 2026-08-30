import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/mobile/screens/nfse_servico_screen.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: child,
  );
}

void main() {
  group('NfseServicoScreen', () {
    testWidgets('smoke test — renderiza sem erros', (tester) async {
      await tester.pumpWidget(_wrap(const NfseServicoScreen()));
      await tester.pump();
      // Sem exception = PASS
    });

    testWidgets('campos obrigatorios do cabecalho sao visiveis no topo',
        (tester) async {
      await tester.pumpWidget(_wrap(const NfseServicoScreen()));
      await tester.pump();

      // Municipio fica logo no topo — deve estar visivel sem scroll
      expect(find.text('Município de Prestação *'), findsOneWidget);
      // Nome / Razao Social tambem fica proximo ao topo
      expect(find.text('Nome / Razão Social do Tomador *'), findsOneWidget);
    });

    testWidgets('campos de servico e imposto estao presentes na arvore de widgets',
        (tester) async {
      await tester.pumpWidget(_wrap(const NfseServicoScreen()));
      await tester.pump();

      // Fazemos scroll para expor todos os items do ListView
      await tester.dragUntilVisible(
        find.text('Descrição do Serviço *'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      expect(find.text('Descrição do Serviço *'), findsOneWidget);

      await tester.dragUntilVisible(
        find.text('Valor R\$ *'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      expect(find.text('Valor R\$ *'), findsOneWidget);

      await tester.dragUntilVisible(
        find.text('Alíquota ISS % *'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      expect(find.text('Alíquota ISS % *'), findsOneWidget);
    });

    testWidgets('submit com campos obrigatorios vazios exibe validacao',
        (tester) async {
      await tester.pumpWidget(_wrap(const NfseServicoScreen()));
      await tester.pump();

      // Rola ate o botao Emitir NFS-e
      await tester.dragUntilVisible(
        find.text('Emitir NFS-e'),
        find.byType(ListView),
        const Offset(0, -300),
      );

      await tester.tap(find.text('Emitir NFS-e'));
      await tester.pump();

      // Mensagem de campo obrigatorio deve aparecer para ao menos um campo
      expect(find.text('Campo obrigatório'), findsWidgets);
    });

    testWidgets('toggle ISS Retido na Fonte alterna estado', (tester) async {
      await tester.pumpWidget(_wrap(const NfseServicoScreen()));
      await tester.pump();

      // Rola ate o SwitchListTile
      await tester.dragUntilVisible(
        find.byType(SwitchListTile),
        find.byType(ListView),
        const Offset(0, -300),
      );

      // Estado inicial: false
      SwitchListTile tile = tester.widget(find.byType(SwitchListTile));
      expect(tile.value, isFalse);

      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();

      tile = tester.widget(find.byType(SwitchListTile));
      expect(tile.value, isTrue);
    });

    testWidgets('botao Limpar no AppBar reseta campos preenchidos',
        (tester) async {
      await tester.pumpWidget(_wrap(const NfseServicoScreen()));
      await tester.pump();

      // Preenche o primeiro campo (Municipio) que fica no topo
      final campoMunicipio = find.widgetWithText(
          TextFormField, 'Município de Prestação *');
      expect(campoMunicipio, findsOneWidget);
      await tester.enterText(campoMunicipio, 'São Paulo');
      await tester.pump();

      // Clica em Limpar — fica no AppBar, sempre visivel
      final botaoLimpar = find.text('Limpar');
      expect(botaoLimpar, findsOneWidget);
      await tester.tap(botaoLimpar);
      await tester.pump();

      // Campo deve estar vazio
      final campo = tester.widget<TextFormField>(campoMunicipio);
      expect(campo.controller?.text ?? '', isEmpty);
    });
  });
}
