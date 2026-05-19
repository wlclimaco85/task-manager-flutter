import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui; // ← Adicione esta importação

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../models/auth_utility.dart';
import '../../../utils/api_links.dart';


import 'package:task_manager_flutter/utils/app_logger.dart';
class UploadFileCaller {
  Future<int> uploadFiles(
    String itemId,
    Map<String, List<PlatformFile>> filesToUpload,
  ) async {
    final String authToken = '${AuthUtility.userInfo?.token}';

    if (filesToUpload.isEmpty) return 0;

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiLinks.uploadFile),
      );

      request.fields['itemId'] = itemId;

      for (final entry in filesToUpload.entries) {
        final String fieldName = entry.key;
        final List<PlatformFile> files = entry.value;

        for (final platformFile in files) {
          Uint8List fileBytes;

          if (platformFile.bytes != null) {
            fileBytes = platformFile.bytes!;
          } else if (platformFile.path != null) {
            File ioFile = File(platformFile.path!);
            fileBytes = await ioFile.readAsBytes();
          } else {
            continue;
          }

          request.files.add(
            http.MultipartFile.fromBytes(
              fieldName,
              fileBytes,
              filename: platformFile.name,
            ),
          );
        }
      }

      // Adicionar headers de autenticação
      if (authToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }

      // Enviar a requisição
      final response = await request.send();

      // Verificar resposta
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final decoded = jsonDecode(responseBody);
        return decoded['fileId'] ?? 0;
      } else {
        final errorBody = await response.stream.bytesToString();
        L.d('Erro no upload (${response.statusCode}): $errorBody');
      }
    } catch (e) {
      L.d('Exceção durante o upload: $e');
    }
    return 0;
  }

  Future<int> downloadFile(int fileId, String fileName) async {
    try {
      final String authToken = '${AuthUtility.userInfo?.token}';

      final response = await http.get(
        Uri.parse(
          ApiLinks.downloadFile(fileId.toString()),
        ),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        await Share.shareXFiles(
          [XFile(file.path, mimeType: fileName.split('.').last)],
          sharePositionOrigin: ui.Rect.largest,
        );

        L.d('Download realizado com sucesso');
      } else {
        L.d('Falha no download: ${response.statusCode}');
      }
      return response.statusCode;
    } catch (e) {
      L.d('Erro no download: $e');
    }
    return 0;
  }
}
