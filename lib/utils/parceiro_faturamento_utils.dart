class ParceiroFaturamentoUtils {
  static String observacaoPadrao(String servico, DateTime hoje) {
    const meses = [
      'Janeiro',
      'Fevereiro',
      'Marco',
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
    final competencia = DateTime(hoje.year, hoje.month - 1);
    return '$servico - ${meses[competencia.month - 1]}/${competencia.year}';
  }

  static Map<String, dynamic> buildPayload({
    required List<int> parceiroIds,
    required bool todos,
    required int produtoId,
    required int serieId,
    required String observacao,
  }) {
    return {
      'parceiroIds': parceiroIds,
      'todos': todos,
      'produtoId': produtoId,
      'serieId': serieId,
      'observacao': observacao.trim(),
    };
  }
}
