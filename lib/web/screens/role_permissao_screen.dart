import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/role_permissao_model.dart';
import '../../models/auth_utility.dart';
import '../../utils/api_links.dart';
import '../../utils/grid_colors.dart';
import '../../utils/tenant_context.dart';
import '../../utils/menu_config.dart';

// Fix (card #460): converte o id de menu (snake_case, ex.: 'nfe_entrada')
// para o formato usado pelo backend em role_permissao.tela_nome (camelCase,
// ex.: 'nfeEntrada'). Os dois catalogos evoluiram separadamente -- o match
// por igualdade direta (t.id == p.telaNome) nunca encontrava a permissao
// real, entao a tabela sempre aparecia toda desmarcada.
//
// LIMITACAO CONHECIDA: esta conversao mecanica cobre o padrao regular
// (snake_case -> camelCase) usado pela maioria das telas do seed
// (V101__Role_permissao.sql), mas o backend usa em alguns casos vocabulario
// proprio nao-mecanico (ex.: 'ged' em vez de 'diretorios'/'arquivos',
// 'kanbanChamados' em vez de 'chamados', 'pontoWeb' em vez de 'ponto').
// Alem disso, varias telas visiveis no MenuConfig (Planos, Orcamentos,
// Pedidos de Venda/Compra, Aprovacao de Compras, Tabela de Precos,
// Devolucoes, Dashboard Comercial) nao tem nenhuma linha de seed em
// V101__Role_permissao.sql -- para essas, a tela aparecera desmarcada ate
// que uma migration adicione o seed correspondente (fora do escopo deste
// fix, que e sobre o mecanismo de match, nao sobre dados faltantes).
String toBackendTelaNome(String menuItemId) {
  final parts = menuItemId.split('_');
  if (parts.isEmpty) return menuItemId;
  final buffer = StringBuffer(parts.first);
  for (final part in parts.skip(1)) {
    if (part.isEmpty) continue;
    buffer.write(part[0].toUpperCase());
    buffer.write(part.substring(1));
  }
  return buffer.toString();
}

// Fix (card #471): confirmado via consulta direta ao banco de dev que
// role_permissao.tela_nome NÃO segue uma convenção única -- registros
// diferentes usam snake_case ('nfe_entrada', 'equipamento') e camelCase
// ('nfeEntrada', 'contasBancarias') dependendo de quando/como foram
// gravados (seeds diferentes ao longo do tempo). O match exato contra
// toBackendTelaNome() (sempre camelCase) por isso perdia registros
// snake_case legados -- a tela aparecia desmarcada mesmo quando a
// permissão já existia no banco. Normalizando (lowercase + remove "_")
// dos dois lados, o match funciona independente de qual convenção o
// registro específico usa.
String _normalizeTelaNome(String s) =>
    s.toLowerCase().replaceAll('_', '');

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

  // Fix (card #460, sintoma 3): apos o PUT bem-sucedido, atualiza
  // _permissoes localmente (upsert do registro alterado) e chama setState,
  // em vez de deixar o estado antigo intocado -- antes disso o checkbox
  // nao refletia o clique ate o usuario trocar de role e voltar.
  Future<void> _salvar(String menuItemId, String campo, bool valor) async {
    if (_roleId == null) return;
    final roleId = _roleId!;
    final telaNome = toBackendTelaNome(menuItemId);
    final token = AuthUtility.userInfo?.token ?? '';
    final tenantId = TenantContext.empresaId?.toString() ?? '';

    try {
      final response = await http.put(
        Uri.parse('${ApiLinks.baseUrl}/api/role-permissao/$roleId/$telaNome'),
        headers: {
          'Authorization': 'Bearer $token',
          'X-Tenant-ID': tenantId,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({campo: valor}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao salvar: ${response.statusCode}'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      setState(() {
        final index = _permissoes.indexWhere(
          (p) => p.roleId == roleId && p.telaNome == telaNome,
        );
        if (index >= 0) {
          final atual = _permissoes[index];
          _permissoes[index] = atual.copyWith(
            podeVer: campo == 'podeVer' ? valor : null,
            podeInserir: campo == 'podeInserir' ? valor : null,
            podeEditar: campo == 'podeEditar' ? valor : null,
            podeDeletar: campo == 'podeDeletar' ? valor : null,
            podeBaixar: campo == 'podeBaixar' ? valor : null,
          );
        } else {
          _permissoes.add(RolePermissao(
            id: 0,
            roleId: roleId,
            roleKey: '',
            roleDescription: '',
            telaNome: telaNome,
            podeVer: campo == 'podeVer' ? valor : false,
            podeInserir: campo == 'podeInserir' ? valor : false,
            podeEditar: campo == 'podeEditar' ? valor : false,
            podeDeletar: campo == 'podeDeletar' ? valor : false,
            podeBaixar: campo == 'podeBaixar' ? valor : false,
          ));
        }
      });

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

  RolePermissao _permissaoDe(MenuItem t) {
    final telaNome = toBackendTelaNome(t.id);
    final telaNomeNormalizado = _normalizeTelaNome(t.id);
    return _permissoes.firstWhere(
      (p) =>
          p.roleId == _roleId &&
          _normalizeTelaNome(p.telaNome) == telaNomeNormalizado,
      orElse: () => RolePermissao(
        id: 0,
        roleId: _roleId!,
        roleKey: '',
        roleDescription: '',
        telaNome: telaNome,
        podeVer: false,
        podeInserir: false,
        podeEditar: false,
        podeDeletar: false,
        podeBaixar: false,
      ),
    );
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

  // Fix (card #460, sintoma 2): antes iterava MenuConfig.groups achatando
  // tudo numa lista plana (telas.addAll(g.items)), descartando a estrutura
  // de grupo. Agora preserva os grupos e insere uma TableRow de cabecalho
  // de secao (g.label) antes das telas de cada grupo.
  Widget _buildTabela() {
    if (_roleId == null) return const SizedBox();

    final rows = <TableRow>[
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
    ];

    for (final grupo in MenuConfig.groups) {
      if (grupo.items.isEmpty) continue;
      rows.add(TableRow(
        decoration: BoxDecoration(color: GridColors.primary.withOpacity(0.04)),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              grupo.label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(),
          const SizedBox(),
          const SizedBox(),
          const SizedBox(),
          const SizedBox(),
        ],
      ));
      for (final t in grupo.items) {
        final p = _permissaoDe(t);
        rows.add(TableRow(
          children: [
            _cell('   ${t.label}'),
            _check(p.podeVer, () => _salvar(t.id, 'podeVer', !p.podeVer)),
            _check(p.podeInserir, () => _salvar(t.id, 'podeInserir', !p.podeInserir)),
            _check(p.podeEditar, () => _salvar(t.id, 'podeEditar', !p.podeEditar)),
            _check(p.podeDeletar, () => _salvar(t.id, 'podeDeletar', !p.podeDeletar)),
            _check(p.podeBaixar, () => _salvar(t.id, 'podeBaixar', !p.podeBaixar)),
          ],
        ));
      }
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
        children: rows,
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
