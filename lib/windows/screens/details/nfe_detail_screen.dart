import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import '../../../utils/grid_colors.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/auth_utility.dart';
import '../../../models/nfe_pagamento_model.dart';
import '../../../models/nfe_fatura_model.dart';
import '../../../models/nfe_duplicata_model.dart';
import '../../../utils/api_links.dart';
import '../../../utils/tenant_context.dart';
import '../../../widgets/searchable_dropdown.dart';
import '../../../utils/grid_texts.dart';

const _red = GridColors.primary;
const _green = GridColors.secondary;
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

  // NF07 — Pagamentos
  List<NfePagamento> _pagamentos = [];
  NfeFatura? _fatura;
  List<NfeDuplicata> _duplicatas = [];
  bool _pagamentosLoading = false;
  // Campos de novo pagamento em edição inline
  String _novoPagTpag = '01';
  final TextEditingController _novoPagVpag = TextEditingController();
  // Campos fatura
  final TextEditingController _fatNFat = TextEditingController();
  final TextEditingController _fatVOrig = TextEditingController();
  final TextEditingController _fatVLiq = TextEditingController();
  // Campos de nova duplicata em edição inline
  final TextEditingController _dupNDup = TextEditingController();
  final TextEditingController _dupDVenc = TextEditingController();
  final TextEditingController _dupVDup = TextEditingController();

  // Dropdowns
  final List<Map<String, dynamic>> _empresas = [];
  List<Map<String, dynamic>> _parceiros = [];
  List<Map<String, dynamic>> _destinatarios = []; // parceiros do parceiro logado
  List<Map<String, dynamic>> _formasPagamento = [];
  List<Map<String, dynamic>> _finalidades = [];
  List<Map<String, dynamic>> _produtos = [];
  List<Map<String, dynamic>> _series = [];
  List<Map<String, dynamic>> _unidades = [];
  List<Map<String, dynamic>> _tiposOperacao = [];
  String? _tipoOperacaoId;
  Map<String, dynamic> _topSelected = {};

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

  // Dados do usuário logado (para campos disabled)
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
      _loadPagamentos();
    }
  }

  void _initCabecalho() {
    final i = widget.item;
    final login = AuthUtility.userInfo?.login;

    _chaveCtrl.text = i['chave']?.toString() ?? '';
    _numeroCtrl.text = i['numero']?.toString() ?? '';
    _serieCtrl.text = i['serie']?.toString() ?? '';

    // Status: PENDENTE para novo, mantém o existente para edição
    _statusVal = _isNovo ? 'PENDENTE' : (i['status']?.toString() ?? 'PENDENTE');
    _ambienteVal = i['ambiente']?.toString() ?? 'HOMOLOGACAO';

    // Empresa: prioriza localstore, fallback para o item
    final sessEmpId = login?.empresa?.id?.toString();
    _empresaId = sessEmpId ?? (i['empresa'] is Map ? i['empresa']['id'] : i['empresa'])?.toString();
    _empresaNome = login?.empresa?.nome ?? (i['empresa'] is Map ? i['empresa']['nome'] : null)?.toString();

    // Parceiro: prioriza localstore, fallback para o item
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
    final empId  = login?.empresa?.id?.toString() ?? _empresaId;

    await Future.wait([
      _loadList('${ApiLinks.baseUrl}/api/forma_pagamento?tamanho=100', (d) => setState(() => _formasPagamento = d)),
      _loadList('${ApiLinks.baseUrl}/api/nfe-finalidade?tamanho=50', (d) => setState(() => _finalidades = d)),
      _loadList('${ApiLinks.baseUrl}/api/produto-contabil?tamanho=500${empId != null ? '&empId=$empId' : ''}${parcId != null ? '&parceiroId=$parcId' : ''}&isServico=false',
          (d) => setState(() => _produtos = d)),
      _loadList('${ApiLinks.baseUrl}/api/nfe-serie?tamanho=100${empId != null ? '&empId=$empId' : ''}',
          (d) => setState(() => _series = d)),
      _loadList('${ApiLinks.baseUrl}/api/unidade_medida?tamanho=200', (d) => setState(() => _unidades = d)),
      _loadList('${ApiLinks.baseUrl}/api/parceiro?tamanho=500${empId != null ? '&empId=$empId' : ''}',
          (d) => setState(() => _parceiros = d)),
      _loadList('${ApiLinks.baseUrl}/api/nfe-tipo-operacao?tamanho=200', (d) => setState(() => _tiposOperacao = d)),
      // Destinatários: parceiros vinculados ao parceiro logado (mesma empresa)
      _loadDestinatarios(empId, parcId),
    ]);

    if (_tipoOperacaoId != null) {
      final found = _tiposOperacao.firstWhere((e) => e['id']?.toString() == _tipoOperacaoId, orElse: () => {});
      if (found.isNotEmpty) setState(() => _topSelected = found);
    }
  }

  Future<void> _loadDestinatarios(String? empId, String? parcId) async {
    // Busca parceiros da mesma empresa — são os possíveis destinatários
    final url = '${ApiLinks.baseUrl}/api/parceiro?tamanho=500'
        '${empId != null ? '&empId=$empId' : ''}'
        '${parcId != null ? '&parceiroId=$parcId' : ''}';
    await _loadList(url, (d) => setState(() => _destinatarios = d));
    // Se não retornou nada, busca sem filtro de parceiro (só empresa)
    if (_destinatarios.isEmpty && empId != null) {
      await _loadList('${ApiLinks.baseUrl}/api/parceiro?tamanho=500&empId=$empId',
          (d) => setState(() => _destinatarios = d));
    }
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

  // ── NF07: Pagamentos, Fatura, Duplicatas ─────────────────────────────────

  Future<void> _loadPagamentos() async {
    if (_isNovo) return;
    setState(() => _pagamentosLoading = true);
    try {
      // Pagamentos
      final rp = await TenantContext.get('${ApiLinks.baseUrl}/api/nfe/$_nfeId/pagamentos');
      if (rp.statusCode == 200) {
        final b = jsonDecode(rp.body);
        final List raw = b is List ? b : (b['data'] is List ? b['data'] : (b['data']?['dados'] ?? b['dados'] ?? []));
        setState(() => _pagamentos = raw.whereType<Map>().map((e) => NfePagamento.fromJson(Map<String, dynamic>.from(e))).toList());
      }
      // Fatura
      final rf = await TenantContext.get('${ApiLinks.baseUrl}/api/nfe/$_nfeId/fatura');
      if (rf.statusCode == 200) {
        try {
          final bf = jsonDecode(rf.body);
          final data = bf is Map ? (bf['data'] ?? bf) : bf;
          if (data is Map) {
            final fatura = NfeFatura.fromJson(Map<String, dynamic>.from(data));
            setState(() {
              _fatura = fatura;
              _fatNFat.text = fatura.nFat ?? '';
              _fatVOrig.text = fatura.vOrig?.toString() ?? '';
              _fatVLiq.text = fatura.vLiq?.toString() ?? '';
            });
          }
        } catch (_) {}
      }
      // Duplicatas
      final rd = await TenantContext.get('${ApiLinks.baseUrl}/api/nfe/$_nfeId/duplicatas');
      if (rd.statusCode == 200) {
        final bd = jsonDecode(rd.body);
        final List rawd = bd is List ? bd : (bd['data'] is List ? bd['data'] : (bd['data']?['dados'] ?? bd['dados'] ?? []));
        setState(() => _duplicatas = rawd.whereType<Map>().map((e) => NfeDuplicata.fromJson(Map<String, dynamic>.from(e))).toList());
      }
    } catch (_) {}
    setState(() => _pagamentosLoading = false);
  }

  Future<void> _adicionarPagamento() async {
    final vPag = double.tryParse(_novoPagVpag.text.replaceAll(',', '.'));
    if (vPag == null || vPag <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe um valor válido'), backgroundColor: _red));
      return;
    }
    try {
      final r = await TenantContext.post('${ApiLinks.baseUrl}/api/nfe/$_nfeId/pagamentos', {'tPag': _novoPagTpag, 'vPag': vPag});
      if (!mounted) return;
      if (r.statusCode == 200 || r.statusCode == 201) {
        _novoPagVpag.clear();
        await _loadPagamentos();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pagamento adicionado!'), backgroundColor: _green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ${r.statusCode}'), backgroundColor: _red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
    }
  }

  Future<void> _removerPagamento(NfePagamento pag) async {
    if (pag.id == null) return;
    try {
      final r = await TenantContext.delete('${ApiLinks.baseUrl}/api/nfe/$_nfeId/pagamentos/${pag.id}');
      if (!mounted) return;
      if (r.statusCode == 200 || r.statusCode == 204) {
        await _loadPagamentos();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ${r.statusCode}'), backgroundColor: _red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
    }
  }

  Future<void> _salvarFatura() async {
    final body = {
      'nFat': _fatNFat.text.trim(),
      'vOrig': double.tryParse(_fatVOrig.text.replaceAll(',', '.')),
      'vLiq': double.tryParse(_fatVLiq.text.replaceAll(',', '.')),
    };
    try {
      final r = _fatura?.id != null
          ? await TenantContext.put('${ApiLinks.baseUrl}/api/nfe/$_nfeId/fatura', body)
          : await TenantContext.post('${ApiLinks.baseUrl}/api/nfe/$_nfeId/fatura', body);
      if (!mounted) return;
      if (r.statusCode == 200 || r.statusCode == 201) {
        await _loadPagamentos();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fatura salva!'), backgroundColor: _green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ${r.statusCode}'), backgroundColor: _red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
    }
  }

  Future<void> _adicionarDuplicata() async {
    final vDup = double.tryParse(_dupVDup.text.replaceAll(',', '.'));
    if (vDup == null || vDup <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe um valor válido'), backgroundColor: _red));
      return;
    }
    final body = {
      'nDup': _dupNDup.text.trim(),
      'dVenc': _dupDVenc.text.trim(),
      'vDup': vDup,
    };
    try {
      final r = await TenantContext.post('${ApiLinks.baseUrl}/api/nfe/$_nfeId/duplicatas', body);
      if (!mounted) return;
      if (r.statusCode == 200 || r.statusCode == 201) {
        _dupNDup.clear(); _dupDVenc.clear(); _dupVDup.clear();
        await _loadPagamentos();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Duplicata adicionada!'), backgroundColor: _green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ${r.statusCode}'), backgroundColor: _red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
    }
  }

  Future<void> _removerDuplicata(NfeDuplicata dup) async {
    if (dup.id == null) return;
    try {
      final r = await TenantContext.delete('${ApiLinks.baseUrl}/api/nfe/$_nfeId/duplicatas/${dup.id}');
      if (!mounted) return;
      if (r.statusCode == 200 || r.statusCode == 204) {
        await _loadPagamentos();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ${r.statusCode}'), backgroundColor: _red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
    }
  }

  Future<void> _gerarContasPagar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Gerar Contas a Pagar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Text('Confirma a geração de Contas a Pagar para a NF-e #$_nfeId?\n'
            'Serão criadas ${_duplicatas.length} conta(s) baseadas nas duplicatas.',
            style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text(GridTexts.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Gerar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final r = await TenantContext.post('${ApiLinks.baseUrl}/api/nfe/$_nfeId/gerar-contas-pagar', {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(r.statusCode == 200 ? 'Contas a Pagar geradas com sucesso!' : 'Erro ${r.statusCode}: ${r.body}'),
        backgroundColor: r.statusCode == 200 ? _green : _red));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
    }
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

  // NF08: usa POST /api/nfe/{id}/emitir (geração de XML real)
  Future<void> _emitir() async {
    if (_isNovo) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salve a NF-e antes de emitir'), backgroundColor: _red));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Emitir NF-e', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Confirma a emissão da NF-e #$_nfeId?', style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 8),
          const Text('O XML será gerado e assinado digitalmente.', style: TextStyle(fontSize: 11, color: _grey)),
        ]),
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
      // NF08: novo endpoint que gera XML real e assina digitalmente
      final r = await TenantContext.post(ApiLinks.emitirNfe(_nfeId), {});
      if (!mounted) return;
      if (r.statusCode == 200 || r.statusCode == 201) {
        setState(() => _statusVal = 'AUTORIZADA');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('NF-e emitida com sucesso! XML gerado e assinado.'),
          backgroundColor: _green));
      } else {
        String msg = 'Erro ${r.statusCode}';
        try {
          final body = jsonDecode(r.body);
          msg = body['message']?.toString() ?? body['mensagem']?.toString() ?? body['error']?.toString() ?? msg;
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: _red));
      }
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
      final r = await TenantContext.post(ApiLinks.cancelarNfe(_nfeId), {'justificativa': motivoCtrl.text.trim()});
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
      final r = await TenantContext.get(ApiLinks.danfeNfe(_nfeId));
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
      final r = await TenantContext.get(ApiLinks.xmlNfe(_nfeId));
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
    final result = await FilePicker.pickFiles(
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
      if (r.statusCode == 200) setState(() => _statusVal = 'CANCELADA');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
    }
  }

  // ── CABEÇALHO com dropdowns ──
  Widget _cabecalho() {
    final hasSession = AuthUtility.userInfo?.login != null;

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
        // Chave: sempre disabled (gerada na transmissão)
        _inpDisabled('Chave', _chaveCtrl),
        // Número: disabled (preenchido automaticamente pela série)
        _inpDisabled('Número', _numeroCtrl),
        // Série: dropdown para SAÍDA (auto-preenche número), input para ENTRADA
        _isEntrada
          ? _inp('Série', _serieCtrl)
          : _ddObjSerie('Série', _serieCtrl.text, _series),
        // Tipo de Operação: usado para pré-preencher CFOP/CST/Alíquota ICMS no Novo Item
        _ddTipoOperacao(),
        // Status: disabled (PENDENTE no insert, muda só ao transmitir)
        _inpDisabledText('Status', _statusVal ?? 'PENDENTE'),
        _dd('Ambiente', _ambienteVal, ['HOMOLOGACAO','PRODUCAO'], (v) => setState(() => _ambienteVal = v)),
        // Empresa: disabled, vem do localstore
        hasSession && _empresaNome != null
          ? _inpDisabledText('Empresa', _empresaNome!)
          : _ddObj('Empresa', _empresaId, _empresas, 'nome', (v) => setState(() => _empresaId = v)),
        // Parceiro: disabled, vem do localstore
        hasSession && _parceiroNome != null
          ? _inpDisabledText('Parceiro', _parceiroNome!)
          : _ddObj('Parceiro', _parceiroId, _parceiros, 'nome', (v) => setState(() => _parceiroId = v)),
        // Destinatário: dropdown filtrado pelos parceiros do parceiro logado
        _ddObjSearch('Destinatário', _destinatarioId, _destinatarios, 'nome',
            (v) => setState(() => _destinatarioId = v)),
        _ddObj('Forma de Pagamento', _formaPagId, _formasPagamento, 'descricao', (v) => setState(() => _formaPagId = v)),
        _ddObj('Finalidade', _finalidadeId, _finalidades, 'descricao', (v) => setState(() => _finalidadeId = v)),
      ]))),
    ]));
  }

  /// Dropdown de Tipo de Operação — define CFOP/CST/Alíquota ICMS herdados pelos itens
  Widget _ddTipoOperacao() {
    final opts = _tiposOperacao.map((e) => <String, dynamic>{
      'id': e['id']?.toString() ?? '',
      'nome': '${e['codigo'] ?? ''} - ${e['descricao'] ?? ''}',
    }).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SearchableDropdownField(
        label: 'Tipo de Operação',
        value: opts.any((o) => o['id'] == _tipoOperacaoId) ? _tipoOperacaoId : null,
        items: opts,
        valueField: 'id',
        displayField: 'nome',
        nullable: true,
        nullLabel: '— Selecione —',
        onChanged: (v) {
          setState(() {
            _tipoOperacaoId = v;
            _topSelected = _tiposOperacao.firstWhere((e) => e['id']?.toString() == v, orElse: () => {});
          });
        },
      ),
    );
  }

  /// Campo de texto desabilitado (readonly visual)
  Widget _inpDisabled(String label, TextEditingController ctrl) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextFormField(
      controller: ctrl,
      enabled: false,
      style: const TextStyle(fontSize: 12, color: _grey),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 11, color: _grey),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: _bord)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: _bord)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
    ),
  );

  /// Campo de texto desabilitado com valor fixo (sem controller)
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

  Widget _ddObjSearch(String label, String? val, List<Map<String, dynamic>> opts,
      String displayField, void Function(String?) cb) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SearchableDropdownField(
        label: label,
        value: opts.any((o) => o['id']?.toString() == val) ? val : null,
        items: opts
            .map((o) => <String, dynamic>{
                  'id': o['id']?.toString() ?? '',
                  'nome': o[displayField]?.toString() ?? '',
                })
            .toList(),
        valueField: 'id',
        displayField: 'nome',
        nullable: true,
        nullLabel: '— Selecione —',
        onChanged: cb,
      ),
    );
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
    child: SearchableDropdownField(
      label: label,
      value: val,
      items: opts.map((o) => <String, dynamic>{'id': o, 'nome': o}).toList(),
      valueField: 'id',
      displayField: 'nome',
      nullable: true,
      nullLabel: '— Selecione —',
      onChanged: cb,
    ));

  Widget _ddObj(String label, String? val, List<Map<String, dynamic>> opts, String displayField, void Function(String?) cb) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SearchableDropdownField(
        label: label,
        value: opts.any((o) => o['id']?.toString() == val) ? val : null,
        items: opts
            .map((o) => <String, dynamic>{
                  'id': o['id']?.toString() ?? '',
                  'nome': o[displayField]?.toString() ?? '',
                })
            .toList(),
        valueField: 'id',
        displayField: 'nome',
        nullable: true,
        nullLabel: '— Selecione —',
        onChanged: cb,
      ),
    );
  }

  Future<void> _salvarItem(Map<String, dynamic> item) async {
    final isNew = item['id'] == null;
    final body = <String, dynamic>{
      if (!isNew) 'id': item['id'],
      'nfeId': item['nfe_id'] ?? int.tryParse(_nfeId),
      if (item['produto'] != null) 'produto': item['produto'],
      'xProd':    item['x_prod']    ?? item['xProd']    ?? '',
      'ncm':      item['ncm']       ?? '',
      'cfop':     item['cfop']      ?? '',
      'uCom':     item['u_com']     ?? item['uCom']     ?? '',
      'qCom':     double.tryParse((item['q_com']     ?? item['qCom']     ?? '').toString()),
      'vUnCom':   double.tryParse((item['v_un_com']  ?? item['vUnCom']   ?? '').toString()),
      'vProd':    double.tryParse((item['v_prod']    ?? item['vProd']    ?? '').toString()),
      'cstIcms':  item['cst_icms']  ?? item['cstIcms']  ?? '',
      'aliqIcms': double.tryParse((item['aliq_icms'] ?? item['aliqIcms'] ?? '').toString()),
      'vIcms':    double.tryParse((item['v_icms']    ?? item['vIcms']    ?? '').toString()),
    };
    try {
      final r = isNew
          ? await TenantContext.post('${ApiLinks.baseUrl}/api/nfe_item', body)
          : await TenantContext.put('${ApiLinks.baseUrl}/api/nfe_item/${item['id']}', body);
      if (!mounted) return;
      if (r.statusCode == 200 || r.statusCode == 201) {
        if (isNew) {
          try {
            final b = jsonDecode(r.body);
            final newId = b is Map
                ? (b['data'] is Map ? b['data']['id'] : (b['data'] ?? b['id']))
                : null;
            if (newId != null) setState(() => item['id'] = newId);
          } catch (_) {}
        }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Item salvo!'), backgroundColor: _green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ${r.statusCode}'), backgroundColor: _red));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro: $e'), backgroundColor: _red));
      }
    }
  }

  Future<void> _salvarCabecalho() async {
    final body = <String, dynamic>{
      if (!_isNovo) 'id': widget.item['id'],
      'chave': _chaveCtrl.text, 'numero': _numeroCtrl.text, 'serie': _serieCtrl.text,
      if (_statusVal != null) 'status': _statusVal,
      if (_ambienteVal != null) 'ambiente': _ambienteVal,
      'tipoOperacao': widget.item['tipoOperacao'] ?? 'SAIDA',
      if (_empresaId != null) 'empresa': {'id': int.tryParse(_empresaId!) ?? _empresaId},
      if (_parceiroId != null) 'parceiro': {'id': int.tryParse(_parceiroId!) ?? _parceiroId},
      if (_destinatarioId != null) 'destinatario': {'id': int.tryParse(_destinatarioId!) ?? _destinatarioId},
      if (_formaPagId != null) 'formaPagamento': {'id': int.tryParse(_formaPagId!) ?? _formaPagId},
      if (_finalidadeId != null) 'nfeFinalidade': {'id': int.tryParse(_finalidadeId!) ?? _finalidadeId},
      if (_tipoOperacaoId != null) 'nfeTipoOperacao': {'id': int.tryParse(_tipoOperacaoId!) ?? _tipoOperacaoId},
    };
    try {
      final r = _isNovo
          ? await TenantContext.post('${ApiLinks.baseUrl}/api/nfe', body)
          : await TenantContext.put('${ApiLinks.baseUrl}/api/nfe/${widget.item['id']}', body);
      if (!mounted) return;
      if (r.statusCode == 200 || r.statusCode == 201) {
        // Para nova NF-e: captura o ID retornado e carrega os itens/contas
        if (_isNovo) {
          try {
            final b = jsonDecode(r.body);
            final newId = b is Map ? (b['data'] is Map ? b['data']['id'] : (b['data'] ?? b['id'])) : null;
            if (newId != null) {
              setState(() => widget.item['id'] = newId);
              _loadItens();
              _loadContas();
            }
          } catch (_) {}
        }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salvo!'), backgroundColor: _green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ${r.statusCode}'), backgroundColor: _red));
      }
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
      _ddObjItem('Unidade', item['u_com']?.toString() ?? item['uCom']?.toString(), _unidades.isNotEmpty ? _unidades : _unidadesFallback(), 'nome', (v) {
        setState(() { item['u_com'] = v; item['uCom'] = v; });
      }),
      _iInp('Quantidade', item, 'q_com', 'qCom'),
      _iInp('Vl. Unitário', item, 'v_un_com', 'vUnCom'),
      _iInp('Vl. Total', item, 'v_prod', 'vProd'),
      _iInp('CST ICMS', item, 'cst_icms', 'cstIcms'),
      _iInp('Alíq. ICMS', item, 'aliq_icms', 'aliqIcms'),
      _iInp('BC ICMS', item, 'v_bc_icms', 'vBcIcms'),
      _iInp('Vl. ICMS', item, 'v_icms', 'vIcms'),
      // NF03: Botão Calcular ICMS
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SizedBox(width: double.infinity, child: OutlinedButton.icon(
          onPressed: () => _calcularIcms(item),
          icon: const Icon(Icons.calculate_outlined, size: 14),
          label: const Text('Calcular ICMS', style: TextStyle(fontSize: 11)),
          style: OutlinedButton.styleFrom(foregroundColor: _green, side: const BorderSide(color: _green),
            padding: const EdgeInsets.symmetric(vertical: 6)),
        )),
      ),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: ElevatedButton.icon(
        onPressed: () => _salvarItem(item),
        icon: const Icon(Icons.save, size: 14),
        label: const Text('Salvar Item', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 10)))),
    ]));
  }

  // NF03: Calculadora ICMS
  Future<void> _calcularIcms(Map<String, dynamic> item) async {
    try {
      final body = <String, dynamic>{
        if (item['id'] != null) 'id': item['id'],
        'cstIcms': item['cst_icms'] ?? item['cstIcms'],
        'aliqIcms': double.tryParse((item['aliq_icms'] ?? item['aliqIcms'] ?? '').toString()),
        'vProd': double.tryParse((item['v_prod'] ?? item['vProd'] ?? '').toString()),
        'qCom': double.tryParse((item['q_com'] ?? item['qCom'] ?? '').toString()),
        'vUnCom': double.tryParse((item['v_un_com'] ?? item['vUnCom'] ?? '').toString()),
      };
      final r = await TenantContext.post('${ApiLinks.baseUrl}/api/nfe_item/calcular-icms', body);
      if (!mounted) return;
      if (r.statusCode == 200) {
        final calculated = jsonDecode(r.body);
        final data = calculated is Map ? (calculated['data'] ?? calculated) : calculated;
        setState(() {
          item['v_bc_icms'] = (data['vBcIcms'] ?? data['v_bc_icms'] ?? 0).toString();
          item['vBcIcms']   = item['v_bc_icms'];
          item['v_icms']    = (data['vIcms'] ?? data['v_icms'] ?? 0).toString();
          item['vIcms']     = item['v_icms'];
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ICMS calculado!'), backgroundColor: _green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ${r.statusCode}'), backgroundColor: _red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
    }
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SearchableDropdownField(
        label: label,
        value: opts.any((o) => o['id']?.toString() == val) ? val : null,
        items: opts
            .map((o) => <String, dynamic>{
                  'id': o['id']?.toString() ?? '',
                  'nome': '${o['serie'] ?? ''} (atual: ${o['numeroAtual'] ?? 1})',
                })
            .toList(),
        valueField: 'id',
        displayField: 'nome',
        nullable: true,
        nullLabel: '— Selecione —',
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
        },
      ),
    );
  }

  Widget _ddObjItem(String label, String? val, List<Map<String, dynamic>> opts, String df, void Function(String?) cb) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SearchableDropdownField(
        label: label,
        value: opts.any((o) => o['id']?.toString() == val) ? val : null,
        items: opts
            .map((o) => <String, dynamic>{
                  'id': o['id']?.toString() ?? '',
                  'nome': o[df]?.toString() ?? '',
                })
            .toList(),
        valueField: 'id',
        displayField: 'nome',
        nullable: true,
        nullLabel: '— Selecione —',
        onChanged: cb,
      ),
    );
  }

  void _novoItem() => setState(() {
    final novoItem = <String, dynamic>{'nfe_id': int.tryParse(_nfeId) ?? 0};
    if (_topSelected.isNotEmpty) {
      novoItem['cfop'] = _topSelected['cfop']?.toString() ?? '';
      novoItem['cst_icms'] = _topSelected['cstIcms']?.toString() ?? '';
      novoItem['aliq_icms'] = _topSelected['aliqIcms']?.toString() ?? '';
    }
    _itens.add(novoItem);
    _selItem = _itens.length - 1;
    _itensGrid = false;
  });

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
    {'id': 'UN', 'nome': 'UN', 'descricao': 'Unidade'},
    {'id': 'KG', 'nome': 'KG', 'descricao': 'Quilograma'},
    {'id': 'G', 'nome': 'G', 'descricao': 'Grama'},
    {'id': 'L', 'nome': 'L', 'descricao': 'Litro'},
    {'id': 'ML', 'nome': 'ML', 'descricao': 'Mililitro'},
    {'id': 'M', 'nome': 'M', 'descricao': 'Metro'},
    {'id': 'M2', 'nome': 'M2', 'descricao': 'Metro Quadrado'},
    {'id': 'M3', 'nome': 'M3', 'descricao': 'Metro Cúbico'},
    {'id': 'CX', 'nome': 'CX', 'descricao': 'Caixa'},
    {'id': 'PC', 'nome': 'PC', 'descricao': 'Peça'},
    {'id': 'PAR', 'nome': 'PAR', 'descricao': 'Par'},
    {'id': 'DZ', 'nome': 'DZ', 'descricao': 'Dúzia'},
    {'id': 'SC', 'nome': 'SC', 'descricao': 'Saco'},
    {'id': 'T', 'nome': 'T', 'descricao': 'Tonelada'},
  ];

  Widget _togBtn(IconData ic, bool on, VoidCallback cb) => InkWell(onTap: cb,
    child: Container(padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: on ? _green : Colors.transparent, borderRadius: BorderRadius.circular(4), border: Border.all(color: on ? _green : _bord)),
      child: Icon(ic, size: 16, color: on ? Colors.white : _grey)));

  Widget _nb(IconData ic, VoidCallback cb) => InkWell(onTap: cb,
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 1), child: Icon(ic, size: 18, color: _dark)));

  // ── RODAPÉ ──
  Widget _rodape() {
    final tabs = ['Totais', 'Impostos', 'Financeiro', 'Pagamentos'];
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
      case 3: return _pagamentosTab();
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

  // ── TAREFA NF07: Aba de Pagamentos ────────────────────────────────────────
  Widget _pagamentosTab() {
    if (_isNovo) {
      return const Center(child: Text('Salve a NF-e antes de gerenciar pagamentos.', style: TextStyle(color: _grey, fontSize: 12)));
    }
    if (_pagamentosLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final valorTotal = (widget.item['valorTotal'] as num?)?.toDouble() ?? 0;
    final totalPago = _pagamentos.fold<double>(0, (s, p) => s + p.vPag);
    final diferenca = totalPago - valorTotal;
    final okPago = diferenca.abs() <= 0.01;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Seção 1: Formas de Pagamento ──────────────────────────────────
        _secTitle('Formas de Pagamento'),
        const SizedBox(height: 6),
        ..._pagamentos.map((pag) => Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _bord), borderRadius: BorderRadius.circular(4)),
          child: Row(children: [
            Expanded(child: Text(NfePagamento.labelTipo(pag.tPag), style: const TextStyle(fontSize: 12))),
            const SizedBox(width: 8),
            Text('R\$ ${pag.vPag.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            IconButton(icon: const Icon(Icons.delete_outline, size: 16, color: _red),
              padding: EdgeInsets.zero, constraints: const BoxConstraints(),
              onPressed: () => _removerPagamento(pag)),
          ]),
        )),

        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFFF8F8F8), border: Border.all(color: _bord), borderRadius: BorderRadius.circular(4)),
          child: Row(children: [
            SizedBox(width: 160,
              child: DropdownButtonFormField<String>(
                initialValue: _novoPagTpag, isDense: true,
                decoration: const InputDecoration(labelText: 'Tipo', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6), border: OutlineInputBorder()),
                style: const TextStyle(fontSize: 12, color: _dark),
                items: NfePagamento.todosCodigos.map((c) => DropdownMenuItem(value: c, child: Text('$c - ${NfePagamento.labelTipo(c)}', style: const TextStyle(fontSize: 11)))).toList(),
                onChanged: (v) => setState(() => _novoPagTpag = v ?? '01'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: TextFormField(
              controller: _novoPagVpag,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(labelText: 'Valor (R\$)', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6), border: OutlineInputBorder()),
            )),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _adicionarPagamento,
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Adicionar', style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
            ),
          ]),
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: okPago ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(4), border: Border.all(color: okPago ? _green : _red)),
          child: Row(children: [
            const Icon(Icons.info_outline, size: 14),
            const SizedBox(width: 6),
            Text('Total pago: R\$ ${totalPago.toStringAsFixed(2)}  |  Total NF-e: R\$ ${valorTotal.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 11, color: okPago ? _green : _red, fontWeight: FontWeight.bold)),
            if (!okPago) ...[
              const SizedBox(width: 6),
              Text('(dif: R\$ ${diferenca.toStringAsFixed(2)})', style: const TextStyle(fontSize: 10, color: _red)),
            ],
          ]),
        ),

        const SizedBox(height: 16),
        const Divider(),

        // ── Seção 2: Fatura ───────────────────────────────────────────────
        _secTitle('Fatura'),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: TextFormField(controller: _fatNFat, style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(labelText: 'Número da Fatura', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6), border: OutlineInputBorder()))),
          const SizedBox(width: 8),
          Expanded(child: TextFormField(controller: _fatVOrig, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(labelText: 'Valor Original', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6), border: OutlineInputBorder()))),
          const SizedBox(width: 8),
          Expanded(child: TextFormField(controller: _fatVLiq, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(labelText: 'Valor Líquido', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6), border: OutlineInputBorder()))),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _salvarFatura,
            style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            child: const Text('Salvar Fatura', style: TextStyle(fontSize: 11)),
          ),
        ]),

        const SizedBox(height: 16),
        const Divider(),

        // ── Seção 3: Duplicatas ───────────────────────────────────────────
        _secTitle('Duplicatas'),
        const SizedBox(height: 6),
        ..._duplicatas.map((dup) => Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _bord), borderRadius: BorderRadius.circular(4)),
          child: Row(children: [
            Expanded(child: Text(dup.nDup ?? '-', style: const TextStyle(fontSize: 12))),
            const SizedBox(width: 8),
            Text(dup.dVenc ?? '-', style: const TextStyle(fontSize: 11, color: _grey)),
            const SizedBox(width: 8),
            Text('R\$ ${(dup.vDup ?? 0).toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            IconButton(icon: const Icon(Icons.delete_outline, size: 16, color: _red),
              padding: EdgeInsets.zero, constraints: const BoxConstraints(),
              onPressed: () => _removerDuplicata(dup)),
          ]),
        )),

        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFFF8F8F8), border: Border.all(color: _bord), borderRadius: BorderRadius.circular(4)),
          child: Row(children: [
            Expanded(child: TextFormField(controller: _dupNDup, style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(labelText: 'Nº Dup.', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6), border: OutlineInputBorder()))),
            const SizedBox(width: 8),
            Expanded(child: TextFormField(controller: _dupDVenc, style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(labelText: 'Dt. Venc. (AAAA-MM-DD)', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6), border: OutlineInputBorder()))),
            const SizedBox(width: 8),
            Expanded(child: TextFormField(controller: _dupVDup, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(labelText: 'Valor', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6), border: OutlineInputBorder()))),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _adicionarDuplicata,
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Adicionar', style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
            ),
          ]),
        ),

        const SizedBox(height: 16),
        const Divider(),

        // ── Botão: Gerar Contas a Pagar ───────────────────────────────────
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          icon: const Icon(Icons.receipt_long),
          label: const Text('Gerar Contas a Pagar', style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(backgroundColor: _red, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12)),
          onPressed: _duplicatas.isEmpty ? null : _gerarContasPagar,
        )),
        if (_duplicatas.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('Adicione duplicatas antes de gerar as contas.', style: TextStyle(fontSize: 11, color: _grey)),
          ),

      ]),
    );
  }

  Widget _secTitle(String title) => Text(title,
    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _dark));
}

