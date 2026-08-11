import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/nfce/nfce_config_fiscal_cache_model.dart';
import 'package:task_manager_flutter/utils/api_links.dart';

void main() {
  group('NFC-e config fiscal por cliente', () {
    test('URL sem cliente busca configuracao da empresa', () {
      final url = ApiLinks.configFiscal(1);

      expect(url, endsWith('/api/v1/fiscal/nfce/config/1'));
      expect(url, isNot(contains('parceiroId=')));
    });

    test('URL com cliente busca configuracao especifica do parceiro', () {
      final url = ApiLinks.configFiscal(1, parceiroId: 814);

      expect(url, endsWith('/api/v1/fiscal/nfce/config/1?parceiroId=814'));
    });

    test('cache separa empresa e cliente na chave local', () {
      expect(
        NfceConfigFiscalCacheModel.chave(empresaId: 1),
        equals('emp1_par-'),
      );
      expect(
        NfceConfigFiscalCacheModel.chave(empresaId: 1, parceiroId: 814),
        equals('emp1_par814'),
      );
    });
  });
}
