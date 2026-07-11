import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/windows/screens/role_permissao_screen.dart'
    as windows;
import 'package:task_manager_flutter/web/screens/role_permissao_screen.dart'
    as web;

// Regressão card #460: tela Controle de Acesso não carregava o estado
// salvo das permissões porque o id do MenuConfig (snake_case, ex.:
// 'nfe_entrada') nunca batia com role_permissao.tela_nome no backend
// (camelCase, ex.: 'nfeEntrada'). toBackendTelaNome() faz essa conversão.
void main() {
  group('windows/screens/role_permissao_screen.toBackendTelaNome', () {
    test('converte id simples de uma palavra sem alteração', () {
      expect(windows.toBackendTelaNome('chat'), 'chat');
    });

    test('converte snake_case de duas palavras em camelCase', () {
      expect(windows.toBackendTelaNome('nfe_entrada'), 'nfeEntrada');
    });

    test('converte snake_case de três palavras em camelCase', () {
      expect(
          windows.toBackendTelaNome('nfe_tipo_operacao'), 'nfeTipoOperacao');
    });

    test('bate com valores reais do seed V101__Role_permissao.sql', () {
      expect(windows.toBackendTelaNome('tipo_parceiro'), 'tipoParceiro');
      expect(windows.toBackendTelaNome('contas_pagar'), 'contasPagar');
      expect(windows.toBackendTelaNome('nfe_saida'), 'nfeSaida');
      expect(windows.toBackendTelaNome('nfe_serie'), 'nfeSerie');
    });
  });

  group('web/screens/role_permissao_screen.toBackendTelaNome', () {
    test('converte snake_case em camelCase (mesma lógica da versão Windows)',
        () {
      expect(web.toBackendTelaNome('nfe_entrada'), 'nfeEntrada');
      expect(web.toBackendTelaNome('tipo_parceiro'), 'tipoParceiro');
    });
  });
}
