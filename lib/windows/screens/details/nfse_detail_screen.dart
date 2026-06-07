import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/auth_utility.dart';
import '../../../utils/api_links.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/tenant_context.dart';
import '../../../widgets/searchable_dropdown.dart';

const _red = GridColors.primary;
const _green = GridColors.secondary;
const _bord = Color(0xFFDDDDDD);
const _grey = Color(0xFF757575);
const _dark = Color(0xFF212121);
const _bg = Color(0xFFF5F5F5);

/// Tela de inserção/detalhe de NFSe — espelha o layout do NfeSankhyaDetailScreen:
/// cabeçalho fiscal à esquerda + grid de itens (produtos de serviço) à direita
/// com aba de Impostos (ISS).
class NfseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  const NfseDetailScreen({super.key, required this.item});
  @override
  State<NfseDetailScreen> createState() => _NfseDetailScreenState();
}

class _NfseDetailScreenState extends State<NfseDetailScreen> {
  int _tab = 0;
  bool _itensGrid = true;
  int _selItem = 0;

  double _cabWidth = 320;
  double _rodapeHeight = 240;

  List<Map<String, dynamic>> _itens = [];

  // Dropdowns
  final List<Map<String, dynamic>> _empresas = [];
  List<Map<String, dynamic>> _tomadores = []; // parceiros
  List<Map<String, dynamic>> _produtos = []; // somente isServico == true

  // Controllers cabeçalho
  final _numeroCtrl = TextEditingController();
  final _serieCtrl = TextEditingController();
  final _municipioCtrl = TextEditingController();
  final _codigoServicoCtrl = TextEditingController();
  String? _statusVal;
  String? _ambienteVal;
  String? _empresaId;
  String? _tomadorId;
  DateTime? _dataEmissao;
  DateTime? _dataCompetencia;

  String? _empresaNome;

