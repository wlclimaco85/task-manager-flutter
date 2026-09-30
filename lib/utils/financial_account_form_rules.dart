/// Regras de campos e ordenação para formulários de contas financeiras
/// (conta_pagar e conta_receber).

bool isFinancialInternalFormField(String screenName, String fieldName) {
  final s = screenName.toLowerCase().replaceAll('_', '');
  if (s != 'contapagar' && s != 'contareceber') {
    return false;
  }
  final fn = fieldName.toLowerCase().replaceAll('_', '');
  return fn == 'moduloid' || fn == 'contratoid';
}

int financialAccountFormOrder({
  required String screenName,
  required String fieldName,
  required int backendOrder,
  required bool isRequired,
}) {
  final s = screenName.toLowerCase().replaceAll('_', '');
  if (s != 'contapagar' && s != 'contareceber') {
    return backendOrder;
  }

  final fn = fieldName.toLowerCase().replaceAll('_', '');

  // Dados de baixa vão para o final
  if (fn.contains('baixa')) {
    return 400 + backendOrder;
  }

  // Recorrência e parcelas
  if (fn.contains('recorrencia') ||
      fn == 'diavencimento' ||
      fn == 'parcelaatual' ||
      fn == 'totalparcelas' ||
      fn == 'valorparcela') {
    return 300 + backendOrder;
  }

  // Campos obrigatórios no topo
  if (isRequired) {
    return 100 + backendOrder;
  }

  // Campos gerais
  return 200 + backendOrder;
}
