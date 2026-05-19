import 'package:flutter/material.dart';
import '../../../models/chat_model.dart';
import '../../../utils/api_links.dart';
import '../../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../../../models/auth_utility.dart';

import 'package:task_manager_flutter/utils/app_logger.dart';

class ChatCaller {
  Future<List<ChatMessage>> fetchChats(BuildContext context) async {
    List<ChatMessage>? model = [];
    ChatMessageModel models;
    try {
      // Tenta email do login primeiro, depois dados pessoais
      final login = AuthUtility.userInfo?.login;
      final dp = AuthUtility.userInfo?.data?.codDadosPessoal;
      final email = login?.email ?? dp?.email;
      if (email == null || email.isEmpty) {
        L.d('ChatCaller: email do usuario nao encontrado');
        return model;
      }
      final url = '${ApiLinks.fecthChats}?user=${Uri.encodeComponent(email)}';

      final NetworkResponse response = await NetworkCaller().getRequest(url);

      if (response.statusCode == 200 && response.body != null) {
        models = ChatMessageModel.fromJson(response.body!);
        model.addAll(models.messages ?? []);
      }
    } catch (e) {
      L.d('Erro ao carregar chats: $e');
    }
    return model;
  }

  Future<List<ChatMessage>> fetchChatsById(
      BuildContext context, String chatId) async {
    List<ChatMessage>? model = [];
    ChatMessageModel models;
    try {
      L.d('URL de requisição: $chatId');

      final encodedId = Uri.encodeQueryComponent(chatId);
      final NetworkResponse response = await NetworkCaller()
          .getRequest('${ApiLinks.fecthChatById}$encodedId');

      if (response.statusCode == 200 && response.body != null) {
        models = ChatMessageModel.fromJson(response.body!);
        model.addAll(models.messages ?? []);
      } else {
        L.d('Erro: Nenhum dado retornado');
      }
    } catch (e) {
      L.d('Erro: $e'); // Log do erro
      throw Exception('Erro ao carregar cotações: $e');
    }
    return model;
  }
}
