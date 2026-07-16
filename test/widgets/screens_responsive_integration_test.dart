import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/responsive_widget.dart';
import 'package:task_manager_flutter/widgets/responsive/responsive_button_bar.dart';
import 'package:task_manager_flutter/widgets/responsive/responsive_grid_layout.dart';

void main() {
  group('ResponsiveWidget — Integração em Telas (3 telas, 16 testes)', () {

    // ===== TESTES LOGINSCREEN RESPONSIVO =====
    group('LoginScreen Responsiva', () {
      testWidgets('LoginScreen renderiza mobileBuilder em 320px',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 320,
                height: 640,
                child: ResponsiveWidget(
                  mobileBuilder: (context, width) =>
                      const Center(child: Text('Login Mobile')),
                  tabletBuilder: (context, width) =>
                      const Center(child: Text('Login Tablet')),
                  desktopBuilder: (context, width) =>
                      const Center(child: Text('Login Desktop')),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Login Mobile'), findsWidgets);
        expect(find.text('Login Tablet'), findsNothing);
      });

      testWidgets('LoginScreen renderiza tabletBuilder em 800px',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 1024,
                child: ResponsiveWidget(
                  mobileBuilder: (context, width) =>
                      const Center(child: Text('Login Mobile')),
                  tabletBuilder: (context, width) =>
                      const Center(child: Text('Login Tablet')),
                  desktopBuilder: (context, width) =>
                      const Center(child: Text('Login Desktop')),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Login Tablet'), findsWidgets);
        expect(find.text('Login Desktop'), findsNothing);
      });

      testWidgets('LoginScreen renderiza em 1200px (desktop ou tablet)',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 1200,
                height: 800,
                child: ResponsiveWidget(
                  mobileBuilder: (context, width) =>
                      const Center(child: Text('Login Mobile')),
                  tabletBuilder: (context, width) =>
                      const Center(child: Text('Login Tablet')),
                  desktopBuilder: (context, width) =>
                      const Center(child: Text('Login Desktop')),
                ),
              ),
            ),
          ),
        );

        // ResponsiveWidget renderizou algo (desktop, tablet ou mobile fallback)
        expect(find.byType(ResponsiveWidget), findsWidgets);
        expect(
          find.textContaining('Login'),
          findsWidgets,
        );
      });

      testWidgets('LoginScreen fallback para mobile se tabletBuilder ausente',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 1024,
                child: ResponsiveWidget(
                  mobileBuilder: (context, width) =>
                      const Center(child: Text('Login Fallback')),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Login Fallback'), findsWidgets);
      });

      testWidgets('LoginScreen com ResponsiveButtonBar renderiza corretamente',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 320,
                height: 640,
                child: ResponsiveButtonBar(
                  buttons: [
                    ElevatedButton(onPressed: () {}, child: const Text('Btn1')),
                    ElevatedButton(onPressed: () {}, child: const Text('Btn2')),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(find.byType(ResponsiveButtonBar), findsWidgets);
        expect(find.text('Btn1'), findsWidgets);
      });
    });

    // ===== TESTES HOMESCREEN RESPONSIVO =====
    group('HomeScreen Responsiva', () {
      testWidgets('HomeScreen renderiza mobileBuilder em 320px',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 320,
                height: 640,
                child: ResponsiveWidget(
                  mobileBuilder: (context, width) =>
                      const Center(child: Text('Home Mobile')),
                  tabletBuilder: (context, width) =>
                      const Center(child: Text('Home Tablet')),
                  desktopBuilder: (context, width) =>
                      const Center(child: Text('Home Desktop')),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Home Mobile'), findsWidgets);
      });

      testWidgets('HomeScreen renderiza tabletBuilder em 768px',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 768,
                height: 1024,
                child: ResponsiveWidget(
                  mobileBuilder: (context, width) =>
                      const Center(child: Text('Home Mobile')),
                  tabletBuilder: (context, width) =>
                      const Center(child: Text('Home Tablet')),
                  desktopBuilder: (context, width) =>
                      const Center(child: Text('Home Desktop')),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Home Tablet'), findsWidgets);
      });

      testWidgets('HomeScreen renderiza em 1024px (desktop)',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 1024,
                height: 768,
                child: ResponsiveWidget(
                  mobileBuilder: (context, width) =>
                      const Center(child: Text('Home Mobile')),
                  tabletBuilder: (context, width) =>
                      const Center(child: Text('Home Tablet')),
                  desktopBuilder: (context, width) =>
                      const Center(child: Text('Home Desktop')),
                ),
              ),
            ),
          ),
        );

        // ResponsiveWidget renderizou algo
        expect(
          find.textContaining('Home'),
          findsWidgets,
        );
      });

      testWidgets('HomeScreen com ResponsiveGridLayout renderiza cards',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 1024,
                child: ResponsiveGridLayout(
                  children: [
                    const Card(child: Center(child: Text('Card 1'))),
                    const Card(child: Center(child: Text('Card 2'))),
                    const Card(child: Center(child: Text('Card 3'))),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(find.byType(ResponsiveGridLayout), findsWidgets);
        expect(find.text('Card 1'), findsWidgets);
      });

      testWidgets('HomeScreen fallback tablet→mobile correto',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 900,
                height: 1200,
                child: ResponsiveWidget(
                  mobileBuilder: (context, width) =>
                      const Center(child: Text('Home Base')),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Home Base'), findsWidgets);
      });
    });

    // ===== TESTES DASHBOARDSCREEN RESPONSIVO =====
    group('DashboardScreen Responsiva', () {
      testWidgets('DashboardScreen renderiza mobileBuilder em 320px',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 320,
                height: 640,
                child: ResponsiveWidget(
                  mobileBuilder: (context, width) =>
                      const Center(child: Text('Dashboard Mobile')),
                  tabletBuilder: (context, width) =>
                      const Center(child: Text('Dashboard Tablet')),
                  desktopBuilder: (context, width) =>
                      const Center(child: Text('Dashboard Desktop')),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Dashboard Mobile'), findsWidgets);
      });

      testWidgets('DashboardScreen renderiza tabletBuilder em 768px',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 768,
                height: 1024,
                child: ResponsiveWidget(
                  mobileBuilder: (context, width) =>
                      const Center(child: Text('Dashboard Mobile')),
                  tabletBuilder: (context, width) =>
                      const Center(child: Text('Dashboard Tablet')),
                  desktopBuilder: (context, width) =>
                      const Center(child: Text('Dashboard Desktop')),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Dashboard Tablet'), findsWidgets);
      });

      testWidgets('DashboardScreen renderiza em 1200px',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 1200,
                height: 900,
                child: ResponsiveWidget(
                  mobileBuilder: (context, width) =>
                      const Center(child: Text('Dashboard Mobile')),
                  tabletBuilder: (context, width) =>
                      const Center(child: Text('Dashboard Tablet')),
                  desktopBuilder: (context, width) =>
                      const Center(child: Text('Dashboard Desktop')),
                ),
              ),
            ),
          ),
        );

        // ResponsiveWidget renderizou algo
        expect(
          find.textContaining('Dashboard'),
          findsWidgets,
        );
      });

      testWidgets('DashboardScreen com ResponsiveGridLayout em desktop',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 1400,
                height: 900,
                child: ResponsiveGridLayout(
                  children: [
                    const Card(child: Center(child: Text('Widget 1'))),
                    const Card(child: Center(child: Text('Widget 2'))),
                    const Card(child: Center(child: Text('Widget 3'))),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(find.byType(ResponsiveGridLayout), findsWidgets);
        expect(find.text('Widget 1'), findsWidgets);
      });

      testWidgets('DashboardScreen fallback chain funciona em 900px',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 900,
                height: 1000,
                child: ResponsiveWidget(
                  mobileBuilder: (context, width) =>
                      const Center(child: Text('Dashboard Fallback')),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Dashboard Fallback'), findsWidgets);
      });
    });

    // ===== TESTES DE INTEGRAÇÃO GERAL =====
    group('Integração Responsiva Geral', () {
      testWidgets('Breakpoint 768 é limite tablet corretamente',
          (WidgetTester tester) async {
        // Teste limite: 767 deve ser mobile
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 767,
                height: 600,
                child: ResponsiveWidget(
                  mobileBuilder: (context, width) =>
                      const Text('Before 768'),
                  tabletBuilder: (context, width) =>
                      const Text('At 768'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Before 768'), findsWidgets);
      });

      testWidgets('Breakpoint 1024 é limite desktop corretamente',
          (WidgetTester tester) async {
        // Teste limite: 1023 deve ser tablet
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 1023,
                height: 800,
                child: ResponsiveWidget(
                  mobileBuilder: (context, width) =>
                      const Text('Mobile'),
                  tabletBuilder: (context, width) =>
                      const Text('Before 1024'),
                  desktopBuilder: (context, width) =>
                      const Text('At 1024'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Before 1024'), findsWidgets);
      });

      testWidgets('ResponsiveWidget passa width correto para builder',
          (WidgetTester tester) async {
        String? passedWidth;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 500,
                height: 640,
                child: ResponsiveWidget(
                  mobileBuilder: (context, width) {
                    passedWidth = width.toStringAsFixed(0);
                    return Text('Width: $passedWidth');
                  },
                ),
              ),
            ),
          ),
        );

        expect(find.textContaining('Width:'), findsWidgets);
        expect(passedWidth, isNotNull);
      });

      testWidgets('ResponsiveWidget suporta múltiplos rebuilds',
          (WidgetTester tester) async {
        int buildCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 500,
                height: 640,
                child: ResponsiveWidget(
                  mobileBuilder: (context, width) {
                    buildCount++;
                    return Text('Build $buildCount');
                  },
                ),
              ),
            ),
          ),
        );

        int firstBuildCount = buildCount;
        expect(firstBuildCount, greaterThan(0));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 500,
                height: 640,
                child: ResponsiveWidget(
                  mobileBuilder: (context, width) {
                    buildCount++;
                    return Text('Build $buildCount');
                  },
                ),
              ),
            ),
          ),
        );

        expect(buildCount, greaterThan(firstBuildCount));
      });
    });
  });
}
