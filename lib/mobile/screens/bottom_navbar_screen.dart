import 'dart:async';

import 'package:flutter/material.dart';

import 'package:task_manager_flutter/models/alert_model.dart';
import 'package:task_manager_flutter/models/auth_utility.dart';
import 'package:task_manager_flutter/services/alert_caller.dart';
import 'package:task_manager_flutter/utils/grid_colors.dart';
import 'package:task_manager_flutter/utils/security_matrix.dart';
import 'package:task_manager_flutter/utils/module_priority.dart';
import 'package:task_manager_flutter/widgets/contextual_home_screen.dart';

import '../../customization/dynamic_grid_dynamic_screen.dart';
import '../../customization/generic_grid/grid_models.dart'
    show CustomAction, FieldConfig, FieldType, FileConfig;
import '../../windows/screens/comunicado_detalhe_screen.dart';
import '../../windows/screens/fechar_chamado_dialog.dart';
import 'sem_acesso_screen.dart';
import '../../auth_screens/login_screen.dart';
import 'chatMessageListScreen.dart';
import 'dashboard_screen.dart';
import '../../features/trading/trading_dashboard_screen.dart';
import '../../features/trading/screens/backtest_screen.dart';
import '../../features/trading/services/backtest_repository.dart';
import '../../services/network_caller.dart';
import '../../utils/api_links.dart';
import '../../utils/app_logger.dart';
import '../../utils/tenant_context.dart';
import '../../web/screens/nfce/pdv_screen.dart';
import '../../web/screens/nfce/config_fiscal_screen.dart';
import 'documento_screen.dart';
import 'meu_perfil_screen.dart';
import 'ponto_screen.dart';
import '../../widgets/crm/crm_pipeline_screen.dart';
import '../../widgets/fiscal/fiscal_automation_screen.dart';
import 'mensalidade_screen.dart';
import 'conta_pagar_grid_screen.dart';
import 'conta_receber_grid_screen.dart';
import 'conta_bancaria_grid_screen.dart';
import 'parceiro_grid_screen.dart';
import 'login_grid_screen.dart';
import 'nfse_consulta_screen.dart';
import 'nfse_serie_screen.dart';
import 'extrato_importacao_screen.dart' show MobileExtratoImportacaoScreen;
import '../../web/screens/cobranca_automatica_screen.dart';
import '../../widgets/user_banners.dart';
import 'alvara_screen.dart';
import '../../widgets/dashboard_area/placeholder/dashboard_atendimento_placeholder_screen.dart';

class BottomNavBarScreen extends StatefulWidget {
  const BottomNavBarScreen({super.key});

  @override
  State<BottomNavBarScreen> createState() => _BottomNavBarScreenState();
}

class _BottomNavBarScreenState extends State<BottomNavBarScreen> {
  int selectedIndex = 0;

