import 'package:intl/intl.dart';

enum TipoRegistro { entrada, saida }

extension TipoRegistroApi on TipoRegistro {
  String get apiValue => this == TipoRegistro.entrada ? 'ENTRADA' : 'SAIDA';

  static TipoRegistro fromApi(String value) {
    final v = value.toUpperCase();
    if (v == 'ENTRADA') return TipoRegistro.entrada;
    return TipoRegistro.saida;
  }

  String get label => this == TipoRegistro.entrada ? 'Entrada' : 'Saída';
}

class PontoModel {
  final int id;
  final int parceiroId;
  final DateTime dataHora;
  final TipoRegistro tipo;
  final String? observacao;

  PontoModel({
    required this.id,
    required this.parceiroId,
    required this.dataHora,
    required this.tipo,
    this.observacao,
  });

  /// Ajuste esse parse caso o JSON do backend seja diferente.
  /// Aqui estou assumindo algo assim:
  /// {
  ///   "id": 1,
  ///   "parceiroId": 10,
  ///   "data": "2025-11-17",
  ///   "hora": "08:14:00",
  ///   "tipo": "ENTRADA",
  ///   "observacao": null
  /// }
  factory PontoModel.fromJson(Map<String, dynamic> json) {
    final dataStr = json['data'] as String?;
    final horaStr = json['hora'] as String?;

    DateTime dataHora;

    if (dataStr != null && horaStr != null) {
      dataHora = DateTime.parse('${dataStr}T$horaStr');
    } else if (json['dataHora'] != null) {
      dataHora = DateTime.parse(json['dataHora'] as String);
    } else {
      dataHora = DateTime.now();
    }

    return PontoModel(
      id: json['id'] as int,
      parceiroId: json['parceiroId'] as int,
      dataHora: dataHora,
      tipo: TipoRegistroApi.fromApi(json['tipo'] as String),
      observacao: json['observacao'] as String?,
    );
  }

  String get horaFormatada => DateFormat.Hm().format(dataHora);
}
