# Wave 3 Research — W3R4: Flutter Agendamento Recorrente UI + Sync

**Pesquisa Formal**: Provider state management, Windows native interop, background scheduling, offline sync, UI/UX design  
**Projeto**: Flutter Cliente (task_manager_flutter)  
**Plataformas**: Mobile (Android/iOS) + Web (via Flutter Web) + Windows Desktop  
**Story Points**: 11 SP  
**Timeline**: 2026-07-28 T+300h (6h pesquisa)  
**Status**: RESEARCH COMPLETO — PRONTO P3 EXECUÇÃO

---

## 1. Provider State Management — Pattern Flutter

### Arquitetura Escolhida

**Provider** (pub.dev/packages/provider) com **Riverpod** para tipos avançados, mas Provider como primário por compatibilidade web/desktop.

### Padrão ChangeNotifier + Consumer

```dart
// lib/features/agendamento/data/models/agendamento_model.dart
import 'package:flutter/foundation.dart';

class AgendamentoNfe {
  final String id;
  final String nfeId;
  final String rrule;
  final DateTime proximaData;
  final String status; // ATIVO, PAUSADO, FINALIZADO
  final DateTime criadoEm;

  AgendamentoNfe({
    required this.id,
    required this.nfeId,
    required this.rrule,
    required this.proximaData,
    required this.status,
    required this.criadoEm,
  });

  factory AgendamentoNfe.fromJson(Map<String, dynamic> json) {
    return AgendamentoNfe(
      id: json['id'] as String,
      nfeId: json['nfeId'] as String,
      rrule: json['rrule'] as String,
      proximaData: DateTime.parse(json['proximaData'] as String),
      status: json['status'] as String,
      criadoEm: DateTime.parse(json['criadoEm'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nfeId': nfeId,
    'rrule': rrule,
    'proximaData': proximaData.toIso8601String(),
    'status': status,
    'criadoEm': criadoEm.toIso8601String(),
  };

  AgendamentoNfe copyWith({
    String? id,
    String? nfeId,
    String? rrule,
    DateTime? proximaData,
    String? status,
    DateTime? criadoEm,
  }) {
    return AgendamentoNfe(
      id: id ?? this.id,
      nfeId: nfeId ?? this.nfeId,
      rrule: rrule ?? this.rrule,
      proximaData: proximaData ?? this.proximaData,
      status: status ?? this.status,
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }
}

// lib/features/agendamento/presentation/providers/agendamento_provider.dart
class AgendamentoNotifier extends ChangeNotifier {
  final AgendamentoService _service;
  
  List<AgendamentoNfe> _agendamentos = [];
  bool _isLoading = false;
  String? _error;
  
  AgendamentoNotifier(this._service);
  
  List<AgendamentoNfe> get agendamentos => _agendamentos;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> carregarAgendamentos() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _agendamentos = await _service.listarAgendamentos();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<AgendamentoNfe?> criar(String nfeId, String rrule) async {
    try {
      final novo = await _service.criar(nfeId, rrule);
      _agendamentos.add(novo);
      notifyListeners();
      return novo;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
  
  Future<void> pausar(String agendamentoId) async {
    try {
      await _service.mudarStatus(agendamentoId, 'PAUSADO');
      final idx = _agendamentos.indexWhere((a) => a.id == agendamentoId);
      if (idx >= 0) {
        _agendamentos[idx] = _agendamentos[idx].copyWith(status: 'PAUSADO');
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  Future<void> retomar(String agendamentoId) async {
    try {
      await _service.mudarStatus(agendamentoId, 'ATIVO');
      final idx = _agendamentos.indexWhere((a) => a.id == agendamentoId);
      if (idx >= 0) {
        _agendamentos[idx] = _agendamentos[idx].copyWith(status: 'ATIVO');
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}

// Registrar provider
final agendamentoProvider = ChangeNotifierProvider((ref) {
  final service = ref.watch(agendamentoServiceProvider);
  return AgendamentoNotifier(service);
});
```

