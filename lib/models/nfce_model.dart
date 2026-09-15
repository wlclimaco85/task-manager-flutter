import 'package:intl/intl.dart';

class NfceModel {
  final int id;
  final String? chaveAcesso;
  final int? numero;
  final int? serie;
  final String statusSefaz;
  final String? protocolo;
  final String? motivoRejeicao;
  final String? danfeUrl;
  final int? vendaId;
  final double? valorTotal;
  final DateTime? dataEmissao;

  const NfceModel({
    required this.id,
    this.chaveAcesso,
    this.numero,
    this.serie,
    required this.statusSefaz,
    this.protocolo,
    this.motivoRejeicao,
    this.danfeUrl,
    this.vendaId,
    this.valorTotal,
    this.dataEmissao,
  });

  factory NfceModel.fromJson(Map<String, dynamic> json) {
    return NfceModel(
      id: json['id'] ?? 0,
      chaveAcesso: json['chaveAcesso'],
      numero: json['numero'],
      serie: json['serie'],
      statusSefaz: json['statusSefaz'] ?? 'PENDENTE',
      protocolo: json['protocolo'],
      motivoRejeicao: json['motivoRejeicao'],
      danfeUrl: json['danfeUrl'],
      vendaId: json['vendaId'],
      valorTotal: json['valorTotal'] != null ? double.tryParse(json['valorTotal'].toString()) : null,
      dataEmissao: json['dataEmissao'] != null ? DateTime.tryParse(json['dataEmissao'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (chaveAcesso != null) 'chaveAcesso': chaveAcesso,
      if (numero != null) 'numero': numero,
      if (serie != null) 'serie': serie,
      'statusSefaz': statusSefaz,
      if (protocolo != null) 'protocolo': protocolo,
      if (motivoRejeicao != null) 'motivoRejeicao': motivoRejeicao,
      if (danfeUrl != null) 'danfeUrl': danfeUrl,
      if (vendaId != null) 'vendaId': vendaId,
      if (valorTotal != null) 'valorTotal': valorTotal,
      if (dataEmissao != null) 'dataEmissao': dataEmissao?.toIso8601String(),
    };
  }

  String get numeroFormatado => numero != null ? numero.toString().padLeft(9, '0') : '';
  String get serieFormatada => serie != null ? serie.toString().padLeft(3, '0') : '';
}
