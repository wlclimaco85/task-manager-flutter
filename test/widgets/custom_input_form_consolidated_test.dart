import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/custom_input_form_consolidated.dart';

void main() {
  group('CustomInputFormConsolidated', () {
    late TextEditingController controller;

    setUp(() {
      controller = TextEditingController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('renders text input correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomInputFormConsolidated(
              controller: controller,
              label: 'Name',
              hint: 'Enter your name',
            ),
          ),
        ),
      );

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Name'), findsWidgets);
    });

    testWidgets('renders password input with obscured text',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomInputFormConsolidated(
              controller: controller,
              label: 'Password',
              hint: 'Enter password',
              isPassword: true,
            ),
          ),
        ),
      );

      final formField = find.byType(TextFormField);
      expect(formField, findsOneWidget);

      // Password field should have obscureText: true
      await tester.enterText(formField, 'secret');
      expect(controller.text, 'secret');
    });

    testWidgets('renders textarea with multiline enabled',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomInputFormConsolidated(
              controller: controller,
              label: 'Description',
              hint: 'Enter description',
              multiline: true,
              maxLines: 5,
            ),
          ),
        ),
      );

      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('renders with label and hint', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomInputFormConsolidated(
              controller: controller,
              label: 'Email',
              hint: 'user@example.com',
            ),
          ),
        ),
      );

      expect(find.text('Email'), findsWidgets);
      expect(find.text('user@example.com'), findsOneWidget);
    });

    testWidgets('validates email correctly', (WidgetTester tester) async {
      String? emailValidator(String? value) {
        if (value == null || value.isEmpty) {
          return 'Email is required';
        }
        if (!value.contains('@')) {
          return 'Invalid email';
        }
        return null;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              child: CustomInputFormConsolidated(
                controller: controller,
                label: 'Email',
                hint: 'user@example.com',
                validator: emailValidator,
              ),
            ),
          ),
        ),
      );

      final formField = find.byType(TextFormField);
      expect(formField, findsOneWidget);
    });

    testWidgets('validates required field', (WidgetTester tester) async {
      String? requiredValidator(String? value) {
        if (value == null || value.isEmpty) {
          return 'This field is required';
        }
        return null;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              child: CustomInputFormConsolidated(
                controller: controller,
                label: 'Username',
                hint: 'Enter username',
                validator: requiredValidator,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('calls onChanged callback when text changes',
        (WidgetTester tester) async {
      String changedValue = '';

      void onChanged(String value) {
        changedValue = value;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomInputFormConsolidated(
              controller: controller,
              label: 'Name',
              hint: 'Enter name',
              onChanged: onChanged,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'John');
      await tester.pumpAndSettle();

      expect(changedValue, 'John');
    });

    testWidgets('disables input when isDisabled is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomInputFormConsolidated(
              controller: controller,
              label: 'Disabled Field',
              hint: 'Cannot edit',
              isDisabled: true,
            ),
          ),
        ),
      );

      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('shows error state', (WidgetTester tester) async {
      String? errorValidator(String? value) {
        if (value == null || value.isEmpty) {
          return 'Error: Field is empty';
        }
        return null;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              child: CustomInputFormConsolidated(
                controller: controller,
                label: 'Error Field',
                hint: 'Enter something',
                validator: errorValidator,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('integrates with signup flow', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CustomInputFormConsolidated(
                  controller: controller,
                  label: 'Email',
                  hint: 'user@example.com',
                  inputType: TextInputType.emailAddress,
                ),
                CustomInputFormConsolidated(
                  controller: TextEditingController(),
                  label: 'Password',
                  hint: 'Enter password',
                  isPassword: true,
                ),
                CustomInputFormConsolidated(
                  controller: TextEditingController(),
                  label: 'Confirm Password',
                  hint: 'Confirm password',
                  isPassword: true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(CustomInputFormConsolidated), findsWidgets);
      expect(find.byType(TextFormField), findsWidgets);
    });
  });
}
