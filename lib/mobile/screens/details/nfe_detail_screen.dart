import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import '../../../../utils/grid_colors.dart';
import '../../../../models/auth_utility.dart';
import '../../../../utils/api_links.dart';
import '../../../../utils/tenant_context.dart';
import '../../../../widgets/searchable_dropdown.dart';
import '../../../../utils/grid_texts.dart';

const _red = GridColors.primary;
const _green = GridColors.secondary;
const _grey = Color(0xFF757575);
const _dark = Color(0xFF212121);
const _bg = Color(0xFFF5F5F5);

class MobileNfeSankhyaDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  const MobileNfeSankhyaDetailScreen({super.key, required this.item});
  @override
  State<MobileNfeSankhyaDetailScreen> createState() => _State();
}

class _State extends State<MobileNfeSankhyaDetailScreen> {
  int _tab = 0;
  bool _isLoading = false;

  List<Map<String, dynamic>> _itens = [];
  List<Map<String, dynamic>> _contas = [];
  List<Map<String, dynamic>> _formasPagamento = [];
  List<Map<String, dynamic>> _finalidades = [];
  List<Map<String, dynamic>> _parceiros = [];
  List<Map<String, dynamic>> _destinatarios = [];
  List<Map<String, dynamic>> _series = [];
  List<Map<String, dynamic>> _unidades = [];
  List<Map<String, dynamic>> _tiposOperacao = [];

  // Controllers cabeçalho
  final _chaveCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _serieCtrl = TextEditingController();
  String? _statusVal;
  String? _ambienteVal;
  String? _empresaId;
  String? _parceiroId;
  String? _destinatarioId;
  String? _formaPagId;
  String? _finalidadeId;
  String? _serieId;
  String? _tipoOperacaoId;

  String? _empresaNome;
  String? _parceiroNome;

  bool get _isNovo => widget.item['id'] == null;
  String get _nfeId => widget.item['id']?.toString() ?? '';
  bool get _isEntrada => widget.item['tipoOperacao']?.toString().toUpperCase() == 'ENTRADA';

  @override
  void initState() {
    super.initState();
    _initCabecalho();
    _loadDropdowns();
    if (!_isNovo) {
      _loadItens();
      _loadContas();
    }
  }

  void _initCabecalho() {
    final i = widget.item;
    final login = AuthUtility.userInfo?.login;

    _chaveCtrl.text = i['chave']?.toString() ?? '';
    _numeroCtrl.text = i['numero']?.toString() ?? '';
    _serieCtrl.text = i['serie']?.toString() ?? '';

    _statusVal = _isNovo ? 'PENDENTE' : (i['status']?.toString() ?? 'PENDENTE');
    _ambienteVal = i['ambiente']?.toString() ?? 'HOMOLOGACAO';

    final sessEmpId = login?.empresa?.id?.toString();
    _empresaId = sessEmpId ?? (i['empresa'] is Map ? i['empresa']['id'] : i['empresa'])?.toString();
    _empresaNome = login?.empresa?.nome ?? (i['empresa'] is Map ? i['empresa']['nome'] : null)?.toString();

    final sessParcId = login?.parceiro?.id?.toString();
    _parceiroId = sessParcId ?? (i['parceiro'] is Map ? i['parceiro']['id'] : i['parceiro'])?.toString();
    _parceiroNome = login?.parceiro?.nome ?? (i['parceiro'] is Map ? i['parceiro']['nome'] : null)?.toString();

    _destinatarioId = (i['destinatario'] is Map ? i['destinatario']['id'] : i['destinatario'])?.toString();
    _formaPagId = (i['formaPagamento'] is Map ? i['formaPagamento']['id'] : null)?.toString();
    _finalidadeId = (i['nfeFinalidade'] is Map ? i['nfeFinalidade']['id'] : null)?.toString();

    final topData = i['nfeTipoOperacao'];
    _tipoOperacaoId = (topData is Map ? topData['id'] : topData)?.toString();
  }