// ─── Widget de busca rápida para destinatário ─────────────────────────────────

class _DestinatarioSearch extends StatefulWidget {
  final List<Map<String, dynamic>> opts;
  final String displayField;
  final void Function(String id, String nome) onSelect;

  const _DestinatarioSearch({
    required this.opts,
    required this.displayField,
    required this.onSelect,
  });

  @override
  State<_DestinatarioSearch> createState() => _DestinatarioSearchState();
}

class _DestinatarioSearchState extends State<_DestinatarioSearch> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _filtered = [];
  bool _show = false;

  void _onChanged(String q) {
    final query = q.toLowerCase().trim();
    setState(() {
      _show = query.isNotEmpty;
      _filtered = query.isEmpty
          ? []
          : widget.opts
              .where((o) => (o[widget.displayField]?.toString() ?? '')
                  .toLowerCase()
                  .contains(query))
              .take(8)
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _ctrl,
          onChanged: _onChanged,
          style: const TextStyle(fontSize: 11),
          decoration: InputDecoration(
            hintText: 'Buscar destinatário...',
            hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
            prefixIcon: const Icon(Icons.search, size: 14, color: Color(0xFF9E9E9E)),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
          ),
        ),
        if (_show && _filtered.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFDDDDDD)),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)],
            ),
            child: Column(
              children: _filtered.map((o) {
                final id = o['id']?.toString() ?? '';
                final nome = o[widget.displayField]?.toString() ?? '';
                return InkWell(
                  onTap: () {
                    widget.onSelect(id, nome);
                    _ctrl.clear();
                    setState(() { _show = false; _filtered = []; });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
                    ),
                    child: Text(nome, style: const TextStyle(fontSize: 12)),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
