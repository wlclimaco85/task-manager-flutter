import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class CustomAction<T> {
  final IconData icon;
  final String label;
  final void Function(BuildContext, T) onPressed;
  final bool Function(T)? isVisible;

  CustomAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isVisible,
  });
}

void main() {
  group('CustomAction', () {
    test('isVisible retorna true quando nao definido', () {
      final action = CustomAction<String>(
        icon: Icons.price_check,
        label: 'Baixar',
        onPressed: (ctx, item) {},
      );
      expect(action.isVisible?.call('qualquer'), isNull);
    });

    test('isVisible filtra quando retorna false', () {
      final action = CustomAction<String>(
        icon: Icons.attach_file,
        label: 'Anexo',
        onPressed: (ctx, item) {},
        isVisible: (item) => item == 'visivel',
      );
      expect(action.isVisible!('visivel'), isTrue);
      expect(action.isVisible!('outro'), isFalse);
    });

    test('onPressed recebe o item correto', () {
      String? received;
      final action = CustomAction<String>(
        icon: Icons.price_check,
        label: 'Baixar',
        onPressed: (ctx, item) => received = item,
      );
      final ctx = MockBuildContext();
      action.onPressed(ctx, 'item123');
      expect(received, 'item123');
    });

    test('label e icon sao acessiveis', () {
      final action = CustomAction<String>(
        icon: Icons.star,
        label: 'Teste',
        onPressed: (ctx, item) {},
      );
      expect(action.icon, Icons.star);
      expect(action.label, 'Teste');
    });
  });
}

class MockBuildContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
