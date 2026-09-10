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
String _normalizeTelaNome(String s) =>
    s.toLowerCase().replaceAll('_', '');

// Conversao de snake_case para camelCase
String toBackendTelaNome(String screenName) {
  if (!screenName.contains('_')) {
    return screenName;
  }

  final parts = screenName.split('_');
  final buffer = StringBuffer(parts[0]);

  for (int i = 1; i < parts.length; i++) {
    final part = parts[i];
    if (part.isNotEmpty) {
      buffer.write(part[0].toUpperCase() + part.substring(1));
    }
  }

  return buffer.toString();
}

class RolePermissaoMobileScreen extends StatefulWidget {
  const RolePermissaoMobileScreen({super.key});

  @override
  State<RolePermissaoMobileScreen> createState() => _RolePermissaoMobileScreenState();
}

class _RolePermissaoMobileScreenState extends State<RolePermissaoMobileScreen> {
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

  // Fix (card #493): mobile - refatorado para receber telaNome diretamente
  Future<void> _salvar(String telaNome, String campo, bool valor) async {
    if (_roleId == null) return;
    final roleId = _roleId!;
    final token = AuthUtility.userInfo?.token ?? '';
    final tenantId = TenantContext.empresaId?.toString() ?? '';

    try {
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
                    Expanded(child: _buildListaMobile()),
                  ],
                ),
    );
  }

  /// Fix (card #493): layout mobile otimizado - lista vertical com cards
  /// em vez de tabela horizontal. Cada tela tem seus checkboxes organizados
  /// em 2 linhas (Ver/Inserir/Editar na primeira, Deletar/Baixar na segunda).
  Widget _buildListaMobile() {
    if (_roleId == null) return const SizedBox();

    if (_telas.isEmpty) {
      return const Center(child: Text('Nenhuma tela disponível'));
    }

    return ListView.builder(
      itemCount: _telas.length,
      itemBuilder: (context, index) {
        final tela = _telas[index];
        final p = _permissaoDe(tela);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome da tela
                Text(
                  tela.descricao.isNotEmpty ? tela.descricao : tela.nome,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),

                // Primeira linha: Ver, Inserir, Editar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _permCheckbox('Ver', p.podeVer, () => _salvar(tela.nome, 'podeVer', !p.podeVer)),
                    _permCheckbox('Inserir', p.podeInserir, () => _salvar(tela.nome, 'podeInserir', !p.podeInserir)),
                    _permCheckbox('Editar', p.podeEditar, () => _salvar(tela.nome, 'podeEditar', !p.podeEditar)),
                  ],
                ),
                const SizedBox(height: 8),

                // Segunda linha: Deletar, Baixar
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _permCheckbox('Deletar', p.podeDeletar, () => _salvar(tela.nome, 'podeDeletar', !p.podeDeletar)),
                    ),
                    Expanded(
                      child: _permCheckbox('Baixar', p.podeBaixar, () => _salvar(tela.nome, 'podeBaixar', !p.podeBaixar)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Widget para exibir checkbox com label (mobile-friendly)
  Widget _permCheckbox(String label, bool valor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(value: valor, onChanged: (_) => onTap()),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