  List<Alert> _notifications = [];
  int _unreadCount = 0;
  Timer? _alertTimer;

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
    _alertTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) _fetchAlerts();
    });
  }

  @override
  void dispose() {
    _alertTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAlerts() async {
    try {
      final data = await AlertCaller().fetchNotificacoes(context);
      if (mounted) {
        setState(() {
          _notifications = data;
          _unreadCount = data.length;
        });
      }
    } catch (_) {}
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 8, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Notificacoes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: GridColors.textSecondary,
                      ),
                    ),
                  ),
                  if (_notifications.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _notifications.clear();
                          _unreadCount = 0;
                        });
                        setLocal(() {});
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.delete_sweep, size: 18),
                      label: const Text('Limpar tudo'),
                      style: TextButton.styleFrom(
                          foregroundColor: GridColors.error),
                    ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _notifications.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Sem notificacoes',
                        style: TextStyle(color: Colors.grey)),
                  )
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 16),
                      itemBuilder: (_, i) {
                        final n = _notifications[i];
                        final dt = DateTime.tryParse(n.data ?? '');
                        final fmt = dt != null
                            ? '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
                            : '';
                        return ListTile(
                          leading: const Icon(Icons.notifications_outlined,
                              color: GridColors.primary),
                          title: Text(n.texto,
                              style: const TextStyle(fontSize: 13)),
                          subtitle: fmt.isNotEmpty ? Text(fmt) : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.close,
                                size: 18, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                _notifications.removeWhere((x) => x.id == n.id);
                                _unreadCount = _notifications.length;
                              });
                              setLocal(() {});
                            },
                          ),
                        );
                      },
                    ),
                  ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildScreens(SecurityMatrix sec) {
    final items = <Widget>[];

    // 1. Início (sempre visível)
    items.add(ContextualHomeScreen(
      key: const ValueKey('inicio'),
      onNavigate: (rota) => _navigateFromInicio(rota, sec),
    ));

    // 2. Chat (gateado)
    items.add(
      sec.canView(AppScreen.chat)
          ? (AuthUtility.userInfo?.login?.email != null
              ? ChatListScreen(
                  key: const ValueKey('chat'),
                  userName: AuthUtility.userInfo?.login?.email ?? '',
                )
              : const ChatListScreen(
                  key: ValueKey('chat'), userName: 'Usuario'))
          : _buildGatedPlaceholder('Chat indisponível'),
    );

    // 3. Comunicados (gateado)
    items.add(
      sec.canView(AppScreen.comunicados)
          ? _comunicadoGridInline(sec: sec)
          : _buildGatedPlaceholder('Comunicados indisponível'),
    );

    // 4. Slot dinâmico do módulo de maior prioridade (gateado)
    final slot = _dynamicSlotInfo();
    if (slot != null) {
      items.add(_buildDynamicModuleScreen(slot.rota, sec));
    } else {
      items.add(_buildGatedPlaceholder('Nenhum módulo disponível'));
    }

    // 5. Mais (sempre presente — abre bottom sheet)
    items.add(Container(key: const ValueKey('mais')));

    return items;
  }

  /// Placeholder para slots sem permissão (evita IndexedStack quebrar).
  Widget _buildGatedPlaceholder(String msg) {
    return const SizedBox.shrink();
  }

  /// Constrói o widget do slot dinâmico baseado na rota do módulo.
  Widget _buildDynamicModuleScreen(String rota, SecurityMatrix sec) {
    switch (rota) {
      case 'pdv':
        return const PdvScreen(key: ValueKey('dynamic_pdv'));
      case 'nfse':
        return NfseConsultaScreen(
          key: const ValueKey('dynamic_nfse'),
          hasPermission: (action) =>
              _hasPermissionFor(sec, AppScreen.nfseLista, action),
        );
      case 'contas_pagar':
        return ContaPagarGridScreen(
          key: const ValueKey('dynamic_contas_pagar'),
          hasPermission: (action) =>
              _hasPermissionFor(sec, AppScreen.contasPagar, action),
        );
      case 'calendario':
        return const CalendarScreen(key: ValueKey('dynamic_calendario'));
      case 'ponto':
        return const PontoScreen(key: ValueKey('dynamic_ponto'));
      case 'pedidos_venda':
        return Container(key: const ValueKey('dynamic_pedidos_venda'));
      default:
        return _buildGatedPlaceholder('Módulo não disponível');
    }
  }

  /// Navega a partir dos atalhos da ContextualHomeScreen para a tela correta
  /// ou para o slot dinâmico na BottomNav.
  void _navigateFromInicio(String rota, SecurityMatrix sec) {
    // Se a rota for uma das telas dos slots fixos, muda o tab.
    final slotIndexMap = <String, int>{
      'chat': 1,
    };
    if (slotIndexMap.containsKey(rota)) {
      setState(() => selectedIndex = slotIndexMap[rota]!);
      return;
    }

    // Tenta encontrar o índice do slot dinâmico
    final slot = _dynamicSlotInfo();
    if (slot != null && slot.rota == rota) {
      // O slot dinâmico está na posição 3 (após Inicio=0, Chat=1, Comunicados=2)
      setState(() => selectedIndex = 3);
      return;
    }

    // Fallback: navegação push normal
    onMenuOptionSelected(_rotaParaLabel(rota), sec);
  }

  /// Mapa auxiliar: rota → label que o onMenuOptionSelected entende.
  String _rotaParaLabel(String rota) {
    return switch (rota) {
      'pdv' => 'PDV',
      'nfse' => 'Notas de Serviço (NFS-e)',
      'contas_pagar' => 'Contas Pagar',
      'calendario' => 'Calendario',
      'ponto' => 'Bater Ponto',
      'produtos' => 'Produtos',
      'parceiros' => 'Parceiros',
      'pedidos_venda' => 'Pedidos Venda',
      'dashboard' => 'Dashboard',
      'chat' => 'Chat',
      'comunicados' => 'Comunicados',
      'chamados' => 'Chamados',
      _ => rota,
    };
  }

  /// Retorna informações do slot dinâmico baseado no módulo de maior prioridade.
  _DynamicSlot? _dynamicSlotInfo() {
    final contratados = ModuloAccess.modulosContratados;
    final modulo = ModulePriority.highest(contratados);

    if (modulo == null) return null;
    final limitado =
        modulo == 'Financeiro' && SecurityMatrix.current().isFinanceiroLimitado;

    return switch (modulo) {
      'Comercial' => _DynamicSlot(Icons.point_of_sale, 'PDV', 'pdv'),
      'NFS-e' => _DynamicSlot(Icons.description, 'NFS-e', 'nfse'),
      'Financeiro' => limitado
          ? _DynamicSlot(Icons.payments, 'Contas Pagar', 'contas_pagar')
          : _DynamicSlot(Icons.calendar_month, 'Calendário', 'calendario'),
      'Departamento Pessoal' =>
        _DynamicSlot(Icons.access_time, 'Bater Ponto', 'ponto'),
      _ => _DynamicSlot(Icons.apps, modulo, modulo),
    };
  }

  /// Navega a partir do slot dinâmico da BottomNav.
  void _onDynamicSlotTap() {
    final slot = _dynamicSlotInfo();
    if (slot != null) {
      onMenuOptionSelected(slot.label, SecurityMatrix.current());
    }
  }

  Widget _gedDynamicGrid(SecurityMatrix sec) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_dynamic_inline_ged_arquivo'),
      telaNome: 'arquivo',
      hasPermission: (action) => _hasPermissionFor(sec, AppScreen.ged, action),
      storageKey: 'mobile_dynamic_ged_arquivo',
      fetchEndpointOverride: ApiLinks.allArquivos,
      createEndpointOverride: ApiLinks.uploadArquivo,
      updateEndpointOverride: ApiLinks.updateArquivo(':id'),
      deleteEndpointOverride: ApiLinks.deleteArquivo(':id'),
      fieldOverrides: _gedFieldOverrides(),
    );
  }

  List<FieldConfig> _gedFieldOverrides() {
    return [
      const FieldConfig(
        label: 'ID',
        fieldName: 'id',
        isInForm: false,
        showInCard: false,
        isVisibleByDefault: false,
      ),
      const FieldConfig(
        label: 'Arquivo',
        fieldName: 'file',
        fieldType: FieldType.file,
        isRequired: true,
        fileConfig: FileConfig(
          allowedExtensions: [
            'pdf',
            'doc',
            'docx',
            'jpg',
            'jpeg',
            'png',
            'xls',
            'xlsx',
            'csv',
            'txt',
          ],
          maxFileSize: 10 * 1024 * 1024,
          fileFieldName: 'file',
        ),
      ),
      FieldConfig(
        label: 'Diretorio',
        fieldName: 'diretorio',
        fieldType: FieldType.dropdown,
        dropdownFutureBuilder: () => _dropdownFromEndpoint(
          ApiLinks.allDiretorios,
          labelKeys: const ['nome', 'descricao', 'label'],
        ),
        dropdownValueField: 'value',
        dropdownDisplayField: 'label',
      ),
      FieldConfig(
        label: 'Parceiro',
        fieldName: 'parceiro',
        fieldType: FieldType.dropdown,
        dropdownFutureBuilder: () => _dropdownFromEndpoint(
          ApiLinks.allParceiros,
          labelKeys: const ['nome', 'razaoSocial', 'label'],
        ),
        dropdownValueField: 'value',
        dropdownDisplayField: 'label',
      ),
    ];
  }

  Future<List<Map<String, dynamic>>> _dropdownFromEndpoint(
    String endpoint, {
    required List<String> labelKeys,
  }) async {
    final response = await NetworkCaller().getRequest(endpoint);
    final raw = response.body?['data']?['dados'] ??
        response.body?['data'] ??
        response.body?['content'] ??
        response.body;
    if (!response.isSuccess || raw is! List) return [];

    return raw
        .whereType<Map>()
        .map((item) {
          final map = Map<String, dynamic>.from(item);
          final label = labelKeys.map((key) => map[key]?.toString()).firstWhere(
              (value) => value != null && value.isNotEmpty,
              orElse: () => map['id']?.toString() ?? '');
          return {
            'value': map['id']?.toString() ?? '',
            'label': label,
          };
        })
        .where((item) => item['value']!.isNotEmpty)
        .toList();
  }

  Widget _dynamicGridInline({
    required String telaNome,
    required SecurityMatrix sec,
    required AppScreen screen,
  }) {
    return DynamicGridDynamicScreen(
      key: ValueKey('mobile_dynamic_inline_$telaNome'),
      telaNome: telaNome,
      hasPermission: (action) => _hasPermissionFor(sec, screen, action),
      storageKey: 'mobile_dynamic_$telaNome',
      showAppBar: false,
    );
  }

  /// Tela de Comunicados mobile: apenas o botao "Visualizar comunicado" (customAction).
  /// hasPermission retorna false para tudo — bloqueia todos os botoes automaticos
  /// (server actions, detailScreenBuilder). Os customActions nao sao afetados.
  Widget _comunicadoGridInline({required SecurityMatrix sec}) {
    return Scaffold(
      appBar: const SimpleAppBar(title: 'Comunicados', icon: Icons.campaign),
      body: DynamicGridDynamicScreen(
        key: const ValueKey('mobile_dynamic_inline_comunicado'),
        telaNome: 'comunicado',
        hasPermission: (action) => false,
        storageKey: 'mobile_dynamic_comunicado',
        showAppBar: false,
        customActions: _comunicadoActionsBuilder,
      ),
    );
  }

  /// Tela de Chamados mobile: "Visualizar", "Fechar" e "Reabrir" — sem botoes automaticos.
  /// hasPermission retorna false para tudo exceto insert/create — bloqueia server actions
  /// e detailScreenBuilder. Os customActions nao sao afetados pelo hasPermission.
  Widget _chamadoGridInline({required SecurityMatrix sec}) {
    return Scaffold(
      appBar:
          const SimpleAppBar(title: 'Solicitacoes', icon: Icons.support_agent),
      body: DynamicGridDynamicScreen(
        key: const ValueKey('mobile_dynamic_inline_chamado'),
        telaNome: 'chamado',
        hasPermission: (action) {
          final lower = action.toLowerCase();
          // Permite criar chamados no mobile
          if (lower == 'insert' || lower == 'create') {
            return _hasPermissionFor(sec, AppScreen.chamados, action);
          }
          // Bloqueia todos os outros botoes automaticos — acoes via customActions
          return false;
        },
        storageKey: 'mobile_dynamic_chamado',
        showAppBar: false,
        customActions: () => [
          CustomAction(
            icon: Icons.open_in_new_outlined,
            label: 'Visualizar chamado',
            onPressed: (ctx, item) => _mostrarDetalheChamado(ctx, item),
            isVisible: (_) => true,
          ),
          CustomAction(
            icon: Icons.task_alt_outlined,
            label: 'Fechar chamado',
            onPressed: (ctx, item) {
              final id = item['id'];
              if (id == null) return;
              final chamadoId =
                  id is int ? id : int.tryParse(id.toString()) ?? 0;
              if (chamadoId == 0) return;
              showDialog(
                context: ctx,
                builder: (_) => FecharChamadoDialog(chamadoId: chamadoId),
              );
            },
            isVisible: (item) {
              final status = (item['status'] ?? '').toString().toLowerCase();
              return status != 'fechado' &&
                  status != 'cancelado' &&
                  status != '3' &&
                  status != '4';
            },
          ),
          CustomAction(
            icon: Icons.replay_outlined,
            label: 'Reabrir chamado',
            onPressed: (ctx, item) => _mostrarReabrirChamadoDialog(ctx, item),
            isVisible: (item) {
              final status = (item['status'] ?? '').toString().toLowerCase();
              return status == 'fechado' ||
                  status == 'cancelado' ||
                  status == '3' ||
                  status == '4';
            },
          ),
        ],
      ),
    );
  }

  /// Exibe um dialog para digitar o motivo e reabrir o chamado.
  void _mostrarReabrirChamadoDialog(
      BuildContext context, Map<String, dynamic> item) {
    final id = item['id'];
    if (id == null) return;
    final chamadoId = id is int ? id : int.tryParse(id.toString()) ?? 0;
    if (chamadoId == 0) return;
    final motivoCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reabrir chamado'),
        content: TextField(
          controller: motivoCtrl,
          decoration: const InputDecoration(
            labelText: 'Motivo da reabertura',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: GridColors.primary),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final url =
                    '${ApiLinks.baseUrl}/api/chamados/$chamadoId/reabrir';
                await TenantContext.post(url, {'motivo': motivoCtrl.text});
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: GridColors.success,
                      content: Text('Chamado reaberto com sucesso'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: GridColors.error,
                      content: Text('Erro ao reabrir chamado: $e'),
                    ),
                  );
                }
              }
            },
            child: const Text('Reabrir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _mostrarDetalheChamado(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        builder: (_, sc) => ListView(
          controller: sc,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: GridColors.divider,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Text(
              item['titulo']?.toString() ?? 'Chamado',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: GridColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            _detalheRow('Descricao', item['descricao']),
            _detalheRow('Status', item['status']),
            _detalheRow('Prioridade', item['prioridade']),
            _detalheRow('Setor', item['setor']?['nome'] ?? item['setor']),
            _detalheRow(
                'Abertura', item['dhCreatedAt'] ?? item['dataAbertura']),
            if ((item['motivoFechamento'] ?? '').toString().isNotEmpty)
              _detalheRow('Motivo fechamento', item['motivoFechamento']),
          ],
        ),
      ),
    );
  }

  Widget _detalheRow(String label, dynamic value) {
    final text = value?.toString() ?? '';
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: GridColors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  List<BottomNavigationBarItem> _buildNavItems(
    SecurityMatrix sec,
    int selected,
  ) {
    final items = <BottomNavigationBarItem>[];

    void addItem({
      required IconData icon,
      required String label,
    }) {
      final index = items.length;
      final active = index == selected;
      items.add(BottomNavigationBarItem(
        icon: _bottomNavIcon(icon, active: active),
        label: label,
      ));
    }

    // 4 slots fixos
    addItem(icon: Icons.home, label: "Início");
    addItem(icon: Icons.chat, label: "Chat");
    addItem(icon: Icons.campaign, label: "Comunicados");

    // Slot dinâmico do módulo de maior prioridade
    final slot = _dynamicSlotInfo();
    if (slot != null) {
      addItem(icon: slot.icon, label: slot.label);
    } else {
      addItem(icon: Icons.apps, label: "Módulo");
    }

    // Último item = Mais
    addItem(icon: Icons.apps_rounded, label: "Mais");

    return items;
  }

  Widget _bottomNavIcon(IconData icon, {required bool active}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: active ? 46 : 40,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border:
            active ? Border.all(color: GridColors.secondary, width: 1.2) : null,
      ),
      child: Icon(
        icon,
        size: active ? 21 : 20,
        color: active
            ? GridColors.secondary
            : Colors.white.withValues(alpha: 0.82),
      ),
    );
  }

  bool _hasPermissionFor(
    SecurityMatrix sec,
    AppScreen screen,
    String action,
  ) {
    return switch (action) {
      'insert' || 'create' => sec.canInsert(screen),
      'update' || 'edit' => sec.canUpdate(screen),
      'delete' || 'remove' => sec.canDelete(screen),
      'baixar' || 'baixa' => sec.canBaixar(screen),
      _ => sec.canView(screen),
    };
  }

  static List<CustomAction> _comunicadoActionsBuilder() {
    return [
      CustomAction(
        icon: Icons.visibility_outlined,
        label: 'Visualizar comunicado',
        onPressed: (BuildContext ctx, Map<String, dynamic> item) {
          Navigator.of(ctx).push(MaterialPageRoute(
            builder: (_) => WindowsComunicadoDetalheScreen(comunicado: item),
          ));
        },
        isVisible: (_) => true,
      ),
    ];
  }

  Future<void> _pushDynamicGrid({
    required String telaNome,
    required SecurityMatrix sec,
    AppScreen? screen,
    String? fetchEndpointOverride,
    String? createEndpointOverride,
    String? updateEndpointOverride,
    String? deleteEndpointOverride,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DynamicGridDynamicScreen(
          key: ValueKey('mobile_dynamic_push_$telaNome'),
          telaNome: telaNome,
          hasPermission: (action) =>
              screen == null ? true : _hasPermissionFor(sec, screen, action),
          storageKey: 'mobile_dynamic_$telaNome',
          fetchEndpointOverride: fetchEndpointOverride,
          createEndpointOverride: createEndpointOverride,
          updateEndpointOverride: updateEndpointOverride,
          deleteEndpointOverride: deleteEndpointOverride,
        ),
      ),
    );
  }

  void onMenuOptionSelected(String option, SecurityMatrix sec) {
    Navigator.pop(context); // fecha o bottom sheet do menu
    Future<void>? nav;

    switch (option) {
      case "Contas Pagar":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ContaPagarGridScreen(
              hasPermission: (action) =>
                  _hasPermissionFor(sec, AppScreen.contasPagar, action),
            ),
          ),
        );
        break;
      case "Contas Receber":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ContaReceberGridScreen(
              hasPermission: (action) =>
                  _hasPermissionFor(sec, AppScreen.contasReceber, action),
            ),
          ),
        );
        break;
      case "Régua de Cobrança":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const Scaffold(
              // Header principal padrao (logo, empresa, usuario, alertas e sair).
              // showFilterButton: false — a tela tem cabecalho proprio com
              // Atualizar/Nova etapa/Executar, nao usa a barra de grid.
              appBar: UserBannerAppBar(
                screenTitle: 'Régua de Cobrança',
                showFilterButton: false,
              ),
              body: SafeArea(child: CobrancaAutomaticaScreen()),
            ),
          ),
        );
        break;
      case "Parceiros":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ParceiroGridScreen(
              hasPermission: (action) =>
                  _hasPermissionFor(sec, AppScreen.parceiros, action),
            ),
          ),
        );
        break;
      case "Usuários":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LoginGridScreen(
              hasPermission: (action) =>
                  _hasPermissionFor(sec, AppScreen.logins, action),
            ),
          ),
        );
        break;
      case "Notas de Serviço (NFS-e)":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NfseConsultaScreen(
              hasPermission: (action) =>
                  _hasPermissionFor(sec, AppScreen.nfseLista, action),
            ),
          ),
        );
        break;
      case "Séries NFS-e":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NfseSerieScreen(
              hasPermission: (action) =>
                  _hasPermissionFor(sec, AppScreen.nfseSerie, action),
            ),
          ),
        );
        break;
      case "Produtos":
        nav = _pushDynamicGrid(
          telaNome: 'produto',
          sec: sec,
          screen: AppScreen.produto,
        );
        break;
      case "Dashboard":
        nav = Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DashboardPage()),
        );
        break;
      case "Atendimento":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const DashboardAtendimentoPlaceholderScreen()),
        );
        break;
      case "Trading":
        nav = Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TradingDashboardScreen()),
        );
        break;
      case "Backtesting":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BacktestScreen(
              repository: BacktestRepository(ApiLinks.baseUrl,
                  headers: TenantContext.jsonHeaders),
            ),
          ),
        );
        break;
      case "PDV":
        nav = Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PdvScreen()),
        );
        break;
      case "Config Fiscal":
        nav = Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ConfigFiscalScreen()),
        );
        break;
      case "CRM/Funil":
        nav = Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CrmPipelineScreen()),
        );
        break;
      case "Obrigacoes":
        nav = Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FiscalAutomationScreen()),
        );
        break;
      case "Contas Bancarias":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ContaBancariaGridScreen(
              hasPermission: (action) =>
                  _hasPermissionFor(sec, AppScreen.contasBancarias, action),
            ),
          ),
        );
        break;
      case "Bater Ponto":
        nav = Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PontoScreen()),
        );
        break;
      case "Funcionários":
        nav = _pushDynamicGrid(
          telaNome: 'funcionario',
          sec: sec,
          screen: AppScreen.funcionarios,
        );
        break;
      case "Mensalidades":
        nav = Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MobileMensalidadeScreen()),
        );
        break;
      case "Alvarás":
        nav = Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MobileAlvaraScreen()),
        );
        break;
      case "Meu Perfil":
        nav = Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MeuPerfilScreen()),
        );
        break;
      case "Importar Extratos":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MobileExtratoImportacaoScreen(),
          ),
        );
        break;
      case "Voltar":
        return;
      case "Sair":
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Sair do aplicativo'),
            content: const Text('Deseja encerrar a sessão?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.primary,
                    foregroundColor: Colors.white),
                onPressed: () async {
                  Navigator.pop(context);
                  await AuthUtility.clearUserInfo();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  }
                },
                child: const Text('Sair'),
              ),
            ],
          ),
        );
        return; // logout não reabre o menu
    }

    // Quando o usuário pressionar voltar em qualquer tela do menu "Mais",
    // reabrir o menu automaticamente.
    nav?.then((_) {
      if (mounted) _showMenuOptions(context, sec);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sec = SecurityMatrix.current();
    final screens = _buildScreens(sec);

    final safeIndex = selectedIndex.clamp(0, screens.length - 1);
    final navItems = _buildNavItems(sec, safeIndex);

    // BottomNavigationBar exige no mínimo 2 itens
    if (navItems.length < 2) {
      return const SemAcessoScreen();
    }

    return Scaffold(
      backgroundColor: GridColors.pageBackground,
      body: Stack(
        children: [
          IndexedStack(
            index: safeIndex,
            children: screens,
          ),
          const AppLoggerOverlay(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: GridColors.primary,
          border: Border(
            top: BorderSide(color: GridColors.primaryDark, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: GridColors.primary,
          currentIndex: safeIndex,
          unselectedItemColor: Colors.white.withValues(alpha: 0.82),
          selectedItemColor: Colors.white,
          unselectedLabelStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.82),
          ),
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          onTap: (int index) {
            // Índice fixo: 0=Início, 1=Chat, 2=Comunicados, 3=Slot Dinâmico, 4=Mais
            if (index == 4) {
              // Último slot = Mais → abre bottom sheet agrupado
              _showMenuOptions(context, sec);
            } else if (index == 3) {
              // Slot dinâmico: verifica permissão antes de navegar
              final slot = _dynamicSlotInfo();
              if (slot != null) {
                setState(() => selectedIndex = 3);
              }
            } else {
              setState(() => selectedIndex = index);
            }
          },
          items: navItems,
        ),
      ),
    );
  }

  void _showMenuOptions(BuildContext context, SecurityMatrix sec) {
    final contratados = ModuloAccess.modulosContratados;

    // Define os grupos de módulos com seus itens (gateados por permissão)
    final modulos = <_ModuloGroup>[
      _ModuloGroup(
        'Comercial',
        Icons.business,
        [
          if (sec.canView(AppScreen.pdvNfce))
            _MoreMenuAction(Icons.point_of_sale, 'PDV'),
          if (sec.canView(AppScreen.produto))
            _MoreMenuAction(Icons.inventory, 'Produtos'),
          if (sec.canView(AppScreen.parceiros))
            _MoreMenuAction(Icons.people, 'Parceiros'),
        ],
      ),
      _ModuloGroup(
        'Financeiro',
        Icons.account_balance,
        [
          if (sec.canView(AppScreen.contasPagar))
            _MoreMenuAction(Icons.payments, 'Contas Pagar'),
          if (sec.canView(AppScreen.contasReceber))
            _MoreMenuAction(Icons.account_balance_wallet, 'Contas Receber'),
          if (sec.canView(AppScreen.contasBancarias))
            _MoreMenuAction(Icons.account_balance, 'Contas Bancarias'),
          if (sec.canView(AppScreen.dashboard))
            _MoreMenuAction(Icons.bar_chart, 'Dashboard'),
          if (sec.canView(AppScreen.contasReceber))
            _MoreMenuAction(Icons.notifications_active, 'Régua de Cobrança'),
          if (sec.canView(AppScreen.contasBancarias))
            _MoreMenuAction(Icons.upload_file, 'Importar Extratos'),
        ],
      ),
      _ModuloGroup(
        'Departamento Pessoal',
        Icons.badge,
        [
          if (sec.canView(AppScreen.ponto))
            _MoreMenuAction(Icons.access_time, 'Bater Ponto'),
          if (sec.canView(AppScreen.funcionarios))
            _MoreMenuAction(Icons.people_outline, 'Funcionários'),
        ],
      ),
      _ModuloGroup(
        'NFS-e',
        Icons.description,
        [
          if (sec.canView(AppScreen.nfseLista))
            _MoreMenuAction(Icons.file_copy, 'Notas de Serviço (NFS-e)'),
          if (sec.canView(AppScreen.nfseSerie))
            _MoreMenuAction(Icons.tag, 'Séries NFS-e'),
        ],
      ),
      _ModuloGroup(
        'Outros',
        Icons.apps,
        [
          if (sec.canView(AppScreen.parceiros))
            _MoreMenuAction(Icons.handshake, 'Parceiros'),
          if (sec.canView(AppScreen.dashAtendimentoArea))
            _MoreMenuAction(Icons.support_agent, 'Atendimento'),
          if (sec.canView(AppScreen.mensalidades))
            _MoreMenuAction(Icons.receipt_long, 'Mensalidades'),
          if (sec.canView(AppScreen.logins))
            _MoreMenuAction(Icons.manage_accounts, 'Usuários'),
          _MoreMenuAction(Icons.verified_user, 'Alvarás'),
          _MoreMenuAction(Icons.account_circle, 'Meu Perfil'),
          _MoreMenuAction(Icons.settings, 'Config Fiscal'),
          _MoreMenuAction(Icons.exit_to_app, 'Sair', isDestructive: true),
        ],
      ),
    ];

    // Filtra apenas grupos com itens visíveis
    final gruposVisiveis = modulos.where((g) => g.items.isNotEmpty).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: GridColors.card,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: GridColors.divider,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: GridColors.secondarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.apps_rounded,
                        color: GridColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mais opções',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: GridColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Acesse os módulos do sistema',
                            style: TextStyle(
                              fontSize: 12,
                              color: GridColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close),
                      color: GridColors.textMuted,
                      tooltip: 'Fechar',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Grupos do módulo contratado — com badge "contratado"
                ...gruposVisiveis.map((grupo) {
                  final contratado = contratados.contains(grupo.nome);
                  return _buildModuloGroup(
                    grupo,
                    contratado,
                    sec,
                  );
                }),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.arrow_downward_rounded),
                    label: const Text('Fechar menu'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModuloGroup(
    _ModuloGroup grupo,
    bool contratado,
    SecurityMatrix sec,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 12, bottom: 6),
          child: Row(
            children: [
              Icon(grupo.icon,
                  size: 16,
                  color:
                      contratado ? GridColors.secondary : GridColors.textMuted),
              const SizedBox(width: 8),
              Text(
                grupo.nome,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: contratado
                      ? GridColors.textSecondary
                      : GridColors.textMuted,
                ),
              ),
              if (contratado) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: GridColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'contratado',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: GridColors.success,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: grupo.items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.95,
          ),
          itemBuilder: (_, index) {
            final item = grupo.items[index];
            return _menuItemGrid(
              item.icon,
              item.title,
              sec,
              isDestructive: item.isDestructive,
            );
          },
        ),
        const Divider(height: 20),
      ],
    );
  }

  Widget _menuItemGrid(
    IconData icon,
    String title,
    SecurityMatrix sec, {
    bool isDestructive = false,
  }) {
    final Color accent =
        isDestructive ? GridColors.primary : GridColors.secondary;
    final Color background =
        isDestructive ? GridColors.primarySoft : GridColors.secondarySoft;

    return InkWell(
      onTap: () => onMenuOptionSelected(title, sec),
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        decoration: BoxDecoration(
          color: GridColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: GridColors.divider),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: background,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.1,
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreMenuAction {
  final IconData icon;
  final String title;
  final bool isDestructive;

  const _MoreMenuAction(
    this.icon,
    this.title, {
    this.isDestructive = false,
  });
}

class _ModuloGroup {
  final String nome;
  final IconData icon;
  final List<_MoreMenuAction> items;

  const _ModuloGroup(this.nome, this.icon, this.items);
}

/// Informações do slot dinâmico da BottomNavBar.
class _DynamicSlot {
  final IconData icon;
  final String label;
  final String rota;
  const _DynamicSlot(this.icon, this.label, this.rota);
}
