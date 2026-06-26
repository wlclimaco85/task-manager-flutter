import 'package:flutter/material.dart';

/// Lógica pura do badge de status de coleta do Instagram Monitor.
/// Extraída para ser testável independentemente da tela.
abstract final class InstagramStatusHelper {
  static Map<String, dynamic> collectionStatusItem(
      dynamic collectionStatus, String key) {
    if (collectionStatus is Map && collectionStatus[key] is Map) {
      return Map<String, dynamic>.from(collectionStatus[key] as Map);
    }
    return const {
      'status': 'DESCONHECIDA',
      'source': '',
      'reason': 'sem_coleta',
      'count': 0,
      'expectedCount': 0,
    };
  }

  static String worstCollectionStatus(List<String?> statuses) {
    final normalized =
        statuses.map((s) => (s ?? 'DESCONHECIDA').toUpperCase()).toList();
    if (normalized.contains('VAZIA')) return 'VAZIA';
    if (normalized.contains('TRUNCADA')) return 'TRUNCADA';
    if (normalized.contains('DESCONHECIDA')) return 'DESCONHECIDA';
    if (normalized.contains('COMPLETA')) return 'COMPLETA';
    return 'DESCONHECIDA';
  }

  static Color collectionStatusColor(String status) {
    switch (status) {
      case 'COMPLETA':
        return const Color(0xFF2E7D32);
      case 'TRUNCADA':
        return const Color(0xFFF9A825);
      case 'VAZIA':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFF757575);
    }
  }

  static String statusTooltipLine(Map<String, dynamic> item) {
    final status = item['status']?.toString() ?? 'DESCONHECIDA';
    final source = item['source']?.toString() ?? '';
    final reason = item['reason']?.toString() ?? '';
    final count = item['count']?.toString() ?? '0';
    final expected = item['expectedCount']?.toString() ?? '0';
    return '$status ($source/$reason, $count/$expected)';
  }
}
