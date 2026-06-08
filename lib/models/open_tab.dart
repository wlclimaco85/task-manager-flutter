import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Representa uma aba interna aberta no shell principal (estilo navegador/IDE).
///
/// Cada aba mantém uma referência ao [content] já instanciado (com [Key]
/// estável), o que permite usar [IndexedStack] no shell para preservar o
/// estado (filtros, scroll, formulários) de todas as abas abertas
/// simultaneamente.
class OpenTab {
  /// Identificador único da aba (ex.: 'screen_31').
  final String id;

  /// Rótulo exibido na faixa de abas.
  final String label;

  /// Ícone exibido na faixa de abas (FontAwesome, igual ao usado no menu).
  final FaIconData icon;

  /// Widget já instanciado a ser exibido quando a aba estiver ativa.
  final Widget content;

  /// Índice da tela na lista `_screens` do shell (usado para localizar a
  /// aba já aberta correspondente a um item de menu).
  final int screenIndex;

  const OpenTab({
    required this.id,
    required this.label,
    required this.icon,
    required this.content,
    required this.screenIndex,
  });
}
