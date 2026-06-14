// test/widgets/meu_perfil_screen_test.dart
//
// Testes de widget para MeuPerfilScreen (tela "Meu Perfil" — mobile).
// Cobre a validação de nome vazio ao salvar.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/mobile/screens/meu_perfil_screen.dart';
import 'package:task_manager_flutter/models/auth_utility.dart';
import 'package:task_manager_flutter/models/login_model.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  setUp(() {
    AuthUtility.userInfo = LoginModel(
      login: Login(id: 1, nome: 'Usuário Teste', email: 'teste@exemplo.com'),
    );
  });

  group('MeuPerfilScreen — validação de nome', () {
    testWidgets(
        'ao tocar em Salvar com o campo Nome vazio, exibe "Informe o nome."',
        (tester) async {
      await tester.pumpWidget(_wrap(const MeuPerfilScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Salvar'));
      await tester.pump();

      expect(find.text('Informe o nome.'), findsOneWidget);
    });
  });
}
