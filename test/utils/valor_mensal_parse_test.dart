import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/nfse_faturar_utils.dart';

void main() {
  // Bug: "1097.47" vindo do backend era salvo como 109747 (ponto tratado como milhar).
  test('valor com ponto decimal do backend nao vira 100x maior', () {
    expect(nfseParseValorDigitado('1097.47'), 1097.47);
    expect(nfseParseValorDigitado('1097.5'), 1097.5);
    expect(nfseParseValorDigitado('810'), 810);
  });

  test('valor mascarado com virgula decimal continua correto', () {
    expect(nfseParseValorDigitado('1.097,47'), 1097.47);
    expect(nfseParseValorDigitado('1097,47'), 1097.47);
    expect(nfseParseValorDigitado(''), isNull);
  });
}
