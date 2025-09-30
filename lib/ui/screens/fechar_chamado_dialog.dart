// fechar_chamado_dialog.dart
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/services/chamado_caller.dart';
import 'package:task_manager_flutter/data/models/chamado_model.dart';

class FecharChamadoDialog extends StatefulWidget {
  final int chamadoId;
  final Chamado? chamado;

  const FecharChamadoDialog({super.key, required this.chamadoId, this.chamado});

  @override
  _FecharChamadoDialogState createState() => _FecharChamadoDialogState();
}

class _FecharChamadoDialogState extends State<FecharChamadoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _solucaoController = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Fechar Chamado'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _solucaoController,
              decoration: InputDecoration(
                labelText: 'Solução',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, informe a solução';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            if (_loading) CircularProgressIndicator(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _fecharChamado,
          child: Text('Fechar Chamado'),
        ),
      ],
    );
  }

  void _fecharChamado() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _loading = true);

      try {
        final response = await ChamadoCaller().fecharChamado(
          ApiLinks.fecharChamados(widget.chamadoId),
          _solucaoController.text,
          widget.chamado, // 👈 aqui o ajuste
        );

        if (!response.isEmpty) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Chamado fechado com sucesso!')),
          );
        } else {
          throw Exception('Erro ao fechar chamado');
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      } finally {
        setState(() => _loading = false);
      }
    }
  }
}
