import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget de formulário de cobrança simplificado
class CobrancaFormSimples extends StatefulWidget {
  final Function(String, double, String) onSubmit;

  const CobrancaFormSimples({
    required this.onSubmit,
    Key? key,
  }) : super(key: key);

  @override
  State<CobrancaFormSimples> createState() => _CobrancaFormSimplesState();
}

class _CobrancaFormSimplesState extends State<CobrancaFormSimples> {
  final _formKey = GlobalKey<FormState>();
  final _clienteController = TextEditingController();
  final _valorController = TextEditingController();
  final _dataController = TextEditingController();

  @override
  void dispose() {
    _clienteController.dispose();
    _valorController.dispose();
    _dataController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Formulário Cobrança')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                key: const Key('campo_cliente'),
                controller: _clienteController,
                decoration: const InputDecoration(labelText: 'Cliente'),
                validator: (v) => v?.isEmpty ?? true ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('campo_valor'),
                controller: _valorController,
                decoration: const InputDecoration(labelText: 'Valor'),
                keyboardType: TextInputType.number,
                validator: (v) => v?.isEmpty ?? true ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('campo_data'),
                controller: _dataController,
                decoration: const InputDecoration(labelText: 'Data'),
                validator: (v) => v?.isEmpty ?? true ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                key: const Key('botao_enviar'),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onSubmit(
                      _clienteController.text,
                      double.parse(_valorController.text),
                      _dataController.text,
                    );
                  }
                },
                child: const Text('Enviar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  group('Cobrança Flow — Testes Widget', () {
    testWidgets(
      'formulário deve validar campos obrigatórios',
      (WidgetTester tester) async {
        bool enviado = false;
        await tester.pumpWidget(
          MaterialApp(
            home: CobrancaFormSimples(
              onSubmit: (_, __, ___) {
                enviado = true;
              },
            ),
          ),
        );

        final botao = find.byKey(const Key('botao_enviar'));
        await tester.tap(botao);
        await tester.pumpAndSettle();

        expect(find.text('Obrigatório'), findsWidgets);
        expect(enviado, false);
      },
    );

    testWidgets(
      'deve aceitar formulário com campos válidos',
      (WidgetTester tester) async {
        bool enviado = false;
        String? cliente;
        double? valor;

        await tester.pumpWidget(
          MaterialApp(
            home: CobrancaFormSimples(
              onSubmit: (c, v, _) {
                enviado = true;
                cliente = c;
                valor = v;
              },
            ),
          ),
        );

        await tester.enterText(
          find.byKey(const Key('campo_cliente')),
          'Cliente XYZ',
        );
        await tester.enterText(
          find.byKey(const Key('campo_valor')),
          '150.50',
        );
        await tester.enterText(
          find.byKey(const Key('campo_data')),
          '2026-12-31',
        );

        await tester.tap(find.byKey(const Key('botao_enviar')));
        await tester.pump();

        expect(enviado, true);
        expect(cliente, 'Cliente XYZ');
        expect(valor, 150.50);
      },
    );

    testWidgets(
      'deve exibir campo cliente visível',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: CobrancaFormSimples(
              onSubmit: (_, __, ___) {},
            ),
          ),
        );

        expect(find.byKey(const Key('campo_cliente')), findsOneWidget);
      },
    );

    testWidgets(
      'deve exibir campo valor visível',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: CobrancaFormSimples(
              onSubmit: (_, __, ___) {},
            ),
          ),
        );

        expect(find.byKey(const Key('campo_valor')), findsOneWidget);
      },
    );

    testWidgets(
      'deve exibir botão enviar',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: CobrancaFormSimples(
              onSubmit: (_, __, ___) {},
            ),
          ),
        );

        expect(find.byKey(const Key('botao_enviar')), findsOneWidget);
      },
    );
  });
}