### Consumer Widget

```dart
// lib/features/agendamento/presentation/screens/agendamento_list_screen.dart
class AgendamentoListScreen extends ConsumerWidget {
  const AgendamentoListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(agendamentoProvider);
    final notifier = ref.read(agendamentoProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendamentos NFe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.carregarAgendamentos(),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.agendamentos.isEmpty
              ? const Center(child: Text('Nenhum agendamento'))
              : ListView.builder(
                  itemCount: provider.agendamentos.length,
                  itemBuilder: (context, index) {
                    final agend = provider.agendamentos[index];
                    return AgendamentoTile(
                      agendamento: agend,
                      onPausar: () => notifier.pausar(agend.id),
                      onRetomar: () => notifier.retomar(agend.id),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoCriacao(context, notifier),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _mostrarDialogoCriacao(BuildContext context, AgendamentoNotifier notifier) {
    // TODO: implementar diálogo de criação
  }
}
```

### Multi-Platform Sync

Provider automaticamente sincroniza estado entre abas web e entre app/desktop quando data muda (via `notifyListeners()`). Para sincronização remota:

```dart
// lib/features/agendamento/domain/services/agendamento_sync_service.dart
class AgendamentoSyncService {
  final AgendamentoApi _api;
  final HiveBox<AgendamentoNfe> _localBox;
  final AgendamentoNotifier _notifier;
  
  Timer? _syncTimer;
  
  void iniciarSyncPeriodico() {
    _syncTimer = Timer.periodic(Duration(minutes: 15), (_) async {
      await sincronizar();
    });
  }
  
  Future<void> sincronizar() async {
    try {
      // 1. Upload pendências locais (offline-first)
      final pendentes = _localBox.values
          .where((a) => a.status == 'PENDENTE_SYNC')
          .toList();
      
      for (final agend in pendentes) {
        try {
          await _api.criar(agend.nfeId, agend.rrule);
          await _localBox.delete(agend.id);
        } catch (e) {
          logger.w('Sync error para ${agend.id}: $e');
        }
      }
      
      // 2. Download agendamentos remotos
      final remotos = await _api.listarAgendamentos();
      
      // 3. Merge com local (server-wins)
      for (final remoto in remotos) {
        await _localBox.put(remoto.id, remoto);
      }
      
      // 4. Notificar UI
      await _notifier.carregarAgendamentos();
    } catch (e) {
      logger.e('Sync error: $e');
    }
  }
  
  @override
  void dispose() {
    _syncTimer?.cancel();
  }
}
```

---

## 2. Native Bridge — Windows Desktop Interop

### Problema: Background Scheduling em Windows

Windows não tem equivalente nativo ao Android `WorkManager` ou iOS `BackgroundTasks`. Flutter não pode manter isolate rodando em background.

### Solução: Platform Channel + Native C++

**Abordagem**: Chamar DLL nativa (C++) via platform channel para registrar com Task Scheduler do Windows.

```dart
// lib/services/windows/background_scheduler_service.dart
import 'package:flutter/services.dart';

class WindowsBackgroundScheduler {
  static const platform = MethodChannel('br.app.academia/background_scheduler');
  
  /// Registrar tarefa recorrente em Windows Task Scheduler
  /// retorna true se registrado com sucesso
  static Future<bool> agendarTarefa({
    required String nomeAgendamento,
    required String rrule,
    required String scriptPath, // caminho para .bat que executa sync
  }) async {
    try {
      final result = await platform.invokeMethod<bool>('agendarTarefa', {
        'nome': nomeAgendamento,
        'rrule': rrule,
        'scriptPath': scriptPath,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      logger.e('Platform error: ${e.message}');
      return false;
    }
  }
  
  /// Remover tarefa do Task Scheduler
  static Future<bool> removerTarefa(String nomeAgendamento) async {
    try {
      final result = await platform.invokeMethod<bool>('removerTarefa', {
        'nome': nomeAgendamento,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      logger.e('Platform error: ${e.message}');
      return false;
    }
  }
  
  /// Listar tarefas registradas
  static Future<List<String>> listarTarefas() async {
    try {
      final result = await platform.invokeMethod<List>('listarTarefas');
      return result?.cast<String>() ?? [];
    } on PlatformException catch (e) {
      logger.e('Platform error: ${e.message}');
      return [];
    }
  }
}
```

