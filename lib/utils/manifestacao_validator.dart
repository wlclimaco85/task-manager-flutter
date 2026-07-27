import '../models/manifestacao/manifestacao_status.dart';

/// Utilitário de validação para Manifestação
class ManifestacaoValidator {
  /// Valida status (obrigatório)
  static String? validateStatus(ManifestacaoStatus? value) {
    if (value == null) {
      return 'Status é obrigatório';
    }
    return null;
  }

  /// Valida observação (obrigatória para recusa)
  static String? validateObservacao(
    String? value,
    ManifestacaoStatus? status,
  ) {
    if (status == ManifestacaoStatus.recusar) {
      if (value == null || value.trim().isEmpty) {
        return 'Observação é obrigatória para recusa';
      }
      if (value.length < 10) {
        return 'Observação deve ter pelo menos 10 caracteres';
      }
    }
    if (value != null && value.length > 500) {
      return 'Observação não pode exceder 500 caracteres';
    }
    return null;
  }

  /// Valida quantidade recebida (obrigatória para parcial)
  static String? validateQuantidade(
    int? value,
    ManifestacaoStatus? status,
  ) {
    if (status == ManifestacaoStatus.parcial) {
      if (value == null || value <= 0) {
        return 'Quantidade deve ser maior que 0';
      }
    }
    return null;
  }

  /// Valida motivo da recusa (obrigatório para recusa total)
  static String? validateMotivoRecusa(
    String? value,
    ManifestacaoStatus? status,
  ) {
    if (status == ManifestacaoStatus.recusar) {
      if (value == null || value.trim().isEmpty) {
        return 'Motivo é obrigatório';
      }
    }
    return null;
  }

  /// Valida todo o formulário
  static Map<String, String> validateAll({
    required ManifestacaoStatus? status,
    required String observacao,
    required int? quantidadeRecebida,
    required String? motivoRecusa,
  }) {
    final errors = <String, String>{};

    final statusError = validateStatus(status);
    if (statusError != null) {
      errors['status'] = statusError;
    }

    final obsError = validateObservacao(observacao, status);
    if (obsError != null) {
      errors['observacao'] = obsError;
    }

    final qtdError = validateQuantidade(quantidadeRecebida, status);
    if (qtdError != null) {
      errors['quantidadeRecebida'] = qtdError;
    }

    final motivoError = validateMotivoRecusa(motivoRecusa, status);
    if (motivoError != null) {
      errors['motivoRecusa'] = motivoError;
    }

    return errors;
  }
}