  Future<void> _loadDropdowns() async {
    final login = AuthUtility.userInfo?.login;
    final parcId = login?.parceiro?.id?.toString() ?? _parceiroId;
    final empId = login?.empresa?.id?.toString() ?? _empresaId;

    await Future.wait([
      _loadList('${ApiLinks.baseUrl}/api/forma_pagamento?tamanho=100', (d) => setState(() => _formasPagamento = d)),
      _loadList('${ApiLinks.baseUrl}/api/nfe-finalidade?tamanho=50', (d) => setState(() => _finalidades = d)),
      _loadList('${ApiLinks.baseUrl}/api/nfe-serie?tamanho=100${empId != null ? '&empId=$empId' : ''}', (d) {
        setState(() => _series = d);
        if (_serieCtrl.text.isNotEmpty && _serieId == null) {
          final match = d.where((s) => s['serie']?.toString() == _serieCtrl.text).firstOrNull;
          if (match != null) _serieId = match['id']?.toString();
        }
      }),
      _loadList('${ApiLinks.baseUrl}/api/unidade_medida?tamanho=200', (d) => setState(() => _unidades = d)),
      _loadList('${ApiLinks.baseUrl}/api/parceiro?tamanho=500${empId != null ? '&empId=$empId' : ''}', (d) => setState(() => _parceiros = d)),
      _loadList('${ApiLinks.baseUrl}/api/nfe-tipo-operacao?tamanho=200', (d) => setState(() => _tiposOperacao = d)),
    ]);
  }

  Future<void> _loadList(String url, void Function(List<Map<String, dynamic>>) cb) async {
    try {
      final r = await TenantContext.get(url);
      if (r.statusCode == 200) {
        final b = jsonDecode(r.body);
        List raw = [];
        if (b is List) {
          raw = b;
        } else if (b is Map) {
          final data = b['data'];
          if (data is List) {
            raw = data;
          } else if (data is Map) {
            raw = data['dados'] ?? data['content'] ?? data['items'] ?? [];
          } else {
            raw = b['dados'] ?? b['content'] ?? b['items'] ?? [];
          }
        }
        cb(raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList());
      }
    } catch (_) {}
  }

