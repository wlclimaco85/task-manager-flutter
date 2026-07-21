import 'package:provider/provider.dart';
import 'package:task_manager_flutter/models/nfe_state.dart';
import 'package:task_manager_flutter/providers/nfe_notifier.dart';
import 'package:task_manager_flutter/repositories/nfe_repository.dart';

/// Provider que disponibiliza o NfeNotifier para a árvore de widgets
///
/// Uso:
/// ```dart
/// ChangeNotifierProvider<NfeNotifier>(
///   create: (_) => nfeProvider,
///   child: MyApp(),
/// )
/// ```
///
/// Ou no widget:
/// ```dart
/// final notifier = Provider.of<NfeNotifier>(context);
/// notifier.listarNfe();
/// ```
final nfeRepositoryProvider = Provider((ref) => NfeRepository());

final nfeNotifierProvider = ChangeNotifierProvider<NfeNotifier>((ref) {
  return NfeNotifier(NfeRepository());
});

/// Stream selector para o estado de NFes
/// Usado com Consumer/Selector para otimizar rebuilds
final nfeStateProvider = Provider<NfeState>((ref) {
  final notifier = ref.watch(nfeNotifierProvider);
  return notifier.state;
});

/// Selector para verificar se está carregando
final nfeLoadingProvider = Provider<bool>((ref) {
  final state = ref.watch(nfeStateProvider);
  return state.isLoading;
});

/// Selector para verificar se há erro
final nfeErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(nfeStateProvider);
  return state.errorMessage;
});

/// Selector para lista de NFes
final nfeListProvider = Provider<List>((ref) {
  final state = ref.watch(nfeStateProvider);
  return state.nfes;
});

/// Selector para NFe selecionada
final nfeSelectedProvider = Provider((ref) {
  final state = ref.watch(nfeStateProvider);
  return state.selected;
});
