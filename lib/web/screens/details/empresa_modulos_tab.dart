import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../models/auth_utility.dart';
import '../../../utils/api_links.dart';
import '../../../utils/grid_colors.dart';

/// Aba customizada de gerenciamento de módulos de serviço para uma empresa.
/// Exibe 4 checkboxes (Comercial, Financeiro, Departamento Pessoal, NFS-e)
/// e sincroniza com o backend via GET/POST /api/empresa-modulo.
class EmpresaModulosTab extends StatefulWidget {
  final int empresaId;
  final ValueChanged<List<int>>? onModulosChanged;

  const EmpresaModulosTab({
    super.key,
    required this.empresaId,
    this.onModulosChanged,
  });

  @override
  State<EmpresaModulosTab> createState() => _EmpresaModulosTabState();
}

class _EmpresaModulosTabState extends State<EmpresaModulosTab> {
  bool _carregando = true;
  String? _erroCarregamento;

  /// Mapa: nome do módulo → ID (carregado do servidor na inicialização)
  final Map<String, int> _modulosDisponiveis = {
    'Comercial': 0,
    'Financeiro': 0,
    'Departamento Pessoal': 0,
    'NFS-e': 0,
  };

  /// Conjunto de IDs dos módulos marcados atualmente
  late Set<int> _modulosMarcados;

  @override
  void initState() {
    super.initState();
    _modulosMarcados = {};
    _carregarModulos();
  }

  /// GET /api/empresa-modulo?empresaId=X — carrega módulos vinculados e nomes dos módulos
  Future<void> _carregarModulos() async {
    if (!mounted) return;
    setState(() {
      _carregando = true;
      _erroCarregamento = null;
    });

    try {
      final token = AuthUtility.userInfo?.token;
      final resp = await http.get(
        Uri.parse('${ApiLinks.baseUrl}/api/empresa-modulo?empresaId=${widget.empresaId}'),
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final List<dynamic> dados = body is List ? body : (body['data'] ?? body['content'] ?? []);

        final marcados = <int>{};
        for (final item in dados) {
          final id = item['id'] as int?;
          final nome = item['nome'] as String?;
          if (id != null && nome != null) {
            _modulosDisponiveis[nome] = id;
            marcados.add(id);
          }
        }

        if (mounted) {
          setState(() {
            _modulosMarcados = marcados;
            _carregando = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _erroCarregamento = 'Erro ${resp.statusCode} ao carregar módulos';
            _carregando = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erroCarregamento = 'Erro de conexão: $e';
          _carregando = false;
        });
      }
    }
  }

  /// POST /api/empresa-modulo — persiste a lista de módulos selecionados
  Future<void> _salvarModulos() async {
    try {
      final token = AuthUtility.userInfo?.token;
      final resp = await http.post(
        Uri.parse('${ApiLinks.baseUrl}/api/empresa-modulo'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'empresaId': widget.empresaId,
          'moduloIds': _modulosMarcados.toList(),
        }),
      );

      if (mounted && resp.statusCode == 200) {
        widget.onModulosChanged?.call(_modulosMarcados.toList());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar módulos: $e')),
        );
      }
    }
  }

  /// Alterna seleção de um módulo e persiste no backend
  Future<void> _toggleModulo(String nomePrincipal, bool marcado) async {
    final moduloId = _modulosDisponiveis[nomePrincipal];
    if (moduloId == null || moduloId == 0) return;

    setState(() {
      if (marcado) {
        _modulosMarcados.add(moduloId);
      } else {
        _modulosMarcados.remove(moduloId);
      }
    });

    await _salvarModulos();
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_erroCarregamento != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _erroCarregamento!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: GridColors.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _carregarModulos,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Módulos de Serviço Contratados',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          title: const Text('Comercial'),
          subtitle: const Text('Vendas, pedidos, PDV/NFC-e'),
          value: _modulosMarcados.contains(_modulosDisponiveis['Comercial']),
          onChanged: (v) => _toggleModulo('Comercial', v ?? false),
        ),
        CheckboxListTile(
          title: const Text('Financeiro'),
          subtitle: const Text('Contas a pagar/receber, bancárias'),
          value: _modulosMarcados.contains(_modulosDisponiveis['Financeiro']),
          onChanged: (v) => _toggleModulo('Financeiro', v ?? false),
        ),
        CheckboxListTile(
          title: const Text('Departamento Pessoal'),
          subtitle: const Text('Funcionários, ponto e ajustes'),
          value: _modulosMarcados.contains(_modulosDisponiveis['Departamento Pessoal']),
          onChanged: (v) => _toggleModulo('Departamento Pessoal', v ?? false),
        ),
        CheckboxListTile(
          title: const Text('NFS-e'),
          subtitle: const Text('Notas fiscais de serviço'),
          value: _modulosMarcados.contains(_modulosDisponiveis['NFS-e']),
          onChanged: (v) => _toggleModulo('NFS-e', v ?? false),
        ),
      ],
    );
  }
}
