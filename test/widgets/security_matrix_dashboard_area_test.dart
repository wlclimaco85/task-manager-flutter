import 'package:flutter_test/flutter_test.dart';

import 'package:task_manager_flutter/models/login_model.dart';
import 'package:task_manager_flutter/models/role_model.dart';
import 'package:task_manager_flutter/utils/security_matrix.dart';

/// Testes de permissão granular dos 5 AppScreen novos de dashboard de área
/// (Fase 171, Tarefa F4). Cobre os dois mecanismos sobrepostos descritos no
/// Pitfall 3 da pesquisa: role_permissao (via backendPerms) E
/// ModuloAccess/_moduloToScreens — confirmando que o bloqueio por módulo
/// prevalece mesmo com role_permissao correta (Warning W4 do PLAN.md).
void main() {
  LoginModel buildUserInfo({
    required List<RolePermissaoItem> permissoes,
  }) {
    return LoginModel(
      token: 'token-fake',
      login: Login(
        id: 1,
        tipoLogin: LoginEnum.APP_ABRACO,
        roles: [Role(id: 32, key: 'ROLE_FINANCEIRO_MOD', description: 'Financeiro')],
      ),
      permissoes: permissoes,
    );
  }

  RolePermissaoItem permissao(String telaNome, {bool podeVer = true}) {
    return RolePermissaoItem(
      telaNome: telaNome,
      podeVer: podeVer,
      podeInserir: false,
      podeEditar: false,
      podeDeletar: false,
    );
  }

  setUp(() {
    // Reset do estado estatico de ModuloAccess entre testes — evita que um
    // teste anterior deixe _modulosContratados/_loaded vazando para o
    // proximo (estado global compartilhado entre testes).
    ModuloAccess.reset();
  });

  group('SecurityMatrix — canView dos 5 AppScreen novos via role_permissao',
      () {
    test('usuario com pode_ver=TRUE para dashFinanceiroArea ve a tela quando ModuloAccess nao filtra',
        () {
      final userInfo = buildUserInfo(
          permissoes: [permissao('dashFinanceiroArea')]);
      final matrix = SecurityMatrix.of(userInfo);

      // ModuloAccess nao carregado (_loaded=false) -> isScreenAllowed retorna
      // true sempre (comportamento padrao antes do primeiro load() real).
      expect(matrix.canView(AppScreen.dashFinanceiroArea), isTrue);
    });

    test('usuario SEM pode_ver para dashDpArea nao ve a tela', () {
      final userInfo = buildUserInfo(permissoes: [
        permissao('dashFinanceiroArea'),
        // dashDpArea ausente da lista de permissoes
      ]);
      final matrix = SecurityMatrix.of(userInfo);

      expect(matrix.canView(AppScreen.dashDpArea), isFalse);
    });

    test('usuario com pode_ver=FALSE explicito para dashAtendimentoArea nao ve a tela',
        () {
      final userInfo = buildUserInfo(permissoes: [
        permissao('dashAtendimentoArea', podeVer: false),
      ]);
      final matrix = SecurityMatrix.of(userInfo);

      expect(matrix.canView(AppScreen.dashAtendimentoArea), isFalse);
    });

    test('os 5 AppScreen novos respeitam role_permissao individualmente',
        () {
      final userInfo = buildUserInfo(permissoes: [
        permissao('dashFinanceiroArea'),
        permissao('dashComercialArea'),
        // dashAtendimentoArea, dashDpArea, dashFiscalArea ausentes
      ]);
      final matrix = SecurityMatrix.of(userInfo);

      expect(matrix.canView(AppScreen.dashFinanceiroArea), isTrue);
      expect(matrix.canView(AppScreen.dashComercialArea), isTrue);
      expect(matrix.canView(AppScreen.dashAtendimentoArea), isFalse);
      expect(matrix.canView(AppScreen.dashDpArea), isFalse);
      expect(matrix.canView(AppScreen.dashFiscalArea), isFalse);
    });
  });

  group(
      'SecurityMatrix — bloqueio por ModuloAccess/_moduloToScreens prevalece sobre role_permissao (Warning W4)',
      () {
    test(
        'role_permissao.pode_ver=TRUE para dashFinanceiroArea MAS modulo Financeiro NAO contratado -> canView=false',
        () {
      final userInfo = buildUserInfo(
          permissoes: [permissao('dashFinanceiroArea')]);
      final matrix = SecurityMatrix.of(userInfo);

      // Simula ModuloAccess carregado SEM o modulo 'Financeiro' contratado —
      // dashFinanceiroArea pertence a esse modulo (security_matrix.dart),
      // entao o bloqueio por modulo deve prevalecer mesmo com
      // role_permissao correta.
      ModuloAccess.setContratadosParaTeste(['Notas Fiscais']);

      expect(matrix.canView(AppScreen.dashFinanceiroArea), isFalse,
          reason:
              'Bloqueio por modulo deve prevalecer mesmo com role_permissao.pode_ver=TRUE');
    });

    test(
        'role_permissao.pode_ver=TRUE para dashDpArea MAS modulo Departamento Pessoal NAO contratado -> canView=false',
        () {
      final userInfo = buildUserInfo(permissoes: [permissao('dashDpArea')]);
      final matrix = SecurityMatrix.of(userInfo);

      ModuloAccess.setContratadosParaTeste(['Financeiro']);

      expect(matrix.canView(AppScreen.dashDpArea), isFalse);
    });

    test(
        'modulo Financeiro contratado E role_permissao.pode_ver=TRUE -> canView=true (ambos os mecanismos liberando)',
        () {
      final userInfo = buildUserInfo(
          permissoes: [permissao('dashFinanceiroArea')]);
      final matrix = SecurityMatrix.of(userInfo);

      ModuloAccess.setContratadosParaTeste(['Financeiro']);

      expect(matrix.canView(AppScreen.dashFinanceiroArea), isTrue);
    });

    test(
        'usuario SEM role_permissao.pode_ver MESMO COM modulo contratado -> canView=false (inverso do W4)',
        () {
      final userInfo = buildUserInfo(permissoes: [
        permissao('dashFinanceiroArea', podeVer: false),
      ]);
      final matrix = SecurityMatrix.of(userInfo);

      ModuloAccess.setContratadosParaTeste(['Financeiro']);

      expect(matrix.canView(AppScreen.dashFinanceiroArea), isFalse,
          reason:
              'Sem role_permissao.pode_ver, mesmo com modulo contratado, a tela nao deve aparecer');
    });

    test(
        'dashAtendimentoArea/dashComercialArea/dashFiscalArea pertencem a modulos (Chamados/Comercial/Notas Fiscais) — deny quando modulo nao contratado',
        () {
      final userInfo = buildUserInfo(permissoes: [
        permissao('dashAtendimentoArea'),
        permissao('dashComercialArea'),
        permissao('dashFiscalArea'),
      ]);
      final matrix = SecurityMatrix.of(userInfo);

      // Sem modulos contratados: deny-by-default para telas de modulo
      ModuloAccess.setContratadosParaTeste([]);

      expect(matrix.canView(AppScreen.dashAtendimentoArea), isFalse,
          reason: 'dashAtendimentoArea pertence ao modulo Chamados');
      expect(matrix.canView(AppScreen.dashComercialArea), isFalse,
          reason: 'dashComercialArea pertence ao modulo Comercial');
      expect(matrix.canView(AppScreen.dashFiscalArea), isFalse,
          reason: 'dashFiscalArea pertence ao modulo Notas Fiscais');
    });

    test(
        'dashAtendimentoArea/dashComercialArea/dashFiscalArea PERMITIDAS quando modulos contratados',
        () {
      final userInfo = buildUserInfo(permissoes: [
        permissao('dashAtendimentoArea'),
        permissao('dashComercialArea'),
        permissao('dashFiscalArea'),
      ]);
      final matrix = SecurityMatrix.of(userInfo);

      ModuloAccess.setContratadosParaTeste(['Chamados', 'Comercial', 'Notas Fiscais']);

      expect(matrix.canView(AppScreen.dashAtendimentoArea), isTrue);
      expect(matrix.canView(AppScreen.dashComercialArea), isTrue);
      expect(matrix.canView(AppScreen.dashFiscalArea), isTrue);
    });
  });
}
