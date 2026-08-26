import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/services/ged_download_service.dart';

void main() {
  test('download GED salva bytes e compartilha o arquivo recebido', () async {
    final directory = await Directory.systemTemp.createTemp('ged-download-');
    addTearDown(() => directory.delete(recursive: true));
    String? compartilhado;

    final service = GedDownloadService(
      request: (uri, headers) async {
        expect(uri.path, endsWith('/api/arquivos/download/2983'));
        return http.Response('pdf-real', 200,
            headers: {'content-type': 'application/pdf'});
      },
      temporaryDirectory: () async => directory,
      share: (path, fileName) async => compartilhado = '$path|$fileName',
    );

    final path = await service.download(2983, 'documento.pdf');

    expect(await File(path).readAsString(), 'pdf-real');
    expect(compartilhado, '$path|documento.pdf');
  });

  test('download GED transforma resposta HTTP em erro tipado', () async {
    final service = GedDownloadService(
      request: (_, __) async => http.Response('nao encontrado', 404),
      temporaryDirectory: Directory.systemTemp.createTemp,
      share: (_, __) async {},
    );

    expect(() => service.download(2983, 'documento.pdf'),
        throwsA(isA<GedDownloadException>()));
  });
}
