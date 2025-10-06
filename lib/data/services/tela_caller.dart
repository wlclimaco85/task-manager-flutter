import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';

import '../models/telas_model.dart';
// services/tela_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import '../models/tela_config.dart';

class TelaService {
  final NetworkCaller networkCaller;
  late Future<SharedPreferences> _prefs;

  TelaService({required this.networkCaller}) {
    _prefs = SharedPreferences.getInstance();
  }

  static const String baseUrl = '/api/telas';

  Future<TelaConfig?> getTelaByNome(String nome) async {
    try {
      final response = await networkCaller.getRequest('$baseUrl/$nome');

      if (response.isSuccess && response.body != null) {
        return TelaConfig.fromJson(response.body!);
      }
      return null;
    } catch (e) {
      print('Erro ao buscar tela: $e');
      return null;
    }
  }

  Future<List<UserFieldPreference>> getUserPreferences(
      int telaId, int userId) async {
    try {
      final response = await networkCaller
          .getRequest('$baseUrl/$telaId/user-preferences/$userId');

      if (response.isSuccess && response.body != null) {
        return (response.body! as List)
            .map((pref) => UserFieldPreference.fromJson(pref))
            .toList();
      }
      return [];
    } catch (e) {
      print('Erro ao buscar preferências: $e');
      return [];
    }
  }

  Future<bool> saveUserPreferences(
      int telaId, int userId, Map<String, bool> fieldVisibility) async {
    try {
      final response = await networkCaller.postRequest(
        '$baseUrl/$telaId/user-preferences/$userId',
        fieldVisibility,
      );

      return response.isSuccess;
    } catch (e) {
      print('Erro ao salvar preferências: $e');
      return false;
    }
  }

  // Cache local para melhor performance
  Future<void> saveTelaToCache(String nome, TelaConfig tela) async {
    final prefs = await _prefs;
    await prefs.setString('tela_$nome', json.encode(tela.toJson()));
  }

  Future<TelaConfig?> getTelaFromCache(String nome) async {
    final prefs = await _prefs;
    final cached = prefs.getString('tela_$nome');
    if (cached != null) {
      return TelaConfig.fromJson(json.decode(cached));
    }
    return null;
  }
}