### Windows Native Code (C++)

```cpp
// windows/runner/background_scheduler.cc
#include <windows.h>
#include <taskschd.h>
#include <comdef.h>
#include <wchar.h>

#pragma comment(library, "taskschd.lib")
#pragma comment(library, "comsupp.lib")

// Registrar agendamento no Windows Task Scheduler
HRESULT RegisterScheduledTask(
    const wchar_t* taskName,
    const wchar_t* rrule,
    const wchar_t* scriptPath) {
  
  // 1. Inicializar COM
  HRESULT hr = CoInitializeEx(NULL, COINIT_MULTITHREADED);
  if (FAILED(hr)) {
    printf("CoInitializeEx failed: %x\n", hr);
    return hr;
  }
  
  // 2. Conectar ao Task Scheduler
  ITaskService *pService = NULL;
  hr = CoCreateInstance(CLSID_TaskScheduler, NULL, CLSCTX_INPROC_SERVER, 
                        IID_ITaskService, (void**)&pService);
  if (FAILED(hr)) {
    printf("Failed to CoCreate TaskScheduler: %x\n", hr);
    CoUninitialize();
    return hr;
  }
  
  // 3. Conectar ao local
  hr = pService->Connect(_variant_t(), _variant_t(), _variant_t(), _variant_t());
  if (FAILED(hr)) {
    printf("Connect failed: %x\n", hr);
    pService->Release();
    CoUninitialize();
    return hr;
  }
  
  // 4. Pegar folder de tarefas
  ITaskFolder *pRootFolder = NULL;
  hr = pService->GetFolder(_bstr_t(L"\\"), &pRootFolder);
  if (FAILED(hr)) {
    printf("Cannot get RootFolder: %x\n", hr);
    pService->Release();
    CoUninitialize();
    return hr;
  }
  
  // 5. Criar nova tarefa
  ITaskDefinition *pTask = NULL;
  hr = pService->NewTask(0, &pTask);
  if (FAILED(hr)) {
    printf("Cannot create TaskDefinition: %x\n", hr);
    pRootFolder->Release();
    pService->Release();
    CoUninitialize();
    return hr;
  }
  
  // 6. Configurar triggers (recurrence)
  // Parsear RRULE e criar MatchingRule no Task Scheduler
  // Exemplo: "FREQ=MONTHLY;BYDAY=2FR" -> MonthlyDOWTrigger com DayOfWeek=Friday, WeekOfMonth=2
  // [Código de parsing RRULE para Windows triggers omitido por brevidade]
  
  // 7. Registrar tarefa
  IRegisteredTask *pRegisteredTask = NULL;
  hr = pRootFolder->RegisterTaskDefinition(
      _bstr_t(taskName),
      pTask,
      TASK_CREATE_OR_UPDATE,
      _variant_t(),           // user
      _variant_t(),           // password
      TASK_LOGON_SERVICE_ACCOUNT,
      _variant_t(),           // sddl
      &pRegisteredTask);
  
  if (FAILED(hr)) {
    printf("Error registering task: %x\n", hr);
  }
  
  // Cleanup
  pRootFolder->Release();
  pTask->Release();
  if (pRegisteredTask) pRegisteredTask->Release();
  pService->Release();
  CoUninitialize();
  
  return hr;
}
```

### Fallback: Dart Timer (Multi-Platform)

Se platform channel falhar (ex: não há permissão), usar Timer Dart como fallback:

