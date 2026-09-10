import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/grid_user_preferences_key.dart';

void main() {
  test('monta chave de coluna isolada por usuario e tela', () {
    final usuario1 = GridUserPreferencesKey.base(
      storageKey: 'generic_grid_settings',
      title: 'Contas a Pagar',
      userKey: 'u10',
    );
    final usuario2 = GridUserPreferencesKey.base(
      storageKey: 'generic_grid_settings',
      title: 'Contas a Pagar',
      userKey: 'u11',
    );

    expect(usuario1, isNot(usuario2));
    expect(
      GridUserPreferencesKey.columnKey(usuario1, 'valorBaixa'),
      'grid_columns_v2__u10__generic_grid_settings__contas_a_pagar_valorbaixa',
    );
  });

  test('mantem formato legado para migrar preferencias ja gravadas', () {
    final legacyBase = GridUserPreferencesKey.legacyBase(
      storageKey: 'generic_grid_settings',
      title: 'Produto',
    );

    expect(legacyBase, 'generic_grid_settings_Produto');
    expect(
      GridUserPreferencesKey.legacyColumnKey(legacyBase, 'preco'),
      'generic_grid_settings_Produtopreco',
    );
  });
}
