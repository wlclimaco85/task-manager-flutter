import 'dart:convert';
import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';
import 'package:http/http.dart' as http;
import '../../utils/api_links.dart';
import '../../utils/tenant_context.dart';
import '../../utils/menu_config.dart';

// ─── Cores ────────────────────────────────────────────────────────────────────
const _red   = GridColors.primary;
const _green = GridColors.secondary;
const _bord  = Color(0xFFDDDDDD);
const _grey  = Color(0xFF757575);
const _bg    = Color(0xFFF5F5F5);
const _card  = Colors.white;

// ─── Catálogo de telas do sistema ─────────────────────────────────────────────
// Fonte ÚNICA = MenuConfig (o mesmo menu lateral). Gerado dinamicamente para
// nunca ficar dessincronizado: cada grupo/submenu do menu vira uma tela aqui.
// telaNome = MenuItem.id (chave canônica usada no PUT /api/role-permissao).
final List<Map<String, String>> _todasTelas = _buildTodasTelas();

List<Map<String, String>> _buildTodasTelas() {
  final list = <Map<String, String>>[];
  for (final g in MenuConfig.groups) {
    for (final item in g.items) {
      list.add({'nome': item.id, 'label': item.label, 'grupo': g.label});
    }
  }
  for (final item in MenuConfig.loose) {
    list.add({'nome': item.id, 'label': item.label, 'grupo': 'Outros'});
  }
  return list;
}

// ─────────────────────────────────────────────────────────────────────────────
class RolePermissaoScreen extends StatefulWidget {
  const RolePermissaoScreen({super.key});
  @override
  State<RolePermissaoScreen> createState() => _RolePermissaoScreenState();
}

class _RolePermissaoScreenState extends State<RolePermissaoScreen> {
  // Dados
  List<Map<String, dynamic>> _roles = [];
  // roleId → telaNome → {podeVer, podeInserir, podeEditar, podeDeletar}
  final Map<int, Map<String, Map<String, bool>>> _perms = {};

