class ChatMessage {
  final String sender;
  final String content;
  final String type;
  final int? fileId;
  final String? fileName;
  final String? timestamp;
  final String? fileUrl; // <- novo

  // Novos campos do payload
  final int? empId;
  final int? codApp;
  final int? codUsuOrig;
  final int? codUsuDest;
  final String? sector;
  final String? chatId;
  final String? uploadDate;
  final String? text;
  // Fix card #444: status real da conversa (Aberto/Finalizado), vindo do
  // backend agrupado por chatId (antes nao existia e a UI usava 'Ativo' fixo).
  final String? status;

  ChatMessage({
    required this.sender,
    required this.content,
    required this.type,
    this.fileId,
    this.fileName,
    this.timestamp,
    this.empId,
    this.codApp,
    this.codUsuOrig,
    this.codUsuDest,
    this.sector,
    this.chatId,
    this.uploadDate,
    this.text,
    this.fileUrl,
    this.status,
  });

  // Construtor a partir de JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      sender: json['sender'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? '',
      fileId: json['fileId'],
      fileName: json['fileName'],
      timestamp: json['timestamp'],
      fileUrl: json['fileUrl'],
      empId: json['empId'],
      codApp: json['codApp'],
      codUsuOrig: json['codUsuOrig'],
      codUsuDest: json['codUsuDest'],
      sector: json['sector'],
      chatId: json['chatId'],
      uploadDate: json['uploadDate'],
      text: json['text'],
      status: json['status'],
    );
  }

  // Converter para JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['sender'] = sender;
    data['content'] = content;
    data['type'] = type;
    data['fileId'] = fileId;
    data['fileName'] = fileName;
    data['timestamp'] = timestamp;
    data['fileUrl'] = fileUrl;

    // Novos campos
    data['empId'] = empId;
    data['codApp'] = codApp;
    data['codUsuOrig'] = codUsuOrig;
    data['codUsuDest'] = codUsuDest;
    data['sector'] = sector;
    data['chatId'] = chatId;
    data['uploadDate'] = uploadDate;
    data['text'] = text;
    data['status'] = status;

    return data;
  }

  // Converter lista de JSON em lista de ChatMessage
  static List<ChatMessage> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((item) => ChatMessage.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}

/// Modelo para item do kanban de chat.
class ChatKanbanItem {
  final String chatId;
  final String? cliente;
  final String? clienteEmail;
  final String? setor;
  final String? setorId;
  final String? ultimaMensagem;
  final String status;
  final int naoLidos;
  final DateTime? dataUltimaMensagem;
  final String? usuarioResponsavel;
  final String? usuarioResponsavelId;
  final int? empresaId;

  ChatKanbanItem({
    required this.chatId,
    this.cliente,
    this.clienteEmail,
    this.setor,
    this.setorId,
    this.ultimaMensagem,
    required this.status,
    this.naoLidos = 0,
    this.dataUltimaMensagem,
    this.usuarioResponsavel,
    this.usuarioResponsavelId,
    this.empresaId,
  });

  factory ChatKanbanItem.fromJson(Map<String, dynamic> json) {
    return ChatKanbanItem(
      chatId: json['chatId']?.toString() ?? json['id']?.toString() ?? '',
      cliente: json['cliente']?.toString() ?? json['clienteNome']?.toString(),
      clienteEmail: json['clienteEmail']?.toString(),
      setor: json['setor']?.toString() ?? json['sector']?.toString(),
      setorId: json['setorId']?.toString(),
      ultimaMensagem: json['ultimaMensagem']?.toString() ?? json['lastMessage']?.toString(),
      status: json['status']?.toString() ?? 'Aguardando',
      naoLidos: int.tryParse(json['naoLidos']?.toString() ?? '0') ?? 0,
      dataUltimaMensagem: json['dataUltimaMensagem'] != null
          ? DateTime.tryParse(json['dataUltimaMensagem'].toString())
          : null,
      usuarioResponsavel: json['usuarioResponsavel']?.toString(),
      usuarioResponsavelId: json['usuarioResponsavelId']?.toString(),
      empresaId: int.tryParse(json['empresaId']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'chatId': chatId,
    'cliente': cliente,
    'clienteEmail': clienteEmail,
    'setor': setor,
    'setorId': setorId,
    'ultimaMensagem': ultimaMensagem,
    'status': status,
    'naoLidos': naoLidos,
    'dataUltimaMensagem': dataUltimaMensagem?.toIso8601String(),
    'usuarioResponsavel': usuarioResponsavel,
    'usuarioResponsavelId': usuarioResponsavelId,
    'empresaId': empresaId,
  };
}

class ChatMessageModel {
  String? status;
  String? token;
  List<ChatMessage>? messages;

  ChatMessageModel({this.status, this.token, this.messages});

  ChatMessageModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    token = json['token'];
    messages = json['data'] != null
        ? ChatMessage.fromJsonList(json['data']['dados'])
        : [];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['token'] = token;
    if (messages != null) {
      data['data'] = {
        'messages': messages!.map((msg) => msg.toJson()).toList(),
      };
    }
    return data;
  }
}
