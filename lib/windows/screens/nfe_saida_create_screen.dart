import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/auth_utility.dart';
import '../../services/nfe_saida_service.dart';
import '../../utils/api_links.dart';
import '../../utils/grid_colors.dart';
import '../../utils/tenant_context.dart';
import '../../widgets/searchable_dropdown.dart';
import '../../utils/grid_texts.dart';

class NfeSaidaCreateScreen extends StatefulWidget {
  const NfeSaidaCreateScreen({super.key});

  @override
  State<NfeSaidaCreateScreen> createState() => _NfeSaidaCreateScreenState();
}

class _NfeSaidaCreateScreenState extends State<NfeSaidaCreateScreen> {
  final _service = NfeSaidaService();

  List<Map<String, dynamic>> _topList = [];
  List<Map<String, dynamic>> _empresas = [];
  List<Map<String, dynamic>> _parceiros = [];
  List<Map<String, dynamic>> _destinatarios = [];
  List<Map<String, dynamic>> _formasPagamento = [];
  List<Map<String, dynamic>> _finalidades = [];
  List<Map<String, dynamic>> _series = [];

  Map<String, dynamic>? _topSelected;
  String? _empresaId;
  String? _parceiroId;
  String? _destinatarioId;
  String? _formaPagId;
  String? _finalidadeId;
  String? _serieVal;

