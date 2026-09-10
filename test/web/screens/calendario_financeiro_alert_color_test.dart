import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calendario financeiro destaca dias com contas a pagar pendentes', () {
    final source =
        File('lib/web/screens/documento_screen.dart').readAsStringSync();

    expect(source, contains('static const Color _pagarAlertBackground'));
    expect(source, contains('} else if (markers.hasPagar) {'));
    expect(source, contains('bgColor = _pagarAlertBackground;'));
    expect(source, contains('textColor = Colors.white;'));
    expect(source,
        contains('_statusBadgeIcon(Icons.arrow_upward, Colors.white, 11)'));
  });
}