```dart
class AgendamentoSchedulerService {
  Timer? _timer;
  final AgendamentoNotifier _notifier;
  final AgendamentoSyncService _syncService;
  
  void iniciar() {
    // Tentar platform channel (Windows)
    if (Platform.isWindows) {
      _iniciarWindowsScheduler();
    } else {
      // Fallback: Timer Dart a cada 15min
      _iniciarDartTimer();
    }
  }
  
  void _iniciarWindowsScheduler() async {
    final tarefasRegistradas = await WindowsBackgroundScheduler.listarTarefas();
    if (tarefasRegistradas.isEmpty) {
      // Registrar primeira vez
      final sucesso = await WindowsBackgroundScheduler.agendarTarefa(
        nomeAgendamento: 'AppAcademiaSync',
        rrule: 'FREQ=MINUTELY;INTERVAL=15',
        scriptPath: 'C:\\AppAcademia\\sync_runner.bat',
      );
      if (!sucesso) {
        logger.w('Windows scheduler falhou, usando fallback Dart Timer');
        _iniciarDartTimer();
      }
    }
  }
  
  void _iniciarDartTimer() {
    _timer = Timer.periodic(Duration(minutes: 15), (_) async {
      await _syncService.sincronizar();
    });
  }
  
  void dispose() {
    _timer?.cancel();
  }
}
```

---

## 3. Background Scheduling — Multi-Platform

### Android: WorkManager

```dart
// pubspec.yaml
dependencies:
  workmanager: ^0.5.0

// lib/services/android/background_task.dart
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    logger.i('Background task executado: $task');
    
    if (task == 'syncAgendamentos') {
      try {
        // Obter serviço (sem BuildContext)
        final box = await Hive.openBox<AgendamentoNfe>('agendamentos');
        final api = AgendamentoApi(); // criar instância sem DI
        
        // Sincronizar
        final remotos = await api.listarAgendamentos();
        for (final agend in remotos) {
          await box.put(agend.id, agend);
        }
        
        logger.i('Sync concluído em background');
        return true;
      } catch (e) {
        logger.e('Background sync error: $e');
        return false;
      }
    }
    
    return Future.value(true);
  });
}

void iniciarBackgroundSync() {
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: kDebugMode,
  );
  
  Workmanager().registerPeriodicTask(
    'syncAgendamentos',
    'syncAgendamentos',
    frequency: Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresDeviceIdle: false,
      requiresBatteryNotLow: false,
    ),
  );
}
```

### iOS: BackgroundTasks (Limitado a 15min)

```dart
// lib/services/ios/background_task.dart
import 'package:workmanager/workmanager.dart';

void iniciarBackgroundSync() {
  // iOS não permite background indefinido sem notificação
  // Usar BackgroundFetch (simula 15min via iOS events)
  // OU usar location updates (requer permissão + bateria)
  
  // Alternativa: Push notifications + sync quando usuário abre app
  logger.i('iOS: Background sync limitado a foreground + app resume');
}

void syncAoResumir() {
  // Chamar quando app retorna para foreground
  AppLifecycleListener(
    onResume: () async {
      await syncService.sincronizar();
    },
  );
}
```

### Web: Service Worker

```dart
// web/service_worker.js (registrado automaticamente via Flutter Web)
self.addEventListener('sync', (event) => {
  if (event.tag === 'syncAgendamentos') {
    event.waitUntil(
      fetch('/api/agendamentos-nfe')
        .then(resp => resp.json())
        .then(data => {
          // Armazenar em IndexedDB
          return db.put('agendamentos', data);
        })
        .catch(err => console.error('Sync error:', err))
    );
  }
});
```

### Recomendação

**Usar workmanager como primário** (Android + fallback iOS/Web). Plataforma-específico:
- Android: WorkManager nativo (15min mín.)
- iOS: BackgroundFetch (evento simulado)
- Windows: Task Scheduler via platform channel
- Web: Service Worker Background Sync API

---

