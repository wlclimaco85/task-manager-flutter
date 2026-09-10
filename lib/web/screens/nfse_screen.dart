import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_windows_screen.dart';
import '../../services/nfse_caller.dart';
import '../../utils/grid_colors.dart';
import '../../widgets/searchable_dropdown.dart';
import 'details/nfse_detail_screen.dart';

/// Tela de NFSe — espelha o layout da NF-e Saída:
/// header vermelho + painel de filtro lateral + botões + grid dinâmica.
class NfseScreen extends StatefulWidget {
  const NfseScreen({super.key});
  @override
  State<NfseScreen> createState() => _NfseScreenState();
}

class _NfseScreenState extends State<NfseScreen> {
  final NfseCaller _caller = NfseCaller();

  // Filtros
  final _numeroCtrl = TextEditingController();
  final _tomadorCtrl = TextEditingController();
  String? _statusFiltro;
  DateTime? _dtEmiIni, _dtEmiFim;
  Map<String, dynamic> _filtros = {};
  int _gridKey = 0;

  // Emissão (dialog)
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

  // Consulta (dialog)
  final _consultaCtrl = TextEditingController();
  bool _consultando = false;
  Map<String, dynamic>? _resultadoConsulta;
  String? _erroConsulta;

  // Cancelamento (dialog)
  final _cancelNumeroCtrl = TextEditingController();
  final _cancelMotivoCtrl = TextEditingController();
  bool _cancelando = false;
  String? _resultadoCancelamento;

  // Auditoria (dialog)
  List<Map<String, dynamic>> _logs = [];
  bool _carregandoLogs = false;

  @override
  void initState() {
    super.initState();
    _aplicarFiltros();
  }

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _tomadorCtrl.dispose();
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

  // ── Filtros ───────────────────────────────────────────────────────────────

  void _aplicarFiltros() {
    final f = <String, dynamic>{};
    if (_numeroCtrl.text.isNotEmpty) f['numero'] = _numeroCtrl.text;
    if (_tomadorCtrl.text.isNotEmpty) f['tomador'] = _tomadorCtrl.text;
    if (_statusFiltro != null) f['status'] = _statusFiltro!;
    if (_dtEmiIni != null) {
      f['dataEmissaoInicio'] = _dtEmiIni!.toIso8601String().substring(0, 10);
    }
    if (_dtEmiFim != null) {
      f['dataEmissaoFim'] = _dtEmiFim!.toIso8601String().substring(0, 10);
    }
    setState(() {
      _filtros = f;
      _gridKey++;
    });
  }

  void _limpar() {
    _numeroCtrl.clear();
    _tomadorCtrl.clear();
    _statusFiltro = null;
    _dtEmiIni = null;
    _dtEmiFim = null;
    _aplicarFiltros();
  }