  // Estado UI
  int? _selectedRoleId;
  String _searchTela = '';
  bool _loading = true;
  // Conjunto de telas com save em andamento
  final Set<String> _saving = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ── Carregamento ────────────────────────────────────────────────────────────
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await Future.wait([_loadRoles(), _loadPerms()]);
    } catch (e) {
      _snack('Erro ao carregar: $e', error: true);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadRoles() async {
    final r = await TenantContext.get('${ApiLinks.baseUrl}/api/role?tamanho=200');
    if (r.statusCode != 200) return;
    final b = jsonDecode(r.body);
    List raw = _extractList(b);
    _roles = raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    if (_roles.isNotEmpty && _selectedRoleId == null) {
      _selectedRoleId = _roles.first['id'] as int?;
    }
  }

  Future<void> _loadPerms() async {
    final r = await TenantContext.get('${ApiLinks.baseUrl}/api/role-permissao/all');
    if (r.statusCode != 200) return;
    final b = jsonDecode(r.body);
    final raw = _extractList(b);
    for (final item in raw.whereType<Map>()) {
      final roleId = item['roleId'] as int?;
      final tela = item['telaNome']?.toString() ?? '';
      if (roleId == null || tela.isEmpty) continue;
      _perms[roleId] ??= {};
      _perms[roleId]![tela] = {
        'podeVer':     item['podeVer'] == true,
        'podeInserir': item['podeInserir'] == true,
        'podeEditar':  item['podeEditar'] == true,
        'podeDeletar': item['podeDeletar'] == true,
      };
    }
  }

  List _extractList(dynamic b) {
    if (b is List) return b;
    if (b is Map) {
      final d = b['data'];
      if (d is List) return d;
      if (d is Map) return d['dados'] ?? d['content'] ?? d['items'] ?? [];
      return b['dados'] ?? b['content'] ?? [];
    }
    return [];
  }

  // ── Toggle de acesso (salva imediatamente) ──────────────────────────────────
  Future<void> _toggleAcesso(String telaNome, bool value) async {
    if (_selectedRoleId == null) return;
    final roleId = _selectedRoleId!;

    // Atualiza UI imediatamente (optimistic)
    setState(() {
      _perms[roleId] ??= {};
      _perms[roleId]![telaNome] = {
        'podeVer':     value,
        'podeInserir': value,
        'podeEditar':  value,
        'podeDeletar': value,
      };
      _saving.add(telaNome);
    });

    try {
      final token = TenantContext.jsonHeaders['Authorization'];
      final resp = await http.put(
        Uri.parse('${ApiLinks.baseUrl}/api/role-permissao/$roleId/$telaNome'),
        headers: {
          if (token != null) 'Authorization': token,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'podeVer':     value,
          'podeInserir': value,
          'podeEditar':  value,
          'podeDeletar': value,
        }),
      );
      if (resp.statusCode != 200 && mounted) {
        // Reverte em caso de erro
        setState(() {
          _perms[roleId]![telaNome] = {
            'podeVer': !value, 'podeInserir': !value,
            'podeEditar': !value, 'podeDeletar': !value,
          };
        });
        _snack('Erro ao salvar permissão', error: true);
      }
    } catch (e) {
      if (mounted) _snack('Erro: $e', error: true);
    } finally {
      if (mounted) setState(() => _saving.remove(telaNome));
    }
  }

  bool _temAcesso(String telaNome) {
    if (_selectedRoleId == null) return false;
    final p = _perms[_selectedRoleId!]?[telaNome];
    if (p == null) return false;
    return p['podeVer'] == true;
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? _red : _green,
      duration: const Duration(seconds: 2),
    ));
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _red,
        foregroundColor: Colors.white,
        title: const Text('Controle de Acesso por Role',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Recarregar',
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── Painel esquerdo: Roles ──────────────────────────────────────
              _buildRolesPanel(),
              Container(width: 1, color: _bord),
              // ── Painel direito: Telas ───────────────────────────────────────
              Expanded(child: _buildTelasPanel()),
            ]),
    );
  }

  // ── Painel de Roles ─────────────────────────────────────────────────────────
  Widget _buildRolesPanel() {
    return SizedBox(
      width: 220,
      child: Column(children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          color: _green,
          child: const Row(children: [
            Icon(Icons.security, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('Roles', style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ]),
        ),
        // Lista
        Expanded(
          child: ListView.separated(
            itemCount: _roles.length,
            separatorBuilder: (_, __) => Container(height: 1, color: _bord),
            itemBuilder: (_, i) {
              final role = _roles[i];
              final id = role['id'] as int?;
              final selected = id == _selectedRoleId;
              final key = role['key']?.toString() ?? '';
              final desc = role['description']?.toString() ?? key;

              // Conta quantas telas têm acesso
              final count = _perms[id]?.values.where((p) => p['podeVer'] == true).length ?? 0;

              return InkWell(
                onTap: () => setState(() => _selectedRoleId = id),
                child: Container(
                  color: selected ? _red.withValues(alpha: 0.08) : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(children: [
                    // Indicador de seleção
                    Container(
                      width: 3,
                      height: 36,
                      decoration: BoxDecoration(
                        color: selected ? _red : Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(desc,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                              color: selected ? _red : Colors.black87,
                            )),
                        const SizedBox(height: 2),
                        Text(key,
                            style: const TextStyle(fontSize: 10, color: _grey)),
                      ],
                    )),
                    // Badge com contagem
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: count > 0 ? _green.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$count',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: count > 0 ? _green : _grey,
                          )),
                    ),
                  ]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  // ── Painel de Telas ─────────────────────────────────────────────────────────
  Widget _buildTelasPanel() {
    if (_selectedRoleId == null) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.arrow_back, size: 40, color: _grey),
          SizedBox(height: 8),
          Text('Selecione uma role', style: TextStyle(color: _grey, fontSize: 14)),
        ]),
      );
    }

    final roleName = _roles
        .firstWhere((r) => r['id'] == _selectedRoleId, orElse: () => {})['description']
        ?.toString() ?? '';

    // Filtra e agrupa
    final filtered = _todasTelas.where((t) =>
        _searchTela.isEmpty ||
        t['label']!.toLowerCase().contains(_searchTela.toLowerCase()) ||
        t['grupo']!.toLowerCase().contains(_searchTela.toLowerCase())).toList();

    // Agrupa por grupo
    final grupos = <String, List<Map<String, String>>>{};
    for (final t in filtered) {
      final g = t['grupo']!;
      grupos[g] ??= [];
      grupos[g]!.add(t);
    }

    // Conta acessos para a role selecionada
    final totalAcesso = _todasTelas.where((t) => _temAcesso(t['nome']!)).length;
    final total = _todasTelas.length;

    return Column(children: [
      // Header do painel direito
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: Colors.white,
        child: Row(children: [
          // Info da role selecionada
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(roleName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text('$totalAcesso de $total telas com acesso',
                style: const TextStyle(fontSize: 11, color: _grey)),
            const SizedBox(height: 2),
            Row(mainAxisSize: MainAxisSize.min, children: const [
              Icon(Icons.cloud_done, size: 12, color: _green),
              SizedBox(width: 4),
              Text('Alterações salvas automaticamente',
                  style: TextStyle(fontSize: 10, color: _green, fontStyle: FontStyle.italic)),
            ]),
          ])),
          // Barra de progresso
          SizedBox(
            width: 120,
            child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${total > 0 ? (totalAcesso * 100 ~/ total) : 0}%',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _green)),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: total > 0 ? totalAcesso / total : 0,
                  backgroundColor: _bord,
                  valueColor: const AlwaysStoppedAnimation<Color>(_green),
                  minHeight: 6,
                ),
              ),
            ]),
          ),
          const SizedBox(width: 16),
          // Ações em massa
          OutlinedButton.icon(
            onPressed: () => _toggleGrupo(null, true),
            icon: const Icon(Icons.select_all, size: 14),
            label: const Text('Liberar tudo', style: TextStyle(fontSize: 11)),
            style: OutlinedButton.styleFrom(
              foregroundColor: _green,
              side: const BorderSide(color: _green),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 6),
          OutlinedButton.icon(
            onPressed: () => _toggleGrupo(null, false),
            icon: const Icon(Icons.block, size: 14),
            label: const Text('Revogar tudo', style: TextStyle(fontSize: 11)),
            style: OutlinedButton.styleFrom(
              foregroundColor: _red,
              side: const BorderSide(color: _red),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ]),
      ),
      // Busca
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: TextField(
          onChanged: (v) => setState(() => _searchTela = v),
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            hintText: 'Buscar tela ou grupo...',
            prefixIcon: const Icon(Icons.search, size: 18, color: _grey),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _bord)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _bord)),
          ),
        ),
      ),
      Container(height: 1, color: _bord),
      // Lista de grupos e telas
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: grupos.length,
          itemBuilder: (_, gi) {
            final grupo = grupos.keys.elementAt(gi);
            final telas = grupos[grupo]!;
            final grupoAcesso = telas.where((t) => _temAcesso(t['nome']!)).length;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _bord),
              ),
              child: Column(children: [
                // Header do grupo
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: const BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                    border: Border(bottom: BorderSide(color: _bord)),
                  ),
                  child: Row(children: [
                    Text(grupo,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12, color: _green)),
                    const SizedBox(width: 8),
                    Text('($grupoAcesso/${telas.length})',
                        style: const TextStyle(fontSize: 11, color: _grey)),
                    const Spacer(),
                    // Toggle do grupo inteiro
                    _GrupoToggle(
                      allOn: grupoAcesso == telas.length,
                      anyOn: grupoAcesso > 0,
                      onToggle: (v) => _toggleGrupo(grupo, v),
                    ),
                  ]),
                ),
                // Telas do grupo
                ...telas.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final tela = entry.value;
                  final nome = tela['nome']!;
                  final label = tela['label']!;
                  final ativo = _temAcesso(nome);
                  final salvando = _saving.contains(nome);

                  return Container(
                    decoration: BoxDecoration(
                      border: idx < telas.length - 1
                          ? const Border(bottom: BorderSide(color: _bord))
                          : null,
                    ),
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                      title: Text(label,
                          style: TextStyle(
                            fontSize: 12,
                            color: ativo ? Colors.black87 : _grey,
                          )),
                      subtitle: Text(nome,
                          style: const TextStyle(fontSize: 10, color: _grey)),
                      trailing: salvando
                          ? const SizedBox(
                              width: 24, height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: _green))
                          : Switch(
                              value: ativo,
                              onChanged: (v) => _toggleAcesso(nome, v),
                              activeThumbColor: _green,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                    ),
                  );
                }),
              ]),
            );
          },
        ),
      ),
    ]);
  }

  // ── Toggle de grupo inteiro ─────────────────────────────────────────────────
  Future<void> _toggleGrupo(String? grupo, bool value) async {
    final telas = grupo == null
        ? _todasTelas
        : _todasTelas.where((t) => t['grupo'] == grupo).toList();

    // Salva todas em paralelo
    await Future.wait(telas.map((t) => _toggleAcesso(t['nome']!, value)));
  }
}

// ─── Widget auxiliar para toggle de grupo ─────────────────────────────────────
class _GrupoToggle extends StatelessWidget {
  final bool allOn;
  final bool anyOn;
  final void Function(bool) onToggle;

  const _GrupoToggle({
    required this.allOn,
    required this.anyOn,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(allOn ? 'Revogar grupo' : 'Liberar grupo',
          style: TextStyle(fontSize: 10, color: allOn ? _red : _green)),
      const SizedBox(width: 4),
      Switch(
        value: allOn,
        onChanged: onToggle,
        activeThumbColor: _green,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ]);
  }
}
