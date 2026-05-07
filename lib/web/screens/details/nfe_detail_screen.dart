import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../utils/api_links.dart';
import '../../../utils/tenant_context.dart';

const _red = Color(0xFF93070A);
const _green = Color(0xFF005826);
const _bord = Color(0xFFDDDDDD);
const _grey = Color(0xFF757575);
const _dark = Color(0xFF212121);
const _bg = Color(0xFFF5F5F5);

class NfeSankhyaDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  const NfeSankhyaDetailScreen({super.key, required this.item});
  @override
  State<NfeSankhyaDetailScreen> createState() => _State();
}

class _State extends State<NfeSankhyaDetailScreen> {
  int _tab = 0;
  bool _itensGrid = true;
  bool _finGrid = true;
  int _selItem = 0;
  int _selFin = 0;

  // Divisórias redimensionáveis
  double _cabWidth = 320;
  double _rodapeHeight = 260;

  List<Map<String, dynamic>> _itens = [];
  List<Map<String, dynamic>> _contas = [];

  // Dropdowns
  List<Map<String, dynamic>> _empresas = [];
  List<Map<String, dynamic>> _parceiros = [];
  List<Map<String, dynamic>> _formasPagamento = [];
  List<Map<String, dynamic>> _finalidades = [];
  List<Map<String, dynamic>> _produtos = [];
  List<Map<String, dynamic>> _series = [];
  List<Map<String, dynamic>> _unidades = [];

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

  String get _nfeId => widget.item['id']?.toString() ?? '';
  bool get _isEntrada => widget.item['tipoOperacao']?.toString().toUpperCase() == 'ENTRADA';

  @override
  void initState() {
    super.initState();
    _initCabecalho();
    _loadDropdowns();
    _loadItens();
    _loadContas();
  }

  void _initCabecalho() {
    final i = widget.item;
    _chaveCtrl.text = i['chave']?.toString() ?? '';
    _numeroCtrl.text = i['numero']?.toString() ?? '';
    _serieCtrl.text = i['serie']?.toString() ?? '';
    _statusVal = i['status']?.toString();
    _ambienteVal = i['ambiente']?.toString();
    _empresaId = (i['empresa'] is Map ? i['empresa']['id'] : i['empresa'])?.toString();
    _parceiroId = (i['parceiro'] is Map ? i['parceiro']['id'] : i['parceiro'])?.toString();
    _destinatarioId = (i['destinatario'] is Map ? i['destinatario']['id'] : i['destinatario'])?.toString();
    _formaPagId = (i['formaPagamento'] is Map ? i['formaPagamento']['id'] : null)?.toString();
    _finalidadeId = (i['nfeFinalidade'] is Map ? i['nfeFinalidade']['id'] : null)?.toString();
  }

  Future<void> _loadDropdowns() async {
    await Future.wait([
      _loadList('${ApiLinks.baseUrl}/api/empresa?tamanho=200', (d) => setState(() => _empresas = d)),
      _loadList('${ApiLinks.baseUrl}/api/parceiro?tamanho=500', (d) => setState(() => _parceiros = d)),
      _loadList('${ApiLinks.baseUrl}/api/forma_pagamento?tamanho=100', (d) => setState(() => _formasPagamento = d)),
      _loadList('${ApiLinks.baseUrl}/api/nfe-finalidade?tamanho=50', (d) => setState(() => _finalidades = d)),
      _loadList('${ApiLinks.baseUrl}/api/produto-contabil?tamanho=500', (d) => setState(() => _produtos = d)),
      _loadList('${ApiLinks.baseUrl}/api/nfe-serie?tamanho=100', (d) => setState(() => _series = d)),
      // Unidades de medida — tenta endpoint padrão
      _loadList('${ApiLinks.baseUrl}/api/unidade_medida?tamanho=200', (d) => setState(() => _unidades = d)),
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
      appBar: AppBar(backgroundColor: _red, foregroundColor: Colors.white,
        title: Text('NF-e #$_nfeId - ${widget.item['tipoOperacao'] ?? ''}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        actions: _isEntrada ? _actionsEntrada() : _actionsSaida()),
      body: Column(children: [
        Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Cabeçalho redimensionável
          SizedBox(width: _cabWidth, child: _cabecalho()),
          // Divisória arrastável
          GestureDetector(
            onHorizontalDragUpdate: (d) => setState(() => _cabWidth = (_cabWidth + d.delta.dx).clamp(200, 600)),
            child: MouseRegion(cursor: SystemMouseCursors.resizeColumn,
              child: Container(width: 6, color: _bord,
                child: const Center(child: Icon(Icons.drag_indicator, size: 14, color: _grey)))),
          ),
          Expanded(child: _itensPanel()),
        ])),
        // Divisória horizontal arrastável
        GestureDetector(
          onVerticalDragUpdate: (d) => setState(() => _rodapeHeight = (_rodapeHeight - d.delta.dy).clamp(120, 400)),
          child: MouseRegion(cursor: SystemMouseCursors.resizeRow,
            child: Container(height: 6, color: _bord,
              child: const Center(child: Icon(Icons.drag_handle, size: 14, color: _grey)))),
        ),
        SizedBox(height: _rodapeHeight, child: _rodape()),
      ]),
    );
  }

