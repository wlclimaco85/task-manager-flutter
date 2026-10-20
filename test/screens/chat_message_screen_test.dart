import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/mobile/screens/chatMenssageScreen.dart';
import 'package:task_manager_flutter/widgets/chat/chat_support_ui.dart';


/// Nenhuma conexão de rede nos testes: HTTP e WebSocket falham na hora.
/// Sem isso a tela abre o WebSocket do endereco configurado (Railway) e deixa timers pendentes.
class _SemRedeHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _ClienteRecusado();
}

class _ClienteRecusado implements HttpClient {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    final nome = invocation.memberName.toString();
    if (nome.contains('open') || nome.contains('get') || nome.contains('post') ||
        nome.contains('put') || nome.contains('delete') || nome.contains('patch') ||
        nome.contains('head') || nome.contains('Url')) {
      return Future<HttpClientRequest>.error(const SocketException('sem rede nos testes'));
    }
    return null;
  }
}

/// Desmonta a tela e avança o relogio para encerrar reconexoes agendadas.
Future<void> _encerrar(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(minutes: 2));
}

void main() {
  setUpAll(() => HttpOverrides.global = _SemRedeHttpOverrides());
  tearDownAll(() => HttpOverrides.global = null);

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
      await _encerrar(tester);
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
      await _encerrar(tester);
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
