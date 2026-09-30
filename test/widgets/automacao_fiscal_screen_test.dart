import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/automacao_fiscal_screen.dart';

/// Card automacao-fiscal-pastas (2026-09-10) -- tela Sistema > Automacao
/// Fiscal. NetworkCaller usa as funcoes top-level de package:http
/// diretamente (sem client injetavel), entao a chamada de rede em si nao e
/// testavel aqui sem infraestrutura adicional (mesmo padrao documentado em
/// produto_impostos_tab_test.dart) -- por isso os mapeamentos de rotulo
/// (origem/tipo de documento) foram extraidos em funcoes puras e sao
/// testados diretamente.
void main() {
  group('origemLabel', () {
    test('mapeia os valores conhecidos do backend', () {
      expect(origemLabel('BOLETO'), 'Boletos');
      expect(origemLabel('SPED'), 'SPED');
      expect(origemLabel('SINTEGRA'), 'Sintegra');
      expect(origemLabel('XML'), 'XML');
    });

    test('valor desconhecido ou nulo cai no fallback', () {
      expect(origemLabel('OUTRO'), 'OUTRO');
      expect(origemLabel(null), '-');
    });
  });

  group('tipoDocumentoLabel', () {
    test('mapeia todos os tipos reconhecidos pelo classificador do backend', () {
      expect(tipoDocumentoLabel('BOLETO_FORNECEDOR'), 'Boleto Fornecedor');
      expect(tipoDocumentoLabel('FGTS'), 'FGTS');
      expect(tipoDocumentoLabel('DAE_ICMS'), 'DAE ICMS');
      expect(tipoDocumentoLabel('DARF_FEDERAL'), 'DARF Federal');
      expect(tipoDocumentoLabel('GUIA_ISS_MUNICIPAL'), 'Guia ISS');
      expect(tipoDocumentoLabel('COMPROVANTE_PAGAMENTO'), 'Comprovante de Pagamento');
      expect(tipoDocumentoLabel('CTE'), 'CT-e (Transporte)');
      expect(tipoDocumentoLabel('NFE'), 'NF-e (Entrada)');
      expect(tipoDocumentoLabel('NFCE'), 'NFC-e (Consumidor)');
      expect(tipoDocumentoLabel('NFSE'), 'NFS-e (Serviço)');
    });

    test('nulo vira traco, tipo desconhecido vira "Não identificado"', () {
      expect(tipoDocumentoLabel(null), '-');
      expect(tipoDocumentoLabel('DESCONHECIDO'), 'Não identificado');
    });
  });

  group('extrairCnpj', () {
    test('extrai CNPJ formatado ou 14 digitos de mensagem de erro', () {
      expect(
        extrairCnpj('CNPJ do arquivo SINTEGRA (38504938000626) nao corresponde a empresa'),
        '38504938000626',
      );
      expect(
        extrairCnpj('Nenhum parceiro cadastrado para o CNPJ 11.222.333/0001-81 na base.'),
        '11.222.333/0001-81',
      );
      expect(extrairCnpj('Erro desconhecido sem documento'), isNull);
      expect(extrairCnpj(null), isNull);
      expect(extrairCnpj(''), isNull);
    });
  });

  group('formatarRelatorioErrosParaClipboard', () {
    test('formata lista de erros consolidada com detalhes para clipboard', () {
      final logs = [
        {
          'status': 'ERRO',
          'arquivo': 'nfe_1066.xml',
          'origem': 'XML',
          'tipoDocumento': 'NFE',
          'mensagem': 'Falha ao parsear XML da NF-e: Invalid byte 2 of 2-byte UTF-8 sequence.',
        },
        {
          'status': 'SUCESSO',
          'arquivo': 'nfe_1067.xml',
          'origem': 'XML',
          'tipoDocumento': 'NFE',
          'mensagem': 'Sucesso',
        },
        {
          'status': 'ERRO',
          'arquivo': 'nfce_26.xml',
          'origem': 'XML',
          'tipoDocumento': 'NFCE',
          'mensagem': 'NF-e já importada. Chave: 31260919364209000162650010000000251758778562',
        },
      ];

      final texto = formatarRelatorioErrosParaClipboard(
        logs: logs,
        dataHora: DateTime(2026, 9, 30, 15, 23),
        pastaRaiz: 'C:\\AutomacaoFiscal',
        ultimoResultado: '1 sucesso, 2 erro',
      );

      expect(texto, contains('RELATÓRIO DE ERROS / EXCEPTIONS'));
      expect(texto, contains('Data/Hora: 30/09/2026 15:23:00'));
      expect(texto, contains('Pasta Raiz: C:\\AutomacaoFiscal'));
      expect(texto, contains('Total de arquivos com erro: 2'));
      expect(texto, contains('Arquivo: nfe_1066.xml'));
      expect(texto, contains('Invalid byte 2 of 2-byte UTF-8 sequence'));
      expect(texto, contains('Arquivo: nfce_26.xml'));
      expect(texto, contains('NF-e já importada'));
      // Não deve incluir arquivos com sucesso
      expect(texto, isNot(contains('nfe_1067.xml')));
    });

    test('quando nao ha erros retorna mensagem amigavel', () {
      final texto = formatarRelatorioErrosParaClipboard(
        logs: [],
        ultimoResultado: '5 sucesso, 0 erro',
      );
      expect(texto, contains('Última execução: 5 sucesso, 0 erro'));
    });
  });
}
