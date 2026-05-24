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
      _topList = results[0] as List<Map<String, dynamic>>;
      _formasPagamento = results[1] as List<Map<String, dynamic>>;
      _finalidades = results[2] as List<Map<String, dynamic>>;
      _series = results[3] as List<Map<String, dynamic>>;
      _parceiros = results[4] as List<Map<String, dynamic>>;
      _destinatarios = results[4] as List<Map<String, dynamic>>;
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
      _snack('Selecione um Tipo de Operação', GridColors.error);
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
        _snack('NF-e criada com sucesso!', GridColors.success);
        Navigator.pop(context, true);
      } else {
        _snack('Erro ao criar NF-e', GridColors.error);
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
        title: const Text('Nova NF-e Saída'),
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
              label: Text(_saving ? 'Salvando...' : 'Salvar', style: const TextStyle(color: Colors.white)),
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
              _section('Tipo de Operação', [
                _twoCol(
                  SearchableDropdownField(
                    label: 'Tipo de Operação',
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
                    hintText: 'Selecione um TOP...',
                  ),
                  const SizedBox.shrink(),
                ),
                if (_topSelected != null) ...[
                  const SizedBox(height: 12),
                  _infoRow('Natureza da Operação', _topSelected!['natOp']?.toString() ?? ''),
                  const SizedBox(height: 8),
                  _twoCol(
                    _infoRow('CFOP', _topSelected!['cfop']?.toString() ?? ''),
                    _infoRow('UF Origem → Destino', '${_topSelected!['ufOrigem'] ?? ''} → ${_topSelected!['ufDestino'] ?? ''}'),
                  ),
                ],
              ]),
              _section('Dados da NF-e', [
                _twoCol(
                  SearchableDropdownField(
                    label: 'Empresa',
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
                      decoration: const InputDecoration(labelText: 'Ambiente', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'HOMOLOGACAO', child: Text('Homologação')),
                        DropdownMenuItem(value: 'PRODUCAO', child: Text('Produção')),
                      ],
                      onChanged: (v) => setState(() => _ambienteVal = v),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                _twoCol(
                  SearchableDropdownField(
                    label: 'Parceiro',
                    value: _parceiroId,
                    items: _parceiros,
                    valueField: 'id',
                    displayField: 'nome',
                    enabled: false,
                    onChanged: (v) {},
                  ),
                  SearchableDropdownField(
                    label: 'Destinatário',
                    value: _destinatarioId,
                    items: _destinatarios,
                    valueField: 'id',
                    displayField: 'nome',
                    onChanged: (v) => setState(() => _destinatarioId = v),
                    nullable: true,
                    hintText: 'Selecione o destinatário...',
                  ),
                ),
                const SizedBox(height: 16),
                _twoCol(
                  DropdownButtonFormField<String>(
                    value: _serieVal,
                    decoration: const InputDecoration(labelText: 'Série', border: OutlineInputBorder()),
                    items: _series.map((s) => DropdownMenuItem(value: s['serie']?.toString() ?? s['id']?.toString(), child: Text(s['serie']?.toString() ?? ''))).toList(),
                    onChanged: (v) => setState(() => _serieVal = v),
                  ),
                  TextField(
                    controller: _numeroCtrl,
                    decoration: const InputDecoration(labelText: 'Número', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ]),
              _section('Configuração Fiscal', [
                _twoCol(
                  SearchableDropdownField(
                    label: 'Finalidade',
                    value: _finalidadeId,
                    items: _finalidades,
                    valueField: 'id',
                    displayField: 'descricao',
                    onChanged: (v) => setState(() => _finalidadeId = v),
                    nullable: true,
                    hintText: 'Selecione...',
                  ),
                  SearchableDropdownField(
                    label: 'Forma de Pagamento',
                    value: _formaPagId,
                    items: _formasPagamento,
                    valueField: 'id',
                    displayField: 'descricao',
                    onChanged: (v) => setState(() => _formaPagId = v),
                    nullable: true,
                    hintText: 'Selecione...',
                  ),
                ),
                if (_topSelected != null) ...[
                  const SizedBox(height: 16),
                  _twoCol(
                    _infoRow('Indicador Consumidor Final', _topSelected!['indFinal'] == '1' ? 'Sim' : 'Não'),
                    _infoRow('Presença do Comprador', _topSelected!['indPres']?.toString() ?? ''),
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
                      const Text('Impostos (do TOP)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 8),
                      _taxRow('ICMS', 'CST: ${_topSelected!['cstIcms'] ?? '-'}', 'Alíq: ${_topSelected!['aliqIcms'] ?? '-'}%'),
                      _taxRow('IPI', 'CST: ${_topSelected!['cstIpi'] ?? '-'}', 'Alíq: ${_topSelected!['aliqIpi'] ?? '-'}%'),
                      _taxRow('PIS', 'CST: ${_topSelected!['cstPis'] ?? '-'}', 'Alíq: ${_topSelected!['pPis'] ?? '-'}%'),
                      _taxRow('COFINS', 'CST: ${_topSelected!['cstCofins'] ?? '-'}', 'Alíq: ${_topSelected!['pCofins'] ?? '-'}%'),
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
                    label: Text(_saving ? 'Salvando...' : 'Salvar NF-e'),
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
