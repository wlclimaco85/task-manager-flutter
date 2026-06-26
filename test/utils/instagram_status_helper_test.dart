// test/utils/instagram_status_helper_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/instagram_status_helper.dart';

void main() {
  group('InstagramStatusHelper.worstCollectionStatus', () {
    test('VAZIA prevalece sobre todos', () {
      expect(
        InstagramStatusHelper.worstCollectionStatus(['COMPLETA', 'VAZIA']),
        'VAZIA',
      );
      expect(
        InstagramStatusHelper.worstCollectionStatus(['TRUNCADA', 'VAZIA']),
        'VAZIA',
      );
    });

    test('TRUNCADA prevalece sobre COMPLETA e DESCONHECIDA', () {
      expect(
        InstagramStatusHelper.worstCollectionStatus(['COMPLETA', 'TRUNCADA']),
        'TRUNCADA',
      );
    });

    test('DESCONHECIDA quando status ausente ou nulo', () {
      expect(
        InstagramStatusHelper.worstCollectionStatus([null, null]),
        'DESCONHECIDA',
      );
    });

    test('COMPLETA quando todos são COMPLETA', () {
      expect(
        InstagramStatusHelper.worstCollectionStatus(['COMPLETA', 'COMPLETA']),
        'COMPLETA',
      );
    });
  });

  group('InstagramStatusHelper.collectionStatusColor', () {
    test('COMPLETA → verde', () {
      expect(
        InstagramStatusHelper.collectionStatusColor('COMPLETA'),
        const Color(0xFF2E7D32),
      );
    });

    test('TRUNCADA → amarelo', () {
      expect(
        InstagramStatusHelper.collectionStatusColor('TRUNCADA'),
        const Color(0xFFF9A825),
      );
    });

    test('VAZIA → vermelho', () {
      expect(
        InstagramStatusHelper.collectionStatusColor('VAZIA'),
        const Color(0xFFC62828),
      );
    });

    test('DESCONHECIDA → cinza', () {
      expect(
        InstagramStatusHelper.collectionStatusColor('DESCONHECIDA'),
        const Color(0xFF757575),
      );
    });
  });

  group('InstagramStatusHelper.collectionStatusItem', () {
    test('extrai mapa aninhado quando presente', () {
      final collectionStatus = {
        'followers': {'status': 'COMPLETA', 'source': 'rapidapi', 'reason': 'ok', 'count': 500, 'expectedCount': 500},
      };
      final result = InstagramStatusHelper.collectionStatusItem(collectionStatus, 'followers');
      expect(result['status'], 'COMPLETA');
      expect(result['source'], 'rapidapi');
    });

    test('retorna DESCONHECIDA quando collectionStatus é nulo', () {
      final result = InstagramStatusHelper.collectionStatusItem(null, 'followers');
      expect(result['status'], 'DESCONHECIDA');
      expect(result['reason'], 'sem_coleta');
    });

    test('retorna DESCONHECIDA quando chave ausente', () {
      final result = InstagramStatusHelper.collectionStatusItem({}, 'followers');
      expect(result['status'], 'DESCONHECIDA');
    });
  });

  group('InstagramStatusHelper.statusTooltipLine', () {
    test('formata linha de tooltip corretamente', () {
      final item = {
        'status': 'COMPLETA',
        'source': 'rapidapi',
        'reason': 'ok',
        'count': 500,
        'expectedCount': 500,
      };
      expect(
        InstagramStatusHelper.statusTooltipLine(item),
        'COMPLETA (rapidapi/ok, 500/500)',
      );
    });

    test('usa DESCONHECIDA quando campos ausentes', () {
      expect(
        InstagramStatusHelper.statusTooltipLine({}),
        'DESCONHECIDA (/, 0/0)',
      );
    });
  });
}
