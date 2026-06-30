import 'package:flutter/material.dart';
import '../../../models/mensalidade_model.dart';

class WebBaixaDialogMensalidade extends StatelessWidget {
  final dynamic mensalidade;

  const WebBaixaDialogMensalidade({super.key, required this.mensalidade});

  Mensalidade? get _casted {
    if (mensalidade is Mensalidade) return mensalidade as Mensalidade;
    if (mensalidade is Map<String, dynamic>) {
      return Mensalidade.fromJson(mensalidade as Map<String, dynamic>);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final m = _casted;
    return AlertDialog(
      title: const Text('Confirmar Baixa'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (m != null) ...[
              if (m.id != null)
                Text('Mensalidade #${m.id}'),
              if (m.valor != null)
                Text('Valor: R\$${m.valor!.toStringAsFixed(2)}'),
              if (m.alunoId != null)
                Text('Aluno ID: ${m.alunoId}'),
            ] else
              const Text('Dados da mensalidade não disponíveis.'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Confirmar Baixa'),
        ),
      ],
    );
  }
}