  bool get _isNovo => widget.item['id'] == null;
  String get _nfseId => widget.item['id']?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    _initCabecalho();
    _loadDropdowns();
    if (!_isNovo) {
      _loadItens();
    }
  }

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _serieCtrl.dispose();
    _municipioCtrl.dispose();
    _codigoServicoCtrl.dispose();
    super.dispose();
  }

  void _initCabecalho() {
    final i = widget.item;
    final login = AuthUtility.userInfo?.login;

    _numeroCtrl.text = i['numero']?.toString() ?? '';
    _serieCtrl.text = i['serie']?.toString() ?? '';
    _municipioCtrl.text = i['municipioPrestacao']?.toString() ??
        i['municipio']?.toString() ??
        '';
    _codigoServicoCtrl.text = i['codigoServicoMunicipal']?.toString() ??
        i['codigoServico']?.toString() ??
        '';

    _statusVal = _isNovo ? 'PENDENTE' : (i['status']?.toString() ?? 'PENDENTE');
    _ambienteVal = i['ambiente']?.toString() ?? 'HOMOLOGACAO';

    final sessEmpId = login?.empresa?.id?.toString();
    _empresaId = sessEmpId ??
        (i['empresa'] is Map ? i['empresa']['id'] : i['empresa'])?.toString();
    _empresaNome = login?.empresa?.nome ??
        (i['empresa'] is Map ? i['empresa']['nome'] : null)?.toString();

    _tomadorId = (i['tomador'] is Map
            ? i['tomador']['id']
            : (i['parceiro'] is Map ? i['parceiro']['id'] : i['tomador'] ?? i['parceiro']))
        ?.toString();

    _dataEmissao = _parseData(i['dataEmissao'] ?? i['dhEmissao']);
    _dataCompetencia = _parseData(i['dataCompetencia']);
  }

  DateTime? _parseData(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadDropdowns() async {
    final login = AuthUtility.userInfo?.login;
    final empId = login?.empresa?.id?.toString() ?? _empresaId;

    await Future.wait([
      _loadList('${ApiLinks.baseUrl}/api/parceiro?tamanho=500${empId != null ? '&empId=$empId' : ''}',
          (d) => setState(() => _tomadores = d)),
      _loadProdutosServico(empId),
    ]);
  }

  /// Busca produtos e filtra client-side por isServico == true
  /// (espelha Produto.isServico). Tenta também ?isServico=true caso o
  /// backend já suporte o filtro server-side.
  Future<void> _loadProdutosServico(String? empId) async {
    final base = '${ApiLinks.baseUrl}/api/produto?tamanho=500'
        '${empId != null ? '&empId=$empId' : ''}';
    List<Map<String, dynamic>> produtos = [];
    await _loadList('$base&isServico=true', (d) => produtos = d);
    if (produtos.isEmpty) {
      await _loadList(base, (d) => produtos = d);
      produtos = produtos.where((p) => p['isServico'] == true).toList();
    }
    if (mounted) setState(() => _produtos = produtos);
  }

  Future<void> _loadList(
      String url, void Function(List<Map<String, dynamic>>) cb) async {
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
      final r = await TenantContext.get(
          '${ApiLinks.baseUrl}/api/nfse_item?nfseId=$_nfseId&tamanho=100');
      if (r.statusCode == 200) {
        final b = jsonDecode(r.body);
        final d = b is Map ? (b['data'] is Map ? b['data']['dados'] : b['data']) : b;
        setState(() => _itens = (d as List? ?? [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList());
      }
    } catch (_) {}
  }

  // ── Salvar cabeçalho ──────────────────────────────────────────────────────

  Future<void> _salvarCabecalho() async {
    final body = <String, dynamic>{
      if (!_isNovo) 'id': widget.item['id'],
      'numero': _numeroCtrl.text,
      'serie': _serieCtrl.text,
      'municipioPrestacao': _municipioCtrl.text,
      'codigoServicoMunicipal': _codigoServicoCtrl.text,
      if (_statusVal != null) 'status': _statusVal,
      if (_ambienteVal != null) 'ambiente': _ambienteVal,
      if (_empresaId != null) 'empresa': {'id': int.tryParse(_empresaId!) ?? _empresaId},
      if (_tomadorId != null) 'tomador': {'id': int.tryParse(_tomadorId!) ?? _tomadorId},
      if (_dataEmissao != null) 'dataEmissao': _dataEmissao!.toIso8601String().substring(0, 10),
      if (_dataCompetencia != null) 'dataCompetencia': _dataCompetencia!.toIso8601String().substring(0, 10),
    };
    try {
      final r = _isNovo
          ? await TenantContext.post('${ApiLinks.baseUrl}/api/nfse', body)
          : await TenantContext.put('${ApiLinks.baseUrl}/api/nfse/${widget.item['id']}', body);
      if (!mounted) return;
      if (r.statusCode == 200 || r.statusCode == 201) {
        if (_isNovo) {
          try {
            final b = jsonDecode(r.body);
            final newId = b is Map ? (b['data'] is Map ? b['data']['id'] : (b['data'] ?? b['id'])) : null;
            if (newId != null) {
              setState(() => widget.item['id'] = newId);
              _loadItens();
            }
          } catch (_) {}
        }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salvo!'), backgroundColor: _green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ${r.statusCode}: ${r.body}'), backgroundColor: _red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
    }
  }

  Future<void> _salvarItem(Map<String, dynamic> item) async {
    final isNew = item['id'] == null;
    final body = <String, dynamic>{
      if (!isNew) 'id': item['id'],
      'nfseId': item['nfse_id'] ?? int.tryParse(_nfseId),
      if (item['produto'] != null) 'produto': item['produto'],
      'descricao': item['descricao'] ?? '',
      'quantidade': double.tryParse((item['quantidade'] ?? '').toString()),
      'valorUnitario': double.tryParse((item['valorUnitario'] ?? item['valor_unitario'] ?? '').toString()),
      'valorTotal': double.tryParse((item['valorTotal'] ?? item['valor_total'] ?? '').toString()),
      'aliquotaIss': double.tryParse((item['aliquotaIss'] ?? item['aliquota_iss'] ?? '').toString()),
      'valorIss': double.tryParse((item['valorIss'] ?? item['valor_iss'] ?? '').toString()),
      'codigoTributacaoMunicipal': item['codigoTributacaoMunicipal'] ?? item['codigo_tributacao_municipal'] ?? '',
      'issRetido': item['issRetido'] == true || item['iss_retido'] == true,
    };
    try {
      final r = isNew
          ? await TenantContext.post('${ApiLinks.baseUrl}/api/nfse_item', body)
          : await TenantContext.put('${ApiLinks.baseUrl}/api/nfse_item/${item['id']}', body);
      if (!mounted) return;
      if (r.statusCode == 200 || r.statusCode == 201) {
        if (isNew) {
          try {
            final b = jsonDecode(r.body);
            final newId = b is Map ? (b['data'] is Map ? b['data']['id'] : (b['data'] ?? b['id'])) : null;
            if (newId != null) setState(() => item['id'] = newId);
          } catch (_) {}
        }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item salvo!'), backgroundColor: _green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ${r.statusCode}'), backgroundColor: _red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
    }
  }

  void _novoItem() => setState(() {
        _itens.add({'nfse_id': int.tryParse(_nfseId) ?? 0});
        _selItem = _itens.length - 1;
        _itensGrid = false;
      });

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _red,
        foregroundColor: Colors.white,
        title: Text('NFSe #$_nfseId',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        actions: [
          TextButton.icon(
            onPressed: _salvarCabecalho,
            icon: const Icon(Icons.save, size: 16, color: Colors.white),
            label: const Text('Salvar', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: _cabWidth, child: _cabecalho()),
            GestureDetector(
              onHorizontalDragUpdate: (d) => setState(() => _cabWidth = (_cabWidth + d.delta.dx).clamp(200, 600)),
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                child: Container(width: 6, color: _bord,
                  child: const Center(child: Icon(Icons.drag_indicator, size: 14, color: _grey))),
              ),
            ),
            Expanded(child: _itensPanel()),
          ]),
        ),
        GestureDetector(
          onVerticalDragUpdate: (d) => setState(() => _rodapeHeight = (_rodapeHeight - d.delta.dy).clamp(120, 400)),
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeRow,
            child: Container(height: 6, color: _bord,
              child: const Center(child: Icon(Icons.drag_handle, size: 14, color: _grey))),
          ),
        ),
        SizedBox(height: _rodapeHeight, child: _rodape()),
      ]),
    );
  }

  // ── CABEÇALHO ──
  Widget _cabecalho() {
    final hasSession = AuthUtility.userInfo?.login != null;
    return Container(
      color: Colors.white,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          color: _green,
          child: Row(children: [
            const Expanded(child: Text('Cabeçalho', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
            SizedBox(height: 24, child: ElevatedButton.icon(
              onPressed: _salvarCabecalho,
              icon: const Icon(Icons.save, size: 12), label: const Text('Salvar', style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: _green, padding: const EdgeInsets.symmetric(horizontal: 8)))),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(10),
            child: Column(children: [
              hasSession && _empresaNome != null
                  ? _inpDisabledText('Empresa', _empresaNome!)
                  : _ddObj('Empresa', _empresaId, _empresas, 'nome', (v) => setState(() => _empresaId = v)),
              _ddObj('Tomador / Parceiro', _tomadorId, _tomadores, 'nome', (v) => setState(() => _tomadorId = v)),
              _inp('Série', _serieCtrl),
              _inp('Número', _numeroCtrl),
              _dateField('Data Emissão', _dataEmissao, (d) => setState(() => _dataEmissao = d)),
              _dateField('Data Competência', _dataCompetencia, (d) => setState(() => _dataCompetencia = d)),
              _inp('Município de Prestação', _municipioCtrl),
              _inp('Código de Serviço Municipal', _codigoServicoCtrl),
              _inpDisabledText('Status', _statusVal ?? 'PENDENTE'),
              _dd('Ambiente', _ambienteVal, ['HOMOLOGACAO', 'PRODUCAO'], (v) => setState(() => _ambienteVal = v)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _inp(String label, TextEditingController ctrl) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextFormField(
          controller: ctrl,
          style: const TextStyle(fontSize: 12, color: _dark),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(fontSize: 11, color: _grey),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: _bord)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: _green, width: 1.5)),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
        ),
      );

  Widget _inpDisabledText(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(fontSize: 11, color: _grey),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: _bord)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: _bord)),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          child: Text(value, style: const TextStyle(fontSize: 12, color: _grey)),
        ),
      );

  Widget _dd(String label, String? val, List<String> opts, void Function(String?) cb) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SearchableDropdownField(
          label: label,
          value: val,
          items: opts.map((o) => <String, dynamic>{'id': o, 'nome': o}).toList(),
          valueField: 'id',
          displayField: 'nome',
          nullable: true,
          nullLabel: '— Selecione —',
          onChanged: cb,
        ),
      );

  Widget _ddObj(String label, String? val, List<Map<String, dynamic>> opts, String displayField, void Function(String?) cb) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SearchableDropdownField(
        label: label,
        value: opts.any((o) => o['id']?.toString() == val) ? val : null,
        items: opts.map((o) => <String, dynamic>{'id': o['id']?.toString() ?? '', 'nome': o[displayField]?.toString() ?? ''}).toList(),
        valueField: 'id',
        displayField: 'nome',
        nullable: true,
        nullLabel: '— Selecione —',
        onChanged: cb,
      ),
    );
  }

  Widget _dateField(String label, DateTime? val, void Function(DateTime?) cb) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: val ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
          );
          if (d != null) cb(d);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(fontSize: 11, color: _grey),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: _bord)),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          child: Row(children: [
            const Icon(Icons.calendar_today, size: 14, color: _grey),
            const SizedBox(width: 6),
            Text(
              val != null
                  ? '${val.day.toString().padLeft(2, '0')}/${val.month.toString().padLeft(2, '0')}/${val.year}'
                  : '— Selecione —',
              style: const TextStyle(fontSize: 12, color: _dark),
            ),
          ]),
        ),
      ),
    );
  }

  // ── ITENS ──
  Widget _itensPanel() {
    return Container(
      color: Colors.white,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          color: const Color(0xFFF8F8F8),
          child: Row(children: [
            const Text('Itens (Serviços)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(width: 8),
            _togBtn(Icons.view_list, _itensGrid, () => setState(() => _itensGrid = true)),
            const SizedBox(width: 4),
            _togBtn(Icons.edit_note, !_itensGrid, () => setState(() => _itensGrid = false)),
            const SizedBox(width: 8),
            SizedBox(height: 24, child: ElevatedButton.icon(
              onPressed: _novoItem,
              icon: const Icon(Icons.add, size: 12), label: const Text('Novo', style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10)))),
            if (!_itensGrid && _itens.isNotEmpty) ...[
              const SizedBox(width: 4),
              SizedBox(height: 24, child: ElevatedButton.icon(
                onPressed: () => _salvarItem(_itens[_selItem]),
                icon: const Icon(Icons.save, size: 12), label: const Text('Salvar', style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: _green, padding: const EdgeInsets.symmetric(horizontal: 8)))),
            ],
            const Spacer(),
            if (!_itensGrid && _itens.isNotEmpty) ...[
              _nb(Icons.first_page, () => setState(() => _selItem = 0)),
              _nb(Icons.chevron_left, () => setState(() { if (_selItem > 0) _selItem--; })),
              Text(' ${_selItem + 1}/${_itens.length} ', style: const TextStyle(fontSize: 11)),
              _nb(Icons.chevron_right, () => setState(() { if (_selItem < _itens.length - 1) _selItem++; })),
              _nb(Icons.last_page, () => setState(() => _selItem = _itens.length - 1)),
            ],
          ]),
        ),
        Container(height: 1, color: _bord),
        Expanded(
          child: _itensGrid
              ? _gridSemHeader(telaNome: 'nfse_item', extraParams: {'nfseId': _nfseId, 'nfse_id': _nfseId})
              : (_itens.isEmpty
                  ? const Center(child: Text('Nenhum item', style: TextStyle(color: _grey)))
                  : _iForm()),
        ),
      ]),
    );
  }

  Widget _iForm() {
    if (_selItem >= _itens.length) return const SizedBox();
    final item = _itens[_selItem];
    final prodId = (item['produto'] is Map ? item['produto']['id'] : item['produto_id'])?.toString();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Column(children: [
        // Produto — somente os marcados como serviço (Produto.isServico == true)
        _ddObjItem('Produto (Serviço)', prodId, _produtos, 'nome', (v) {
          final prod = _produtos.firstWhere((p) => p['id']?.toString() == v, orElse: () => {});
          setState(() {
            item['produto'] = {'id': int.tryParse(v ?? '') ?? v};
            if (prod.isNotEmpty) {
              item['descricao'] = prod['nome']?.toString() ?? '';
              item['valorUnitario'] = prod['preco']?.toString() ?? '';
              item['aliquotaIss'] = prod['aliquotaIss']?.toString() ?? prod['aliquota_iss']?.toString() ?? '';
              item['codigoTributacaoMunicipal'] = prod['codigoTributacaoMunicipal']?.toString() ?? '';
            }
          });
        }),
        _iInp('Descrição', item, 'descricao'),
        _iInp('Quantidade', item, 'quantidade'),
        _iInp('Vl. Unitário', item, 'valorUnitario'),
        _iInp('Vl. Total', item, 'valorTotal'),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: () => _salvarItem(item),
          icon: const Icon(Icons.save, size: 14),
          label: const Text('Salvar Item', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 10)))),
      ]),
    );
  }

  Widget _iInp(String label, Map<String, dynamic> item, String key) {
    final ctrl = TextEditingController(text: item[key]?.toString() ?? '');
    ctrl.addListener(() => item[key] = ctrl.text);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: ctrl,
        style: const TextStyle(fontSize: 12, color: _dark),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 11, color: _grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: _bord)),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
      ),
    );
  }

  Widget _ddObjItem(String label, String? val, List<Map<String, dynamic>> opts, String df, void Function(String?) cb) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SearchableDropdownField(
        label: label,
        value: opts.any((o) => o['id']?.toString() == val) ? val : null,
        items: opts.map((o) => <String, dynamic>{'id': o['id']?.toString() ?? '', 'nome': o[df]?.toString() ?? ''}).toList(),
        valueField: 'id',
        displayField: 'nome',
        nullable: true,
        nullLabel: '— Selecione —',
        onChanged: cb,
      ),
    );
  }

  Widget _gridSemHeader({required String telaNome, Map<String, dynamic>? extraParams}) {
    return DynamicGridWindowsScreen<Map<String, dynamic>>(
      key: ValueKey('${telaNome}_$_nfseId'),
      telaNome: telaNome,
      hasPermission: (p) => p == 'create' ? false : true,
      fromJson: (json) => json,
      toJson: (a) => a,
      extraParams: extraParams,
      showAppBar: false,
    );
  }

  Widget _togBtn(IconData ic, bool on, VoidCallback cb) => InkWell(
        onTap: cb,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: on ? _green : Colors.transparent, borderRadius: BorderRadius.circular(4), border: Border.all(color: on ? _green : _bord)),
          child: Icon(ic, size: 16, color: on ? Colors.white : _grey),
        ),
      );

  Widget _nb(IconData ic, VoidCallback cb) => InkWell(
        onTap: cb,
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 1), child: Icon(ic, size: 18, color: _dark)),
      );

  // ── RODAPÉ: abas ──
  Widget _rodape() {
    final tabs = ['Totais', 'Impostos'];
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
    return GestureDetector(
      onTap: () => setState(() => _tab = idx),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: on ? Colors.white : Colors.transparent, border: Border(bottom: BorderSide(color: on ? _red : Colors.transparent, width: 2))),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: on ? FontWeight.bold : FontWeight.normal, color: on ? _red : _grey)),
      ),
    );
  }

  Widget _tabContent() {
    switch (_tab) {
      case 0:
        return _totaisTab();
      case 1:
        return _impostosTab();
      default:
        return const SizedBox();
    }
  }

  Widget _totaisTab() {
    final vt = widget.item['valorTotal']?.toString() ?? '0,00';
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(children: [_card('Vlr. NFSe', vt), _card('Total Serviços', vt)]),
    );
  }

  Widget _card(String label, String value) => Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(6), border: Border.all(color: _bord)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: _grey)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _dark)),
        ]),
      );

  /// Aba Impostos — ISS / alíquota ISS / código de tributação municipal /
  /// ISS retido por item (espelha _impostosTab do NfeSankhyaDetailScreen,
  /// mas exibindo os campos de ISS de cada item da NFSe).
  Widget _impostosTab() {
    if (_itens.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(10),
        child: Text('Impostos (ISS) calculados a partir dos itens.', style: TextStyle(color: _grey, fontSize: 12)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(10),
      itemCount: _itens.length,
      separatorBuilder: (_, __) => const Divider(height: 16),
      itemBuilder: (_, i) {
        final item = _itens[i];
        final descricao = item['descricao']?.toString() ?? 'Item ${i + 1}';
        final aliquota = item['aliquotaIss']?.toString() ?? item['aliquota_iss']?.toString() ?? '-';
        final valorIss = item['valorIss']?.toString() ?? item['valor_iss']?.toString() ?? '-';
        final codTrib = item['codigoTributacaoMunicipal']?.toString() ?? item['codigo_tributacao_municipal']?.toString() ?? '-';
        final retido = item['issRetido'] == true || item['iss_retido'] == true;
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: _bord)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(descricao, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 6),
            Wrap(spacing: 16, runSpacing: 6, children: [
              _impInfo('Alíquota ISS', '$aliquota%'),
              _impInfo('Valor ISS', valorIss),
              _impInfo('Cód. Tributação Municipal', codTrib),
              _impInfo('ISS Retido', retido ? 'Sim' : 'Não'),
            ]),
          ]),
        );
      },
    );
  }

  Widget _impInfo(String label, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 10, color: _grey)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _dark)),
      ]);
}
