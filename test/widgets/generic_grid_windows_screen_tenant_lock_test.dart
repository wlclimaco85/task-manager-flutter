import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/auth_utility.dart';
import 'package:task_manager_flutter/models/empresa_model.dart';
import 'package:task_manager_flutter/models/login_model.dart';
import 'package:task_manager_flutter/models/parceiro_model.dart';
import 'package:task_manager_flutter/widgets/generic_grid_windows_screen.dart';

void main() {
  group('travamento por parceiroId/parcId no contexto (extraParams)', () {
    const parceiroField = FieldConfigWindows(
      fieldName: 'parceiro',
      label: 'Parceiro',
    );
    const fornecedorField = FieldConfigWindows(
      fieldName: 'fornecedor',
      label: 'Fornecedor',
    );

    test(
        'sem parceiroId/parcId, Parceiro fica acessivel e Fornecedor bloqueado',
        () {
      final hasContextParceiro = hasParceiroContextInExtraParams({});

      expect(hasContextParceiro, isFalse);
      expect(
        isParceiroFieldDisabledByStorage(parceiroField, hasContextParceiro),
        isFalse,
      );
      expect(
        isFornecedorFieldEnabledByStorage(fornecedorField, hasContextParceiro),
        isFalse,
      );
    });

    test('com parceiroId, Parceiro trava e Fornecedor fica acessivel', () {
      final hasContextParceiro = hasParceiroContextInExtraParams({
        'parceiroId': '17',
      });

      expect(hasContextParceiro, isTrue);
      expect(
        isParceiroFieldDisabledByStorage(parceiroField, hasContextParceiro),
        isTrue,
      );
      expect(
        isFornecedorFieldEnabledByStorage(fornecedorField, hasContextParceiro),
        isTrue,
      );
    });

    test('com parcId, Parceiro trava e Fornecedor fica acessivel', () {
      final hasContextParceiro = hasParceiroContextInExtraParams({
        'parcId': 23,
      });

      expect(hasContextParceiro, isTrue);
      expect(
        isParceiroFieldDisabledByStorage(parceiroField, hasContextParceiro),
        isTrue,
      );
      expect(
        isFornecedorFieldEnabledByStorage(fornecedorField, hasContextParceiro),
        isTrue,
      );
    });

    test('valores vazios, zero ou null no contexto nao ativam o travamento',
        () {
      expect(
        hasParceiroContextInExtraParams({
          'parceiroId': '0',
          'parcId': 'null',
        }),
        isFalse,
      );
    });
  });

  // Bug real (card campo-parceiro-fornecedor-disabled-invertido): a versao
  // anterior lia SharedPreferences.get('parceiroId'/'parcId'), chaves que
  // NUNCA sao gravadas em lugar nenhum do app -- a leitura sempre retornava
  // null, travando "Fornecedor" para sempre e deixando "Parceiro" refem so
  // do proprio login. O contexto real de "estou dentro de um parceiro
  // especifico" vem do extraParams passado pela tela de origem (aba "Contas
  // a Pagar/Receber" dentro de parceiro_detail_screen.dart passa
  // parceiro/parceiroId; dentro de empresa_detail_screen.dart passa so
  // empresa/empresaId).
  group('contexto efetivo de parceiro (extraParams + login)', () {
    tearDown(() => AuthUtility.userInfo = null);

    test(
        'extraParams com parceiroId -> contexto de parceiro, independente do login',
        () {
      expect(
        effectiveHasParceiroContext({'parceiroId': 17}, false),
        isTrue,
      );
      expect(
        effectiveHasParceiroContext({'parceiroId': 17}, true),
        isTrue,
      );
    });

    test('extraParams com parcId -> contexto de parceiro', () {
      expect(effectiveHasParceiroContext({'parcId': '23'}, false), isTrue);
    });

    test(
        'extraParams so com empresa (aba dentro de Empresa) -> NUNCA contexto '
        'de parceiro, mesmo com login de parceiro (escritorio contabil)',
        () {
      expect(
        effectiveHasParceiroContext({'empresa': 5}, true),
        isFalse,
      );
      expect(
        effectiveHasParceiroContext({'empresaId': 5}, true),
        isFalse,
      );
    });

    test(
        'sem extraParams (acesso direto pelo menu) -> cai no proprio login',
        () {
      expect(effectiveHasParceiroContext(null, true), isTrue);
      expect(effectiveHasParceiroContext(null, false), isFalse);
      expect(effectiveHasParceiroContext({}, true), isTrue);
    });

    test(
        'cenario real do bug: campo Parceiro fica acessivel e Fornecedor '
        'bloqueado ao abrir "Novo Item" dentro de uma Empresa', () {
      AuthUtility.userInfo = LoginModel(
        token: 'token-test',
        login: Login(
          id: 1,
          email: 'contabilidade@test.com',
          empresa: Empresa(id: 1, nome: 'Empresa Teste'),
          parceiro: Parceiro(id: 99, nome: 'Escritorio Contabil'),
        ),
      );

      final hasContext = effectiveHasParceiroContext(
        {'empresa': 5},
        AuthUtility.userInfo!.login!.parceiro!.id! > 0,
      );

      const parceiroField = FieldConfigWindows(
        fieldName: 'parceiro',
        label: 'Parceiro',
      );
      const fornecedorField = FieldConfigWindows(
        fieldName: 'fornecedor',
        label: 'Fornecedor',
      );

      expect(hasContext, isFalse);
      expect(
        isParceiroFieldDisabledByStorage(parceiroField, hasContext),
        isFalse,
        reason: 'Parceiro deve ficar ACESSIVEL dentro de uma Empresa',
      );
      expect(
        isFornecedorFieldEnabledByStorage(fornecedorField, hasContext),
        isFalse,
        reason: 'Fornecedor deve ficar BLOQUEADO dentro de uma Empresa',
      );
    });

    test(
        'cenario real: campo Parceiro trava e Fornecedor fica acessivel ao '
        'abrir "Novo Item" dentro de um Parceiro especifico', () {
      final hasContext = effectiveHasParceiroContext(
        {'parceiro': 99, 'empresaId': 5},
        false,
      );

      const parceiroField = FieldConfigWindows(
        fieldName: 'parceiro',
        label: 'Parceiro',
      );
      const fornecedorField = FieldConfigWindows(
        fieldName: 'fornecedor',
        label: 'Fornecedor',
      );

      expect(hasContext, isTrue);
      expect(
        isParceiroFieldDisabledByStorage(parceiroField, hasContext),
        isTrue,
        reason: 'Parceiro deve ficar BLOQUEADO dentro de um Parceiro',
      );
      expect(
        isFornecedorFieldEnabledByStorage(fornecedorField, hasContext),
        isTrue,
        reason: 'Fornecedor deve ficar ACESSIVEL dentro de um Parceiro',
      );
    });
  });
}
