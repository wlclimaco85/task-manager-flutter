import 'package:flutter_test/flutter_test.dart';

/// Mock de um listener para rastrear notificações
class MockStateListener {
  int notificationCount = 0;
  List<String> eventos = [];

  void onStateChanged(String evento) {
    notificationCount++;
    eventos.add(evento);
  }
}

/// Serviço de gerenciamento de estado UI (mock)
class UIStateService {
  final List<Function(String)> _listeners = [];
  Map<String, dynamic> _state = {};

  /// Registra um listener para mudanças de estado
  void addListener(Function(String) listener) {
    _listeners.add(listener);
  }

  /// Remove um listener
  void removeListener(Function(String) listener) {
    _listeners.remove(listener);
  }

  /// Notifica todos os listeners de uma mudança
  void _notifyListeners(String evento) {
    for (final listener in _listeners) {
      listener(evento);
    }
  }

  /// Atualiza o estado e notifica listeners
  void updateState(String key, dynamic value) {
    _state[key] = value;
    _notifyListeners('estado_atualizado: $key');
  }

  /// Obtém valor do estado
  dynamic getState(String key) => _state[key];

  /// Limpa o estado
  void reset() {
    _state.clear();
    _notifyListeners('estado_resetado');
  }

  /// Retorna cópia do estado
  Map<String, dynamic> getFullState() => Map.from(_state);
}

/// Serviço de persistência em SharedPreferences (mock)
class MockSharedPreferences {
  final Map<String, dynamic> _data = {};

  Future<bool> setString(String key, String value) async {
    _data[key] = value;
    return true;
  }

  Future<bool> setInt(String key, int value) async {
    _data[key] = value;
    return true;
  }

  Future<bool> setBool(String key, bool value) async {
    _data[key] = value;
    return true;
  }

  String? getString(String key) => _data[key] as String?;
  int? getInt(String key) => _data[key] as int?;
  bool? getBool(String key) => _data[key] as bool?;

  Future<bool> remove(String key) async {
    _data.remove(key);
    return true;
  }

  Future<bool> clear() async {
    _data.clear();
    return true;
  }
}

