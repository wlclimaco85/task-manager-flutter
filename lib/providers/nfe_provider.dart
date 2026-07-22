import 'package:provider/provider.dart';
import 'package:task_manager_flutter/models/nfe_state.dart';
import 'package:task_manager_flutter/providers/nfe_notifier.dart';
import 'package:task_manager_flutter/repositories/nfe_repository.dart';

/// Provider que disponibiliza o NfeNotifier para a árvore de widgets
///
/// Uso:
/// ```dart
/// ChangeNotifierProvider<NfeNotifier>(
///   create: (_) => NfeNotifier(NfeRepository()),
///   child: MyApp(),
/// )
/// ```
///
/// Ou no widget:
/// ```dart
/// final notifier = Provider.of<NfeNotifier>(context);
/// notifier.listarNfe();
/// ```
final nfeRepositoryProvider = Provider((_) => NfeRepository());

final nfeNotifierProvider = ChangeNotifierProvider<NfeNotifier>((_) {
  return NfeNotifier(NfeRepository());
});

/// Stream selector para o estado de NFes
/// Usado com Consumer/Selector para otimizar rebuilds
final nfeStateProvider = Provider<NfeState>((_) {
  throw UnimplementedError('Use nfeNotifierProvider.watch() instead');
});

/// Selector para verificar se está carregando
final nfeLoadingProvider = Provider<bool>((_) {
  throw UnimplementedError('Use nfeNotifierProvider.watch() instead');
});

/// Selector para verificar se há erro
final nfeErrorProvider = Provider<String?>((_) {
  throw UnimplementedError('Use nfeNotifierProvider.watch() instead');
});

/// Selector para lista de NFes
final nfeListProvider = Provider<List>((_) {
  throw UnimplementedError('Use nfeNotifierProvider.watch() instead');
});

/// Selector para NFe selecionada
final nfeSelectedProvider = Provider((_) {
  throw UnimplementedError('Use nfeNotifierProvider.watch() instead');
});
