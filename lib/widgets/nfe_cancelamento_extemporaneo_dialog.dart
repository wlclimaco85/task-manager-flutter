import 'package:flutter/material.dart';

import '../utils/api_links.dart';
import '../utils/app_logger.dart';
import '../utils/fiscal_error_message.dart';
import '../utils/grid_colors.dart';
import '../utils/tenant_context.dart';

/// Mensagem de erro do cancelamento extemporâneo; cStat 501 = a SEFAZ ainda não liberou o prazo.
String erroCancelamentoExtemporaneo(int status, String body) {
  final mensagem = fiscalErrorMessage(status, body);
  final semLiberacao = body.contains('501') || body.toLowerCase().contains('prazo de cancelamento');
  return semLiberacao
      ? '$mensagem\nSolicite a liberação no portal da SEFAZ do emitente e transmita novamente.'
      : mensagem;
}

/// Abre o cancelamento extemporâneo (fora do prazo) da NF-e. Devolve true quando a SEFAZ homologou.
Future<bool> cancelarNfeExtemporaneo(BuildContext context, String nfeId, {String numero = ''}) async {
  final cancelada = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => NfeCancelamentoExtemporaneoDialog(nfeId: nfeId, numero: numero),
  );
  return cancelada ?? false;
}

class NfeCancelamentoExtemporaneoDialog extends StatefulWidget {
  final String nfeId;
  final String numero;

  const NfeCancelamentoExtemporaneoDialog({super.key, required this.nfeId, this.numero = ''});

  @override
  State<NfeCancelamentoExtemporaneoDialog> createState() => _NfeCancelamentoExtemporaneoDialogState();
}

class _NfeCancelamentoExtemporaneoDialogState extends State<NfeCancelamentoExtemporaneoDialog> {
  final _motivo = TextEditingController();
  bool _liberado = false;
  bool _enviando = false;
  String? _erro;

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  Future<void> _transmitir() async {
    final motivo = _motivo.text.trim();
    if (motivo.length < 15 || motivo.length > 255) {
      setState(() => _erro = 'A justificativa deve ter de 15 a 255 caracteres.');
      return;
    }
    setState(() {
      _enviando = true;
      _erro = null;
    });
    String erro;
    try {
      final r = await TenantContext.post(
          ApiLinks.cancelarNfe(widget.nfeId), {'justificativa': motivo, 'extemporaneo': true});
      if (!mounted) return;
      if (r.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('NF-e cancelada fora do prazo e homologada pela SEFAZ.'),
            backgroundColor: GridColors.success));
        Navigator.pop(context, true);
        return;
      }
      erro = erroCancelamentoExtemporaneo(r.statusCode, r.body);
      AppLogger.i.warn('Cancelamento extemporâneo da NF-e #${widget.nfeId}: ${r.statusCode} - ${r.body}');
    } catch (e, st) {
      AppLogger.i.error('Cancelamento extemporâneo da NF-e #${widget.nfeId}: $e', st);
      erro = 'Não foi possível confirmar o cancelamento. Consulte a situação da nota na SEFAZ antes de tentar de novo.';
    }
    if (!mounted) return;
    setState(() {
      _enviando = false;
      _erro = erro;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancelamento extemporâneo',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('NF-e #${widget.nfeId}${widget.numero.isEmpty ? '' : ' — número ${widget.numero}'}',
                style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 10),
            const Text(
              'Use quando passaram mais de 24 horas da autorização.\n\n'
              '1. Antes de transmitir, peça a liberação na SEFAZ do emitente. Em MG: SIARE > NF-e > '
              'Solicitar Cancelamento Extemporâneo (informe a chave de acesso e o motivo da perda do prazo). '
              'Depois do protocolo do SIARE, o prazo para transmitir é de 30 dias.\n'
              '2. Só cabe se a operação não aconteceu (em regra, a mercadoria não saiu).\n'
              '3. Pode haver multa; em MG, após 168 horas da autorização há penalidade.\n\n'
              'Prazo e procedimento mudam conforme o estado. Se a SEFAZ não aceitar o cancelamento, '
              'confirme com o contador a emissão de uma NF-e de estorno.',
              style: TextStyle(fontSize: 12),
            ),
            CheckboxListTile(
              key: const Key('extemporaneo-liberado'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _liberado,
              onChanged: _enviando ? null : (v) => setState(() => _liberado = v ?? false),
              title: const Text('Já verifiquei a regra da SEFAZ e a liberação exigida no meu estado',
                  style: TextStyle(fontSize: 12)),
            ),
            TextField(
              key: const Key('extemporaneo-motivo'),
              controller: _motivo,
              enabled: !_enviando,
              maxLines: 3,
              maxLength: 255,
              decoration: const InputDecoration(
                  labelText: 'Justificativa *', hintText: 'Mínimo 15 caracteres', border: OutlineInputBorder()),
            ),
            if (_erro != null) Text(_erro!, style: const TextStyle(fontSize: 12, color: GridColors.error)),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: _enviando ? null : () => Navigator.pop(context, false), child: const Text('Voltar')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: GridColors.error, foregroundColor: Colors.white),
          onPressed: _liberado && !_enviando ? _transmitir : null,
          child: Text(_enviando ? 'Transmitindo...' : 'Transmitir cancelamento'),
        ),
      ],
    );
  }
}
