import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../models/anexo_financeiro_model.dart';
import '../services/anexo_financeiro_service.dart';

class AnexoFinanceiroWidget extends StatefulWidget {
  final int lancamentoId;
  final String lancamentoTipo; // "PAGAR" ou "RECEBER"

  const AnexoFinanceiroWidget({
    super.key,
    required this.lancamentoId,
    required this.lancamentoTipo,
  });

  @override
  State<AnexoFinanceiroWidget> createState() => _AnexoFinanceiroWidgetState();
}

class _AnexoFinanceiroWidgetState extends State<AnexoFinanceiroWidget> {
  final _service = AnexoFinanceiroService();
  List<AnexoFinanceiro> _anexos = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() { _loading = true; _error = null; });
    try {
      _anexos = await _service.listar(widget.lancamentoId, widget.lancamentoTipo);
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _upload() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    setState(() { _loading = true; _error = null; });
    try {
      final novo = await _service.upload(widget.lancamentoId, widget.lancamentoTipo, file);
      setState(() { _anexos.add(novo); });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _baixar(AnexoFinanceiro anexo) async {
    if (anexo.id == null) return;
    setState(() { _loading = true; });
    try {
      final bytes = await _service.download(anexo.id!);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${anexo.fileName}');
      await file.writeAsBytes(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Salvo em ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _remover(AnexoFinanceiro anexo) async {
    if (anexo.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover anexo'),
        content: Text('Remover "${anexo.fileName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remover', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() { _loading = true; });
    try {
      await _service.remover(anexo.id!);
      setState(() { _anexos.removeWhere((a) => a.id == anexo.id); });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Comprovantes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Spacer(),
            TextButton.icon(
              onPressed: _loading ? null : _upload,
              icon: const Icon(Icons.attach_file, size: 18),
              label: const Text('Anexar'),
            ),
          ],
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          ),
        if (_anexos.isEmpty && !_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Nenhum comprovante anexado', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ..._anexos.map((a) => _AnexoTile(
          anexo: a,
          onDownload: () => _baixar(a),
          onRemove: () => _remover(a),
        )),
      ],
    );
  }
}

class _AnexoTile extends StatelessWidget {
  final AnexoFinanceiro anexo;
  final VoidCallback onDownload;
  final VoidCallback onRemove;

  const _AnexoTile({required this.anexo, required this.onDownload, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final icon = anexo.isPdf
        ? Icons.picture_as_pdf
        : anexo.isImage
            ? Icons.image
            : Icons.attach_file;
    final iconColor = anexo.isPdf ? Colors.red : anexo.isImage ? Colors.blue : Colors.grey;

    return ListTile(
      dense: true,
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(anexo.fileName, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
      subtitle: anexo.tamanhoBytes != null ? Text(anexo.tamanhoFormatado, style: const TextStyle(fontSize: 11)) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.download, size: 18), onPressed: onDownload, tooltip: 'Baixar'),
          IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), onPressed: onRemove, tooltip: 'Remover'),
        ],
      ),
    );
  }
}
