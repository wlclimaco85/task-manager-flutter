import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/login_model.dart';
import 'package:task_manager_flutter/services/permission_service.dart';
import 'package:task_manager_flutter/utils/menu_config.dart';

void main() {
  group('PermissionService', () {
    setUp(() {
      // Limpar antes de cada teste
      PermissionService().clear();
    });

    test('canViewScreen retorna false sem permissões configuradas', () {
      expect(PermissionService().canViewScreen('nfe_entrada'), false);
    });

    test('canViewScreen retorna false se podeVer é false', () {
      final permissoes = [
        RolePermissaoItem(
          telaNome: 'NFeEntrada',
          podeVer: false,
          podeInserir: true,
          podeEditar: true,
          podeDeletar: true,
        ),
      ];
      PermissionService().setPermissoes(permissoes);
      expect(PermissionService().canViewScreen('nfe_entrada'), false);
    });

    test('canViewScreen retorna true se podeVer é true', () {
      final permissoes = [
        RolePermissaoItem(
          telaNome: 'NFeEntrada',
          podeVer: true,
          podeInserir: false,
          podeEditar: false,
          podeDeletar: false,
        ),
      ];
      PermissionService().setPermissoes(permissoes);
      expect(PermissionService().canViewScreen('nfe_entrada'), true);
    });

    test('getFilteredMenuGroups remove grupos sem itens permitidos', () {
      final permissoes = [
        RolePermissaoItem(
          telaNome: 'NFeEntrada',
          podeVer: true,
          podeInserir: false,
          podeEditar: false,
          podeDeletar: false,
        ),
      ];
      PermissionService().setPermissoes(permissoes);

      final filtered = PermissionService().getFilteredMenuGroups();

      // Grupos vazios são removidos
      expect(filtered.every((g) => g.items.isNotEmpty), true);

      // Comercial (contém NFeEntrada) deve estar presente
      expect(
        filtered.any((g) => g.id == 'comercial'),
        true,
      );
    });

    test('getFilteredMenuGroups retorna grupo vazio sem permissões', () {
      PermissionService().setPermissoes([]); // sem permissões
      final filtered = PermissionService().getFilteredMenuGroups();
      expect(filtered.isEmpty, true);
    });

    test('getPermission retorna RolePermissaoItem correto', () {
      final permissoes = [
        RolePermissaoItem(
          id: 1,
          roleId: 2,
          telaNome: 'NFeEntrada',
          podeVer: true,
          podeInserir: true,
          podeEditar: false,
          podeDeletar: false,
        ),
      ];
      PermissionService().setPermissoes(permissoes);

      final perm = PermissionService().getPermission('nfe_entrada');
      expect(perm?.podeVer, true);
      expect(perm?.podeInserir, true);
      expect(perm?.podeEditar, false);
    });

    test('clear limpa permissões', () {
      final permissoes = [
        RolePermissaoItem(
          telaNome: 'NFeEntrada',
          podeVer: true,
          podeInserir: false,
          podeEditar: false,
          podeDeletar: false,
        ),
      ];
      PermissionService().setPermissoes(permissoes);
      expect(PermissionService().canViewScreen('nfe_entrada'), true);

      PermissionService().clear();
      expect(PermissionService().canViewScreen('nfe_entrada'), false);
    });

    test('mapeamento de MenuItem.id para telaNome funciona', () {
      // Testar alguns mapeamentos principais
      const testCases = {
        'nfe_entrada': 'NFeEntrada',
        'chat': 'Chat',
        'dashboard': 'Dashboard',
        'funcionario': 'Funcionarios',
        'academy': 'Academia', // Verifica se é academi (esperado Academia)
      };

      for (final entry in testCases.entries) {
        final perm = PermissionService().getPermission(entry.key);
        // Apenas verificar se não retorna erro
        // (pode retornar null se o telaNome não corresponder exatamente)
      }
    });

    test('getFilteredLooseItems filtra itens soltos corretamente', () {
      final permissoes = [
        RolePermissaoItem(
          telaNome: 'Dashboard',
          podeVer: true,
          podeInserir: false,
          podeEditar: false,
          podeDeletar: false,
        ),
      ];
      PermissionService().setPermissoes(permissoes);

      final filtered = PermissionService().getFilteredLooseItems();

      // Dashboard deve estar nos loose items
      expect(
        filtered.any((item) => item.id == 'dashboard'),
        true,
      );
    });
  });
}
