import 'package:flutter/material.dart';
import '../../services/nfse_caller.dart';

class NfseScreen extends StatefulWidget {
  const NfseScreen({super.key});
  @override
  State<NfseScreen> createState() => _NfseScreenState();
}

class _NfseScreenState extends State<NfseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
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
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 3) _carregarAuditoria();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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
          _resultadoEmissao = '''
NFSe emitida com sucesso!
Número: ${result['numero'] ?? result['nfseNumber'] ?? '-'}
Protocolo: ${result['protocolo'] ?? result['protocol'] ?? '-'}
Status: ${result['status'] ?? result['situacao'] ?? '-'}
Chave: ${result['chave'] ?? '-'}
''';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _resultadoEmissao = 'Erro: $e');
      }
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
      if (mounted) {
        setState(() => _resultadoCancelamento = 'Erro: $e');
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NFSe - Nota Fiscal de Serviços'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Emissão'),
            Tab(text: 'Consulta'),
            Tab(text: 'Cancelamento'),
            Tab(text: 'Auditoria'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEmissaoTab(),
          _buildConsultaTab(),
          _buildCancelamentoTab(),
          _buildAuditoriaTab(),
        ],
      ),
    );
  }

  Widget _buildEmissaoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _campo('Município', _municipioCtrl),
          _campo('CNPJ Tomador', _cnpjCtrl),
          _campo('Nome Tomador', _nomeCtrl),
          _campo('Descrição do Serviço', _descricaoCtrl),
          _campo('Valor', _valorCtrl, teclado: TextInputType.number),
          _campo('Alíquota ISS', _aliquotaCtrl, teclado: TextInputType.number),
          _campo('CNAE', _cnaeCtrl),
          _campo('Código Tributação', _codigoTribCtrl),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _emitindo ? null : _emitir,
              icon: _emitindo
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(_emitindo ? 'Emitindo...' : 'Emitir NFSe'),
            ),
          ),
          if (_resultadoEmissao != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _resultadoEmissao!.startsWith('Erro')
                    ? Colors.red.shade50
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_resultadoEmissao!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConsultaTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _consultaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Número NFSe',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _consultando ? null : _consultar,
                icon: _consultando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: Text(_consultando ? 'Consultando...' : 'Consultar'),
              ),
            ],
          ),
          if (_erroConsulta != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_erroConsulta!),
              ),
            ),
          if (_resultadoConsulta != null) ...[
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: _resultadoConsulta!.entries.map((e) {
                  return ListTile(
                    title: Text('${e.key}:'),
                    trailing: Text('${e.value}'),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCancelamentoTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _cancelNumeroCtrl,
            decoration: const InputDecoration(
              labelText: 'Número NFSe',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cancelMotivoCtrl,
            decoration: const InputDecoration(
              labelText: 'Motivo do Cancelamento',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _cancelando ? null : _cancelar,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              icon: _cancelando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cancel),
              label: Text(_cancelando ? 'Cancelando...' : 'Cancelar NFSe'),
            ),
          ),
          if (_resultadoCancelamento != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _resultadoCancelamento!.startsWith('Erro')
                    ? Colors.red.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_resultadoCancelamento!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAuditoriaTab() {
    if (_carregandoLogs) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_logs.isEmpty) {
      return const Center(child: Text('Nenhum log de auditoria encontrado.'));
    }
    return RefreshIndicator(
      onRefresh: _carregarAuditoria,
      child: ListView.builder(
        itemCount: _logs.length,
        itemBuilder: (_, i) {
          final log = _logs[i];
          final data = log['data'] ?? log['createdAt'] ?? log['timestamp'] ?? '';
          final acao =
              log['acao'] ?? log['operacao'] ?? log['tipo'] ?? log['evento'] ?? '';
          final desc = log['descricao'] ?? log['detalhe'] ?? log['mensagem'] ?? '';
          return ListTile(
            leading: const Icon(Icons.history),
            title: Text('$acao'),
            subtitle: Text('$data - $desc'),
            isThreeLine: true,
          );
        },
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
        ),
      ),
    );
  }
}
