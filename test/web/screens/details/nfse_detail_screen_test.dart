import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/web/screens/details/nfse_detail_screen.dart';

/// Confirma que a versão web de [NfseDetailScreen] (usada em
/// lib/web/screens/details/nfse_detail_screen.dart) recebeu o mesmo
/// tratamento do card 6F94hyxf aplicado à versão windows: 6 seções
/// sequenciais reais (sem abas), busca inline sem Dialog e sem o antigo
/// layout de painéis lado a lado com divisor redimensionável (regressão
/// original do card, que a versão web ainda tinha antes desta correção).
void main() {
  testWidgets('Web: usa 6 secoes sequenciais em coluna unica (sem divisor lateral)',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: const NfseDetailScreen(item: {})));
    await tester.pump();

    const titulos = [
      'Dados da nota',
      'Cliente / Tomador',
      'Dados fiscais do serviço',
      'Serviços da nota',
      'Impostos retidos',
      'Totais',
    ];
    for (final titulo in titulos) {
      expect(find.text(titulo), findsOneWidget, reason: 'seção "$titulo"');
    }

    // Não deve haver mais o handle de arrastar (drag) do antigo layout de
    // colunas redimensionáveis por GestureDetector (cabeçalho estreito à
    // esquerda + grid de itens à direita).
    expect(find.byIcon(Icons.drag_indicator), findsNothing);
    expect(find.byIcon(Icons.drag_handle), findsNothing);

    final dadosNota = tester.getTopLeft(find.text('Dados da nota'));
    final servicos = tester.getTopLeft(find.text('Serviços da nota'));
    expect(servicos.dx, dadosNota.dx);
    expect(servicos.dy, greaterThan(dadosNota.dy));
  });

  testWidgets('Web: busca abre popover inline, sem Dialog modal',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: const NfseDetailScreen(item: {})));
    await tester.pump();

    final serieField = find.widgetWithText(InputDecorator, 'Série');
    expect(serieField, findsOneWidget);
    await tester.tap(serieField);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(Dialog), findsNothing);
    expect(find.textContaining('Buscar'), findsOneWidget);
  });

  // Card 4phuZyDS: os botões Emitir/Cancelar chamam o endpoint fiscal com o
  // nfseId do registro real (ver _emitirNfse/_cancelarNfse). Estes testes
  // cobrem a wiring visível sem depender de rede real: visibilidade
  // condicionada a NFSe já existente e a validação de pré-requisitos que
  // bloqueia o envio antes de qualquer chamada HTTP.
  group('Card 4phuZyDS — botões Emitir/Cancelar', () {
    testWidgets('NFSe nova (sem id) não mostra botões Emitir/Cancelar',
        (tester) async {
      await tester
          .pumpWidget(MaterialApp(home: const NfseDetailScreen(item: {})));
      await tester.pump();

      expect(find.widgetWithText(OutlinedButton, 'Emitir'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Cancelar'), findsNothing);
    });

    testWidgets(
        'NFSe existente mostra botões Emitir/Cancelar e bloqueia envio sem tomador/itens',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: NfseDetailScreen(item: const {'id': 501, 'status': 'PENDENTE'})));
      await tester.pump();

      expect(find.widgetWithText(OutlinedButton, 'Emitir'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Cancelar'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Emitir'));
      await tester.pump();

      // Sem tomador/município/itens preenchidos, a validação local deve
      // barrar o envio (nenhuma chamada de rede) e mostrar o motivo.
      expect(find.textContaining('Preencha antes de emitir'), findsOneWidget);
    });

    testWidgets('Status em inglês (ISSUED) é exibido traduzido no chip',
        (tester) async {
      // Viewport maior que o padrão do teste (800x600) -- o rótulo traduzido
      // ("Autorizada pela prefeitura") é mais longo que o valor bruto
      // ("PENDENTE") e o chip usa Wrap/InputDecorator com largura calculada
      // por LayoutBuilder; sem isso o texto mais longo causa overflow do
      // Row interno só por falta de espaço da tela de teste, sem relação
      // com a tradução em si.
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
          home: NfseDetailScreen(
              item: const {'id': 502, 'status': 'ISSUED'})));
      await tester.pump();

      expect(find.text('Autorizada pela prefeitura'), findsOneWidget);
      expect(find.text('ISSUED'), findsNothing);
    });

    testWidgets('NFSe já autorizada desabilita o botão Emitir', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(MaterialApp(
          home: NfseDetailScreen(
              item: const {'id': 503, 'status': 'AUTHORIZED'})));
      await tester.pump();

      final emitirBtn = tester.widget<OutlinedButton>(
          find.ancestor(
              of: find.text('Já autorizada'),
              matching: find.byType(OutlinedButton)));
      expect(emitirBtn.onPressed, isNull);
    });

    testWidgets('NFSe já cancelada desabilita o botão Cancelar', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(MaterialApp(
          home: NfseDetailScreen(
              item: const {'id': 504, 'status': 'CANCELLED'})));
      await tester.pump();

      final cancelarBtn = tester.widget<OutlinedButton>(
          find.ancestor(
              of: find.text('Já cancelada'),
              matching: find.byType(OutlinedButton)));
      expect(cancelarBtn.onPressed, isNull);
    });
  });
}
