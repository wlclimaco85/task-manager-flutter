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

  /// Observacao padrao para uma competencia (mes/ano) escolhida no popUp.
  static String observacaoPadraoCompetencia(String servico, int mes, int ano) {
    return observacaoPadrao(servico, DateTime(ano, mes + 1));
  }

  static Map<String, dynamic> buildPayload({
    required List<int> parceiroIds,
    required bool todos,
    required int produtoId,
    required int serieId,
    required String observacao,
    int? mesReferencia,
    int? anoReferencia,
  }) {
    return {
      'parceiroIds': parceiroIds,
      'todos': todos,
      'produtoId': produtoId,
      'serieId': serieId,
      'observacao': observacao.trim(),
      if (mesReferencia != null) 'mesReferencia': mesReferencia,
      if (anoReferencia != null) 'anoReferencia': anoReferencia,
    };
  }
}
