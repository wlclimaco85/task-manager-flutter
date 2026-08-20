import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/menu_config.dart';
import 'package:task_manager_flutter/utils/role_permission_catalog.dart';

void main() {
  test('catalogo de permissoes usa menus reais agrupados e pesquisaveis', () {
    final grupos = RolePermissionCatalog.groups();
    final todasAsTelas = grupos.expand((grupo) => grupo.entries).toList();

    final financeiro =
        grupos.firstWhere((grupo) => grupo.label == 'Financeiro');
    final contasPagar = financeiro.entries.firstWhere(
      (tela) => tela.menuItemId == 'contas_pagar',
    );

    expect(contasPagar.label, 'Contas a Pagar');
    expect(contasPagar.telaNome, 'ContasPagar');
    expect(
      todasAsTelas.any(
        (tela) => tela.label.toLowerCase().contains('gerada automaticamente'),
      ),
      isFalse,
    );

    final filtrados = RolePermissionCatalog.groups(query: 'pagar')
        .expand((grupo) => grupo.entries)
        .map((tela) => tela.label);

    expect(filtrados, contains('Contas a Pagar'));
  });

  test('catalogo de permissoes cobre todos os itens reais do menu', () {
    final itensDoMenu = [
      ...MenuConfig.groups.expand((grupo) => grupo.items),
      ...MenuConfig.loose,
    ].where((item) => item.screenIndex >= 0).map((item) => item.id).toSet();

    final itensDoCatalogo = RolePermissionCatalog.groups()
        .expand((grupo) => grupo.entries)
        .map((tela) => tela.menuItemId)
        .toSet();

    expect(itensDoCatalogo, containsAll(itensDoMenu));
  });
}