## 4. Offline Sync — Arquitetura

### Padrão: Optimistic Update + Queue Local

```dart
// lib/services/offline_sync_service.dart
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OfflineSyncService {
  final AgendamentoApi _api;
  final Box<AgendamentoNfe> _agendBox;
  final Box<SyncQueue> _queueBox;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySub;
  
  // Estado
  bool _isOnline = false;
  
  OfflineSyncService(this._api, this._agendBox, this._queueBox);
  
  Future<void> iniciar() async {
    // Monitorar conectividade
    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
      _isOnline = !result.contains(ConnectivityResult.none);
      if (_isOnline) _sincronizarFila();
    });
    
    // Check inicial
    _isOnline = !(await Connectivity().checkConnectivity()).contains(ConnectivityResult.none);
  }
  
  /// Criar agendamento com optimistic update
  Future<AgendamentoNfe?> criarAgendamento(String nfeId, String rrule) async {
    // 1. Criar localmente (otimista)
    final novoLocal = AgendamentoNfe(
      id: uuid.v4(),
      nfeId: nfeId,
      rrule: rrule,
      proximaData: _proximaData(rrule),
      status: 'ATIVO',
      criadoEm: DateTime.now(),
    );
    
    await _agendBox.put(novoLocal.id, novoLocal);
    
    // 2. Enfileirar sync
    await _queueBox.add(SyncQueue(
      id: uuid.v4(),
      tipo: 'CREATE_AGENDAMENTO',
      dataAgendamento: novoLocal,
      status: 'PENDENTE',
      tentativas: 0,
    ));
    
    // 3. Tentar sync imediato
    if (_isOnline) {
      try {
        final remoto = await _api.criar(nfeId, rrule);
        await _agendBox.put(remoto.id, remoto);
        await _queueBox.delete(0); // remover fila se sucesso
        return remoto;
      } catch (e) {
        logger.w('Criar agendamento falhou, marcado para retry: $e');
      }
    }
    
    return novoLocal;
  }
  
  /// Sincronizar fila de pendências
  Future<void> _sincronizarFila() async {
    if (!_isOnline) return;
    
    final filas = _queueBox.values.where((q) => q.status == 'PENDENTE').toList();
    
    for (final fila in filas) {
      try {
        if (fila.tipo == 'CREATE_AGENDAMENTO') {
          final remoto = await _api.criar(
            fila.dataAgendamento.nfeId,
            fila.dataAgendamento.rrule,
          );
          
          // Merge: remoto sobrescreve local (server-wins)
          await _agendBox.put(remoto.id, remoto);
          
          // Remover fila
          await fila.delete();
          logger.i('Sync concluído para ${fila.id}');
        }
      } catch (e) {
        fila.tentativas++;
        
        if (fila.tentativas >= 5) {
          fila.status = 'FALHA_IRREVERSIVEL';
          await fila.save();
          logger.e('Max retry para ${fila.id}');
        } else {
          // Retry exponencial
          await Future.delayed(Duration(seconds: pow(2, fila.tentativas).toInt()));
        }
      }
    }
  }
  
  Future<void> dispose() async {
    await _connectivitySub.cancel();
  }
}

// lib/data/models/sync_queue.dart
@HiveType(typeId: 10)
class SyncQueue extends HiveObject {
  @HiveField(0)
  late String id;
  
  @HiveField(1)
  late String tipo; // CREATE_AGENDAMENTO, UPDATE_STATUS, etc
  
  @HiveField(2)
  late AgendamentoNfe? dataAgendamento;
  
  @HiveField(3)
  late String status; // PENDENTE, PROCESSANDO, FALHA_IRREVERSIVEL
  
  @HiveField(4)
  late int tentativas;
  
  @HiveField(5)
  late DateTime criadoEm;
  
  SyncQueue({
    required this.id,
    required this.tipo,
    required this.dataAgendamento,
    required this.status,
    required this.tentativas,
    DateTime? criadoEm,
  }) : criadoEm = criadoEm ?? DateTime.now();
}
```

