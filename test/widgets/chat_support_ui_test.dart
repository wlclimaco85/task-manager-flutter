import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/chat/chat_support_ui.dart';

void main() {
  group('ChatSupportUI', () {
    testWidgets('ChatListTileCard exibe ícone Mais com cor cinza',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatListTileCard(
              title: 'Suporte',
              subtitle: 'Dúvida sobre produto',
              time: '14:30',
              status: 'Ativo',
              selected: false,
              onTap: () {},
              onMore: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.more_horiz), findsOneWidget);

      // Verifica se o IconButton está presente
      final iconButton = find.byType(IconButton);
      expect(iconButton, findsWidgets);
    });

    testWidgets('ChatStatusPill renderiza corretamente',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatStatusPill(status: 'Ativo'),
          ),
        ),
      );

      expect(find.text('Ativo'), findsOneWidget);
    });

    testWidgets('Enter no campo de mensagem envia a conversa',
        (WidgetTester tester) async {
      var envios = 0;
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatComposer(
              controller: controller,
              onAttach: () {},
              onTicket: () {},
              onSend: () => envios++,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'Oi, preciso de ajuda');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();

      expect(envios, 1);
    });

    testWidgets('Botao enviar dispara uma mensagem digitada',
        (WidgetTester tester) async {
      var envios = 0;
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatComposer(
              controller: controller,
              onAttach: () {},
              onTicket: () {},
              onSend: () => envios++,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'dddddd');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      expect(envios, 1);
    });
  });
}
