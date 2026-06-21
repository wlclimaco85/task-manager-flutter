enum CanalCobranca {
  email('EMAIL', 'E-mail', true),
  notificacaoInterna('NOTIFICACAO_INTERNA', 'Notificacao interna', true),
  whatsapp('WHATSAPP', 'WhatsApp', false),
  sms('SMS', 'SMS', false);

  const CanalCobranca(this.apiValue, this.label, this.disponivel);

  final String apiValue;
  final String label;
  final bool disponivel;

  static CanalCobranca fromJson(Object? value) {
    final normalized = value?.toString().toUpperCase() ?? '';
    return values.firstWhere(
      (canal) => canal.apiValue == normalized,
      orElse: () => email,
    );
  }
}

class ReguaCobranca {
  const ReguaCobranca({
    this.id,
    required this.nome,
    required this.diasAposVencimento,
    required this.canal,
    required this.mensagem,
    required this.somenteDiaUtil,
    required this.ordem,
    this.ativo = true,
  });

  final int? id;
  final String nome;
  final int diasAposVencimento;
  final CanalCobranca canal;
  final String mensagem;
  final bool somenteDiaUtil;
  final int ordem;
  final bool ativo;

  factory ReguaCobranca.fromJson(Map<String, dynamic> json) {
    return ReguaCobranca(
      id: _asInt(json['id']),
      nome: json['nome']?.toString() ?? 'Etapa de cobranca',
      diasAposVencimento: _asInt(json['diasAposVencimento']) ?? 0,
      canal: CanalCobranca.fromJson(json['canal']),
      mensagem: json['mensagem']?.toString() ?? '',
      somenteDiaUtil: _asBool(json['somenteDiaUtil'], fallback: true),
      ordem: _asInt(json['ordem']) ?? 1,
      ativo: _asBool(json['ativo'], fallback: true),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'nome': nome,
        'diasAposVencimento': diasAposVencimento,
        'canal': canal.apiValue,
        'mensagem': mensagem,
        'somenteDiaUtil': somenteDiaUtil,
        'ordem': ordem,
        'ativo': ativo,
      };
}

class ExecucaoReguaResultado {
  const ExecucaoReguaResultado({
    required this.titulosAvaliados,
    required this.enviosEnfileirados,
    required this.duplicadosIgnorados,
  });

  final int titulosAvaliados;
  final int enviosEnfileirados;
  final int duplicadosIgnorados;

  factory ExecucaoReguaResultado.fromJson(Map<String, dynamic> json) =>
      ExecucaoReguaResultado(
        titulosAvaliados: _asInt(json['titulosAvaliados']) ?? 0,
        enviosEnfileirados: _asInt(json['enviosEnfileirados']) ?? 0,
        duplicadosIgnorados: _asInt(json['duplicadosIgnorados']) ?? 0,
      );
}

class CobrancaRegua {
  const CobrancaRegua({
    required this.id,
    required this.clienteNome,
    required this.valor,
    required this.vencimento,
    required this.status,
    this.etapa,
    this.canal,
    this.executadaEm,
    this.resultado,
  });

  final int id;
  final String clienteNome;
  final double valor;
  final DateTime? vencimento;
  final String status;
  final String? etapa;
  final CanalCobranca? canal;
  final DateTime? executadaEm;
  final String? resultado;

  factory CobrancaRegua.fromJson(Map<String, dynamic> json) {
    final cliente = json['cliente'];
    final parceiro = json['parceiro'];
    return CobrancaRegua(
      id: _asInt(json['id'] ?? json['cobrancaId'] ?? json['contaReceberId']) ??
          0,
      clienteNome: json['clienteNome']?.toString() ??
          (cliente is Map ? cliente['nome']?.toString() : null) ??
          (parceiro is Map ? parceiro['nome']?.toString() : null) ??
          (json['clienteId'] == null
              ? null
              : 'Cliente #${json['clienteId']}') ??
          'Cliente nao informado',
      valor: _asDouble(json['valor'] ?? json['valorTitulo']) ?? 0,
      vencimento: _asDate(json['vencimento'] ?? json['dataVencimento']),
      status: json['status']?.toString() ?? 'PENDENTE',
      etapa: json['etapa']?.toString() ?? json['etapaNome']?.toString(),
      canal:
          json['canal'] == null ? null : CanalCobranca.fromJson(json['canal']),
      executadaEm: _asDate(json['executadaEm'] ?? json['dataAcao']),
      resultado:
          json['resultado']?.toString() ?? json['mensagemErro']?.toString(),
    );
  }
}

int? _asInt(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value');
double? _asDouble(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('$value');
DateTime? _asDate(Object? value) =>
    value == null ? null : DateTime.tryParse(value.toString());
bool _asBool(Object? value, {required bool fallback}) {
  if (value is bool) return value;
  if (value == null) return fallback;
  return value.toString().toLowerCase() == 'true';
}
