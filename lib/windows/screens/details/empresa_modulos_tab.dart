import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../models/auth_utility.dart';
import '../../../utils/api_links.dart';
import '../../../utils/grid_colors.dart';

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

class _ModuloCatalogo {
  final int id;
  final String nome;
  final String? descricao;

  const _ModuloCatalogo({
    required this.id,
    required this.nome,
    this.descricao,
  });
}

class _EmpresaModulosTabState extends State<EmpresaModulosTab> {
  bool _carregando = true;
  String? _erroCarregamento;
  List<_ModuloCatalogo> _catalogo = [];
  Set<int> _modulosMarcados = {};
  Map<int, double> _valoresPorModulo = {};

  bool get _podeEditarModulos {
    final email = AuthUtility.userInfo?.login?.email?.trim().toLowerCase();
    return email == 'wlclimaco@gmail.com' || email == 'wlclimaco@gmail';
  }

  @override
  void initState() {
    super.initState();
    _carregarModulos();
  }

  Future<void> _carregarModulos() async {
    if (!mounted) return;
    setState(() {
      _carregando = true;
      _erroCarregamento = null;
    });

    try {
      final token = AuthUtility.userInfo?.token;
      final headers = {if (token != null) 'Authorization': 'Bearer $token'};

      final respCatalogo = await http.get(
        Uri.parse('${ApiLinks.allModuloServico}?tamanho=200'),
        headers: headers,
      );
      final respVinculados = await http.get(
        Uri.parse(
          '${ApiLinks.baseUrl}/api/empresa-modulo?empresaId=${widget.empresaId}',
        ),
        headers: headers,
      );

      if (!mounted) return;
      if (respCatalogo.statusCode != 200) {
        setState(() {
          _erroCarregamento =
              'Erro ${respCatalogo.statusCode} ao carregar catalogo de modulos';
          _carregando = false;
        });
        return;
      }

      final bodyCatalogo = jsonDecode(respCatalogo.body);
      final dadosCatalogo = (bodyCatalogo['data']?['dados'] ??
          bodyCatalogo['data'] ??
          []) as List<dynamic>;
      final porNome = <String, _ModuloCatalogo>{};
      for (final item in dadosCatalogo) {
        final id = item['id'] as int?;
        final nome = item['nome'] as String?;
        if (id == null || nome == null) continue;
        final existente = porNome[nome];
        if (existente == null || id < existente.id) {
          porNome[nome] = _ModuloCatalogo(
            id: id,
            nome: nome,
            descricao: item['descricao'] as String?,
          );
        }
      }

      final marcados = <int>{};
      final valores = <int, double>{};
      if (respVinculados.statusCode == 200) {
        final bodyVinculados = jsonDecode(respVinculados.body);
        final dadosVinculados = bodyVinculados is List
            ? bodyVinculados
            : (bodyVinculados['data'] ?? bodyVinculados['content'] ?? [])
                as List<dynamic>;
        for (final item in dadosVinculados) {
          final nome = item['nome'] as String?;
          if (nome == null) continue;
          final modulo = porNome[nome];
          if (modulo == null) continue;
          marcados.add(modulo.id);
          valores[modulo.id] = (item['valor'] as num?)?.toDouble() ?? 0;
        }
      }

      setState(() {
        _catalogo = porNome.values.toList()
          ..sort((a, b) => a.nome.compareTo(b.nome));
        _modulosMarcados = marcados;
        _valoresPorModulo = valores;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erroCarregamento = 'Erro de conexao: $e';
        _carregando = false;
      });
    }
  }

  Future<void> _salvarModulos() async {
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

    if (!mounted) return;
    if (resp.statusCode == 200) {
      widget.onModulosChanged?.call(_modulosMarcados.toList());
      await _carregarModulos();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erro ao salvar modulos: ${resp.statusCode}')),
    );
  }

  Future<void> _toggleModulo(int moduloId, bool marcado) async {
    if (!_podeEditarModulos) return;
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

    final modulosVisiveis = _podeEditarModulos
        ? _catalogo
        : _catalogo.where((m) => _modulosMarcados.contains(m.id)).toList();
    final total = modulosVisiveis
        .where((m) => _modulosMarcados.contains(m.id))
        .fold<double>(0, (sum, m) => sum + (_valoresPorModulo[m.id] ?? 0));

    if (modulosVisiveis.isEmpty) {
      return const Center(child: Text('Nenhum modulo contratado'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Modulos de Cobranca',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        for (final modulo in modulosVisiveis)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            leading: _podeEditarModulos
                ? Checkbox(
                    value: _modulosMarcados.contains(modulo.id),
                    onChanged: (v) => _toggleModulo(modulo.id, v ?? false),
                  )
                : const Icon(
                    Icons.check_circle_outline,
                    color: GridColors.success,
                  ),
            title: Text(modulo.nome),
            subtitle: modulo.descricao != null ? Text(modulo.descricao!) : null,
            trailing: Text(
              'R\$ ${(_valoresPorModulo[modulo.id] ?? 0).toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        const Divider(height: 32),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Total: R\$ ${total.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
