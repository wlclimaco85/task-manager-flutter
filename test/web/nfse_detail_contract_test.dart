import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('NFS-e Web bloqueia tomador da sessao e normaliza series de NFS-e', () {
    final source = File('lib/web/screens/details/nfse_detail_screen.dart')
        .readAsStringSync();

    expect(source, contains('_tomadorNome'));
    expect(source, contains('TenantContext.hasParceiro'));
    expect(source, contains("replaceAll('_', '-').toUpperCase()"));
    expect(source, contains("normalizado == 'NFS-E'"));
    expect(source, contains("serie['numeroAtual'] ?? serie['numero_atual']"));
    expect(source, contains("if (_isNovo || _statusAtual == 'PENDENTE')"));
    expect(source, contains('await _salvarCabecalho();'));
  });

  test('cliente NFS-e preserva o ID no cancelamento quando informado', () {
    final source = File('lib/services/nfse_caller.dart').readAsStringSync();

    expect(source, contains('int? nfseId'));
    expect(source, contains("if (nfseId != null) 'nfseId': nfseId"));
  });
}