void main() {
  group('UI State Management — Testes Unit', () {
    late UIStateService uiStateService;
    late MockSharedPreferences prefs;

    setUp(() {
      uiStateService = UIStateService();
      prefs = MockSharedPreferences();
    });

    tearDown(() {
      uiStateService.reset();
      prefs.clear();
    });

    /// ===== TESTE 1: Notificar Listeners =====
    test(
      'deve notificar listeners quando estado muda',
      () async {
        // ARRANGE
        final listener = MockStateListener();
        uiStateService.addListener(listener.onStateChanged);

        // ACT
        uiStateService.updateState('user_nome', 'João Silva');
        uiStateService.updateState('user_email', 'joao@example.com');

        // ASSERT
        expect(listener.notificationCount, 2);
        expect(listener.eventos, contains('estado_atualizado: user_nome'));
        expect(listener.eventos, contains('estado_atualizado: user_email'));
      },
    );

    /// ===== TESTE 2: Resetar Estado =====
    test(
      'deve resetar estado corretamente',
      () async {
        // ARRANGE
        final listener = MockStateListener();
        uiStateService.addListener(listener.onStateChanged);
        uiStateService.updateState('key1', 'value1');
        uiStateService.updateState('key2', 'value2');

        // ACT
        uiStateService.reset();

        // ASSERT
        expect(uiStateService.getFullState(), isEmpty);
        expect(listener.eventos.last, 'estado_resetado');
      },
    );

    /// ===== TESTE 3: Persistir em SharedPreferences =====
    test(
      'deve persistir estado em SharedPreferences',
      () async {
        // ARRANGE
        const chaveUsuario = 'user_data';
        const chaveTheme = 'app_theme';

        // ACT
        await prefs.setString(chaveUsuario, '{"id": "123", "nome": "João"}');
        await prefs.setBool(chaveTheme, true);

        // ASSERT
        expect(prefs.getString(chaveUsuario), '{"id": "123", "nome": "João"}');
        expect(prefs.getBool(chaveTheme), true);
      },
    );

    /// ===== TESTE 4: Remover Listener =====
    test(
      'deve remover listener corretamente',
      () async {
        // ARRANGE
        final listener1 = MockStateListener();
        final listener2 = MockStateListener();
        uiStateService.addListener(listener1.onStateChanged);
        uiStateService.addListener(listener2.onStateChanged);

        // ACT
        uiStateService.removeListener(listener1.onStateChanged);
        uiStateService.updateState('key', 'value');

        // ASSERT
        expect(listener1.notificationCount, 0);
        expect(listener2.notificationCount, 1);
      },
    );

    /// ===== TESTE 5: Múltiplos Listeners =====
    test(
      'deve notificar múltiplos listeners simultaneamente',
      () async {
        // ARRANGE
        final listener1 = MockStateListener();
        final listener2 = MockStateListener();
        final listener3 = MockStateListener();
        uiStateService.addListener(listener1.onStateChanged);
        uiStateService.addListener(listener2.onStateChanged);
        uiStateService.addListener(listener3.onStateChanged);

        // ACT
        uiStateService.updateState('sync_key', 'sync_value');

        // ASSERT
        expect(listener1.notificationCount, 1);
        expect(listener2.notificationCount, 1);
        expect(listener3.notificationCount, 1);
      },
    );

    /// ===== TESTE 6: Estado Complexo =====
    test(
      'deve armazenar e recuperar estado complexo',
      () async {
        // ARRANGE
        final estadoComplexo = {
          'id': '123',
          'nome': 'João Silva',
          'email': 'joao@example.com',
          'ativo': true,
          'saldo': 1500.75,
        };

        // ACT
        for (final entry in estadoComplexo.entries) {
          uiStateService.updateState(entry.key, entry.value);
        }

        // ASSERT
        expect(uiStateService.getState('id'), '123');
        expect(uiStateService.getState('nome'), 'João Silva');
        expect(uiStateService.getState('email'), 'joao@example.com');
        expect(uiStateService.getState('ativo'), true);
        expect(uiStateService.getState('saldo'), 1500.75);
      },
    );

    /// ===== TESTE 7: Persistência e Recuperação =====
    test(
      'deve persistir e recuperar dados de SharedPreferences',
      () async {
        // ARRANGE
        const chave = 'usuario_token';
        const valor = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9';

        // ACT
        await prefs.setString(chave, valor);
        final recuperado = prefs.getString(chave);

        // ASSERT
        expect(recuperado, valor);
      },
    );

    /// ===== TESTE 8: Limpeza de Dados =====
    test(
      'deve limpar todos dados de SharedPreferences',
      () async {
        // ARRANGE
        await prefs.setString('key1', 'value1');
        await prefs.setString('key2', 'value2');
        await prefs.setBool('key3', true);

        // ACT
        await prefs.clear();

        // ASSERT
        expect(prefs.getString('key1'), isNull);
        expect(prefs.getString('key2'), isNull);
        expect(prefs.getBool('key3'), isNull);
      },
    );

    /// ===== TESTE 9: Remover Chave Individual =====
    test(
      'deve remover chave individual do SharedPreferences',
      () async {
        // ARRANGE
        await prefs.setString('user_id', '123');
        await prefs.setString('user_name', 'João');

        // ACT
        await prefs.remove('user_id');

        // ASSERT
        expect(prefs.getString('user_id'), isNull);
        expect(prefs.getString('user_name'), 'João');
      },
    );

    /// ===== TESTE 10: Notificação Sequencial =====
    test(
      'deve manter ordem de notificações em sequência',
      () async {
        // ARRANGE
        final listener = MockStateListener();
        uiStateService.addListener(listener.onStateChanged);
        final sequencia = ['primeiro', 'segundo', 'terceiro', 'quarto'];

        // ACT
        for (final evento in sequencia) {
          uiStateService.updateState('evento', evento);
        }

        // ASSERT
        expect(listener.notificationCount, 4);
        expect(listener.eventos.length, 4);
        for (int i = 0; i < sequencia.length; i++) {
          expect(
            listener.eventos[i],
            'estado_atualizado: evento',
          );
        }
      },
    );
  });
}