  Future<void> _loadItens() async {
    try {
      final r = await TenantContext.get('${ApiLinks.baseUrl}/api/nfe_item?nfeId=$_nfeId&tamanho=100');
      if (r.statusCode == 200) {
        final b = jsonDecode(r.body);
        final d = b is Map ? (b['data'] is Map ? b['data']['dados'] : b['data']) : b;
        setState(() => _itens = (d as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList());
      }
    } catch (_) {}
  }

  Future<void> _loadContas() async {
    try {
      final ep = _isEntrada ? 'conta_pagar' : 'conta_receber';
      final r = await TenantContext.get('${ApiLinks.baseUrl}/api/$ep?nfeId=$_nfeId&tamanho=100');
      if (r.statusCode == 200) {
        final b = jsonDecode(r.body);
        final d = b is Map ? (b['data'] is Map ? b['data']['dados'] : b['data']) : b;
        setState(() => _contas = (d as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList());
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _red,
        foregroundColor: Colors.white,
        title: Text('NF-e #$_nfeId - ${widget.item['tipoOperacao'] ?? ''}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        actions: _isEntrada ? _actionsEntrada() : _actionsSaida(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  TabBar(
                    onTap: (i) => setState(() => _tab = i),
                    tabs: const [
                      Tab(text: 'Formulário', icon: Icon(Icons.description, size: 18)),
                      Tab(text: 'Itens', icon: Icon(Icons.list, size: 18)),
                      Tab(text: 'Histórico', icon: Icon(Icons.history, size: 18)),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildFormulario(),
                        _buildItens(),
                        _buildHistorico(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  List<Widget> _actionsSaida() => [
    _appBarBtn(Icons.send, 'Emitir', () => _emitir()),
    _appBarBtn(Icons.cancel_outlined, 'Cancelar', () => _cancelar()),
    _appBarBtn(Icons.print, 'DANFE', () => _imprimirDanfe()),
    _appBarBtn(Icons.code, 'XML', () => _baixarXml()),
  ];

  List<Widget> _actionsEntrada() => [
    _appBarBtn(Icons.upload_file, 'XML', () => _importarXml()),
    _appBarBtn(Icons.check_circle_outline, 'Aceitar', () => _aceitar()),
    _appBarBtn(Icons.cancel_outlined, 'Recusar', () => _recusar()),
  ];

  Widget _appBarBtn(IconData icon, String label, VoidCallback onTap) =>
      Tooltip(
        message: label,
        child: IconButton(
          icon: Icon(icon, color: Colors.white, size: 20),
          onPressed: onTap,
        ),
      );

  Widget _buildFormulario() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _section('Identificação'),
          _row([
            _field('Número', _numeroCtrl, flex: 1),
            const SizedBox(width: 8),
            _field('Série', _serieCtrl, flex: 1),
          ]),
          _field('Chave', _chaveCtrl),
          _row([
            _dropField('Status', _statusVal, ['PENDENTE', 'AUTORIZADA', 'CANCELADA', 'REJEITADA'],
                (v) => setState(() => _statusVal = v), flex: 1),
            const SizedBox(width: 8),
            _dropField('Ambiente', _ambienteVal, ['PRODUCAO', 'HOMOLOGACAO'],
                (v) => setState(() => _ambienteVal = v), flex: 1),
          ]),
          const SizedBox(height: 16),
          _section('Dados'),
          _readField('Empresa', _empresaNome ?? ''),
          _readField('Parceiro', _parceiroNome ?? ''),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.save, size: 16),
            label: const Text('Salvar'),
            style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 40)),
          ),
        ],
      ),
    );
  }

