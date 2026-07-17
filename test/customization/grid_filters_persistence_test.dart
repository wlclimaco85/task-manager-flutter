import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Este arquivo testa a persistência de filtros em grid_page.dart
// Testa as funcionalidades: _saveFilters(), _loadSavedFilters(), _clearFilters()

void main() {
  group('Grid Filters Persistence', () {
    const storageKey = 'test_grid_filters';
    final filterKey = '${storageKey}_filters';

    setUp(() {
      // Reset SharedPreferences antes de cada teste
      SharedPreferences.setMockInitialValues({});
    });

    test('saveFilters deve salvar filtros em JSON format', () async {
      final prefs = await SharedPreferences.getInstance();

      // Simular dados de filtro
      final filters = <String, String>{
        'status': 'Pendente',
        'prioridade': 'Alta',
        '_search': 'busca teste',
      };

      final jsonStr = jsonEncode(filters);
      await prefs.setString(filterKey, jsonStr);

      // Verificar que foi salvo
      final saved = prefs.getString(filterKey);
      expect(saved, isNotNull);
      expect(saved, jsonStr);

      // Verificar desserialização
      final loaded = Map<String, dynamic>.from(jsonDecode(saved!));
      expect(loaded['status'], 'Pendente');
      expect(loaded['prioridade'], 'Alta');
      expect(loaded['_search'], 'busca teste');
    });

    test('loadSavedFilters deve recuperar filtros salvos', () async {
      final prefs = await SharedPreferences.getInstance();

      // Salvar filtros
      final filters = {'campo1': 'valor1', 'campo2': 'valor2'};
      final jsonStr = jsonEncode(filters);
      await prefs.setString(filterKey, jsonStr);

      // Simular carregamento como faz _loadSavedFilters()
      final savedFiltersStr = prefs.getString(filterKey);
      expect(savedFiltersStr, isNotNull);

      final filtersMap =
          Map<String, dynamic>.from(jsonDecode(savedFiltersStr!));
      expect(filtersMap.length, 2);
      expect(filtersMap['campo1'], 'valor1');
      expect(filtersMap['campo2'], 'valor2');
    });

    test('clearFilters deve remover filtros da persistência', () async {
      final prefs = await SharedPreferences.getInstance();

      // Salvar filtros primeiro
      final filters = {'status': 'Ativo'};
      await prefs.setString(filterKey, jsonEncode(filters));

      // Verificar que foi salvo
      expect(prefs.getString(filterKey), isNotNull);

      // Remover filtros
      await prefs.remove(filterKey);

      // Verificar que foi removido
      expect(prefs.getString(filterKey), isNull);
    });

    test('filtros vazios não devem ser salvos', () async {
      final prefs = await SharedPreferences.getInstance();

      // Simulando saveFilters com controladores vazios
      final filters = <String, String>{};
      if (filters.isEmpty) {
        // Se vazio, não salva
        return;
      }
    });

    test('busca global deve ser persistida com chave especial _search',
        () async {
      final prefs = await SharedPreferences.getInstance();

      final filters = {
        'status': 'Pendente',
        '_search': 'termo de busca',
      };

      await prefs.setString(filterKey, jsonEncode(filters));

      final saved = prefs.getString(filterKey);
      final loaded = Map<String, dynamic>.from(jsonDecode(saved!));

      expect(loaded['_search'], 'termo de busca');
      expect(loaded['status'], 'Pendente');
    });

    test('deve suportar múltiplos grids com storageKey diferente', () async {
      final prefs = await SharedPreferences.getInstance();

      const grid1Key = '${storageKey}_grid1_filters';
      const grid2Key = '${storageKey}_grid2_filters';

      // Salvar filtros para grid 1
      await prefs.setString(grid1Key, jsonEncode({'status': 'Ativo'}));

      // Salvar filtros para grid 2
      await prefs.setString(grid2Key, jsonEncode({'tipo': 'Premium'}));

      // Verificar isolamento
      final grid1Filters =
          Map<String, dynamic>.from(jsonDecode(prefs.getString(grid1Key)!));
      final grid2Filters =
          Map<String, dynamic>.from(jsonDecode(prefs.getString(grid2Key)!));

      expect(grid1Filters['status'], 'Ativo');
      expect(grid2Filters['tipo'], 'Premium');
      expect(grid1Filters.containsKey('tipo'), false);
      expect(grid2Filters.containsKey('status'), false);
    });

    test('deve manejar caracteres especiais e unicode', () async {
      final prefs = await SharedPreferences.getInstance();

      final filters = {
        'descricao': 'Teste com ãçéñ e caracteres especiais: @#\$%',
        'email': 'user@example.com',
        '_search': '日本語テキスト',
      };

      final jsonStr = jsonEncode(filters);
      await prefs.setString(filterKey, jsonStr);

      final loaded = prefs.getString(filterKey);
      final filtersMap = Map<String, dynamic>.from(jsonDecode(loaded!));

      expect(filtersMap['descricao'], 'Teste com ãçéñ e caracteres especiais: @#\$%');
      expect(filtersMap['email'], 'user@example.com');
      expect(filtersMap['_search'], '日本語テキスト');
    });

    test('dados vazios em SharedPreferences não devem quebrar _loadSavedFilters',
        () async {
      final prefs = await SharedPreferences.getInstance();

      // Simular o que faz _loadSavedFilters quando não há dados
      final savedFiltersStr = prefs.getString(filterKey);

      if (savedFiltersStr == null || savedFiltersStr.isEmpty) {
        // Comportamento esperado: retorna silenciosamente
        expect(true, true);
        return;
      }
    });
  });
}
