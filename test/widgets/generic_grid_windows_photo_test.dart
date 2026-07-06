import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/generic_grid_windows_screen.dart';

void main() {
  test('platformFileToDataUri converts image bytes to data URI', () async {
    final file = PlatformFile(
      name: 'avatar.png',
      size: 3,
      bytes: Uint8List.fromList([1, 2, 3]),
    );

    final dataUri = await platformFileToDataUri(file);

    expect(dataUri, 'data:image/png;base64,AQID');
  });

  test('platformFileToDataUri returns null for empty bytes', () async {
    final file = PlatformFile(
      name: 'avatar.jpg',
      size: 0,
      bytes: Uint8List(0),
    );

    final dataUri = await platformFileToDataUri(file);

    expect(dataUri, isNull);
  });
}
