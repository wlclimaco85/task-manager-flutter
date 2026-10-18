import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

enum MimeType { pdf, csv, xml, other }

class FileSaver {
  FileSaver._();

  static final FileSaver instance = FileSaver._();

  Future<String> saveFile({
    required String name,
    required Uint8List bytes,
    String? fileExtension,
    MimeType? mimeType,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    var fileName = name;
    if (fileExtension != null && !fileName.toLowerCase().endsWith('.$fileExtension')) {
      fileName = '$fileName.$fileExtension';
    }
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}