  final _numeroCtrl = TextEditingController();
  String? _ambienteVal = 'HOMOLOGACAO';

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadDados();
  }

  @override
  void dispose() {
    _numeroCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDados() async {
    final login = AuthUtility.userInfo?.login;
    final empId = login?.empresa?.id?.toString();
    final parcId = login?.parceiro?.id?.toString();

    _empresaId = empId;
    _parceiroId = parcId;

    final results = await Future.wait([
      _service.carregarTiposOperacao(),
      _loadList('${ApiLinks.baseUrl}/api/forma_pagamento?tamanho=100'),
      _loadList('${ApiLinks.baseUrl}/api/nfe-finalidade?tamanho=50'),
      _loadList('${ApiLinks.baseUrl}/api/nfe-serie?tamanho=100${empId != null ? '&empId=$empId' : ''}'),
      _loadList('${ApiLinks.baseUrl}/api/parceiro?tamanho=500${empId != null ? '&empId=$empId' : ''}'),
    ]);

    if (!mounted) return;
    setState(() {
      _topList = results[0];
      _formasPagamento = results[1];
      _finalidades = results[2];
      _series = results[3];
      _parceiros = results[4];
      _destinatarios = results[4];
    });
  }

  Future<List<Map<String, dynamic>>> _loadList(String url) async {
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
            raw = data['dados'] ?? data['content'] ?? [];
          } else {
            raw = b['dados'] ?? b['content'] ?? [];
          }
        }
        return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  void _onTopSelected(Map<String, dynamic>? top) {
    setState(() => _topSelected = top);
  }

  Future<void> _salvar() async {
    if (_topSelected == null) {
      _snack(GridTexts.selectOperationType, GridColors.error);
      return;
    }

    setState(() => _saving = true);
    try {
      final body = <String, dynamic>{
        'tipoOperacao': 'SAIDA',
        'status': 'PENDENTE',
        'ambiente': _ambienteVal,
        'numero': _numeroCtrl.text,
        'serie': _serieVal,
        if (_empresaId != null)
          'empresa': {'id': int.tryParse(_empresaId!) ?? _empresaId},
        if (_parceiroId != null)
          'parceiro': {'id': int.tryParse(_parceiroId!) ?? _parceiroId},
        if (_destinatarioId != null)
          'destinatario': {
            'id': int.tryParse(_destinatarioId!) ?? _destinatarioId
          },
        if (_formaPagId != null)
          'formaPagamento': {'id': int.tryParse(_formaPagId!) ?? _formaPagId},
        if (_finalidadeId != null)
          'nfeFinalidade': {
            'id': int.tryParse(_finalidadeId!) ?? _finalidadeId
          },
        'nfeTipoOperacao': {'id': _topSelected!['id']},
      };

      final result = await _service.criarNfe(body);
      if (!mounted) return;

      if (result != null && result['id'] != null) {
        _snack(GridTexts.nfeCreatedSuccess, GridColors.success);
        Navigator.pop(context, true);
      } else {
        _snack(GridTexts.createNfeError, GridColors.error);
      }
    } catch (e) {
      if (mounted) _snack('Erro: $e', GridColors.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Widget _section(String title, List<Widget> children) {
    return Card(
      color: GridColors.card,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: GridColors.divider)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: GridColors.primary)),
          const Divider(height: 20),
          ...children,
        ]),
      ),
    );
  }

  Widget _twoCol(Widget left, Widget right) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: left),
      const SizedBox(width: 16),
      Expanded(child: right),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.filterBackground,
      appBar: AppBar(
        title: const Text(GridTexts.nfeExitCreateTitle),
        backgroundColor: GridColors.primary,
        foregroundColor: GridColors.textPrimary,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _saving ? null : _salvar,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save, color: Colors.white),
              label: Text(_saving ? GridTexts.saving : GridTexts.save, style: const TextStyle(color: Colors.white)),
              style: TextButton.styleFrom(backgroundColor: GridColors.success, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 800,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _section(GridTexts.operationType, [
                _twoCol(
                  SearchableDropdownField(
                    label: GridTexts.operationType,
                    value: _topSelected?['id']?.toString(),
                    items: _topList.map((e) => {
                      'id': e['id']?.toString() ?? '',
                      'nome': '${e['codigo'] ?? ''} - ${e['descricao'] ?? ''}',
                    }).toList(),
                    valueField: 'id',
                    displayField: 'nome',
                    onChanged: (v) {
                      final found = _topList.where((e) => e['id'].toString() == v).firstOrNull;
                      _onTopSelected(found);
                    },
                    isRequired: true,
                    hintText: GridTexts.selectTopHint,
                  ),
                  const SizedBox.shrink(),
                ),
                if (_topSelected != null) ...[
                  const SizedBox(height: 12),
                  _infoRow(GridTexts.operationNature, _topSelected!['natOp']?.toString() ?? ''),
                  const SizedBox(height: 8),
                  _twoCol(
                    _infoRow(GridTexts.cfop, _topSelected!['cfop']?.toString() ?? ''),
                    _infoRow(GridTexts.ufOriginDestination, '${_topSelected!['ufOrigem'] ?? ''} → ${_topSelected!['ufDestino'] ?? ''}'),
                  ),
                ],
              ]),
              _section(GridTexts.nfeDataSection, [
                _twoCol(
                  SearchableDropdownField(
                    label: GridTexts.company,
                    value: _empresaId,
                    items: _empresas,
                    valueField: 'id',
                    displayField: 'nome',
                    enabled: false,
                    onChanged: (v) {},
                  ),
                  Column(children: [
                    DropdownButtonFormField<String>(
                      value: _ambienteVal,
                      decoration: const InputDecoration(labelText: GridTexts.environment, border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'HOMOLOGACAO', child: Text(GridTexts.environmentHomologation)),
                        DropdownMenuItem(value: 'PRODUCAO', child: Text(GridTexts.environmentProduction)),
                      ],
                      onChanged: (v) => setState(() => _ambienteVal = v),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                _twoCol(
                  SearchableDropdownField(
                    label: GridTexts.partner,
                    value: _parceiroId,
                    items: _parceiros,
                    valueField: 'id',
                    displayField: 'nome',
                    enabled: false,
                    onChanged: (v) {},
                  ),
                  SearchableDropdownField(
                    label: GridTexts.recipient,
                    value: _destinatarioId,
                    items: _destinatarios,
                    valueField: 'id',
                    displayField: 'nome',
                    onChanged: (v) => setState(() => _destinatarioId = v),
                    nullable: true,
                    hintText: GridTexts.selectRecipientHint,
                  ),
                ),
                const SizedBox(height: 16),
                _twoCol(
                  DropdownButtonFormField<String>(
                    value: _serieVal,
                    decoration: const InputDecoration(labelText: GridTexts.series, border: OutlineInputBorder()),
                    items: _series.map((s) => DropdownMenuItem(value: s['serie']?.toString() ?? s['id']?.toString(), child: Text(s['serie']?.toString() ?? ''))).toList(),
                    onChanged: (v) => setState(() => _serieVal = v),
                  ),
                  TextField(
                    controller: _numeroCtrl,
                    decoration: const InputDecoration(labelText: GridTexts.number, border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ]),
              _section(GridTexts.fiscalConfiguration, [
                _twoCol(
                  SearchableDropdownField(
                    label: GridTexts.purpose,
                    value: _finalidadeId,
                    items: _finalidades,
                    valueField: 'id',
                    displayField: 'descricao',
                    onChanged: (v) => setState(() => _finalidadeId = v),
                    nullable: true,
                    hintText: GridTexts.selectEllipsis,
                  ),
                  SearchableDropdownField(
                    label: GridTexts.paymentMethod,
                    value: _formaPagId,
                    items: _formasPagamento,
                    valueField: 'id',
                    displayField: 'descricao',
                    onChanged: (v) => setState(() => _formaPagId = v),
                    nullable: true,
                    hintText: GridTexts.selectEllipsis,
                  ),
                ),
                if (_topSelected != null) ...[
                  const SizedBox(height: 16),
                  _twoCol(
                    _infoRow(GridTexts.finalConsumerIndicator, _topSelected!['indFinal'] == '1' ? GridTexts.yes : GridTexts.no),
                    _infoRow(GridTexts.buyerPresence, _topSelected!['indPres']?.toString() ?? ''),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EAF6),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFC5CAE9)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text(GridTexts.topTaxes, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 8),
                      _taxRow('ICMS', GridTexts.taxCstLabel(_topSelected!['cstIcms'] ?? '-'), GridTexts.taxAliqLabel(_topSelected!['aliqIcms'] ?? '-')),
                      _taxRow('IPI', GridTexts.taxCstLabel(_topSelected!['cstIpi'] ?? '-'), GridTexts.taxAliqLabel(_topSelected!['aliqIpi'] ?? '-')),
                      _taxRow('PIS', GridTexts.taxCstLabel(_topSelected!['cstPis'] ?? '-'), GridTexts.taxAliqLabel(_topSelected!['pPis'] ?? '-')),
                      _taxRow('COFINS', GridTexts.taxCstLabel(_topSelected!['cstCofins'] ?? '-'), GridTexts.taxAliqLabel(_topSelected!['pCofins'] ?? '-')),
                    ]),
                  ),
                ],
              ]),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      side: BorderSide(color: GridColors.divider),
                    ),
                    child: const Text(GridTexts.cancel),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _salvar,
                    icon: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check),
                    label: Text(_saving ? GridTexts.saving : GridTexts.saveNfe),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GridColors.success,
                      foregroundColor: GridColors.textPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 180,
          child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF757575))),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _taxRow(String name, String cst, String aliq) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        SizedBox(width: 80, child: Text(name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        const SizedBox(width: 16),
        Text(cst, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 24),
        Text(aliq, style: const TextStyle(fontSize: 13)),
      ]),
    );
  }
}
