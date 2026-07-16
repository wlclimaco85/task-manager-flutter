import 'package:flutter_test/flutter_test.dart';

// Mock classes para testes de dashboard
class MockContaBancaria {
  final String id;
  final String nome;
  final String banco;
  final double saldo;

  MockContaBancaria({
    required this.id,
    required this.nome,
    required this.banco,
    required this.saldo,
  });
}

/// Serviço mock para testes
class MockDashboardService {
  List<MockContaBancaria> contas = [];

  void adicionarConta(MockContaBancaria conta) {
    contas.add(conta);
  }

  /// Calcula total de saldo de todas as contas
  double calcularTotalSaldo() {
    if (contas.isEmpty) return 0.0;
    return contas.fold(0.0, (sum, conta) => sum + conta.saldo);
  }

  /// Retorna lista de contas
  List<MockContaBancaria> obterContas() {
    return contas;
  }

  /// Formata valor em moeda brasileira
  String formatarMoeda(double valor) {
    final formatter = _MoedaBRFormatter();
    return formatter.formatar(valor);
  }

  /// Reseta lista de contas
  void resetar() {
    contas.clear();
  }
}

/// Formatador de moeda brasileira
class _MoedaBRFormatter {
  String formatar(double valor) {
    final partes = valor.toStringAsFixed(2).split('.');
    final inteira = partes[0];
    final centavos = partes[1];
    return 'R\$ ${inteira.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    )},${centavos}';
  }
}

void main() {
  group('Dashboard — Testes Unit', () {
    late MockDashboardService dashboardService;

    setUp(() {
      dashboardService = MockDashboardService();
    });

    tearDown(() {
      dashboardService.resetar();
    });

    /// ===== TESTE 1: Calcular Total de Saldo =====
    test(
      'deve calcular total de saldo corretamente quando há múltiplas contas',
      () {
        // ARRANGE (Preparar dados)
        final conta1 = MockContaBancaria(
          id: '1',
          nome: 'Conta Corrente',
          banco: 'Banco X',
          saldo: 1000.50,
        );
        final conta2 = MockContaBancaria(
          id: '2',
          nome: 'Conta Poupança',
          banco: 'Banco Y',
          saldo: 2500.75,
        );
        final conta3 = MockContaBancaria(
          id: '3',
          nome: 'Conta Investimento',
          banco: 'Banco Z',
          saldo: 5000.00,
        );

        dashboardService.adicionarConta(conta1);
        dashboardService.adicionarConta(conta2);
        dashboardService.adicionarConta(conta3);

        // ACT (Executar ação)
        final totalSaldo = dashboardService.calcularTotalSaldo();

        // ASSERT (Validar resultado)
        expect(totalSaldo, 8501.25);
      },
    );

    /// ===== TESTE 2: Retornar Lista Vazia =====
    test(
      'deve retornar lista vazia quando nenhuma conta existe',
      () {
        // ARRANGE
        // Nenhuma conta adicionada (lista começa vazia)

        // ACT
        final contas = dashboardService.obterContas();
        final totalSaldo = dashboardService.calcularTotalSaldo();

        // ASSERT
        expect(contas, isEmpty);
        expect(totalSaldo, 0.0);
      },
    );

    /// ===== TESTE 3: Formatar Moeda Brasileira =====
    test(
      'deve formatar moeda em padrão brasileiro (R\$)',
      () {
        // ARRANGE
        const valor = 15750.89;

        // ACT
        final moedaFormatada = dashboardService.formatarMoeda(valor);

        // ASSERT
        expect(moedaFormatada, 'R\$ 15.750,89');
      },
    );

    /// ===== TESTE 4: Formatar Moeda com Valor Zero =====
    test(
      'deve formatar valor zero corretamente',
      () {
        // ARRANGE
        const valor = 0.0;

        // ACT
        final moedaFormatada = dashboardService.formatarMoeda(valor);

        // ASSERT
        expect(moedaFormatada, 'R\$ 0,00');
      },
    );

    /// ===== TESTE 5: Formatar Moeda com Valores Pequenos =====
    test(
      'deve formatar valores pequenos corretamente',
      () {
        // ARRANGE
        const valor = 123.45;

        // ACT
        final moedaFormatada = dashboardService.formatarMoeda(valor);

        // ASSERT
        expect(moedaFormatada, 'R\$ 123,45');
      },
    );

    /// ===== TESTE 6: Calcular Saldo com Uma Conta =====
    test(
      'deve calcular corretamente quando há apenas uma conta',
      () {
        // ARRANGE
        final conta = MockContaBancaria(
          id: '1',
          nome: 'Única Conta',
          banco: 'Banco Único',
          saldo: 999.99,
        );
        dashboardService.adicionarConta(conta);

        // ACT
        final total = dashboardService.calcularTotalSaldo();

        // ASSERT
        expect(total, 999.99);
      },
    );

    /// ===== TESTE 7: Resetar Dashboard =====
    test(
      'deve resetar dashboard removendo todas as contas',
      () {
        // ARRANGE
        dashboardService.adicionarConta(MockContaBancaria(
          id: '1',
          nome: 'Conta 1',
          banco: 'Banco',
          saldo: 1000.0,
        ));

        // ACT
        dashboardService.resetar();

        // ASSERT
        expect(dashboardService.obterContas(), isEmpty);
        expect(dashboardService.calcularTotalSaldo(), 0.0);
      },
    );

    /// ===== TESTE 8: Adicionar Múltiplas Contas Sequencialmente =====
    test(
      'deve manter histórico de múltiplas contas adicionadas',
      () {
        // ARRANGE
        for (int i = 1; i <= 5; i++) {
          dashboardService.adicionarConta(MockContaBancaria(
            id: '$i',
            nome: 'Conta $i',
            banco: 'Banco $i',
            saldo: i * 100.0,
          ));
        }

        // ACT
        final contas = dashboardService.obterContas();
        final total = dashboardService.calcularTotalSaldo();

        // ASSERT
        expect(contas.length, 5);
        expect(total, 1500.0); // (100 + 200 + 300 + 400 + 500)
      },
    );

    /// ===== TESTE 9: Formatar Moeda com Valores Grandes =====
    test(
      'deve formatar valores grandes com separador de milhares',
      () {
        // ARRANGE
        const valor = 1234567.89;

        // ACT
        final moedaFormatada = dashboardService.formatarMoeda(valor);

        // ASSERT
        expect(moedaFormatada, 'R\$ 1.234.567,89');
      },
    );

    /// ===== TESTE 10: Validar Precisão de Ponto Flutuante =====
    test(
      'deve manter precisão com operações de ponto flutuante',
      () {
        // ARRANGE
        final conta1 = MockContaBancaria(
          id: '1',
          nome: 'Conta 1',
          banco: 'Banco',
          saldo: 0.1,
        );
        final conta2 = MockContaBancaria(
          id: '2',
          nome: 'Conta 2',
          banco: 'Banco',
          saldo: 0.2,
        );
        dashboardService.adicionarConta(conta1);
        dashboardService.adicionarConta(conta2);

        // ACT
        final total = dashboardService.calcularTotalSaldo();

        // ASSERT (com tolerância)
        expect(total, closeTo(0.3, 0.001));
      },
    );
  });
}
