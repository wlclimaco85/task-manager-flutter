import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../models/chat_model.dart';
import '../../../utils/api_links.dart';
import '../../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../../../models/auth_utility.dart';
import '../../../utils/tenant_context.dart';

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
      } else {
        // Fix card #442: antes falhava silenciosamente (sem log nenhum),
        // dificultando diagnosticar quando o backend retorna erro.
        L.d('ChatCaller: falha ao carregar chats (status ${response.statusCode})');
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

  // ── Chat Kanban ──────────────────────────────────────────────────────────
  Future<List<ChatKanbanItem>> fetchChatsKanban() async {
    try {
      final url = ApiLinks.chatKanban;
      final resp = await TenantContext.get(url);
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        List lista = [];
        if (body is Map) {
          final d = body['data'] ?? body;
          if (d is List) {
            lista = d;
          } else if (d is Map) {
            lista = d['dados'] ?? d['content'] ?? [];
          }
        } else if (body is List) {
          lista = body;
        }
        return lista
            .whereType<Map>()
            .map((e) => ChatKanbanItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (e) {
      L.d('Erro ao carregar kanban de chats: $e');
    }
    return [];
  }

  // ── Transferir Chat ──────────────────────────────────────────────────────
  Future<bool> transferChat(String chatId, String usuarioDestinoId) async {
    try {
      final url = ApiLinks.chatTransfer(chatId);
      final body = {'usuarioDestinoId': usuarioDestinoId};
      final resp = await TenantContext.put(url, body);
      if (resp.statusCode == 200 || resp.statusCode == 204) return true;
      L.d('Erro ao transferir chat: ${resp.statusCode}');
    } catch (e) {
      L.d('Erro ao transferir chat: $e');
    }
    return false;
  }

  // ── Marcar como lido ─────────────────────────────────────────────────────
  Future<bool> marcarComoLido(String chatId) async {
    try {
      final url = ApiLinks.chatMarkAsRead(chatId);
      final resp = await TenantContext.put(url, {});
      if (resp.statusCode == 200 || resp.statusCode == 204) return true;
    } catch (e) {
      L.d('Erro ao marcar chat como lido: $e');
    }
    return false;
  }

  // ── Usuários do setor para transferência ─────────────────────────────────
  Future<List<Map<String, String>>> fetchUsuariosSetor(String setorId) async {
    try {
      final url = '${ApiLinks.chatUsuariosSetor}?setorId=${Uri.encodeComponent(setorId)}';
      final resp = await TenantContext.get(url);
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        List lista = [];
        if (body is Map) {
          final d = body['data'] ?? body;
          if (d is List) lista = d;
          else if (d is Map) lista = d['dados'] ?? d['content'] ?? [];
        } else if (body is List) {
          lista = body;
        }
        return lista.whereType<Map>().map((e) => {
          'id': (e['id'] ?? e['usuarioId']).toString(),
          'nome': (e['nome'] ?? e['login'] ?? e['email'] ?? 'Usuário').toString(),
        }).toList();
      }
    } catch (e) {
      L.d('Erro ao carregar usuários do setor: $e');
    }
    return [];
  }

  // ── Pegar atendimento (Card #448 Fase 1) ─────────────────────────────────
  Future<bool> pegarAtendimento(String chatId, int usuarioId) async {
    try {
      final url = ApiLinks.chatPickup(chatId, usuarioId);
      final resp = await TenantContext.put(url, {});
      if (resp.statusCode == 200) return true;
      if (resp.statusCode == 409) {
        L.d('Atendimento $chatId ja possui responsavel');
      } else {
        L.d('Erro ao pegar atendimento: ${resp.statusCode}');
      }
    } catch (e) {
      L.d('Erro ao pegar atendimento: $e');
    }
    return false;
  }

  // ── Atualizar status do chat ─────────────────────────────────────────────
  Future<bool> atualizarStatus(String chatId, String novoStatus) async {
    try {
      final url = ApiLinks.chatFinalize(chatId);
      final body = {'status': novoStatus};
      final resp = await TenantContext.put(url, body);
      if (resp.statusCode == 200 || resp.statusCode == 204) return true;
    } catch (e) {
      L.d('Erro ao atualizar status do chat: $e');
    }
    return false;
  }
}
