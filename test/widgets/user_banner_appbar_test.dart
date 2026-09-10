// Testa o fix do card 6a4567ce: UserBannerAppBar exibe inicial do email no
// avatar quando foto ausente, e exibe nome/empresa reais sem fallbacks genéricos.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/auth_utility.dart';
import 'package:task_manager_flutter/models/login_model.dart';
import 'package:task_manager_flutter/models/empresa_model.dart';
import 'package:task_manager_flutter/widgets/user_banners.dart';

Widget _wrap(Widget w) => MaterialApp(home: Scaffold(appBar: w as PreferredSizeWidget?));

void main() {
  tearDown(() => AuthUtility.userInfo = null);

  group('UserBannerAppBar — avatar initial fallback (bug 6a4567ce)', () {
    testWidgets('exibe inicial do email quando foto ausente', (tester) async {
      AuthUtility.userInfo = LoginModel(
        token: 'tok',
        login: Login(email: 'washington@example.com', nome: 'Washington'),
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          appBar: UserBannerAppBar(screenTitle: 'Teste'),
        ),
      ));
      await tester.pump();
      // Inicial do email 'w' em maiúsculo deve aparecer no CircleAvatar
      expect(find.text('W'), findsAtLeastNWidgets(1));
    });

    testWidgets('nao exibe icone person quando email disponivel', (tester) async {
      AuthUtility.userInfo = LoginModel(
        token: 'tok',
        login: Login(email: 'admin@abc.com'),
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(appBar: UserBannerAppBar(screenTitle: 'Teste')),
      ));
      await tester.pump();
      expect(find.byIcon(Icons.person), findsNothing);
    });

    testWidgets('usa inicial do nome quando email vazio', (tester) async {
      AuthUtility.userInfo = LoginModel(
        token: 'tok',
        login: Login(nome: 'Carlos', email: ''),
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(appBar: UserBannerAppBar(screenTitle: 'Teste')),
      ));
      await tester.pump();
      expect(find.text('C'), findsAtLeastNWidgets(1));
    });
  });

  group('UserBannerAppBar — nome e empresa sem fallbacks genéricos', () {
    testWidgets('exibe nome real do usuario', (tester) async {
      AuthUtility.userInfo = LoginModel(
        token: 'tok',
        login: Login(nome: 'Washington', email: 'w@test.com'),
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(appBar: UserBannerAppBar(screenTitle: 'Teste')),
      ));
      await tester.pump();
      expect(find.text('Washington'), findsOneWidget);
    });

    testWidgets('exibe nome da empresa quando disponivel', (tester) async {
      AuthUtility.userInfo = LoginModel(
        token: 'tok',
        login: Login(
          nome: 'Washington',
          email: 'w@test.com',
          empresa: Empresa(id: 1, nome: 'Escritório ABC'),
        ),
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(appBar: UserBannerAppBar(screenTitle: 'Teste')),
      ));
      await tester.pump();
      expect(find.text('Escritório ABC'), findsOneWidget);
    });

    testWidgets('nao exibe texto "Empresa" quando empresa nula', (tester) async {
      AuthUtility.userInfo = LoginModel(
        token: 'tok',
        login: Login(nome: 'Washington', email: 'w@test.com', empresa: null),
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(appBar: UserBannerAppBar(screenTitle: 'Teste')),
      ));
      await tester.pump();
      expect(find.text('Empresa'), findsNothing);
    });

    testWidgets('nao exibe texto "Usuario" quando nome nulo', (tester) async {
      AuthUtility.userInfo = LoginModel(
        token: 'tok',
        login: Login(email: 'w@test.com', nome: null),
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(appBar: UserBannerAppBar(screenTitle: 'Teste')),
      ));
      await tester.pump();
      expect(find.text('Usuário'), findsNothing);
    });

    testWidgets('exibe email quando nome nulo', (tester) async {
      AuthUtility.userInfo = LoginModel(
        token: 'tok',
        login: Login(email: 'w@test.com', nome: null),
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(appBar: UserBannerAppBar(screenTitle: 'Teste')),
      ));
      await tester.pump();
      expect(find.text('w@test.com'), findsOneWidget);
    });
  });
}
