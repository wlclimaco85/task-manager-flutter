import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/role_permissao_model.dart';
import '../../models/auth_utility.dart';
import '../../utils/api_links.dart';
import '../../utils/grid_colors.dart';
import '../../utils/tenant_context.dart';
import '../../utils/menu_config.dart';

class RolePermissaoScreen extends StatefulWidget {
  const RolePermissaoScreen({super.key});

  @override
  State<RolePermissaoScreen> createState() => _RolePermissaoScreenState();
}

class _RolePermissaoScreenState extends State<RolePermissaoScreen> {
  List<RolePermissao> _permissoes = [];
  List<Map<String, dynamic>> _roles = [];
  int? _roleId;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final token = AuthUtility.userInfo?.token ?? '';
    final tenantId = TenantContext.empresaId?.toString() ?? '';

    try {
      final resPermissoes = await http.get(
        Uri.parse('${ApiLinks.baseUrl}/api/role-permissao/all'),
        headers: {'Authorization': 'Bearer $token', 'X-Tenant-ID': tenantId},
      );

      final resRoles = await http.get(
        Uri.parse('${ApiLinks.baseUrl}/api/role'),
        headers: {'Authorization': 'Bearer $token', 'X-Tenant-ID': tenantId},
      );

      if (resPermissoes.statusCode == 200 && resRoles.statusCode == 200) {
        final permData = jsonDecode(resPermissoes.body);
        final rolesData = jsonDecode(resRoles.body);

        setState(() {
          _permissoes = ((permData['data']?['dados'] ?? []) as List)
              .map((j) => RolePermissao.fromJson(j))
              .toList();
          _roles = ((rolesData['data']?['dados'] ?? []) as List)
              .map((r) => {'id': r['id'], 'description': r['description']})
              .toList();
          if (_roles.isNotEmpty) _roleId = _roles.first['id'] as int?;
          _carregando = false;
        });
      }
    } catch (e) {
      setState(() => _carregando = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _salvar(int roleId, String telaNome, String campo, bool valor) async {
    final token = AuthUtility.userInfo?.token ?? '';
    final tenantId = TenantContext.empresaId?.toString() ?? '';

    try {
      await http.put(
        Uri.parse('${ApiLinks.baseUrl}/api/role-permissao/$roleId/$telaNome'),
        headers: {
          'Authorization': 'Bearer $token',
          'X-Tenant-ID': tenantId,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({campo: valor}),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Salvo'), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<MenuItem> _todasTelas() {
    final telas = <MenuItem>[];
    for (final g in MenuConfig.groups) {
      telas.addAll(g.items);
    }
    return telas;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: GridColors.primary,
        title: const Text('Controle de Acesso'),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _roles.isEmpty
              ? const Center(child: Text('Nenhuma role'))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: DropdownButton<int>(
                        value: _roleId,
                        isExpanded: true,
                        items: _roles
                            .map((r) => DropdownMenuItem<int>(
                                  value: r['id'] as int?,
                                  child: Text(r['description'] ?? ''),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _roleId = v),
                      ),
                    ),
                    Expanded(child: _buildTabela()),
                  ],
                ),
    );
  }

  Widget _buildTabela() {
    if (_roleId == null) return const SizedBox();

    final telas = _todasTelas();
    final perms = <String, RolePermissao>{};

    for (final t in telas) {
      perms[t.id] = _permissoes.firstWhere(
        (p) => p.roleId == _roleId && p.telaNome == t.id,
        orElse: () => RolePermissao(
          id: 0,
          roleId: _roleId!,
          roleKey: '',
          roleDescription: '',
          telaNome: t.id,
          podeVer: false,
          podeInserir: false,
          podeEditar: false,
          podeDeletar: false,
          podeBaixar: false,
        ),
      );
    }

    return SingleChildScrollView(
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FixedColumnWidth(60),
          2: FixedColumnWidth(60),
          3: FixedColumnWidth(60),
          4: FixedColumnWidth(60),
          5: FixedColumnWidth(60),
        },
        border: TableBorder.all(color: Colors.grey.shade300),
        children: [
          TableRow(
            decoration: BoxDecoration(color: GridColors.primary.withOpacity(0.1)),
            children: [
              _cell('Tela', bold: true),
              _cell('Ver', bold: true),
              _cell('Inserir', bold: true),
              _cell('Editar', bold: true),
              _cell('Deletar', bold: true),
              _cell('Baixar', bold: true),
            ],
          ),
          ...telas.map((t) {
            final p = perms[t.id]!;
            return TableRow(
              children: [
                _cell(t.label),
                _check(p.podeVer, () => _salvar(_roleId!, t.id, 'podeVer', !p.podeVer)),
                _check(p.podeInserir, () => _salvar(_roleId!, t.id, 'podeInserir', !p.podeInserir)),
                _check(p.podeEditar, () => _salvar(_roleId!, t.id, 'podeEditar', !p.podeEditar)),
                _check(p.podeDeletar, () => _salvar(_roleId!, t.id, 'podeDeletar', !p.podeDeletar)),
                _check(p.podeBaixar, () => _salvar(_roleId!, t.id, 'podeBaixar', !p.podeBaixar)),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _cell(String text, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal),
      ),
    );
  }

  Widget _check(bool valor, VoidCallback onTap) {
    return Center(
      child: Checkbox(value: valor, onChanged: (_) => onTap()),
    );
  }
}
