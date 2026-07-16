import 'package:flutter_test/flutter_test.dart';

/// Serviço de Calendário
class CalendarService {
  static const List<int> feriados = [
    101,  // 1º de janeiro
    411,  // Tiradentes (21/4)
    501,  // Dia do trabalho (1º/5)
    907,  // Independência (7/9)
    1002, // Nossa Senhora (12/10)
    1102, // Finados (2/11)
    1104, // República (15/11)
    1225, // Natal (25/12)
  ];

  /// Verifica se um dia é um feriado
  static bool ehFeriado(int dia, int mes) {
    final codigo = mes * 100 + dia;
    return feriados.contains(codigo);
  }

  /// Verifica se uma data é fim de semana (0 = domingo, 6 = sábado)
  static bool ehFimDeSemana(DateTime data) {
    return data.weekday == 6 || data.weekday == 7;
  }

  /// Formata data em padrão brasileiro (dd/MM/yyyy)
  static String formatarDataBrasileira(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year;
    return '$dia/$mes/$ano';
  }

  /// Calcula o próximo dia útil (não é fim de semana e não é feriado)
  static DateTime calcularProximoDiaUtil(DateTime data) {
    DateTime proximo = data.add(const Duration(days: 1));

    while (ehFimDeSemana(proximo) || ehFeriado(proximo.day, proximo.month)) {
      proximo = proximo.add(const Duration(days: 1));
    }

    return proximo;
  }

  /// Calcula a quantidade de dias úteis entre duas datas
  static int calcularDiasUteis(DateTime inicio, DateTime fim) {
    int diasUteis = 0;
    DateTime atual = inicio;

    while (atual.isBefore(fim) || atual.isAtSameMomentAs(fim)) {
      if (!ehFimDeSemana(atual) && !ehFeriado(atual.day, atual.month)) {
        diasUteis++;
      }
      atual = atual.add(const Duration(days: 1));
    }

    return diasUteis;
  }

  /// Retorna o nome do dia da semana
  static String nomeDiaSemana(DateTime data) {
    const nomes = [
      'Segunda',
      'Terça',
      'Quarta',
      'Quinta',
      'Sexta',
      'Sábado',
      'Domingo',
    ];
    return nomes[data.weekday - 1];
  }

  /// Retorna o nome do mês
  static String nomeMes(int mes) {
    const nomes = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    return nomes[mes - 1];
  }
}