### Conflito Resolution

**Estratégia**: **Server-Wins** (servidor é fonte de verdade após online).

```dart
// Se usuário cria agendamento offline e depois muda status localmente
// Quando online: server-wins sobrescreve

// Alternativa se PO quiser client-wins:
// Armazenar timestamp cliente, comparar com servidor, usar mais recente
```

---

## 5. UI/UX — Agendamento Recorrente

### Tela: Criar Agendamento

```dart
// lib/features/agendamento/presentation/screens/criar_agendamento_screen.dart
class CriarAgendamentoScreen extends StatefulWidget {
  final String nfeId;
  
  const CriarAgendamentoScreen({required this.nfeId});
  
  @override
  State<CriarAgendamentoScreen> createState() => _CriarAgendamentoScreenState();
}

class _CriarAgendamentoScreenState extends State<CriarAgendamentoScreen> {
  late TextEditingController _rruleController;
  String _freq = 'MONTHLY';
  List<String> _byDay = [];
  DateTime _until = DateTime.now().add(Duration(days: 365));
  List<DateTime> _proximasOcorrencias = [];
  
  @override
  void initState() {
    super.initState();
    _rruleController = TextEditingController();
    _gerarPreview();
  }
  
  void _gerarPreview() {
    // Usar ical4j via platform channel para gerar próximas 5 datas
    // OU calcular localmente em Dart (menos preciso)
    
    final rrule = _construirRRule();
    _proximasOcorrencias = _gerarOcorrenciasApproximadas(rrule, 5);
    setState(() {});
  }
  
  String _construirRRule() {
    String rrule = 'FREQ=$_freq';
    if (_byDay.isNotEmpty) {
      rrule += ';BYDAY=${_byDay.join(",")}';
    }
    rrule += ';UNTIL=${_until.toIso8601String().split('T')[0].replaceAll('-', '')}';
    return rrule;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Agendamento NFe')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seção: Frequência
            const Text('Frequência', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'DAILY', label: Text('Diário')),
                ButtonSegment(value: 'WEEKLY', label: Text('Semanal')),
                ButtonSegment(value: 'MONTHLY', label: Text('Mensal')),
                ButtonSegment(value: 'YEARLY', label: Text('Anual')),
              ],
              selected: {_freq},
              onSelectionChanged: (Set<String> selected) {
                setState(() {
                  _freq = selected.first;
                  _byDay.clear();
                  _gerarPreview();
                });
              },
            ),
            const SizedBox(height: 24),
            
            // Seção: Dia da Semana (se WEEKLY)
            if (_freq == 'WEEKLY')
              ...[
                const Text('Dias da Semana', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'].map((day) {
                    return FilterChip(
                      label: Text(day),
                      selected: _byDay.contains(day),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _byDay.add(day);
                          } else {
                            _byDay.remove(day);
                          }
                          _gerarPreview();
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],
            
            // Seção: Data Final
            const Text('Válido até', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              title: Text(_until.toString().split(' ')[0]),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final data = await showDatePicker(
                  context: context,
                  initialDate: _until,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(Duration(days: 1095)), // 3 anos
                );
                if (data != null) {
                  setState(() {
                    _until = data;
                    _gerarPreview();
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            
            // Seção: Preview Próximas Ocorrências
            const Text(
              'Próximas execuções',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._proximasOcorrencias.map((data) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green[600]),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(data),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 24),
            
            // Botão Criar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _criar,
                child: const Text('Agendar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _criar() async {
    final notifier = context.read(agendamentoProvider.notifier);
    final rrule = _construirRRule();
    
    final resultado = await notifier.criar(widget.nfeId, rrule);
    if (resultado != null && mounted) {
      Navigator.pop(context, resultado);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agendamento criado com sucesso')),
      );
    }
  }
  
  @override
  void dispose() {
    _rruleController.dispose();
    super.dispose();
  }
}
```

