// services/tela_service.dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';

import '../models/telas_model.dart';

class TelaService {
  final NetworkCaller networkCaller;
  late Future<SharedPreferences> _prefs;

  TelaService({required this.networkCaller}) {
    _prefs = SharedPreferences.getInstance();
  }

  Future<TelaConfig?> getTelaByNome(String nome) async {
    try {
      final response =
          await networkCaller.getRequest(ApiLinks.getAllTelas(nome));

      print('Response status: ${response.isSuccess}');

      if (response.isSuccess && response.body != null) {
        // CORREÇÃO: Não usar forEach diretamente no response.body!
        // Mostra a estrutura completa de forma segura
        final data = response.body!['data'];
        final dados = data != null ? data['dados'] : null;

        if (dados != null) {
          if (dados is List) {
            print('📋 É uma lista com ${dados.length} elementos');
            if (dados.isNotEmpty) {
              final primeiroItem = dados.first;
              if (primeiroItem is Map<String, dynamic>) {
                print('✅ Convertendo primeiro item para TelaConfig');
                return TelaConfig.fromJson(primeiroItem);
              } else {
                print('❌ Primeiro item não é um Map válido');
              }
            } else {
              print('❌ Lista vazia');
            }
          } else if (dados is Map<String, dynamic>) {
            print('✅ Dados é um Map, convertendo diretamente');
            return TelaConfig.fromJson(dados);
          } else {
            print('❌ Tipo não suportado');
          }
        } else {
          print('❌ Dados é null');
        }
      }

      return null;
    } catch (e) {
      print('❌ Erro ao buscar tela: $e');
      print('🎯 StackTrace: ${e.toString()}');
      return null;
    }
  }

  Future<List<UserFieldPreference>> getUserPreferences(
      int telaId, int userId) async {
    try {
      final response = await networkCaller.getRequest(
          ApiLinks.getAllpreferencias(telaId.toString(), userId.toString()));

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
        ApiLinks.getAllpreferencias(telaId.toString(), userId.toString()),
        fieldVisibility,
      );

      return response.isSuccess;
    } catch (e) {
      print('Erro ao salvar preferências: $e');
      return false;
    }
  }

  Future<void> saveTelaToCache(String nome, TelaConfig tela) async {
    final prefs = await _prefs;

    print('Salvando tela no cache: $nome');
    final jsonData = tela.toJson();
    print('JSON a ser salvo: $jsonData');

    await prefs.setString('tela_$nome', json.encode(jsonData));
  }

  Future<TelaConfig?> getTelaFromCache(String nome) async {
    try {
      final prefs = await _prefs;
      final cached = prefs.getString('tela_$nome');

      if (cached == null || cached.isEmpty) {
        print('❌ Nenhum cache encontrado para: $nome');
        return await _getFromApiWithRetry(nome);
      }

      print('✅ Cache encontrado para: $nome');

      try {
        final decoded = json.decode(cached);
        print('📦 JSON recuperado do cache: $decoded');

        // Validação do cache - SE ID == 0 OU NULL, CHAMA API
        if (_isCacheValid(decoded)) {
          final tela = TelaConfig.fromJson(decoded);
          print(
              '✅ Tela reconstruída do cache: ID=${tela.id}, Nome=${tela.nome}');
          return tela;
        } else {
          print('⚠️ Cache inválido para: $nome (ID: ${decoded['id']})');
          return await _getFromApiWithRetry(nome);
        }
      } catch (e) {
        print('❌ Erro ao decodificar cache: $e');
        return await _getFromApiWithRetry(nome);
      }
    } catch (e) {
      print('❌ Erro geral no cache: $e');
      return await _getFromApiWithRetry(nome);
    }
  }

  bool _isCacheValid(Map<String, dynamic> decoded) {
    return decoded['id'] != null &&
        decoded['id'] > 1 &&
        decoded['nome'] != null &&
        decoded['nome'].isNotEmpty;
  }

  // MÉTODO QUE TENTA A API ATÉ 3 VEZES
  Future<TelaConfig?> _getFromApiWithRetry(String nome) async {
    const maxTentativas = 3;

    for (int tentativa = 1; tentativa <= maxTentativas; tentativa++) {
      try {
        print(
            '🔄 Tentativa $tentativa/$maxTentativas para buscar tela "$nome" da API...');

        final freshTela = await getTelaByNome(nome);

        if (freshTela != null) {
          print('✅ Tela encontrada na API: ID=${freshTela.id}');
          await saveTelaToCache(nome, freshTela);
          return freshTela;
        } else {
          print('❌ Tentativa $tentativa falhou - API retornou null');

          // Se não for a última tentativa, espera um pouco antes de tentar novamente
          if (tentativa < maxTentativas) {
            await Future.delayed(const Duration(seconds: 1)); // Espera 1 segundo
          }
        }
      } catch (e) {
        print('❌ Erro na tentativa $tentativa: $e');

        // Se não for a última tentativa, espera um pouco antes de tentar novamente
        if (tentativa < maxTentativas) {
          await Future.delayed(const Duration(seconds: 1)); // Espera 1 segundo
        }
      }
    }

    print('💥 Todas as $maxTentativas tentativas falharam para a tela "$nome"');
    return null;
  }
}