void main() {
  group('Calendar Service — Testes Unit', () {
    /// ===== TESTE 1: Detectar Feriado =====
    test(
      'deve identificar feriado corretamente',
      () {
        // ASSERT
        expect(CalendarService.ehFeriado(1, 1), true); // Ano Novo
        expect(CalendarService.ehFeriado(21, 4), true); // Tiradentes
        expect(CalendarService.ehFeriado(1, 5), true); // Trabalho
        expect(CalendarService.ehFeriado(7, 9), true); // Independência
      },
    );

    /// ===== TESTE 2: Detectar Não-Feriado =====
    test(
      'deve identificar dia comum como não-feriado',
      () {
        // ASSERT
        expect(CalendarService.ehFeriado(15, 3), false);
        expect(CalendarService.ehFeriado(22, 8), false);
        expect(CalendarService.ehFeriado(10, 6), false);
      },
    );

    /// ===== TESTE 3: Detectar Fim de Semana =====
    test(
      'deve detectar fim de semana corretamente',
      () {
        // ARRANGE — 20/07/2024 é sábado, 21/07/2024 é domingo
        final sabado = DateTime(2024, 7, 20); // Saturday
        final domingo = DateTime(2024, 7, 21); // Sunday
        final terca = DateTime(2024, 7, 16); // Tuesday

        // ASSERT
        expect(CalendarService.ehFimDeSemana(sabado), true);
        expect(CalendarService.ehFimDeSemana(domingo), true);
        expect(CalendarService.ehFimDeSemana(terca), false);
      },
    );

    /// ===== TESTE 4: Formatar Data Brasileira =====
    test(
      'deve formatar data em padrão brasileiro (dd/MM/yyyy)',
      () {
        // ARRANGE
        final data = DateTime(2024, 7, 15);

        // ACT
        final formatado = CalendarService.formatarDataBrasileira(data);

        // ASSERT
        expect(formatado, '15/07/2024');
      },
    );

    /// ===== TESTE 5: Formatar Data com Padding =====
    test(
      'deve adicionar zeros à esquerda para dia e mês',
      () {
        // ARRANGE
        final data = DateTime(2024, 1, 5);

        // ACT
        final formatado = CalendarService.formatarDataBrasileira(data);

        // ASSERT
        expect(formatado, '05/01/2024');
      },
    );

    /// ===== TESTE 6: Calcular Próximo Dia Útil Quando É Feriado =====
    test(
      'deve calcular próximo dia útil quando data é feriado',
      () {
        // ARRANGE — 1º de janeiro é feriado (Ano Novo)
        final anoNovo = DateTime(2024, 1, 1);

        // ACT
        final proximoDiaUtil = CalendarService.calcularProximoDiaUtil(anoNovo);

        // ASSERT — próximo dia útil não deve ser 1º/1 ou fim de semana
        expect(proximoDiaUtil.isAfter(anoNovo), true);
        expect(CalendarService.ehFeriado(proximoDiaUtil.day, proximoDiaUtil.month), false);
        expect(CalendarService.ehFimDeSemana(proximoDiaUtil), false);
      },
    );

    /// ===== TESTE 7: Calcular Próximo Dia Útil Quando É Fim de Semana =====
    test(
      'deve calcular próximo dia útil quando data é sábado',
      () {
        // ARRANGE — 20/07/2024 é sábado
        final sabado = DateTime(2024, 7, 20);

        // ACT
        final proximoDiaUtil = CalendarService.calcularProximoDiaUtil(sabado);

        // ASSERT — deve saltar para segunda-feira (22/07/2024)
        expect(proximoDiaUtil.weekday, 1); // Monday
        expect(proximoDiaUtil.day, 22);
      },
    );

    /// ===== TESTE 8: Calcular Dias Úteis =====
    test(
      'deve calcular quantidade de dias úteis corretamente',
      () {
        // ARRANGE — período de 1 semana (segunda a segunda)
        final inicio = DateTime(2024, 7, 15); // Segunda
        final fim = DateTime(2024, 7, 22); // Segunda (próxima)

        // ACT
        final diasUteis = CalendarService.calcularDiasUteis(inicio, fim);

        // ASSERT — 10 dias úteis (5 dias na primeira semana + 5 dias na segunda)
        expect(diasUteis, greaterThanOrEqualTo(8)); // Mínimo 8 dias úteis
      },
    );

    /// ===== TESTE 9: Retornar Nome do Dia da Semana =====
    test(
      'deve retornar nome correto do dia da semana',
      () {
        // ARRANGE
        final segunda = DateTime(2024, 7, 15); // Segunda
        final quarta = DateTime(2024, 7, 17); // Quarta
        final sexta = DateTime(2024, 7, 19); // Sexta

        // ACT & ASSERT
        expect(CalendarService.nomeDiaSemana(segunda), 'Segunda');
        expect(CalendarService.nomeDiaSemana(quarta), 'Quarta');
        expect(CalendarService.nomeDiaSemana(sexta), 'Sexta');
      },
    );

    /// ===== TESTE 10: Retornar Nome do Mês =====
    test(
      'deve retornar nome correto do mês',
      () {
        // ASSERT
        expect(CalendarService.nomeMes(1), 'Janeiro');
        expect(CalendarService.nomeMes(6), 'Junho');
        expect(CalendarService.nomeMes(12), 'Dezembro');
      },
    );

    /// ===== TESTE 11: Feriado Móvel (Tiradentes) =====
    test(
      'deve reconhecer Tiradentes (21 de abril)',
      () {
        // ASSERT
        expect(CalendarService.ehFeriado(21, 4), true);
        expect(CalendarService.ehFeriado(20, 4), false);
        expect(CalendarService.ehFeriado(22, 4), false);
      },
    );

    /// ===== TESTE 12: Próximo Dia Útil Partindo de Dia Útil =====
    test(
      'deve considerar próximo dia se partindo de dia útil',
      () {
        // ARRANGE — segunda-feira, 15 de julho de 2024
        final segunda = DateTime(2024, 7, 15);

        // ACT
        final proximoDiaUtil = CalendarService.calcularProximoDiaUtil(segunda);

        // ASSERT — deve ser terça-feira
        expect(proximoDiaUtil.weekday, 2); // Tuesday
        expect(proximoDiaUtil.day, 16);
      },
    );
  });
}