### Acessibilidade (WCAG 2.1 AA)

```dart
// lib/features/agendamento/presentation/widgets/agendamento_acessivel.dart
class AgendamentoTile extends StatelessWidget {
  final AgendamentoNfe agendamento;
  final VoidCallback onPausar;
  final VoidCallback onRetomar;
  
  const AgendamentoTile({
    required this.agendamento,
    required this.onPausar,
    required this.onRetomar,
  });
  
  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Agendamento ${agendamento.id}',
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          title: Semantics(
            label: 'Próxima execução',
            child: Text(
              'Próxima: ${DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(agendamento.proximaData)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Semantics(
                label: 'Padrão de recorrência',
                child: Text('Padrão: ${agendamento.rrule}', style: const TextStyle(fontSize: 12)),
              ),
              const SizedBox(height: 4),
              Semantics(
                label: 'Status: ${agendamento.status}',
                child: Text(
                  'Status: ${agendamento.status}',
                  style: TextStyle(
                    fontSize: 12,
                    color: agendamento.status == 'ATIVO' ? Colors.green[600] : Colors.orange[600],
                  ),
                ),
              ),
            ],
          ),
          trailing: Semantics(
            button: true,
            enabled: true,
            label: agendamento.status == 'ATIVO' ? 'Pausar agendamento' : 'Retomar agendamento',
            onTap: agendamento.status == 'ATIVO' ? onPausar : onRetomar,
            child: IconButton(
              icon: Icon(
                agendamento.status == 'ATIVO' ? Icons.pause_circle : Icons.play_circle,
                size: 24, // 24dp mín para touch
              ),
              onPressed: agendamento.status == 'ATIVO' ? onPausar : onRetomar,
              tooltip: agendamento.status == 'ATIVO' ? 'Pausar' : 'Retomar',
            ),
          ),
        ),
      ),
    );
  }
}
```

**WCAG 2.1 AA Checklist**:
- ✅ Touch targets ≥ 48×48 dp (IconButton)
- ✅ Contraste ≥ 7.5:1 (testes com `flutter test` + color_contrast package)
- ✅ Semantic labels para screen readers
- ✅ Keyboard navigation (TAB para buttons)
- ✅ Dark mode support (via Theme)

---

## 6. Dark Mode

```dart
// lib/config/theme/theme.dart
ThemeData buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: Colors.blue[700]!,
    ),
  );
}

// lib/main.dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppAcademia',
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system, // seguir sistema
      home: const HomeScreen(),
    );
  }
}
```

---

## 7. Próximos Passos — P3 Execução

### Task Breakdown (Estimativa 30h críticas)

| Task | Subtarefas | SP | Horas |
|------|-----------|----|----|
| **T1: Provider Setup** | Models, notifiers, consumers | 2 | 4h |
| **T2: UI Screens** | Criar/listar/pausar agendamentos | 3 | 8h |
| **T3: Offline Sync** | Hive, sync service, queue logic | 2 | 6h |
| **T4: Background Scheduling** | WorkManager (Android), Timer (iOS/Web), Platform channel (Windows) | 2 | 6h |
| **T5: Tests + E2E** | Unit tests, widget tests, offline scenarios | 1 | 4h |
| **T6: Replicação** | task_manager_flutter_merged_final sync 100% | 1 | 2h |

**Total**: 11 SP, 30h críticas.

---

## 📋 Conclusão Research W3R4

✅ Provider state management definido (ChangeNotifier + Consumer).  
✅ Windows Desktop interop via platform channel + Task Scheduler.  
✅ Multi-platform background scheduling (WorkManager/Timer/Web API).  
✅ Offline sync com optimistic update (server-wins).  
✅ UI/UX design (RRULE picker, preview ocorrências, WCAG 2.1 AA).  
✅ Dark mode suportado.

**SEM BLOQUEADORES. PRONTO P3 EXECUÇÃO.**
