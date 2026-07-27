import 'manifestacao_status.dart';

/// Modelo de dados para Manifestação de Recebimento de NFe
class ManifestacaoModel {
  final String nfeId;
  final String numero;
  final String fornecedor;
  final String valor;
  final DateTime dataEmissao;
  ManifestacaoStatus? status;
  String observacao;
  int? quantidadeRecebida;
  String? motivoRecusa;

  ManifestacaoModel({
    required this.nfeId,
    required this.numero,
    required this.fornecedor,
    required this.valor,
    required this.dataEmissao,
    this.status,
    this.observacao = '',
    this.quantidadeRecebida,
    this.motivoRecusa,
  });

  /// CR-06: Valida se o formulário pode ser submetido
  /// Validação crítica de quantidade: > 0 e <= 999999
  bool get isValid {
    if (status == null) return false;
    
    if (status == ManifestacaoStatus.recusar) {
      if (observacao.isEmpty) return false;
    }
    
    if (status == ManifestacaoStatus.parcial) {
      // CR-06 VALIDAÇÃO CRÍTICA
      if (quantidadeRecebida == null) return false;
      if (quantidadeRecebida! <= 0) return false;      // ← REJEITA NEGATIVO
      if (quantidadeRecebida! > 999999) return false;  // ← REJEITA > 999999
    }
    
    return true;
  }

  /// Converte para JSON para enviar à API
  Map<String, dynamic> toJson() {
    return {
      'nfeId': nfeId,
      'numero': numero,
      'status': status?.codigo,
      'observacao': observacao,
      'quantidadeRecebida': quantidadeRecebida,
      'motivoRecusa': motivoRecusa,
    };
  }

  /// Cria instância a partir de JSON
  factory ManifestacaoModel.fromJson(Map<String, dynamic> json) {
    return ManifestacaoModel(
      nfeId: json['nfeId'] as String,
      numero: json['numero'] as String,
      fornecedor: json['fornecedor'] as String,
      valor: json['valor'] as String,
      dataEmissao: json['dataEmissao'] != null
          ? DateTime.parse(json['dataEmissao'] as String)
          : DateTime.now(),
      status: ManifestacaoStatus.fromCodigo(json['status'] as String?),
      observacao: json['observacao'] as String? ?? '',
      quantidadeRecebida: json['quantidadeRecebida'] as int?,
      motivoRecusa: json['motivoRecusa'] as String?,
    );
  }

  /// Cópia com novos valores
  ManifestacaoModel copyWith({
    String? nfeId,
    String? numero,
    String? fornecedor,
    String? valor,
    DateTime? dataEmissao,
    ManifestacaoStatus? status,
    String? observacao,
    int? quantidadeRecebida,
    String? motivoRecusa,
  }) {
    return ManifestacaoModel(
      nfeId: nfeId ?? this.nfeId,
      numero: numero ?? this.numero,
      fornecedor: fornecedor ?? this.fornecedor,
      valor: valor ?? this.valor,
      dataEmissao: dataEmissao ?? this.dataEmissao,
      status: status ?? this.status,
      observacao: observacao ?? this.observacao,
      quantidadeRecebida: quantidadeRecebida ?? this.quantidadeRecebida,
      motivoRecusa: motivoRecusa ?? this.motivoRecusa,
    );
  }
}
