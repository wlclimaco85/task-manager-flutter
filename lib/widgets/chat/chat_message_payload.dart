import '../../models/chat_model.dart';

Map<String, dynamic> buildChatOutgoingPayload({
  required String senderName,
  required String senderEmail,
  required String content,
  required String sector,
  required String chatId,
  required String type,
  DateTime? timestamp,
  int? empresaId,
  int? parceiroId,
  int? aplicativoId,
  int? userId,
  int? fileId,
  String? fileName,
  String? fileUrl,
  int? ticketId,
}) {
  final resolvedChatId = resolveOutgoingChatId(
    chatId: chatId,
  );

  return {
    'sender': senderName,
    'senderName': senderName,
    'senderEmail': senderEmail,
    'content': content,
    'sector': sector,
    'type': type,
    'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
    'chatId': resolvedChatId,
    if (empresaId != null) 'empId': empresaId,
    if (parceiroId != null) 'parceiroId': parceiroId,
    if (aplicativoId != null) 'codApp': aplicativoId,
    if (userId != null) 'codUsuOrig': userId,
    if (fileName != null) 'fileName': fileName,
    if (fileId != null) 'fileId': fileId,
    if (fileUrl != null) 'fileUrl': fileUrl,
    if (ticketId != null) 'ticketId': ticketId,
  };
}

ChatMessage? appendOutgoingChatMessage(
  List<ChatMessage> messages,
  Map<String, dynamic> payload,
) {
  final candidate = ChatMessage.fromJson(payload);
  if (messages
      .any((message) => chatMessagesAreEquivalent(message, candidate))) {
    return null;
  }
  messages.add(candidate);
  return candidate;
}

bool chatMessagesAreEquivalent(ChatMessage current, ChatMessage candidate) {
  if (current.type == 'file' &&
      candidate.type == 'file' &&
      current.fileId != null &&
      candidate.fileId != null) {
    return current.fileId == candidate.fileId;
  }
  if (current.type == 'ticket' && candidate.type == 'ticket') {
    return current.chatId == candidate.chatId &&
        current.sender == candidate.sender &&
        current.content == candidate.content;
  }
  // Para mensagens de texto (ou outros tipos sem arquivo):
  // Se o conteúdo, remetente e chatId forem iguais, tratamos como equivalente
  // para evitar duplicação entre o envio local otimista e o eco do WebSocket.
  if (current.chatId == candidate.chatId &&
      current.sender == candidate.sender &&
      current.content == candidate.content) {
    if (current.timestamp == candidate.timestamp ||
        current.timestamp == null ||
        candidate.timestamp == null) {
      return true;
    }
    // Caso ambos tenham timestamp mas com formato ligeiramente diferente,
    // verifica se a diferença é menor que 5 segundos.
    try {
      final t1 = DateTime.tryParse(current.timestamp!);
      final t2 = DateTime.tryParse(candidate.timestamp!);
      if (t1 != null && t2 != null) {
        return t1.difference(t2).abs().inSeconds <= 5;
      }
    } catch (_) {}
    return true;
  }
  return false;
}

String resolveOutgoingChatId({
  required String chatId,
}) {
  final normalized = chatId.trim();
  if (normalized.isNotEmpty && normalized != '0') {
    return normalized;
  }
  return normalized.isEmpty ? '0' : normalized;
}
