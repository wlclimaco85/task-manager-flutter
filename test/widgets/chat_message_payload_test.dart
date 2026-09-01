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
}
