import 'package:flutter/material.dart';

import '../services/menu_publicado_service.dart';
import '../utils/app_logger.dart';

/// Modelo, consulta e titulo escolhidos para a tela herdar de um modelo de planilha.
class PedidoTelaDeModelo {
  final int modeloId;
  final int fonte;
  final String titulo;

  const PedidoTelaDeModelo(this.modeloId, this.fonte, this.titulo);
}

class TelaDeModeloDialog extends StatefulWidget {
  final MenuPublicadoService? servico;

  const TelaDeModeloDialog({super.key, this.servico});

  @override
  State<TelaDeModeloDialog> createState() => _TelaDeModeloDialogState();
}

class _TelaDeModeloDialogState extends State<TelaDeModeloDialog> {
  late final MenuPublicadoService _svc = widget.servico ?? MenuPublicadoService();
  final _titulo = TextEditingController();
  List<ModeloPlanilha>? _modelos;
  ModeloPlanilha? _modelo;
  int? _id;
  int _fonte = 0;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _listar();
  }

  @override
  void dispose() {
    _titulo.dispose();
    super.dispose();
  }

  Future<void> _listar() async {
    try {
      final lista = await _svc.modelos();
      if (mounted) setState(() => _modelos = lista);
    } catch (e) {
      AppLogger.i.warn('TelaDeModeloDialog: erro ao listar modelos: $e');
      if (mounted) {
        setState(() {
          _modelos = const [];
          _erro = '$e';
        });
      }
    }
  }

  Future<void> _escolher(int id) async {
    setState(() {
      _id = id;
      _modelo = null;
      _fonte = 0;
      _erro = null;
    });
    try {
      final m = await _svc.modelo(id);
      if (!mounted || _id != id) return;
      setState(() {
        _modelo = m;
        if (_titulo.text.trim().isEmpty) _titulo.text = m.titulo;
        if (m.fontes.isEmpty) {
          _erro = 'Este modelo não busca dados por SELECT. Use "A partir de planilha".';
        }
      });
    } catch (e) {
      AppLogger.i.warn('TelaDeModeloDialog: erro ao abrir modelo $id: $e');
      if (mounted) setState(() => _erro = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final modelos = _modelos;
    final m = _modelo;
    final pronto = m != null && m.fontes.isNotEmpty;
    return AlertDialog(
      title: const Text('Tela a partir de modelo de planilha'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('A tela usa a tabela da consulta, com as mesmas colunas, ordem e rótulos. '
                'Os filtros do SELECT não valem na tela: ela mostra todos os registros da empresa nessa tabela.'),
            const SizedBox(height: 12),
            if (modelos == null)
              const LinearProgressIndicator()
            else if (modelos.isEmpty)
              const Text('Nenhum modelo de planilha criado.')
            else
              DropdownButtonFormField<int>(
                initialValue: _id,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Modelo *'),
                items: [for (final i in modelos) DropdownMenuItem(value: i.id, child: Text(i.titulo))],
                onChanged: (v) {
                  if (v != null) _escolher(v);
                },
              ),
            if (_id != null && m == null && _erro == null) const LinearProgressIndicator(),
            if (pronto) ...[
              if (m.fontes.length > 1)
                DropdownButtonFormField<int>(
                  key: ValueKey('fonte-${m.id}'),
                  initialValue: _fonte,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Consulta'),
                  items: [
                    for (var i = 0; i < m.fontes.length; i++)
                      DropdownMenuItem(value: i, child: Text('Célula ${m.fontes[i].celula}')),
                  ],
                  onChanged: (v) => setState(() => _fonte = v ?? 0),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(m.fontes[_fonte].sql, style: const TextStyle(fontSize: 12)),
              ),
              TextField(
                controller: _titulo,
                maxLength: 150,
                decoration: const InputDecoration(labelText: 'Título da tela *'),
              ),
            ],
            if (_erro != null) Text(_erro!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: !pronto
              ? null
              : () {
                  final titulo = _titulo.text.trim();
                  if (titulo.isEmpty) {
                    setState(() => _erro = 'Informe o título da tela.');
                    return;
                  }
                  Navigator.pop(context, PedidoTelaDeModelo(m.id!, _fonte, titulo));
                },
          child: const Text('Criar'),
        ),
      ],
    );
  }
}
