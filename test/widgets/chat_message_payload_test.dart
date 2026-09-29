import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/chat_model.dart';
import 'package:task_manager_flutter/widgets/chat/chat_message_payload.dart';

void main() {
  test('payload da primeira mensagem preserva chatId 0 e envia tenant completo',
      () {
    final timestamp = DateTime.parse('2026-08-28T18:15:40.266');

    final payload = buildChatOutgoingPayload(
      senderName: 'BRASIL MODA SURF LTDA',
      senderEmail: 'brasilmodasurfltda@gmail.com',
      content: 'dddddd',
      sector: 'Departamento Fiscal',
      chatId: '0',
      type: 'text',
      timestamp: timestamp,
      empresaId: 9,
      parceiroId: 1751,
      aplicativoId: 4,
      userId: 967,
    );

    expect(payload['chatId'], '0');
    expect(payload['empId'], 9);
    expect(payload['parceiroId'], 1751);
    expect(payload['codApp'], 4);
    expect(payload['codUsuOrig'], 967);
    expect(payload['content'], 'dddddd');
    expect(payload['sector'], 'Departamento Fiscal');
    expect(payload['timestamp'], '2026-08-28T18:15:40.266');
  });

  test('payload sem empresa e parceiro preserva chatId 0 para backend resolver',
      () {
    final payload = buildChatOutgoingPayload(
      senderName: 'Cliente',
      senderEmail: 'cliente@appacademia.local',
      content: 'primeira mensagem',
      sector: 'Departamento Fiscal',
      chatId: '0',
      type: 'text',
    );

    expect(payload['chatId'], '0');
    expect(payload.containsKey('empId'), isFalse);
    expect(payload.containsKey('parceiroId'), isFalse);
  });

  test('payload de conversa existente preserva chatId recebido', () {
    final payload = buildChatOutgoingPayload(
      senderName: 'Cliente',
      senderEmail: 'cliente@appacademia.local',
      content: 'continuando',
      sector: 'Departamento Fiscal',
      chatId: 'empresa-1-parceiro-1751-chamado-33',
      type: 'text',
      empresaId: 1,
      parceiroId: 1751,
    );

    expect(payload['chatId'], 'empresa-1-parceiro-1751-chamado-33');
  });

  test('anexo enviado aparece localmente e eco do WebSocket nao duplica', () {
    final messages = <ChatMessage>[];
    final payload = buildChatOutgoingPayload(
      senderName: 'BRASIL MODA SURF LTDA',
      senderEmail: 'brasilmodasurfltda@gmail.com',
      content: 'Arquivo: contrato.pdf',
      sector: 'Departamento Fiscal',
      chatId: 'empresa-1-parceiro-1751',
      type: 'file',
      timestamp: DateTime.parse('2026-09-29T20:04:00'),
      empresaId: 1,
      parceiroId: 1751,
      fileId: 321,
      fileName: 'contrato.pdf',
      fileUrl: '/api/arquivos/download/321',
    );

    final localMessage = appendOutgoingChatMessage(messages, payload);
    final echoedMessage = appendOutgoingChatMessage(messages, {
      ...payload,
      'timestamp': '2026-09-29T20:04:01',
      'uploadDate': '2026-09-29T20:04:01',
    });

    expect(localMessage, isNotNull);
    expect(localMessage!.type, 'file');
    expect(localMessage.fileId, 321);
    expect(localMessage.fileName, 'contrato.pdf');
    expect(messages, hasLength(1));
    expect(echoedMessage, isNull);
  });

  test('confirmacao do chamado aparece imediatamente na conversa', () {
    final messages = <ChatMessage>[];
    final payload = buildChatOutgoingPayload(
      senderName: 'BRASIL MODA SURF LTDA',
      senderEmail: 'brasilmodasurfltda@gmail.com',
      content:
          'Chamado aberto numero #987. Para acompanhar, acesse a tela de chamados.',
      sector: 'Departamento Fiscal',
      chatId: 'empresa-1-parceiro-1751',
      type: 'ticket',
      timestamp: DateTime.parse('2026-09-29T20:05:00'),
      empresaId: 1,
      parceiroId: 1751,
      ticketId: 987,
    );

    final localMessage = appendOutgoingChatMessage(messages, payload);

    expect(localMessage, isNotNull);
    expect(localMessage!.type, 'ticket');
    expect(localMessage.content, contains('#987'));
    expect(messages.single.content, contains('tela de chamados'));
  });

  test('ChatMessage le parceiroId devolvido pelo WebSocket', () {
    final message = ChatMessage.fromJson({
      'sender': 'BRASIL MODA SURF LTDA',
      'content': 'dddddd',
      'type': 'text',
      'chatId': 'empresa-1-parceiro-1751',
      'empId': 1,
      'parceiroId': '1751',
      'codUsuOrig': '967',
      'codApp': 1,
    });

    expect(message.chatId, 'empresa-1-parceiro-1751');
    expect(message.empId, 1);
    expect(message.parceiroId, 1751);
    expect(message.codUsuOrig, 967);
    expect(message.codApp, 1);
  });

  test('normalizacao preserva nome e foto reais do remetente', () {
    final message = ChatMessage.fromJson({
      'sender': 'Departamento Pessoal',
      'senderName': 'Maria Fiscal',
      'senderFoto': 'data:image/png;base64,Zm90bw==',
      'content': 'resposta da empresa',
      'type': 'text',
      'chatId': 'empresa-1-parceiro-1757-chat-abc',
      'uploadDate': '2026-09-03T02:31:23',
      'codUsuOrig': 970,
    });

    final normalized = normalizeChatMessageForDisplay(message);

    expect(normalized.sender, 'Departamento Pessoal');
    expect(normalized.senderName, 'Maria Fiscal');
    expect(normalized.senderFoto, 'data:image/png;base64,Zm90bw==');
    expect(normalized.content, 'resposta da empresa');
    expect(normalized.timestamp, '2026-09-03T02:31:23');
    expect(
      chatMessageDisplayName(
        normalized,
        isMine: false,
        loggedUserName: 'Atendente logado',
        sector: 'Departamento Pessoal',
      ),
      'Maria Fiscal',
    );
  });
}
