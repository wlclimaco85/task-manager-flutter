import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/api_links.dart';
import 'package:task_manager_flutter/widgets/mdfe_emissao_view.dart';

void main() {
  const chave = '31261112345678000195580010000000421373465956';

  test('corpo de emissao usa cadastro (veiculoId/motoristaIds) e nao envia rodoviario',
      () {
    final corpo = montarCorpoEmissaoMdfe(
      tpAmb: 2,
      tpEmit: 1,
      serie: 1,
      ufIni: 'MG',
      ufFim: 'SP',
      municipioCarregamentoIbge: '3106200',
      municipioCarregamentoNome: 'Belo Horizonte',
      municipioDescargaIbge: '3550308',
      municipioDescargaNome: 'Sao Paulo',
      chavesCte: const [chave],
      chavesNfe: const [],
      valorCarga: 1000,
      unidadeCarga: '01',
      quantidadeCarga: 500,
      veiculoId: 11,
      motoristaIds: const [4, 5],
    );
    expect(corpo['veiculoId'], 11);
    expect(corpo['motoristaIds'], [4, 5]);
    expect(corpo.containsKey('rodoviario'), isFalse);
    expect(corpo.containsKey('emitente'), isFalse);
    expect(corpo.containsKey('infoComplementar'), isFalse);
    final desc = (corpo['descargas'] as List).single as Map;
    expect(desc['chavesCte'], [chave]);
    expect((desc['municipio'] as Map)['codigoIbge'], '3550308');
  });

  test('seguro: sem responsavel nao envia; com contratante envia documento, seguradora e averbacoes', () {
    expect(montarSeguroMdfe(respSeg: null), isNull);

    final emitente = montarSeguroMdfe(respSeg: 1, documentoContratante: '123');
    expect(emitente, {'respSeg': 1});

    final s = montarSeguroMdfe(
      respSeg: 2,
      documentoContratante: '98.765.432/0001-10',
      seguradoraNome: ' Seguradora X ',
      seguradoraCnpj: '11.222.333/0001-81',
      apolice: 'AP-1',
      averbacoes: 'AV1\n\n AV2 \r\nAV3',
    )!;
    expect(s['respSeg'], 2);
    expect(s['cnpjCpfResponsavel'], '98.765.432/0001-10');
    expect(s['seguradoraNome'], 'Seguradora X');
    expect(s['numeroApolice'], 'AP-1');
    expect(s['averbacoes'], ['AV1', 'AV2', 'AV3']);
  });

  test('corpo de emissao inclui seguros so quando informado', () {
    Map<String, dynamic> corpo(Map<String, dynamic>? seguro) => montarCorpoEmissaoMdfe(
          tpAmb: 2, tpEmit: 1, serie: 1, ufIni: 'MG', ufFim: 'SP',
          municipioCarregamentoIbge: '3106200', municipioCarregamentoNome: 'BH',
          municipioDescargaIbge: '3550308', municipioDescargaNome: 'SP',
          chavesCte: const [chave], chavesNfe: const [], valorCarga: 1,
          unidadeCarga: '01', quantidadeCarga: 1, veiculoId: 1,
          motoristaIds: const [1], seguro: seguro);
    expect(corpo(null).containsKey('seguros'), isFalse);
    expect(corpo({'respSeg': 1})['seguros'], [
      {'respSeg': 1}
    ]);
  });

  test('extrairChaves separa por linha e acusa chaves invalidas', () {
    final invalidas = <String>[];
    final chaves = extrairChaves('$chave\n123\n$chave', invalidas: invalidas);
    expect(chaves, [chave, chave]);
    expect(invalidas, ['123']);
  });

  test('endpoints de MDF-e apontam para /api/mdfe/{id}', () {
    expect(ApiLinks.mdfeDamdfe('5'), endsWith('/api/mdfe/5/damdfe'));
    expect(ApiLinks.mdfeConsultar('5'), endsWith('/api/mdfe/5/consultar'));
  });

  test('lista da API le o envelope data.dados', () {
    final lista = listaMdfeDe({
      'data': {
        'dados': [
          {'id': 1, 'status': 'AUTORIZADO'}
        ]
      }
    });
    expect(lista.single['status'], 'AUTORIZADO');
    expect(listaMdfeDe({'data': 'x'}), isEmpty);
    expect(listaMdfeDe(null), isEmpty);
  });
}
