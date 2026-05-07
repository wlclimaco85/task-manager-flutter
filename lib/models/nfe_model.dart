import 'package:flutter/material.dart';

class NfeItem {
  int? id;
  String? cProd;
  String? xProd;
  String? ncm;
  String? cfop;
  String? uCom;
  double? qCom;
  double? vUnCom;
  double? vProd;
  String? cstIcms;
  double? aliqIcms;
  double? vBcIcms;
  double? vIcms;

  NfeItem.fromJson(Map<String, dynamic> j) {
    id = j['id'];
    cProd = j['cProd']?.toString();
    xProd = j['xProd']?.toString();
    ncm = j['ncm']?.toString();
    cfop = j['cfop']?.toString();
    uCom = j['uCom']?.toString();
    qCom = (j['qCom'] as num?)?.toDouble();
    vUnCom = (j['vUnCom'] as num?)?.toDouble();
    vProd = (j['vProd'] as num?)?.toDouble();
    cstIcms = j['cstIcms']?.toString();
    aliqIcms = (j['aliqIcms'] as num?)?.toDouble();
    vBcIcms = (j['vBcIcms'] as num?)?.toDouble();
    vIcms = (j['vIcms'] as num?)?.toDouble();
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'cProd': cProd, 'xProd': xProd, 'ncm': ncm, 'cfop': cfop,
    'uCom': uCom, 'qCom': qCom, 'vUnCom': vUnCom, 'vProd': vProd,
    'cstIcms': cstIcms, 'aliqIcms': aliqIcms, 'vBcIcms': vBcIcms, 'vIcms': vIcms,
  };
}

class Nfe {
  int? id;
  String? chave;
  String? numero;
  String? serie;
  String? status;
  String? protocoloAut;
  String? motivoAut;
  String? ambiente;
  String? finalidade;
  String? tipoOperacao;
  String? dhEmi;
  Map<String, dynamic>? empresa;
  Map<String, dynamic>? parceiro;
  Map<String, dynamic>? destinatario;
  List<NfeItem> itens;

  Nfe({
    this.id, this.chave, this.numero, this.serie, this.status,
    this.protocoloAut, this.motivoAut, this.ambiente, this.finalidade,
    this.tipoOperacao, this.dhEmi, this.empresa, this.parceiro,
    this.destinatario, this.itens = const [],
  });

  factory Nfe.fromJson(Map<String, dynamic> j) {
    return Nfe(
      id: j['id'],
      chave: j['chave']?.toString(),
      numero: j['numero']?.toString(),
      serie: j['serie']?.toString(),
      status: j['status']?.toString(),
      protocoloAut: j['protocoloAut']?.toString(),
      motivoAut: j['motivoAut']?.toString(),
      ambiente: j['ambiente']?.toString(),
      finalidade: j['finalidade']?.toString(),
      tipoOperacao: j['tipoOperacao']?.toString(),
      dhEmi: j['dhEmi']?.toString(),
      empresa: j['empresa'] is Map ? Map<String, dynamic>.from(j['empresa']) : null,
      parceiro: j['parceiro'] is Map ? Map<String, dynamic>.from(j['parceiro']) : null,
      destinatario: j['destinatario'] is Map ? Map<String, dynamic>.from(j['destinatario']) : null,
      itens: (j['itens'] as List? ?? []).whereType<Map>()
          .map((e) => NfeItem.fromJson(Map<String, dynamic>.from(e))).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'chave': chave, 'numero': numero, 'serie': serie, 'status': status,
    'ambiente': ambiente, 'finalidade': finalidade, 'tipoOperacao': tipoOperacao,
    'dhEmi': dhEmi,
    if (empresa != null) 'empresa': empresa,
    if (parceiro != null) 'parceiro': parceiro,
    if (destinatario != null) 'destinatario': destinatario,
  };

  String get parceiroNome => parceiro?['nome']?.toString() ?? '';
  String get destinatarioNome => destinatario?['nome']?.toString() ?? '';
  String get empresaNome => empresa?['nome']?.toString() ?? '';

  Color get statusColor {
    switch (status?.toUpperCase()) {
      case 'AUTORIZADA': return const Color(0xFF2E7D32);
      case 'CANCELADA':  return const Color(0xFFD32F2F);
      case 'REJEITADA':  return const Color(0xFFE65100);
      case 'PENDENTE':   return const Color(0xFFF9A825);
      default:           return const Color(0xFF757575);
    }
  }
}
