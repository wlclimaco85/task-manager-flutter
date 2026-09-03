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

    test('sem parceiroId/parcId, Parceiro fica acessivel', () {
      final hasContextParceiro = hasParceiroContextInExtraParams({});

      expect(hasContextParceiro, isFalse);
      expect(
        isParceiroFieldDisabledByStorage(parceiroField, hasContextParceiro),
        isFalse,
      );
    });

    test('com parceiroId, Parceiro trava', () {
      final hasContextParceiro = hasParceiroContextInExtraParams({
        'parceiroId': '17',
      });

      expect(hasContextParceiro, isTrue);
      expect(
        isParceiroFieldDisabledByStorage(parceiroField, hasContextParceiro),
        isTrue,
      );
    });

    test('com parcId, Parceiro trava', () {
      final hasContextParceiro = hasParceiroContextInExtraParams({
        'parcId': 23,
      });

      expect(hasContextParceiro, isTrue);
      expect(
        isParceiroFieldDisabledByStorage(parceiroField, hasContextParceiro),
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
  //
  // Fix seguinte (pedido explicito do usuario): "Fornecedor" nunca deveria
  // ficar bloqueado -- a trava hardcoded por nome/label desse campo foi
  // removida do widget generico (ver generic_grid_windows_screen.dart).
  // Quem decide "enabled" pra Fornecedor agora e so o FieldConfigWindows de
  // cada tela (conta_pagar_grid_screen.dart, parceiro_detail_screen.dart),
  // sem segunda trava paralela. Os testes abaixo cobrem so o que continua
  // existindo: o contexto efetivo de parceiro e o travamento do campo
  // "Parceiro" (isso nao mudou).
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
        'cenario real: campo Parceiro fica acessivel ao abrir "Novo Item" '
        'dentro de uma Empresa', () {
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

      expect(hasContext, isFalse);
      expect(
        isParceiroFieldDisabledByStorage(parceiroField, hasContext),
        isFalse,
        reason: 'Parceiro deve ficar ACESSIVEL dentro de uma Empresa',
      );
    });

    test(
        'cenario real: campo Parceiro trava ao abrir "Novo Item" dentro de '
        'um Parceiro especifico', () {
      final hasContext = effectiveHasParceiroContext(
        {'parceiro': 99, 'empresaId': 5},
        false,
      );

      const parceiroField = FieldConfigWindows(
        fieldName: 'parceiro',
        label: 'Parceiro',
      );

      expect(hasContext, isTrue);
      expect(
        isParceiroFieldDisabledByStorage(parceiroField, hasContext),
        isTrue,
        reason: 'Parceiro deve ficar BLOQUEADO dentro de um Parceiro',
      );
    });
  });

  // Bug de producao (card WdlEAxFK, achado em code review do card 579,
  // task_6e15201d): o VALOR INICIAL do campo Parceiro (bloco "TAREFA 1" de
  // _openForm) usava TenantContext.hasParceiro bruto em vez do contexto
  // EFETIVO ja calculado por effectiveHasParceiroContext -- um Cliente
  // abrindo uma tela em drill-down de Empresa ainda tinha o campo Parceiro
  // pre-preenchido com o proprio parceiro do login, mesmo o campo devendo
  // ficar sem contexto de parceiro nenhum ali. Fix: shouldPrefillParceiroField
  // reaproveita o contexto efetivo (extraido do bloco TAREFA 1 pra ser
  // testavel sem montar o widget inteiro).
  group('shouldPrefillParceiroField (pre-fill do valor inicial no INSERT)',
      () {
    const parceiroField = FieldConfigWindows(
      fieldName: 'parceiro',
      label: 'Parceiro',
    );
    const clienteField = FieldConfigWindows(
      fieldName: 'cliente',
      label: 'Cliente',
    );
    const fornecedorField = FieldConfigWindows(
      fieldName: 'parceiroFornecedor',
      label: 'Fornecedor',
    );
    const empresaField = FieldConfigWindows(
      fieldName: 'empresa',
      label: 'Empresa',
    );

    test(
        'NAO pre-preenche em drill-down de Empresa mesmo com login de '
        'parceiro (regressao do bug corrigido)', () {
      final hasContext = effectiveHasParceiroContext({'empresa': 5}, true);
      expect(hasContext, isFalse);
      expect(
        shouldPrefillParceiroField(parceiroField, hasContext),
        isFalse,
        reason: 'Contexto empresa-only nao deve pre-preencher Parceiro',
      );
    });

    test('pre-preenche em drill-down de Parceiro (comportamento existente)',
        () {
      final hasContext =
          effectiveHasParceiroContext({'parceiro': 99}, false);
      expect(hasContext, isTrue);
      expect(shouldPrefillParceiroField(parceiroField, hasContext), isTrue);
    });

    test(
        'pre-preenche sem extraParams quando o login tem parceiro '
        '(acesso direto pelo menu, comportamento existente)', () {
      final hasContext = effectiveHasParceiroContext(null, true);
      expect(hasContext, isTrue);
      expect(shouldPrefillParceiroField(parceiroField, hasContext), isTrue);
      expect(shouldPrefillParceiroField(clienteField, hasContext), isTrue);
      expect(shouldPrefillParceiroField(fornecedorField, hasContext), isTrue);
    });

    test('NAO pre-preenche sem extraParams quando o login nao tem parceiro',
        () {
      final hasContext = effectiveHasParceiroContext(null, false);
      expect(hasContext, isFalse);
      expect(shouldPrefillParceiroField(parceiroField, hasContext), isFalse);
    });

    test('campo Empresa nunca e afetado (so campos de Parceiro)', () {
      expect(shouldPrefillParceiroField(empresaField, true), isFalse);
    });
  });
}
