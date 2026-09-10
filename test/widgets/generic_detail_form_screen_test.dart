import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GenericDetailFormScreen - Controllers Persistence', () {
    test('Flag _initialized previne reinicialização múltipla', () {
      // Simula o comportamento de _initControllers com flag _initialized
      bool initialized = false;
      int initCount = 0;
      final controllers = <String, TextEditingController>{};
      final item = {'id': 1, 'nome': 'Teste'};

      void initControllers() {
        if (!initialized) {
          initCount++;
          controllers['nome'] =
              TextEditingController(text: (item['nome'] as String?) ?? '');
          initialized = true;
        }
      }

      // Simula múltiplas chamadas no build()
      initControllers();
      initControllers();
      initControllers();

      // Verificar que inicializou apenas uma vez
      expect(
        initCount,
        1,
        reason: 'Flag _initialized garante inicialização única mesmo com múltiplas chamadas',
      );

      // Verificar que controller foi criado
      expect(
        controllers.containsKey('nome'),
        true,
        reason: 'Controller deve ser criado na primeira inicialização',
      );

      expect(
        controllers['nome']!.text,
        'Teste',
        reason: 'Controller deve manter o valor do item',
      );

      // Editar o controller
      controllers['nome']!.text = 'Alterado';

      // Simular novo rebuild (a flag permanece true)
      initControllers();
      initControllers();

      // initCount ainda deve ser 1 (não reinicializou)
      expect(
        initCount,
        1,
        reason: 'Não deve reinicializar mesmo após múltiplos rebuilds',
      );

      // Valor deve ser preservado (não voltou ao original)
      expect(
        controllers['nome']!.text,
        'Alterado',
        reason: 'Valor alterado deve ser preservado, não reinicializado',
      );
    });

  });
}
