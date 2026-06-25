import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/login_model.dart';
import 'package:task_manager_flutter/models/parceiro_model.dart';
import 'package:task_manager_flutter/models/role_model.dart';
import 'package:task_manager_flutter/utils/security_matrix.dart';

/// Aceite ponta a ponta: matriz módulo ↔ ação (fecha épico "Acesso por Módulo do Cliente").
///
/// Cobre:
/// - AppAction.baixar em Financeiro Limitado (VER + BAIXAR, sem INSERIR/EDITAR/DELETAR)
/// - isFinanceiroLimitado getter
/// - ActionGate: some sem permissão, desabilita por estado (coberto em action_gate_test.dart)
/// - Módulo Comercial com telas corretas
void main() {
  LoginModel buildCliente({
    required List<String> modulosContratados,
    List<RolePermissaoItem> permissoes = const [],
  }) {
    final userInfo = LoginModel(
      token: 'tok',
      login: Login(
        id: 99,
        tipoLogin: LoginEnum.APP_ABRACO,
        roles: [Role(id: 1, key: 'ROLE_FATURISTA', description: 'Faturista')],
        parceiro: Parceiro(id: 5, nome: 'Cliente Teste'),
      ),
      permissoes: permissoes,
    );
    ModuloAccess.setContratadosParaTeste(modulosContratados);
    return userInfo;
  }

  setUp(() => ModuloAccess.reset());

  // ── Financeiro Limitado ─────────────────────────────────────────────────────

  group('Financeiro Limitado — VER e BAIXAR, sem as outras ações', () {
    test('cliente COM Financeiro Limitado pode VER contasPagar', () {
      final info = buildCliente(
        modulosContratados: ['Financeiro Limitado'],
        permissoes: [
          RolePermissaoItem(
              telaNome: 'contasPagar',
              podeVer: true,
              podeInserir: false,
              podeEditar: false,
              podeDeletar: false,
              podeBaixar: true),
        ],
      );
      final matrix = SecurityMatrix.of(info);
      expect(matrix.canView(AppScreen.contasPagar), isTrue);
    });

    test('cliente COM Financeiro Limitado pode BAIXAR contasPagar (action=baixar)', () {
      final info = buildCliente(
        modulosContratados: ['Financeiro Limitado'],
        permissoes: [
          RolePermissaoItem(
              telaNome: 'contasPagar',
              podeVer: true,
              podeInserir: false,
              podeEditar: false,
              podeDeletar: false,
              podeBaixar: true),
        ],
      );
      final matrix = SecurityMatrix.of(info);
      expect(matrix.canBaixar(AppScreen.contasPagar), isTrue);
    });

    test('cliente COM Financeiro Limitado NAO pode INSERIR em contasPagar', () {
      final info = buildCliente(
        modulosContratados: ['Financeiro Limitado'],
        permissoes: [
          RolePermissaoItem(
              telaNome: 'contasPagar',
              podeVer: true,
              podeInserir: true,
              podeEditar: true,
              podeDeletar: true,
              podeBaixar: true),
        ],
      );
      final matrix = SecurityMatrix.of(info);
      // SecurityMatrix._can() impõe restrição de ação no modo limitado.
      expect(matrix.canInsert(AppScreen.contasPagar), isFalse);
    });

    test('cliente COM Financeiro Limitado NAO pode VER contasReceber', () {
      final info = buildCliente(
        modulosContratados: ['Financeiro Limitado'],
        permissoes: [
          RolePermissaoItem(
              telaNome: 'contasReceber',
              podeVer: true,
              podeInserir: false,
              podeEditar: false,
              podeDeletar: false,
              podeBaixar: false),
        ],
      );
      final matrix = SecurityMatrix.of(info);
      // contasReceber pertence ao módulo 'Financeiro' (não ao Limitado).
      expect(matrix.canView(AppScreen.contasReceber), isFalse);
    });
  });

  // ── isFinanceiroLimitado getter ─────────────────────────────────────────────

  group('isFinanceiroLimitado', () {
    test('retorna true quando tem Financeiro Limitado mas NAO tem Financeiro', () {
      final info = buildCliente(modulosContratados: ['Financeiro Limitado']);
      expect(SecurityMatrix.of(info).isFinanceiroLimitado, isTrue);
    });

    test('retorna false quando tem Financeiro completo', () {
      final info = buildCliente(modulosContratados: ['Financeiro']);
      expect(SecurityMatrix.of(info).isFinanceiroLimitado, isFalse);
    });

    test('retorna false quando nao tem nenhum dos dois', () {
      final info = buildCliente(modulosContratados: ['Chamados']);
      expect(SecurityMatrix.of(info).isFinanceiroLimitado, isFalse);
    });
  });

  // ── Módulo Comercial ────────────────────────────────────────────────────────

  group('Módulo Comercial — telas permitidas', () {
    test('cliente COM Comercial pode VER dashComercialArea', () {
      final info = buildCliente(
        modulosContratados: ['Comercial'],
        permissoes: [
          RolePermissaoItem(
              telaNome: 'dashComercialArea',
              podeVer: true,
              podeInserir: false,
              podeEditar: false,
              podeDeletar: false,
              podeBaixar: false),
        ],
      );
      final matrix = SecurityMatrix.of(info);
      expect(matrix.canView(AppScreen.dashComercialArea), isTrue);
    });

    test('cliente SEM Comercial NAO pode VER dashComercialArea', () {
      final info = buildCliente(
        modulosContratados: ['Financeiro'],
        permissoes: [
          RolePermissaoItem(
              telaNome: 'dashComercialArea',
              podeVer: true,
              podeInserir: false,
              podeEditar: false,
              podeDeletar: false,
              podeBaixar: false),
        ],
      );
      final matrix = SecurityMatrix.of(info);
      expect(matrix.canView(AppScreen.dashComercialArea), isFalse);
    });
  });
}
