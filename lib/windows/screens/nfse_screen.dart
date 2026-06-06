import 'package:flutter/material.dart';
import '../../services/nfse_caller.dart';
import '../../utils/grid_colors.dart';

class NfseScreen extends StatefulWidget {
  const NfseScreen({super.key});
  @override
  State<NfseScreen> createState() => _NfseScreenState();
}

class _NfseScreenState extends State<NfseScreen> {
  final NfseCaller _caller = NfseCaller();

  // Emissão
  final _municipioCtrl = TextEditingController();
  final _cnpjCtrl = TextEditingController();
  final _nomeCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  final _aliquotaCtrl = TextEditingController();
  final _cnaeCtrl = TextEditingController();
  final _codigoTribCtrl = TextEditingController();
  bool _emitindo = false;
  String? _resultadoEmissao;

  // Consulta
  final _consultaCtrl = TextEditingController();
  bool _consultando = false;
  Map<String, dynamic>? _resultadoConsulta;
  String? _erroConsulta;

  // Cancelamento
  final _cancelNumeroCtrl = TextEditingController();
  final _cancelMotivoCtrl = TextEditingController();
  bool _cancelando = false;
  String? _resultadoCancelamento;

  // Auditoria
  List<Map<String, dynamic>> _logs = [];
  bool _carregandoLogs = false;

  @override
  void dispose() {
    _municipioCtrl.dispose();
    _cnpjCtrl.dispose();
    _nomeCtrl.dispose();
    _descricaoCtrl.dispose();
    _valorCtrl.dispose();
    _aliquotaCtrl.dispose();
    _cnaeCtrl.dispose();
    _codigoTribCtrl.dispose();
    _consultaCtrl.dispose();
    _cancelNumeroCtrl.dispose();
    _cancelMotivoCtrl.dispose();
    super.dispose();
  }

