/// JSON minimo de uma NFe aceito por [NfeModel.fromJson]. Os campos de tomador
/// e valores ficam por conta dos valores padrao do modelo.
Map<String, dynamic> nfeJson(int id, {String status = 'AUTORIZADA'}) => {
      'id': id,
      'empresaId': 1,
      'numero': '000001',
      'serie': 1,
      'dataHora': '2026-08-04T10:30:00Z',
      'statusNfe': status,
      'cnpjEmitente': '12345678000199',
      'uf': 'SP',
      'ambiente': 'HOMOLOGACAO',
      'criadoEm': '2026-08-04T10:30:00Z',
    };
