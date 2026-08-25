import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/generic_grid_windows_screen.dart';

void main() {
  group('travamento por parceiroId/parcId no storage', () {
    const parceiroField = FieldConfigWindows(
      fieldName: 'parceiro',
      label: 'Parceiro',
    );
    const fornecedorField = FieldConfigWindows(
      fieldName: 'fornecedor',
      label: 'Fornecedor',
    );

    test(
        'sem parceiroId/parcId, Parceiro fica acessivel e Fornecedor bloqueado',
        () {
      final hasStorageParceiro = hasParceiroIdOrParcIdInStorageValues({});

      expect(hasStorageParceiro, isFalse);
      expect(
        isParceiroFieldDisabledByStorage(parceiroField, hasStorageParceiro),
        isFalse,
      );
      expect(
        isFornecedorFieldEnabledByStorage(fornecedorField, hasStorageParceiro),
        isFalse,
      );
    });

    test('com parceiroId, Parceiro trava e Fornecedor fica acessivel', () {
      final hasStorageParceiro = hasParceiroIdOrParcIdInStorageValues({
        'parceiroId': '17',
      });

      expect(hasStorageParceiro, isTrue);
      expect(
        isParceiroFieldDisabledByStorage(parceiroField, hasStorageParceiro),
        isTrue,
      );
      expect(
        isFornecedorFieldEnabledByStorage(fornecedorField, hasStorageParceiro),
        isTrue,
      );
    });

    test('com parcId, Parceiro trava e Fornecedor fica acessivel', () {
      final hasStorageParceiro = hasParceiroIdOrParcIdInStorageValues({
        'parcId': 23,
      });

      expect(hasStorageParceiro, isTrue);
      expect(
        isParceiroFieldDisabledByStorage(parceiroField, hasStorageParceiro),
        isTrue,
      );
      expect(
        isFornecedorFieldEnabledByStorage(fornecedorField, hasStorageParceiro),
        isTrue,
      );
    });

    test('valores vazios, zero ou null no storage nao ativam o travamento', () {
      expect(
        hasParceiroIdOrParcIdInStorageValues({
          'parceiroId': '0',
          'parcId': 'null',
        }),
        isFalse,
      );
    });
  });
}