  Future<void> _emitir() async {
    setState(() { _emitindo = true; _resultadoEmissao = null; });
    try {
      final result = await _caller.emitir(
        municipio: _municipioCtrl.text,
        cnpjTomador: _cnpjCtrl.text,
        nomeTomador: _nomeCtrl.text,
        descricaoServico: _descricaoCtrl.text,
        valor: double.parse(_valorCtrl.text),
        aliquotaIss: double.parse(_aliquotaCtrl.text),
        cnae: _cnaeCtrl.text,
        codigoTributacao: _codigoTribCtrl.text,
      );
      if (mounted) {
        setState(() {
          _resultadoEmissao = 'NFSe emitida!\n'
              'Número: ${result['numero'] ?? result['nfseNumber'] ?? '-'}\n'
              'Protocolo: ${result['protocolo'] ?? result['protocol'] ?? '-'}\n'
              'Status: ${result['status'] ?? result['situacao'] ?? '-'}\n'
              'Chave: ${result['chave'] ?? '-'}';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _resultadoEmissao = 'Erro: $e');
    } finally {
      if (mounted) setState(() => _emitindo = false);
    }
  }

  Future<void> _consultar() async {
    setState(() { _consultando = true; _resultadoConsulta = null; _erroConsulta = null; });
    try {
      final result = await _caller.consultar(_consultaCtrl.text);
      if (mounted) setState(() => _resultadoConsulta = result);
    } catch (e) {
      if (mounted) setState(() => _erroConsulta = e.toString());
    } finally {
      if (mounted) setState(() => _consultando = false);
    }
  }

  Future<void> _cancelar() async {
    setState(() { _cancelando = true; _resultadoCancelamento = null; });
    try {
      final result = await _caller.cancelar(
        numero: _cancelNumeroCtrl.text,
        motivo: _cancelMotivoCtrl.text,
      );
      if (mounted) {
        setState(() {
          _resultadoCancelamento =
              'Cancelamento: ${result['status'] ?? result['mensagem'] ?? 'OK'}';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _resultadoCancelamento = 'Erro: $e');
    } finally {
      if (mounted) setState(() => _cancelando = false);
    }
  }

  Future<void> _carregarAuditoria() async {
    setState(() => _carregandoLogs = true);
    try {
      final logs = await _caller.auditoria();
      if (mounted) setState(() => _logs = logs);
    } catch (_) {
      if (mounted) setState(() => _logs = []);
    } finally {
      if (mounted) setState(() => _carregandoLogs = false);
    }
  }

  void _showEmissaoDialog() {
    showDialog(
      context: context,
      builder: (_) => _EmissaoDialog(
        municipioCtrl: _municipioCtrl,
        cnpjCtrl: _cnpjCtrl,
        nomeCtrl: _nomeCtrl,
        descricaoCtrl: _descricaoCtrl,
        valorCtrl: _valorCtrl,
        aliquotaCtrl: _aliquotaCtrl,
        cnaeCtrl: _cnaeCtrl,
        codigoTribCtrl: _codigoTribCtrl,
        emitindo: _emitindo,
        resultado: _resultadoEmissao,
        onEmitir: _emitir,
      ),
    ).then((_) => setState(() { _resultadoEmissao = null; }));
  }

  void _showConsultaDialog() {
    showDialog(
      context: context,
      builder: (_) => _ConsultaDialog(
        ctrl: _consultaCtrl,
        consultando: _consultando,
        resultado: _resultadoConsulta,
        erro: _erroConsulta,
        onConsultar: _consultar,
      ),
    ).then((_) => setState(() { _resultadoConsulta = null; _erroConsulta = null; }));
  }

  void _showCancelamentoDialog() {
    showDialog(
      context: context,
      builder: (_) => _CancelamentoDialog(
        numeroCtrl: _cancelNumeroCtrl,
        motivoCtrl: _cancelMotivoCtrl,
        cancelando: _cancelando,
        resultado: _resultadoCancelamento,
        onCancelar: _cancelar,
      ),
    ).then((_) => setState(() { _resultadoCancelamento = null; }));
  }

  void _showAuditoriaDialog() {
    _carregarAuditoria();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _AuditoriaDialog(
        logs: _logs,
        carregando: _carregandoLogs,
        onRefresh: _carregarAuditoria,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Container(
          height: 56,
          color: GridColors.error,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: const Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                'NFSe - Nota Fiscal de Serviços',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        // ── Botões de ação ────────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _actionButton(
                icon: Icons.send,
                label: 'Emitir NFSe',
                color: GridColors.primary,
                onTap: _showEmissaoDialog,
              ),
              _actionButton(
                icon: Icons.search,
                label: 'Consultar',
                color: GridColors.secondary,
                onTap: _showConsultaDialog,
              ),
              _actionButton(
                icon: Icons.cancel_outlined,
                label: 'Cancelar NFSe',
                color: GridColors.error,
                onTap: _showCancelamentoDialog,
              ),
              _actionButton(
                icon: Icons.history,
                label: 'Auditoria',
                color: Colors.grey.shade700,
                onTap: _showAuditoriaDialog,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // ── Área principal: informativo / log rápido ─────────────────────
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'Selecione uma ação acima para emitir,\nconsultar ou cancelar NFSe.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialogs internos
// ─────────────────────────────────────────────────────────────────────────────

class _EmissaoDialog extends StatelessWidget {
  final TextEditingController municipioCtrl, cnpjCtrl, nomeCtrl,
      descricaoCtrl, valorCtrl, aliquotaCtrl, cnaeCtrl, codigoTribCtrl;
  final bool emitindo;
  final String? resultado;
  final VoidCallback onEmitir;

  const _EmissaoDialog({
    required this.municipioCtrl,
    required this.cnpjCtrl,
    required this.nomeCtrl,
    required this.descricaoCtrl,
    required this.valorCtrl,
    required this.aliquotaCtrl,
    required this.cnaeCtrl,
    required this.codigoTribCtrl,
    required this.emitindo,
    required this.resultado,
    required this.onEmitir,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Emitir NFSe',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _campo('Município', municipioCtrl),
              _campo('CNPJ Tomador', cnpjCtrl),
              _campo('Nome Tomador', nomeCtrl),
              _campo('Descrição do Serviço', descricaoCtrl),
              Row(children: [
                Expanded(child: _campo('Valor', valorCtrl, teclado: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: _campo('Alíquota ISS', aliquotaCtrl, teclado: TextInputType.number)),
              ]),
              Row(children: [
                Expanded(child: _campo('CNAE', cnaeCtrl)),
                const SizedBox(width: 12),
                Expanded(child: _campo('Cód. Tributação', codigoTribCtrl)),
              ]),
              if (resultado != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: resultado!.startsWith('Erro')
                        ? Colors.red.shade50
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: resultado!.startsWith('Erro')
                          ? Colors.red.shade200
                          : Colors.green.shade200,
                    ),
                  ),
                  child: Text(resultado!, style: const TextStyle(fontSize: 13)),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fechar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: emitindo ? null : onEmitir,
                    icon: emitindo
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send, size: 18),
                    label: Text(emitindo ? 'Emitindo...' : 'Emitir'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: GridColors.primary,
                        foregroundColor: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campo(String label, TextEditingController ctrl,
      {TextInputType? teclado}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: teclado,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }
}

class _ConsultaDialog extends StatelessWidget {
  final TextEditingController ctrl;
  final bool consultando;
  final Map<String, dynamic>? resultado;
  final String? erro;
  final VoidCallback onConsultar;

  const _ConsultaDialog({
    required this.ctrl,
    required this.consultando,
    required this.resultado,
    required this.erro,
    required this.onConsultar,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 480,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Consultar NFSe',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      decoration: const InputDecoration(
                        labelText: 'Número NFSe',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: consultando ? null : onConsultar,
                    icon: consultando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.search, size: 18),
                    label: Text(consultando ? 'Consultando...' : 'Consultar'),
                  ),
                ],
              ),
              if (erro != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(erro!, style: const TextStyle(color: Colors.red)),
                ),
              ],
              if (resultado != null) ...[
                const SizedBox(height: 12),
                ...resultado!.entries.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Text('${e.key}: ',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          Text('${e.value}',
                              style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    )),
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fechar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CancelamentoDialog extends StatelessWidget {
  final TextEditingController numeroCtrl, motivoCtrl;
  final bool cancelando;
  final String? resultado;
  final VoidCallback onCancelar;

  const _CancelamentoDialog({
    required this.numeroCtrl,
    required this.motivoCtrl,
    required this.cancelando,
    required this.resultado,
    required this.onCancelar,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 440,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cancelar NFSe',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red)),
              const SizedBox(height: 20),
              TextField(
                controller: numeroCtrl,
                decoration: const InputDecoration(
                  labelText: 'Número NFSe',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: motivoCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Motivo do Cancelamento',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              if (resultado != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: resultado!.startsWith('Erro')
                        ? Colors.red.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(resultado!, style: const TextStyle(fontSize: 13)),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fechar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: cancelando ? null : onCancelar,
                    icon: cancelando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.cancel, size: 18),
                    label: Text(cancelando ? 'Cancelando...' : 'Cancelar NFSe'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuditoriaDialog extends StatelessWidget {
  final List<Map<String, dynamic>> logs;
  final bool carregando;
  final Future<void> Function() onRefresh;

  const _AuditoriaDialog({
    required this.logs,
    required this.carregando,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 600,
        height: 480,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4))),
              child: Row(
                children: [
                  const Icon(Icons.history, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Auditoria NFSe',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: onRefresh,
                    tooltip: 'Atualizar',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: carregando
                  ? const Center(child: CircularProgressIndicator())
                  : logs.isEmpty
                      ? const Center(
                          child: Text('Nenhum log de auditoria encontrado.'))
                      : ListView.separated(
                          itemCount: logs.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final log = logs[i];
                            final data = log['data'] ??
                                log['createdAt'] ??
                                log['timestamp'] ??
                                '';
                            final acao = log['acao'] ??
                                log['operacao'] ??
                                log['tipo'] ??
                                log['evento'] ??
                                '';
                            final desc = log['descricao'] ??
                                log['detalhe'] ??
                                log['mensagem'] ??
                                '';
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.history, size: 18),
                              title: Text('$acao',
                                  style: const TextStyle(fontSize: 13)),
                              subtitle: Text('$data — $desc',
                                  style: const TextStyle(fontSize: 12)),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