  void _abrirNovo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NfseDetailScreen(item: {})),
    ).then((_) => _aplicarFiltros());
  }

  // ── Ações (mesmas do painel anterior, mantidas como dialogs) ─────────────

  Future<void> _emitir() async {
    setState(() {
      _emitindo = true;
      _resultadoEmissao = null;
    });
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
    setState(() {
      _consultando = true;
      _resultadoConsulta = null;
      _erroConsulta = null;
    });
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
    setState(() {
      _cancelando = true;
      _resultadoCancelamento = null;
    });
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
    ).then((_) => setState(() => _resultadoEmissao = null));
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
    ).then((_) => setState(() {
          _resultadoConsulta = null;
          _erroConsulta = null;
        }));
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
    ).then((_) => setState(() => _resultadoCancelamento = null));
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Header ────────────────────────────────────────────────────────
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
        // ── Conteúdo: filtros laterais + grid ─────────────────────────────
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 200, child: _buildFiltros()),
              Expanded(
                child: DynamicGridWindowsScreen<Map<String, dynamic>>(
                  key: ValueKey(_gridKey),
                  telaNome: 'nfse',
                  hasPermission: (p) => p == 'create' ? false : true,
                  fromJson: (json) => json,
                  toJson: (a) => a,
                  extraParams: _filtros,
                  detailScreenBuilder: (item) => NfseDetailScreen(item: item),
                  showAppBar: false,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFiltros() {
    return Container(
      color: GridColors.filterBackground,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _lbl('Data de Emissão'),
          _dateRange(
              _dtEmiIni,
              _dtEmiFim,
              (s, e) => setState(() {
                    _dtEmiIni = s;
                    _dtEmiFim = e;
                  })),
          const SizedBox(height: 8),
          _lbl('Número da NFSe'),
          _inp(_numeroCtrl, 'Nro. NFSe'),
          const SizedBox(height: 8),
          _lbl('Tomador / Parceiro'),
          _inp(_tomadorCtrl, 'Nome do tomador'),
          const SizedBox(height: 8),
          _lbl('Status'),
          _drop(
              _statusFiltro,
              ['PENDENTE', 'AUTORIZADA', 'CANCELADA', 'REJEITADA'],
              (v) => setState(() => _statusFiltro = v)),
          const SizedBox(height: 12),
          SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _abrirNovo(context),
                icon: const Icon(Icons.add, size: 14),
                label:
                    const Text('+ Nova NFSe', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8)),
              )),
          const SizedBox(height: 6),
          SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _aplicarFiltros,
                icon: const Icon(Icons.search, size: 14),
                label: const Text('Filtrar', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8)),
              )),
          const SizedBox(height: 6),
          SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _limpar,
                icon: const Icon(Icons.clear, size: 14),
                label: const Text('Limpar', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                    foregroundColor: GridColors.divider,
                    padding: const EdgeInsets.symmetric(vertical: 8)),
              )),
          const Divider(height: 24),
          _lbl('Ações rápidas'),
          const SizedBox(height: 4),
          SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showEmissaoDialog,
                icon: const Icon(Icons.send, size: 14),
                label: const Text('Emitir NFSe', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8)),
              )),
          const SizedBox(height: 6),
          SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showConsultaDialog,
                icon: const Icon(Icons.search, size: 14),
                label: const Text('Consultar', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8)),
              )),
          const SizedBox(height: 6),
          SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showCancelamentoDialog,
                icon: const Icon(Icons.cancel_outlined, size: 14),
                label:
                    const Text('Cancelar NFSe', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8)),
              )),
          const SizedBox(height: 6),
          SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showAuditoriaDialog,
                icon: const Icon(Icons.history, size: 14),
                label: const Text('Auditoria', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8)),
              )),
        ]),
      ),
    );
  }

  Widget _lbl(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(t,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: GridColors.textSecondary)));

  Widget _inp(TextEditingController c, String h) => TextField(
      controller: c,
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
          hintText: h,
          hintStyle: const TextStyle(fontSize: 11, color: GridColors.divider),
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: GridColors.divider)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: GridColors.divider))));

  Widget _drop(String? val, List<String> opts, void Function(String?) cb) =>
      SearchableDropdownField(
        label: '',
        value: val,
        items: opts.map((o) => <String, dynamic>{'id': o, 'nome': o}).toList(),
        valueField: 'id',
        displayField: 'nome',
        nullable: true,
        nullLabel: 'Todos',
        hintText: 'Todos',
        onChanged: cb,
      );

  Widget _dateRange(DateTime? ini, DateTime? fim,
          void Function(DateTime?, DateTime?) cb) =>
      Row(children: [
        Expanded(child: _dp(ini, 'Início', (d) => cb(d, fim))),
        const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text('a', style: TextStyle(fontSize: 11))),
        Expanded(child: _dp(fim, 'Fim', (d) => cb(ini, d))),
      ]);

  Widget _dp(DateTime? val, String hint, void Function(DateTime?) cb) =>
      GestureDetector(
        onTap: () async {
          final d = await showDatePicker(
              context: context,
              initialDate: val ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030));
          cb(d);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: GridColors.divider),
          ),
          child: Row(children: [
            const Icon(Icons.calendar_today,
                size: 10, color: GridColors.divider),
            const SizedBox(width: 3),
            Text(
              val != null
                  ? '${val.day.toString().padLeft(2, '0')}/${val.month.toString().padLeft(2, '0')}'
                  : hint,
              style: TextStyle(
                fontSize: 10,
                color:
                    val != null ? GridColors.textSecondary : GridColors.divider,
              ),
            ),
          ]),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialogs internos (mantidos do painel anterior)
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
