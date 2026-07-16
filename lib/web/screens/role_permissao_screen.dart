import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/role_permissao_model.dart';
import '../../models/auth_utility.dart';
import '../../models/tela_model.dart';
import '../../utils/api_links.dart';
import '../../utils/grid_colors.dart';
import '../../utils/tenant_context.dart';
import '../../services/tela_service.dart';

// Fix (card #471): normalizacao de nomes de tela (lowercase + remove "_")
// permite match independente de qual convencao (snake_case vs camelCase)
// o registro especifico usar no banco. Necessario porque role_permissao.tela_nome
// usa multiplas convencoes historicamente.
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
  List<Tela> _telas = [];
  int? _roleId;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
    _carregarTelas();
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

  /// Carrega a lista dinâmica de telas do backend via TelaService
  Future<void> _carregarTelas() async {
    try {
      final telas = await TelaService.listarTelas();
      if (mounted) {
        setState(() {
          _telas = telas;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar telas: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Fix (card #460, sintoma 3): apos o PUT bem-sucedido, atualiza
  // _permissoes localmente (upsert do registro alterado) e chama setState,
  // em vez de deixar o estado antigo intocado -- antes disso o checkbox
  // nao refletia o clique ate o usuario trocar de role e voltar.
  // Fix (card #493): refatorado para receber telaNome diretamente (ja no formato
  // correto do backend) em vez de menuItemId que precisa conversao.
  Future<void> _salvar(String telaNome, String campo, bool valor) async {
    if (_roleId == null) return;
    final roleId = _roleId!;
    final token = AuthUtility.userInfo?.token ?? '';
    final tenantId = TenantContext.empresaId?.toString() ?? '';

    try {
      // CR-05: Usar Uri.encodeComponent() para telaNome para evitar caracteres especiais malformarem a URL
      final baseUri = Uri.parse(ApiLinks.baseUrl);
      final requestUri = baseUri.replace(
        path: '${baseUri.path}/api/role-permissao/$roleId/${Uri.encodeComponent(telaNome)}',
      );

      final response = await http.put(
        requestUri,
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
          (p) => p.roleId == roleId && _normalizeTelaNome(p.telaNome) == _normalizeTelaNome(telaNome),
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

  /// Fix (card #493): refatorado para receber Tela diretamente
  /// em vez de MenuItem. Usa tela.nome (ja no formato do backend)
  /// para fazer match com permissoes armazenadas.
  RolePermissao _permissaoDe(Tela tela) {
    final telaNomeNormalizado = _normalizeTelaNome(tela.nome);
    return _permissoes.firstWhere(
      (p) =>
          p.roleId == _roleId &&
          _normalizeTelaNome(p.telaNome) == telaNomeNormalizado,
      orElse: () => RolePermissao(
        id: 0,
        roleId: _roleId!,
        roleKey: '',
        roleDescription: '',
        telaNome: tela.nome,
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

  /// Fix (card #493): refatorado para iterar _telas (carregadas dinamicamente
  /// do backend via /api/telas) em vez de MenuConfig.groups (hardcoded).
  /// Isso permite que novas telas adicionadas ao banco sejam automaticamente
  /// listadas no controle de acesso, sem necessidade de rebuild do app.
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

    // Itera telas carregadas dinamicamente do backend
    for (final tela in _telas) {
      final p = _permissaoDe(tela);
      rows.add(TableRow(
        children: [
          _cell(tela.descricao.isNotEmpty ? tela.descricao : tela.nome),
          _check(p.podeVer, () => _salvar(tela.nome, 'podeVer', !p.podeVer)),
          _check(p.podeInserir, () => _salvar(tela.nome, 'podeInserir', !p.podeInserir)),
          _check(p.podeEditar, () => _salvar(tela.nome, 'podeEditar', !p.podeEditar)),
          _check(p.podeDeletar, () => _salvar(tela.nome, 'podeDeletar', !p.podeDeletar)),
          _check(p.podeBaixar, () => _salvar(tela.nome, 'podeBaixar', !p.podeBaixar)),
        ],
      ));
    }

    // Se nenhuma tela foi carregada, mostra mensagem
    if (_telas.isEmpty) {
      rows.add(TableRow(
        children: [
          _cell('Nenhuma tela disponível'),
          const SizedBox(),
          const SizedBox(),
          const SizedBox(),
          const SizedBox(),
          const SizedBox(),
        ],
      ));
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
