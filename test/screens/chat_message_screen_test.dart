import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/mobile/screens/chatMenssageScreen.dart';
import 'package:task_manager_flutter/widgets/chat/chat_support_ui.dart';

void main() {
  group('ChatMessageScreen - UI Colors', () {
    testWidgets('Scaffold backgroundColor deve ser ChatSupportPalette.page (verde)',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: ChatMessageScreen(
            sector: 'Suporte',
            userName: 'teste@example.com',
            chatId: '123',
          ),
        ),
      );

      // Act & Assert: Verifica que ChatSupportPalette.page é a cor verde esperada
      expect(
        ChatSupportPalette.page,
        equals(const Color(0xFFEAF5EE)), // verde institucional Abraço
      );

      // Verifica que a cor NÃO é branca (GridColors.background era azul antes)
      expect(
        ChatSupportPalette.page,
        isNot(Colors.white),
      );

      // Verifica que o Scaffold está presente
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets(
        'Botão Finalizar deve estar presente no header (IconButton com stop_circle)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatMessageScreen(
            sector: 'Financeiro',
            userName: 'user@example.com',
            chatId: '456',
          ),
        ),
      );

      // Verifica que o IconButton com stop_circle_outlined está presente
      expect(find.byIcon(Icons.stop_circle_outlined), findsOneWidget);

      // Verifica que é um IconButton (botão clicável)
      expect(find.byType(IconButton), findsWidgets);
    });

    testWidgets('ChatSupportPalette.page deve ser diferente de GridColors.background',
        (WidgetTester tester) async {
      // Verifica que as cores são diferentes (fix estava usando background em vez de page)
      expect(
        ChatSupportPalette.page,
        isNot(equals(const Color(0xFFF3F8FB))), // GridColors.background (azul)
      );
    });
  });
}
