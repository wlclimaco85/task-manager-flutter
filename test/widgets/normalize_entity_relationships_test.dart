import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/generic_grid_windows_screen.dart'
    as windows;
import 'package:task_manager_flutter/widgets/generic_grid_screen.dart'
    as web;

// Regressão card #459: PUT /api/login falhava com 400 "campo parceiro com
// estrutura incompativel" porque o dropdown de parceiro mandava o id como
// String solta ("1536") em vez de objeto {"id": 1536}, ao contrário de
// campos como "empresa" (já vinha correto por outro caminho). O backend
// espera {"id": N} em todo relacionamento @ManyToOne/@JoinColumn.
void main() {
  group('generic_grid_windows_screen.normalizeEntityRelationships', () {
    test('converte id String em objeto {id: int}', () {
      final result = windows.normalizeEntityRelationships({
        'parceiro': '1536',
        'nome': 'Teste',
      });

      expect(result['parceiro'], {'id': 1536});
      expect(result['nome'], 'Teste');
    });

    test('converte id numérico em objeto {id: int}', () {
      final result = windows.normalizeEntityRelationships({'empresa': 20005});

      expect(result['empresa'], {'id': 20005});
    });

    test('não mexe em campo que já é objeto (idempotente)', () {
      final result = windows.normalizeEntityRelationships({
        'aplicativo': {'id': 1},
      });

      expect(result['aplicativo'], {'id': 1});
    });

    test('ignora string vazia', () {
      final result = windows.normalizeEntityRelationships({'parceiro': ''});

      expect(result['parceiro'], '');
    });

    test('não mexe em campos fora da whitelist', () {
      final result =
          windows.normalizeEntityRelationships({'cpfCnpj': '12345678900'});

      expect(result['cpfCnpj'], '12345678900');
    });
  });

  group('generic_grid_screen.normalizeEntityRelationships (Web)', () {
    test('converte id String em objeto {id: int}', () {
      final result = web.normalizeEntityRelationships({'parceiro': '1536'});

      expect(result['parceiro'], {'id': 1536});
    });

    test('não mexe em campo que já é objeto (idempotente)', () {
      final result = web.normalizeEntityRelationships({
        'aplicativo': {'id': 1},
      });

      expect(result['aplicativo'], {'id': 1});
    });
  });
}
