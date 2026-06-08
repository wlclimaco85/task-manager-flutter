import 'dart:html' as html;
import 'dart:typed_data';

Future<List<int>?> pickAndReadFile({String accept = '.csv,.txt'}) async {
  final input = html.FileUploadInputElement()
    ..accept = accept
    ..multiple = false;
  input.click();
  await input.onChange.first;
  final files = input.files;
  if (files == null || files.isEmpty) return null;

  final file = files.first;
  final reader = html.FileReader()..readAsArrayBuffer(file);
  await reader.onLoadEnd.first;
  final raw = reader.result;
  final bytes = raw is ByteBuffer
      ? raw.asUint8List()
      : raw is Uint8List
          ? raw
          : Uint8List.fromList(raw is List<int> ? raw : const <int>[]);
  return bytes;
}
