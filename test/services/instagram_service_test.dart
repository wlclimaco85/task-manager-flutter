// test/services/instagram_service_test.dart
//
// Testes sem credenciais reais: verificam o comportamento defensivo do
// InstagramService quando a API Python local não está disponível.
// Nenhuma chamada HTTP real é feita — a API local nunca chega a ser ativada.

import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/services/instagram_service.dart';

void main() {
  group('InstagramService — fallback sem credenciais (Python API indisponível)', () {
    test('hasLocalApi é false antes de qualquer checkLocalApi', () {
      expect(InstagramService.hasLocalApi, isFalse);
    });

    test('fetchFollowers retorna lista vazia quando API local indisponível', () async {
      final resultado = await InstagramService.fetchFollowers('perfil_mock');
      expect(resultado, isEmpty);
    });

    test('fetchFollowing retorna lista vazia quando API local indisponível', () async {
      final resultado = await InstagramService.fetchFollowing('perfil_mock');
      expect(resultado, isEmpty);
    });

    test('fetchLikers retorna lista vazia quando API local indisponível', () async {
      final resultado = await InstagramService.fetchLikers('media_mock');
      expect(resultado, isEmpty);
    });

    test('fetchInteracoes retorna null quando API local indisponível', () async {
      final resultado = await InstagramService.fetchInteracoes('perfil_mock');
      expect(resultado, isNull);
    });

    test('fetchSessionsStatus retorna null quando API local indisponível', () async {
      final resultado = await InstagramService.fetchSessionsStatus();
      expect(resultado, isNull);
    });

    test('takeSnapshot retorna null quando API local indisponível', () async {
      final resultado = await InstagramService.takeSnapshot('perfil_mock');
      expect(resultado, isNull);
    });
  });
}