  // ── AppBar Actions ────────────────────────────────────────────────────────

  List<Widget> _actionsSaida() => [
    _appBarBtn(Icons.send, 'Emitir', () => _emitir()),
    _appBarBtn(Icons.cancel_outlined, 'Cancelar', () => _cancelar()),
    _appBarBtn(Icons.print, 'DANFE', () => _imprimirDanfe()),
    _appBarBtn(Icons.code, 'XML', () => _baixarXml()),
    const SizedBox(width: 8),
  ];

  List<Widget> _actionsEntrada() => [
    _appBarBtn(Icons.upload_file, 'Importar XML', () => _importarXml()),
    _appBarBtn(Icons.check_circle_outline, 'Aceitar', () => _aceitar()),
    _appBarBtn(Icons.cancel_outlined, 'Recusar', () => _recusar()),
    const SizedBox(width: 8),
  ];

  Widget _appBarBtn(IconData icon, String label, VoidCallback onTap) =>
    TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
    );

  // ── Ações NF-e SAÍDA ──────────────────────────────────────────────────────

  Future<void> _emitir() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Emitir NF-e', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Text('Confirma a emissão da NF-e #$_nfeId?', style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
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
      final r = await TenantContext.post('${ApiLinks.baseUrl}/api/nfe/emissao', {
        'empresaId': _empresaId != null ? int.tryParse(_empresaId!) : null,
        'destinatarioId': _destinatarioId != null ? int.tryParse(_destinatarioId!) : null,
        'serie': _serieCtrl.text,
        'numero': _numeroCtrl.text,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(r.statusCode == 200 ? 'NF-e emitida com sucesso!' : 'Erro ${r.statusCode}: ${r.body}'),
        backgroundColor: r.statusCode == 200 ? _green : _red));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
    }
  }

  Future<void> _cancelar() async {
    final motivoCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar NF-e', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: SizedBox(width: 360, child: Column(mainAxisSize: MainAxisSize.min, children: [
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
        ])),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Motivo deve ter pelo menos 15 caracteres'), backgroundColor: _red));
      return;
    }
    try {
      final r = await TenantContext.post('${ApiLinks.baseUrl}/api/nfe/$_nfeId/cancelar', {'justificativa': motivoCtrl.text.trim()});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(r.statusCode == 200 ? 'NF-e cancelada!' : 'Erro ${r.statusCode}: ${r.body}'),
        backgroundColor: r.statusCode == 200 ? _green : _red));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
    }
  }

  Future<void> _imprimirDanfe() async {
    try {
      final r = await TenantContext.get('${ApiLinks.baseUrl}/api/nfe/$_nfeId/danfe');
      if (!mounted) return;
      if (r.statusCode == 200) {
        await FileSaver.instance.saveFile(
          name: 'danfe_$_nfeId',
          bytes: r.bodyBytes,
          fileExtension: 'pdf',
        );
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('DANFE baixado!'), backgroundColor: _green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ${r.statusCode}'), backgroundColor: _red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
    }
  }

  Future<void> _baixarXml() async {
    try {
      final r = await TenantContext.get('${ApiLinks.baseUrl}/api/nfe/$_nfeId/xml');
      if (!mounted) return;
      if (r.statusCode == 200) {
        await FileSaver.instance.saveFile(
          name: 'nfe_$_nfeId',
          bytes: Uint8List.fromList(r.body.codeUnits),
          fileExtension: 'xml',
        );
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('XML baixado!'), backgroundColor: _green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ${r.statusCode}'), backgroundColor: _red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
    }
  }

  // ── Ações NF-e ENTRADA ────────────────────────────────────────────────────

  Future<void> _importarXml() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xml'],
      withData: true,
    );
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
        content: Text(r.statusCode == 200 ? 'XML importado com sucesso!' : 'Erro ${r.statusCode}: ${r.body}'),
        backgroundColor: r.statusCode == 200 ? _green : _red));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
    }
  }

  Future<void> _aceitar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Aceitar NF-e', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Text('Confirma o aceite da NF-e #$_nfeId?', style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
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
      final r = await TenantContext.post('${ApiLinks.baseUrl}/api/nfe/$_nfeId/aceitar', {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(r.statusCode == 200 ? 'NF-e aceita!' : 'Erro ${r.statusCode}'),
        backgroundColor: r.statusCode == 200 ? _green : _red));
      if (r.statusCode == 200) setState(() => _statusVal = 'AUTORIZADA');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
    }
  }

  Future<void> _recusar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Recusar NF-e', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Text('Confirma a recusa da NF-e #$_nfeId?', style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
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
      final r = await TenantContext.post('${ApiLinks.baseUrl}/api/nfe/$_nfeId/recusar', {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(r.statusCode == 200 ? 'NF-e recusada!' : 'Erro ${r.statusCode}'),
        backgroundColor: r.statusCode == 200 ? _green : _red));
      if (r.statusCode == 200) setState(() => _statusVal = 'CANCELADA');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
    }
  }

  // ── CABEÇALHO com dropdowns ──
  Widget _cabecalho() {
    return Container(color: Colors.white, child: Column(children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), color: _green,
        child: Row(children: [
          const Expanded(child: Text('Cabeçalho', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
          SizedBox(height: 24, child: ElevatedButton.icon(
            onPressed: _salvarCabecalho,
            icon: const Icon(Icons.save, size: 12), label: const Text('Salvar', style: TextStyle(fontSize: 11)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: _green, padding: const EdgeInsets.symmetric(horizontal: 8)))),
        ])),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(10), child: Column(children: [
        _inp('Chave', _chaveCtrl),
        _inp('Número', _numeroCtrl),
        // Série: dropdown para SAÍDA (com auto-preenchimento do número), input livre para ENTRADA
        _isEntrada
          ? _inp('Série', _serieCtrl)
          : _ddObjSerie('Série', _serieCtrl.text, _series),
        _dd('Status', _statusVal, ['PENDENTE','AUTORIZADA','CANCELADA','REJEITADA'], (v) => setState(() => _statusVal = v)),
        _dd('Ambiente', _ambienteVal, ['HOMOLOGACAO','PRODUCAO'], (v) => setState(() => _ambienteVal = v)),
        _ddObj('Empresa', _empresaId, _empresas, 'nome', (v) => setState(() => _empresaId = v)),
        _ddObj('Parceiro', _parceiroId, _parceiros, 'nome', (v) => setState(() => _parceiroId = v)),
        _ddObj('Destinatário', _destinatarioId, _parceiros, 'nome', (v) => setState(() => _destinatarioId = v)),
        _ddObj('Forma de Pagamento', _formaPagId, _formasPagamento, 'descricao', (v) => setState(() => _formaPagId = v)),
        _ddObj('Finalidade', _finalidadeId, _finalidades, 'descricao', (v) => setState(() => _finalidadeId = v)),
      ]))),
    ]));
  }

  Widget _inp(String label, TextEditingController ctrl) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextFormField(controller: ctrl, style: const TextStyle(fontSize: 12, color: _dark),
      decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(fontSize: 11, color: _grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: _bord)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: _green, width: 1.5)),
        isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8))));

  Widget _dd(String label, String? val, List<String> opts, void Function(String?) cb) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: DropdownButtonFormField<String>(value: val, isDense: true,
      decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(fontSize: 11, color: _grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: _bord)),
        isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
      style: const TextStyle(fontSize: 12, color: _dark),
      items: [const DropdownMenuItem(value: null, child: Text('— Selecione —', style: TextStyle(fontSize: 11, color: _grey))),
        ...opts.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 12))))],
      onChanged: cb));

  Widget _ddObj(String label, String? val, List<Map<String, dynamic>> opts, String displayField, void Function(String?) cb) {
    final items = opts.map((o) => DropdownMenuItem<String>(value: o['id']?.toString(), child: Text(o[displayField]?.toString() ?? '', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))).toList();
    final current = items.any((i) => i.value == val) ? val : null;
    return Padding(padding: const EdgeInsets.only(bottom: 8),
      child: DropdownButtonFormField<String>(value: current, isDense: true, isExpanded: true,
        decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(fontSize: 11, color: _grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: _bord)),
          isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
        style: const TextStyle(fontSize: 12, color: _dark),
        items: [const DropdownMenuItem(value: null, child: Text('— Selecione —', style: TextStyle(fontSize: 11, color: _grey))), ...items],
        onChanged: cb));
  }

  Future<void> _salvarCabecalho() async {
    final body = <String, dynamic>{
      'id': widget.item['id'],
      'chave': _chaveCtrl.text, 'numero': _numeroCtrl.text, 'serie': _serieCtrl.text,
      if (_statusVal != null) 'status': _statusVal,
      if (_ambienteVal != null) 'ambiente': _ambienteVal,
      if (_empresaId != null) 'empresa': {'id': int.tryParse(_empresaId!) ?? _empresaId},
      if (_parceiroId != null) 'parceiro': {'id': int.tryParse(_parceiroId!) ?? _parceiroId},
      if (_destinatarioId != null) 'destinatario': {'id': int.tryParse(_destinatarioId!) ?? _destinatarioId},
      if (_formaPagId != null) 'formaPagamento': {'id': int.tryParse(_formaPagId!) ?? _formaPagId},
      if (_finalidadeId != null) 'nfeFinalidade': {'id': int.tryParse(_finalidadeId!) ?? _finalidadeId},
    };
    try {
      final r = await TenantContext.put('${ApiLinks.baseUrl}/api/nfe/${widget.item['id']}', body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(r.statusCode == 200 ? 'Salvo!' : 'Erro ${r.statusCode}'),
        backgroundColor: r.statusCode == 200 ? _green : _red));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
    }
  }

  // ── ITENS: DynamicGridWindowsScreen sem botão Novo + toggle para form ──
  Widget _itensPanel() {
    return Container(color: Colors.white, child: Column(children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), color: const Color(0xFFF8F8F8),
        child: Row(children: [
          const Text('Itens', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(width: 8),
          _togBtn(Icons.view_list, _itensGrid, () => setState(() => _itensGrid = true)),
          const SizedBox(width: 4),
          _togBtn(Icons.edit_note, !_itensGrid, () => setState(() => _itensGrid = false)),
          const SizedBox(width: 8),
          // Botão Novo abre o form customizado
          SizedBox(height: 24, child: ElevatedButton.icon(
            onPressed: _novoItem,
            icon: const Icon(Icons.add, size: 12), label: const Text('Novo', style: TextStyle(fontSize: 11)),
            style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10)))),
          const Spacer(),
          if (!_itensGrid && _itens.isNotEmpty) ...[
            _nb(Icons.first_page, () => setState(() => _selItem = 0)),
            _nb(Icons.chevron_left, () => setState(() { if (_selItem > 0) _selItem--; })),
            Text(' ${_selItem + 1}/${_itens.length} ', style: const TextStyle(fontSize: 11)),
            _nb(Icons.chevron_right, () => setState(() { if (_selItem < _itens.length - 1) _selItem++; })),
            _nb(Icons.last_page, () => setState(() => _selItem = _itens.length - 1)),
          ],
        ])),
      Container(height: 1, color: _bord),
      // Grid: usa DynamicGridWindowsScreen sem botão Novo (hasPermission create=false)
      // Form: usa o form customizado com dropdowns
      Expanded(child: _itensGrid
        ? _gridSemHeader(
            telaNome: 'nfe_item',
            extraParams: {'nfeId': _nfeId, 'nfe_id': _nfeId},
          )
        : (_itens.isEmpty
            ? const Center(child: Text('Nenhum item', style: TextStyle(color: _grey)))
            : _iForm())),
    ]));
  }

  Widget _iForm() {
    if (_selItem >= _itens.length) return const SizedBox();
    final item = _itens[_selItem];
    final prodId = (item['produto'] is Map ? item['produto']['id'] : item['produto_id'])?.toString();
    return SingleChildScrollView(padding: const EdgeInsets.all(10), child: Column(children: [
      // Produto dropdown — ao selecionar, preenche NCM, CFOP, Unidade, Vl. Unitário
      _ddObjItem('Produto', prodId, _produtos, 'nome', (v) {
        final prod = _produtos.firstWhere((p) => p['id']?.toString() == v, orElse: () => {});
        setState(() {
          item['produto'] = {'id': int.tryParse(v ?? '') ?? v};
          if (prod.isNotEmpty) {
            item['x_prod'] = prod['nome']?.toString() ?? '';
            item['ncm'] = prod['ncm']?.toString() ?? '';
            item['cfop'] = prod['cfop']?.toString() ?? '';
            item['u_com'] = prod['unidade']?.toString() ?? '';
            item['v_un_com'] = prod['preco']?.toString() ?? '';
          }
        });
      }),
      _iInp('Descrição (xProd)', item, 'x_prod', 'xProd'),
      _iInp('NCM', item, 'ncm', 'ncm'),
      _iInp('CFOP', item, 'cfop', 'cfop'),
      // Unidade como dropdown
      _ddObjItem('Unidade', item['u_com']?.toString() ?? item['uCom']?.toString(), _unidades.isNotEmpty ? _unidades : _unidadesFallback(), 'sigla', (v) {
        setState(() { item['u_com'] = v; item['uCom'] = v; });
      }),
      _iInp('Quantidade', item, 'q_com', 'qCom'),
      _iInp('Vl. Unitário', item, 'v_un_com', 'vUnCom'),
      _iInp('Vl. Total', item, 'v_prod', 'vProd'),
      _iInp('CST ICMS', item, 'cst_icms', 'cstIcms'),
      _iInp('Alíq. ICMS', item, 'aliq_icms', 'aliqIcms'),
      _iInp('Vl. ICMS', item, 'v_icms', 'vIcms'),
    ]));
  }

  Widget _iInp(String label, Map<String, dynamic> item, String k1, String k2) {
    final ctrl = TextEditingController(text: item[k1]?.toString() ?? item[k2]?.toString() ?? '');
    ctrl.addListener(() { item[k1] = ctrl.text; });
    return Padding(padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(controller: ctrl, style: const TextStyle(fontSize: 12, color: _dark),
        decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(fontSize: 11, color: _grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: _bord)),
          isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8))));
  }

  // Dropdown de série para NF-e SAÍDA — ao selecionar, busca próximo número
  Widget _ddObjSerie(String label, String? val, List<Map<String, dynamic>> opts) {
    final items = opts.map((o) => DropdownMenuItem<String>(
      value: o['id']?.toString(),
      child: Text('${o['serie'] ?? ''} (atual: ${o['numeroAtual'] ?? 1})',
          style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))).toList();
    final current = items.any((i) => i.value == val) ? val : null;
    return Padding(padding: const EdgeInsets.only(bottom: 8),
      child: DropdownButtonFormField<String>(value: current, isDense: true, isExpanded: true,
        decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(fontSize: 11, color: _grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: _bord)),
          isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
        style: const TextStyle(fontSize: 12, color: _dark),
        items: [const DropdownMenuItem(value: null, child: Text('— Selecione —', style: TextStyle(fontSize: 11, color: _grey))), ...items],
        onChanged: (v) async {
          if (v == null) return;
          final serie = opts.firstWhere((o) => o['id']?.toString() == v, orElse: () => {});
          setState(() {
            _serieCtrl.text = serie['serie']?.toString() ?? '';
          });
          // Busca próximo número da série
          try {
            final r = await TenantContext.get('${ApiLinks.baseUrl}/api/nfe-serie/$v');
            if (r.statusCode == 200) {
              final b = jsonDecode(r.body);
              final num = b['numeroAtual']?.toString() ?? '';
              setState(() => _numeroCtrl.text = num);
            }
          } catch (_) {}
        }));
  }

  Widget _ddObjItem(String label, String? val, List<Map<String, dynamic>> opts, String df, void Function(String?) cb) {
    final items = opts.map((o) => DropdownMenuItem<String>(value: o['id']?.toString(), child: Text(o[df]?.toString() ?? '', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))).toList();
    final current = items.any((i) => i.value == val) ? val : null;
    return Padding(padding: const EdgeInsets.only(bottom: 8),
      child: DropdownButtonFormField<String>(value: current, isDense: true, isExpanded: true,
        decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(fontSize: 11, color: _grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: _bord)),
          isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
        style: const TextStyle(fontSize: 12, color: _dark),
        items: [const DropdownMenuItem(value: null, child: Text('— Selecione —', style: TextStyle(fontSize: 11, color: _grey))), ...items],
        onChanged: cb));
  }

  void _novoItem() => setState(() { _itens.add({'nfe_id': int.tryParse(_nfeId) ?? 0}); _selItem = _itens.length - 1; _itensGrid = false; });

  /// Grid sem AppBar — usa MediaQuery para dar padding zero ao topo
  /// evitando o header duplo dentro do detail
  Widget _gridSemHeader({required String telaNome, Map<String, dynamic>? extraParams}) {
    return DynamicGridWindowsScreen<Map<String, dynamic>>(
      key: ValueKey('${telaNome}_$_nfeId'),
      telaNome: telaNome,
      hasPermission: (p) => p == 'create' ? false : true,
      fromJson: (json) => json,
      toJson: (a) => a,
      extraParams: extraParams,
      showAppBar: false,
    );
  }

  // Unidades padrão quando o endpoint não existe
  List<Map<String, dynamic>> _unidadesFallback() => [
    {'id': 'UN', 'sigla': 'UN', 'descricao': 'Unidade'},
    {'id': 'KG', 'sigla': 'KG', 'descricao': 'Quilograma'},
    {'id': 'G', 'sigla': 'G', 'descricao': 'Grama'},
    {'id': 'L', 'sigla': 'L', 'descricao': 'Litro'},
    {'id': 'ML', 'sigla': 'ML', 'descricao': 'Mililitro'},
    {'id': 'M', 'sigla': 'M', 'descricao': 'Metro'},
    {'id': 'M2', 'sigla': 'M2', 'descricao': 'Metro Quadrado'},
    {'id': 'M3', 'sigla': 'M3', 'descricao': 'Metro Cúbico'},
    {'id': 'CX', 'sigla': 'CX', 'descricao': 'Caixa'},
    {'id': 'PC', 'sigla': 'PC', 'descricao': 'Peça'},
    {'id': 'PAR', 'sigla': 'PAR', 'descricao': 'Par'},
    {'id': 'DZ', 'sigla': 'DZ', 'descricao': 'Dúzia'},
    {'id': 'SC', 'sigla': 'SC', 'descricao': 'Saco'},
    {'id': 'T', 'sigla': 'T', 'descricao': 'Tonelada'},
  ];

  Widget _togBtn(IconData ic, bool on, VoidCallback cb) => InkWell(onTap: cb,
    child: Container(padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: on ? _green : Colors.transparent, borderRadius: BorderRadius.circular(4), border: Border.all(color: on ? _green : _bord)),
      child: Icon(ic, size: 16, color: on ? Colors.white : _grey)));

  Widget _nb(IconData ic, VoidCallback cb) => InkWell(onTap: cb,
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 1), child: Icon(ic, size: 18, color: _dark)));

  // ── RODAPÉ ──
  Widget _rodape() {
    final tabs = ['Totais', 'Impostos', 'Financeiro'];
    return Column(children: [
      Container(color: const Color(0xFFF0F0F0), child: Row(children: [
        const SizedBox(width: 8),
        ...tabs.asMap().entries.map((e) => _tabBtn(e.key, e.value)),
      ])),
      Container(height: 1, color: _bord),
      Expanded(child: _tabContent()),
    ]);
  }

  Widget _tabBtn(int idx, String label) {
    final on = _tab == idx;
    return GestureDetector(onTap: () => setState(() => _tab = idx),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: on ? Colors.white : Colors.transparent,
          border: Border(bottom: BorderSide(color: on ? _red : Colors.transparent, width: 2))),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: on ? FontWeight.bold : FontWeight.normal, color: on ? _red : _grey))));
  }

  Widget _tabContent() {
    switch (_tab) {
      case 0: return _totaisTab();
      case 1: return _impostosTab();
      case 2: return _financeiroTab();
      default: return const SizedBox();
    }
  }

  Widget _totaisTab() {
    final vt = widget.item['valorTotal']?.toString() ?? '0,00';
    return Padding(padding: const EdgeInsets.all(10), child: Row(children: [
      _card('Vlr. Nota', vt), _card('Total Produtos', vt), _card('Total Serviços', '0,00'),
    ]));
  }

  Widget _impostosTab() => const Padding(padding: EdgeInsets.all(10),
    child: Text('Impostos calculados a partir dos itens.', style: TextStyle(color: _grey, fontSize: 12)));

  // Financeiro com DynamicGridWindowsScreen no modo grid + form customizado
  Widget _financeiroTab() {
    final label = _isEntrada ? 'Contas a Pagar' : 'Contas a Receber';
    final telaNome = _isEntrada ? 'conta_pagar' : 'conta_receber';
    return Column(children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), color: const Color(0xFFF8F8F8),
        child: Row(children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(width: 8),
          _togBtn(Icons.view_list, _finGrid, () => setState(() => _finGrid = true)),
          const SizedBox(width: 4),
          _togBtn(Icons.edit_note, !_finGrid, () => setState(() => _finGrid = false)),
          const SizedBox(width: 8),
          SizedBox(height: 24, child: ElevatedButton.icon(
            onPressed: _novaConta,
            icon: const Icon(Icons.add, size: 12), label: const Text('Nova', style: TextStyle(fontSize: 11)),
            style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10)))),
          const Spacer(),
          if (!_finGrid && _contas.isNotEmpty) ...[
            _nb(Icons.first_page, () => setState(() => _selFin = 0)),
            _nb(Icons.chevron_left, () => setState(() { if (_selFin > 0) _selFin--; })),
            Text(' ${_selFin + 1}/${_contas.length} ', style: const TextStyle(fontSize: 11)),
            _nb(Icons.chevron_right, () => setState(() { if (_selFin < _contas.length - 1) _selFin++; })),
            _nb(Icons.last_page, () => setState(() => _selFin = _contas.length - 1)),
          ],
        ])),
      Container(height: 1, color: _bord),
      // Grid: DynamicGridWindowsScreen sem botão Novo
      // Form: form customizado com scroll
      Expanded(child: _finGrid
        ? _gridSemHeader(
            telaNome: telaNome,
            extraParams: {'nfeId': _nfeId},
          )
        : (_contas.isEmpty
            ? const Center(child: Text('Nenhuma conta vinculada', style: TextStyle(color: _grey)))
            : _fForm())),
    ]);
  }

  Widget _fForm() {
    if (_selFin >= _contas.length) return const SizedBox();
    final conta = _contas[_selFin];
    // Scroll para ver todos os campos
    return SingleChildScrollView(padding: const EdgeInsets.all(10), child: Column(children: [
      _fInp('Descrição', conta, 'descricao'),
      _fInp('Valor', conta, 'valor'),
      _fInp('Dt. Vencimento', conta, 'data_vencimento'),
      _fInp('Status', conta, 'status'),
      _fInp('Observação', conta, 'observacao'),
      _fInp('Valor Baixa', conta, 'valor_baixa'),
      _fInp('Dt. Baixa', conta, 'data_baixa'),
    ]));
  }

  Widget _fInp(String label, Map<String, dynamic> conta, String key) {
    final ctrl = TextEditingController(text: conta[key]?.toString() ?? '');
    ctrl.addListener(() { conta[key] = ctrl.text; });
    return Padding(padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(controller: ctrl, style: const TextStyle(fontSize: 12, color: _dark),
        decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(fontSize: 11, color: _grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: _bord)),
          isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8))));
  }

  void _novaConta() => setState(() { _contas.add({'nfe_id': int.tryParse(_nfeId) ?? 0}); _selFin = _contas.length - 1; _finGrid = false; });

  Widget _card(String label, String valor) => Container(margin: const EdgeInsets.only(right: 16),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: const Color(0xFFF8F8F8), borderRadius: BorderRadius.circular(4), border: Border.all(color: _bord)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 9, color: _grey)),
      Text(valor, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
    ]));
}
