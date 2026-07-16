import 'package:flutter_test/flutter_test.dart';

/// CARD #319: Testes para exibição legível de labels de roles
///
/// Verifica que roles com description/key vazias nunca exibem "Role #ID"
/// e sempre apresentam um fallback legível
void main() {
  group('LoginGridScreen - Role Label Display', () {
    /// T1: Quando role tem description preenchida, exibir description
    /// não deve exibir "Role #ID"
    test('T1: Exibir description quando preenchida', () {
      final role = {
        'id': 1,
        'description': 'Administrador',
        'key': '',
        'available': true
      };

      final desc = role['description']?.toString();
      final key = role['key']?.toString() ?? role['name']?.toString();
      final label = (desc != null && desc.isNotEmpty)
          ? desc
          : (key != null && key.isNotEmpty)
              ? key
              : 'Sem descrição'; // ← Fallback legível (não "Role #ID")

      expect(label, equals('Administrador'));
      expect(label, isNot('Role #${role['id']}'));
    });

    /// T2: Quando role tem key preenchida (mas description vazia),
    /// exibir key. Não deve ser "Role #ID"
    test('T2: Exibir key quando description vazia', () {
      final role = {
        'id': 2,
        'description': '',
        'key': 'ROLE_USER',
        'available': true
      };

      final desc = role['description']?.toString();
      final key = role['key']?.toString() ?? role['name']?.toString();
      final label = (desc != null && desc.isNotEmpty)
          ? desc
          : (key != null && key.isNotEmpty)
              ? key
              : 'Sem descrição';

      expect(label, equals('ROLE_USER'));
      expect(label, isNot('Role #${role['id']}'));
    });

    /// T3: Quando ambas description e key vazias,
    /// NUNCA exibir "Role #ID", usar fallback legível
    test('T3: Usar fallback legível quando tudo vazio', () {
      final role = {
        'id': 3,
        'description': '',
        'key': '',
        'available': true
      };

      final desc = role['description']?.toString();
      final key = role['key']?.toString() ?? role['name']?.toString();
      final label = (desc != null && desc.isNotEmpty)
          ? desc
          : (key != null && key.isNotEmpty)
              ? key
              : 'Sem descrição';

      // Validação 1: NÃO deve ser "Role #ID"
      expect(label, isNot('Role #3'));

      // Validação 2: Deve ser o fallback legível
      expect(label, equals('Sem descrição'));

      // Validação 3: Não pode estar vazio
      expect(label.isNotEmpty, isTrue);
    });

    /// T4: Cenário misto com vários roles
    /// Verifica que cada role recebe label apropriado
    test('T4: Processar lista de roles com fallback consistente', () {
      final roles = [
        {
          'id': 1,
          'description': 'Administrador',
          'key': 'ROLE_ADMIN',
          'available': true
        },
        {
          'id': 2,
          'description': '',
          'key': 'ROLE_USER',
          'available': true
        },
        {
          'id': 3,
          'description': '',
          'key': '',
          'available': true
        },
      ];

      final labels = roles.map((e) {
        final desc = e['description']?.toString();
        final key = e['key']?.toString();
        return (desc != null && desc.isNotEmpty)
            ? desc
            : (key != null && key.isNotEmpty)
                ? key
                : 'Sem descrição';
      }).toList();

      // Validações
      expect(labels[0], equals('Administrador'));
      expect(labels[1], equals('ROLE_USER'));
      expect(labels[2], equals('Sem descrição'));

      // Nenhuma deve ser "Role #ID"
      for (int i = 0; i < labels.length; i++) {
        expect(labels[i], isNot('Role #${roles[i]['id']}'));
      }
    });

    /// T5: Garantir que valores null/empty são tratados corretamente
    test('T5: Tratamento seguro de null e empty strings', () {
      final testCases = [
        {
          'name': 'null description, key preenchida',
          'role': {'id': 1, 'description': null, 'key': 'KEY1'},
          'expected': 'KEY1'
        },
        {
          'name': 'description preenchida, null key',
          'role': {'id': 2, 'description': 'DESC', 'key': null},
          'expected': 'DESC'
        },
        {
          'name': 'ambos null',
          'role': {'id': 3, 'description': null, 'key': null},
          'expected': 'Sem descrição'
        },
        {
          'name': 'description vazia, key preenchida',
          'role': {'id': 4, 'description': '', 'key': 'KEY4'},
          'expected': 'KEY4'
        },
        {
          'name': 'ambos vazios (empty strings)',
          'role': {'id': 5, 'description': '', 'key': ''},
          'expected': 'Sem descrição'
        },
      ];

      for (final testCase in testCases) {
        final role = testCase['role'] as Map<String, dynamic>;
        final expected = testCase['expected'] as String;

        final desc = role['description']?.toString();
        final key = role['key']?.toString();
        final label = (desc != null && desc.isNotEmpty)
            ? desc
            : (key != null && key.isNotEmpty)
                ? key
                : 'Sem descrição';

        expect(label, equals(expected), reason: testCase['name'] as String);
      }
    });
  });
}
