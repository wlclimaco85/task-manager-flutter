import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/file_saver_compat.dart';

void main() {
  tearDown(() => FileSaver.debugForcarWeb = null);

  test('na web baixa pelo navegador sem usar path_provider (DANFSe pdf)', () async {
    FileSaver.debugForcarWeb = true;
    String? nome;
    String? mime;
    List<int>? dados;

    final retorno = await FileSaver.instance.saveFile(
      name: 'danfse_11',
      bytes: Uint8List.fromList([1, 2, 3]),
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
      baixarNoNavegador: (b, f, m) async {
        dados = b;
        nome = f;
        mime = m;
      },
    );

    expect(nome, 'danfse_11.pdf');
    expect(mime, 'application/pdf');
    expect(dados, [1, 2, 3]);
    expect(retorno, 'danfse_11.pdf');
  });

  test('nome que ja tem a extensao nao duplica', () async {
    FileSaver.debugForcarWeb = true;
    String? nome;
    await FileSaver.instance.saveFile(
      name: 'nota.XML',
      bytes: Uint8List(0),
      fileExtension: 'xml',
      mimeType: MimeType.xml,
      baixarNoNavegador: (b, f, m) async => nome = f,
    );
    expect(nome, 'nota.XML');
  });
}
