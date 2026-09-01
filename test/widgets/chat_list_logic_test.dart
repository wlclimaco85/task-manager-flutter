import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/chat_model.dart';
import 'package:task_manager_flutter/widgets/chat/chat_list_logic.dart';

void main() {
  group('Chat list logic', () {
    test('classifica abertos/finalizados e ordena por ultima mensagem desc',
        () {
      final itens = buildChatListItemsFromMessages([
        ChatMessage(
          sender: 'Cliente',
          content: 'Mensagem antiga',
          type: 'text',
          chatId: 'chat-antigo',
          sector: 'Fiscal',
          status: 'ABERTO',
          uploadDate: '2026-08-26T09:00:00',
        ),
        ChatMessage(
          sender: 'Cliente',
          content: 'Mensagem finalizada',
          type: 'text',
          chatId: 'chat-finalizado',
          sector: 'Financeiro',
          status: 'FECHADO',
          uploadDate: '2026-08-26T11:00:00',
        ),
        ChatMessage(
          sender: 'Cliente',
          content: 'Mensagem recente',
          type: 'text',
          chatId: 'chat-recente',
          sector: 'Departamento Pessoal',
          status: 'ABERTO',
          uploadDate: '2026-08-26T12:00:00',
        ),
      ]);

      expect(itens.map((item) => item.chatId), [
        'chat-recente',
        'chat-finalizado',
        'chat-antigo',
      ]);
      expect(
        itens
            .where((item) => item.status == 'Ativo')
            .map((item) => item.chatId),
        ['chat-recente', 'chat-antigo'],
      );
      expect(
        itens
            .where((item) => item.status == 'Finalizado')
            .map((item) => item.chatId),
        ['chat-finalizado'],
      );
    });

    test('monta setores a partir da mesma estrutura do cadastro de setores',
        () {
      final setores = sectorLabelsFromCadastro(
        [
          {'id': 1, 'descricao': 'Fiscal'},
          {'id': 2, 'label': 'Financeiro'},
          {'id': 3, 'nome': 'Departamento Pessoal'},
        ],
        fallback: const ['Fallback'],
      );

      expect(setores, ['Fiscal', 'Financeiro', 'Departamento Pessoal']);
    });

    test('trata todos os status de encerramento como finalizados', () {
      expect(chatStatusLabel('FECHADO'), 'Finalizado');
      expect(chatStatusLabel('FINALIZADO'), 'Finalizado');
      expect(chatStatusLabel('RESOLVIDO'), 'Finalizado');
      expect(chatStatusLabel('CANCELADO'), 'Finalizado');
      expect(chatStatusLabel('ABERTO'), 'Ativo');
    });
  });
}
