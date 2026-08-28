import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/web/screens/details/nfe_detail_screen.dart';

void main() {
  group('NfeSankhyaDetailScreen importacao XML', () {
    test('rascunho de importacao usa Confirmar Entrada como acao principal',
        () {
      expect(isNfeRascunhoImportacao('RASCUNHO_IMPORTACAO'), isTrue);
      expect(nfeEntradaPrimaryActionLabel('RASCUNHO_IMPORTACAO'),
          'Confirmar Entrada');
      expect(nfeEntradaPrimaryActionLabel('AUTORIZADA'), 'Aceitar');
    });
  });
}
