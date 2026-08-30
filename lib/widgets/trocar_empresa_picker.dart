import 'package:flutter/material.dart';

import '../services/login_empresa_acesso_caller.dart';
import '../utils/grid_colors.dart';

/// Picker simples (dropdown, NAO multi-select — escopo minimo do
/// RESEARCH.md) exibido pos-login quando o usuario tem acesso APROVADO a
/// mais de 1 empresa, e reaproveitado pelo botao "Trocar Empresa" do menu
/// principal (fora do login inicial).
class TrocarEmpresaPicker extends StatefulWidget {
  final List<EmpresaAcessoOption> empresas;
  final int? empresaAtualId;

  const TrocarEmpresaPicker({
    super.key,
    required this.empresas,
    this.empresaAtualId,
  });

  /// So abre o dialogo quando ha de fato mais de 1 empresa aprovada — se
  /// houver <=1, o comportamento existente (ir direto para home) e
  /// preservado e esta funcao retorna null sem exibir nada.
  static Future<int?> mostrarSeNecessario(
    BuildContext context,
    List<EmpresaAcessoOption> empresas, {
    int? empresaAtualId,
  }) async {
    if (empresas.length <= 1) return null;
    return showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (_) => TrocarEmpresaPicker(
        empresas: empresas,
        empresaAtualId: empresaAtualId,
      ),
    );
  }

  @override
  State<TrocarEmpresaPicker> createState() => _TrocarEmpresaPickerState();
}

class _TrocarEmpresaPickerState extends State<TrocarEmpresaPicker> {
  int? _selecionadoId;
  bool _trocando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _selecionadoId = widget.empresaAtualId ??
        (widget.empresas.isNotEmpty ? widget.empresas.first.empresaId : null);
  }

  Future<void> _confirmar() async {
    final selecionado = _selecionadoId;
    if (selecionado == null) return;
    if (selecionado == widget.empresaAtualId) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _trocando = true;
      _erro = null;
    });
    final resultado =
        await LoginEmpresaAcessoCaller.trocarEmpresaAtiva(selecionado);
    if (!mounted) return;
    if (resultado.sucesso) {
      Navigator.of(context).pop(selecionado);
    } else {
      setState(() {
        _trocando = false;
        _erro = resultado.mensagemErro ??
            'Erro ao trocar de empresa. Tente novamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: [
          const Icon(Icons.apartment, color: GridColors.secondary),
          const SizedBox(width: 8),
          const Text('Trocar Empresa'),
        ],
      ),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecione a empresa que deseja acessar:',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            if (_erro != null)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(_erro!,
                    style:
                        TextStyle(color: Colors.red.shade700, fontSize: 12)),
              ),
            DropdownButtonFormField<int>(
              key: const Key('trocar_empresa_dropdown'),
              initialValue: _selecionadoId,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: widget.empresas
                  .map((e) => DropdownMenuItem<int>(
                        value: e.empresaId,
                        child: Text(e.nome, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: _trocando
                  ? null
                  : (v) => setState(() => _selecionadoId = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _trocando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _trocando ? null : _confirmar,
          child: _trocando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Acessar'),
        ),
      ],
    );
  }
}
