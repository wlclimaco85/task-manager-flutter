import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/auth_screens/login_screen.dart';
import 'package:task_manager_flutter/main.dart';

void main() {
  testWidgets('TaskManagerApp exibe LoginScreen quando loggedIn é false',
      (WidgetTester tester) async {
    await tester.pumpWidget(const TaskManagerApp(loggedIn: false));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