  Widget _buildItens() {
    if (_itens.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Nenhum item na NF-e',
              style: const TextStyle(color: _grey, fontSize: 14)),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _itens.length,
      itemBuilder: (ctx, i) {
        final item = _itens[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${item['descricao'] ?? 'Item ${i + 1}'}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Qty: ${item['qCom'] ?? '—'}'),
                    Text('Valor: ${item['vItem'] ?? '—'}'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistorico() {
    if (_contas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Nenhum histórico',
              style: const TextStyle(color: _grey, fontSize: 14)),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _contas.length,
      itemBuilder: (ctx, i) {
        final conta = _contas[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Conta #${conta['id'] ?? '—'}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Valor: ${conta['valor'] ?? '—'}'),
                    Text('Status: ${conta['status'] ?? '—'}'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Ações ─────────────────────────────────────────────────────────────

  Future<void> _emitir() async {
    if (_isNovo) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Salve a NF-e antes de emitir'), backgroundColor: _red));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Emitir NF-e', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Text('Confirma a emissão da NF-e #$_nfeId?',
            style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text(GridTexts.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Emitir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final r = await TenantContext.post(ApiLinks.emitirNfe(_nfeId), {});
      if (!mounted) return;
      if (r.statusCode == 200 || r.statusCode == 201) {
        setState(() => _statusVal = 'AUTORIZADA');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('NF-e emitida com sucesso!'), backgroundColor: _green));
      } else {
        String msg = 'Erro ${r.statusCode}';
        try {
          final body = jsonDecode(r.body);
          msg = body['message']?.toString() ?? body['mensagem']?.toString() ?? msg;
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: _red));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
    }
  }

  Future<void> _cancelar() async {
    final motivoCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar NF-e', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('NF-e #$_nfeId', style: const TextStyle(fontSize: 12, color: _grey)),
          const SizedBox(height: 12),
          TextField(
            controller: motivoCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Motivo do cancelamento *',
              labelStyle: TextStyle(fontSize: 12),
              border: OutlineInputBorder(),
              isDense: true,
              hintText: 'Mínimo 15 caracteres',
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Voltar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar NF-e'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (motivoCtrl.text.trim().length < 15) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Motivo deve ter pelo menos 15 caracteres'), backgroundColor: _red));
      return;
    }
    try {
      final r = await TenantContext.post(ApiLinks.cancelarNfe(_nfeId), {'justificativa': motivoCtrl.text.trim()});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(r.statusCode == 200 ? 'NF-e cancelada!' : 'Erro ${r.statusCode}'),
          backgroundColor: r.statusCode == 200 ? _green : _red));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
    }
  }

  Future<void> _imprimirDanfe() async {
    try {
      final r = await TenantContext.get(ApiLinks.danfeNfe(_nfeId));
      if (!mounted) return;
      if (r.statusCode == 200) {
        await FileSaver.instance.saveFile(
          name: 'danfe_$_nfeId',
          bytes: r.bodyBytes,
          fileExtension: 'pdf',
        );
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('DANFE baixado!'), backgroundColor: _green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ${r.statusCode}'), backgroundColor: _red));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
    }
  }

  Future<void> _baixarXml() async {
    try {
      final r = await TenantContext.get(ApiLinks.xmlNfe(_nfeId));
      if (!mounted) return;
      if (r.statusCode == 200) {
        await FileSaver.instance.saveFile(
          name: 'nfe_$_nfeId',
          bytes: Uint8List.fromList(r.body.codeUnits),
          fileExtension: 'xml',
        );
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('XML baixado!'), backgroundColor: _green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ${r.statusCode}'), backgroundColor: _red));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
    }
  }

  Future<void> _importarXml() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['xml'], withData: true);
    if (result == null || result.files.isEmpty || !mounted) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    try {
      final r = await TenantContext.postMultipart(
        '${ApiLinks.baseUrl}/api/nfe/entrada/import',
        fileBytes: file.bytes!,
        fileName: file.name,
        fileField: 'xml',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(r.statusCode == 200 ? 'XML importado!' : 'Erro ${r.statusCode}'),
          backgroundColor: r.statusCode == 200 ? _green : _red));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
    }
  }

  Future<void> _aceitar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Aceitar NF-e', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Text('Confirma o aceite da NF-e #$_nfeId?', style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text(GridTexts.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Aceitar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final r = await TenantContext.post(ApiLinks.aceitarNfe(_nfeId), {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(r.statusCode == 200 ? 'NF-e aceita!' : 'Erro ${r.statusCode}'),
          backgroundColor: r.statusCode == 200 ? _green : _red));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
    }
  }

  Future<void> _recusar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Recusar NF-e', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Text('Confirma a recusa da NF-e #$_nfeId?', style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text(GridTexts.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Recusar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final r = await TenantContext.post(ApiLinks.recusarNfe(_nfeId), {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(r.statusCode == 200 ? 'NF-e recusada!' : 'Erro ${r.statusCode}'),
          backgroundColor: r.statusCode == 200 ? _green : _red));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
    }
  }

  // ── Builders ──────────────────────────────────────────────────────────

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 8),
    child: Text(title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _dark)),
  );

  Widget _field(String label, TextEditingController ctrl, {int flex = 1}) =>
      Expanded(
        flex: flex,
        child: TextField(
          controller: ctrl,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(fontSize: 11),
            border: const OutlineInputBorder(),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
        ),
      );

  Widget _row(List<Widget> children) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: children),
      );

  Widget _dropField(String label, String? val, List<String> opts,
          void Function(String?) cb, {int flex = 1}) =>
      Expanded(
        flex: flex,
        child: SearchableDropdownField(
          label: label,
          value: val,
          items: opts.map((o) => <String, dynamic>{'id': o, 'nome': o}).toList(),
          valueField: 'id',
          displayField: 'nome',
          nullable: true,
          onChanged: cb,
        ),
      );

  Widget _readField(String label, String val) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextField(
          enabled: false,
          controller: TextEditingController(text: val),
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(fontSize: 11),
            border: const OutlineInputBorder(),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
        ),
      );
}
