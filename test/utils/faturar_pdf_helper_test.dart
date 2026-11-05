import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/faturar_pdf_helper.dart';

void main() {
  test('baixa o PDF de cada nota faturada com sucesso, ignorando falhas de faturamento', () async {
    final obtidos = <int>[];
    final salvos = <String>[];

    final baixados = await baixarPdfsDasNotas(
      [
        {'sucesso': true, 'nfseId': 11},
        {'sucesso': false, 'nfseId': null, 'mensagem': 'limite'},
        {'sucesso': true, 'nfseId': 12},
      ],
      obter: (id) async {
        obtidos.add(id);
        return [37, 80, 68, 70];
      },
      salvar: (nome, bytes) async => salvos.add('$nome:${bytes.length}'),
    );

    expect(baixados, 2);
    expect(obtidos, [11, 12]);
    expect(salvos, ['danfse_11:4', 'danfse_12:4']);
  });

  test('PDF indisponivel ou erro ao salvar nao derruba as demais notas', () async {
    final salvos = <String>[];

    final baixados = await baixarPdfsDasNotas(
      [
        {'sucesso': true, 'nfseId': 1},
        {'sucesso': true, 'nfseId': 2},
        {'sucesso': true, 'nfseId': 3},
      ],
      obter: (id) async => id == 1 ? null : [1],
      salvar: (nome, bytes) async {
        if (nome == 'danfse_2') throw Exception('disco cheio');
        salvos.add(nome);
      },
    );

    expect(baixados, 1);
    expect(salvos, ['danfse_3']);
  });

  test('sem resultados nao baixa nada', () async {
    expect(
        await baixarPdfsDasNotas(const [],
            obter: (_) async => [1], salvar: (_, __) async {}),
        0);
  });
}
