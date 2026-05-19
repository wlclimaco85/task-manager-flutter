// Trading models — sinais, oportunidades, watchlist, alertas e operações assistidas.

class TradingSignal {
  final String id;
  final String asset;
  final String direction; // "BUY" | "SELL"
  final double price;
  final String createdAt;

  const TradingSignal({
    required this.id,
    required this.asset,
    required this.direction,
    required this.price,
    required this.createdAt,
  });

  factory TradingSignal.fromJson(Map<String, dynamic> json) {
    return TradingSignal(
      id: json['id']?.toString() ?? '',
      asset: json['asset']?.toString() ?? '',
      direction: json['direction']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'asset': asset,
        'direction': direction,
        'price': price,
        'createdAt': createdAt,
      };
}

class Opportunity {
  final String id;
  final String asset;
  final String description;
  final String detectedAt;

  const Opportunity({
    required this.id,
    required this.asset,
    required this.description,
    required this.detectedAt,
  });

  factory Opportunity.fromJson(Map<String, dynamic> json) {
    return Opportunity(
      id: json['id']?.toString() ?? '',
      asset: json['asset']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      detectedAt: json['detectedAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'asset': asset,
        'description': description,
        'detectedAt': detectedAt,
      };
}

class WatchlistItem {
  final String id;
  final String assetSymbol;
  final String? notes;
  final String addedAt;

  const WatchlistItem({
    required this.id,
    required this.assetSymbol,
    this.notes,
    required this.addedAt,
  });

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    return WatchlistItem(
      id: json['id']?.toString() ?? '',
      assetSymbol: json['assetSymbol']?.toString() ?? '',
      notes: json['notes']?.toString(),
      addedAt: json['addedAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'assetSymbol': assetSymbol,
        if (notes != null) 'notes': notes,
        'addedAt': addedAt,
      };
}

class TradingAlerta {
  final String id;
  final String assetSymbol;
  final double priceTarget;
  final String direction; // "ABOVE" | "BELOW"
  final String status; // "ATIVO" | "DISPARADO" | "CANCELADO"
  final String? triggeredAt;
  final String? message;

  const TradingAlerta({
    required this.id,
    required this.assetSymbol,
    required this.priceTarget,
    required this.direction,
    required this.status,
    this.triggeredAt,
    this.message,
  });

  bool get isDisparado => status == 'DISPARADO';
  bool get isAtivo => status == 'ATIVO';
  bool get isCancelado => status == 'CANCELADO';

  factory TradingAlerta.fromJson(Map<String, dynamic> json) {
    return TradingAlerta(
      id: json['id']?.toString() ?? '',
      assetSymbol: json['assetSymbol']?.toString() ?? '',
      priceTarget: (json['priceTarget'] as num?)?.toDouble() ?? 0.0,
      direction: json['direction']?.toString() ?? '',
      status: json['status']?.toString() ?? 'ATIVO',
      triggeredAt: json['triggeredAt']?.toString(),
      message: json['message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'assetSymbol': assetSymbol,
        'priceTarget': priceTarget,
        'direction': direction,
        'status': status,
        if (triggeredAt != null) 'triggeredAt': triggeredAt,
        if (message != null) 'message': message,
      };
}

class OperacaoAssistida {
  final String id;
  final String assetSymbol;
  final String direcao; // "BUY" | "SELL"
  final double quantidade;
  final double? stopLoss;
  final double? takeProfit;
  final String status; // "PENDENTE" | "ENVIADA" | "EXECUTADA" | "CANCELADA" | "ERRO"
  final String? externalOrderId;
  final String? errorMessage;
  final String createdAt;
  final String? signalId;

  const OperacaoAssistida({
    required this.id,
    required this.assetSymbol,
    required this.direcao,
    required this.quantidade,
    this.stopLoss,
    this.takeProfit,
    required this.status,
    this.externalOrderId,
    this.errorMessage,
    required this.createdAt,
    this.signalId,
  });

  bool get isPendente => status == 'PENDENTE';
  bool get isEnviada => status == 'ENVIADA';
  bool get isExecutada => status == 'EXECUTADA';
  bool get isCancelada => status == 'CANCELADA';
  bool get isErro => status == 'ERRO';
  bool get cancelavel => isPendente || isEnviada;

  factory OperacaoAssistida.fromJson(Map<String, dynamic> json) {
    return OperacaoAssistida(
      id: json['id']?.toString() ?? '',
      assetSymbol: json['assetSymbol']?.toString() ?? '',
      direcao: json['direcao']?.toString() ?? '',
      quantidade: (json['quantidade'] as num?)?.toDouble() ?? 0.0,
      stopLoss: (json['stopLoss'] as num?)?.toDouble(),
      takeProfit: (json['takeProfit'] as num?)?.toDouble(),
      status: json['status']?.toString() ?? 'PENDENTE',
      externalOrderId: json['externalOrderId']?.toString(),
      errorMessage: json['errorMessage']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
      signalId: json['signalId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'assetSymbol': assetSymbol,
        'direcao': direcao,
        'quantidade': quantidade,
        if (stopLoss != null) 'stopLoss': stopLoss,
        if (takeProfit != null) 'takeProfit': takeProfit,
        'status': status,
        if (externalOrderId != null) 'externalOrderId': externalOrderId,
        if (errorMessage != null) 'errorMessage': errorMessage,
        'createdAt': createdAt,
        if (signalId != null) 'signalId': signalId,
      };
}
