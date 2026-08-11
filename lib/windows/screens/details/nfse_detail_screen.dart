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

/// Largura mínima de campo antes de quebrar linha no grid responsivo das
/// seções (breakpoint informal, não usa MediaQuery global do app).
const double _kCampoMinWidth = 260;

/// Tela de inserção/detalhe de NFSe.
///
/// Layout reorganizado (2026-08) em seções sequenciais tipo card — Dados da
/// Nota, Itens (Serviços), Impostos e Totais — inspirado no padrão
/// Conta Azul / Omie, substituindo o antigo layout de coluna estreita fixa +
/// grid lateral redimensionável que ficava assimétrico e com inputs
/// apertados. Este arquivo é a implementação real usada tanto pelo Windows
/// desktop quanto pelo Web (lib/web/screens/bottom_navbar_screen.dart importa
/// NfseScreen de windows/screens/nfse_screen.dart) — o card de bug era Web,
/// mas a tela é compartilhada.
class NfseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  const NfseDetailScreen({super.key, required this.item});
  @override
  State<NfseDetailScreen> createState() => _NfseDetailScreenState();
}

class _NfseDetailScreenState extends State<NfseDetailScreen> {
  bool _itensGrid = true;
  int _selItem = 0;

  List<Map<String, dynamic>> _itens = [];

  // Dropdowns
  final List<Map<String, dynamic>> _empresas = [];
  List<Map<String, dynamic>> _tomadores = []; // parceiros
  List<Map<String, dynamic>> _produtos = []; // somente isServico == true
  List<Map<String, dynamic>> _series = []; // nfse_serie
  List<Map<String, dynamic>> _cidades = []; // todas as cidades

  // Controllers cabeçalho
  final _numeroCtrl = TextEditingController();
  final _serieCtrl = TextEditingController();
  final _municipioCtrl = TextEditingController();
  final _codigoServicoCtrl = TextEditingController();
  String? _statusVal;
  String? _ambienteVal;
  String? _empresaId;
  String? _tomadorId;
  String? _serieId;
  String? _cidadeId;
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
    _municipioCtrl.text =
        i['municipioPrestacao']?.toString() ?? i['municipio']?.toString() ?? '';
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
            : (i['parceiro'] is Map
                ? i['parceiro']['id']
                : i['tomador'] ?? i['parceiro']))
        ?.toString();

    // Série: tentar extrair id da série (se vier como objeto) ou usar o valor textual
    if (i['serie'] is Map) {
      _serieId = i['serie']['id']?.toString();
      _serieCtrl.text = i['serie']['serie']?.toString() ?? '';
    } else {
      _serieCtrl.text = i['serie']?.toString() ?? '';
    }

    // Cidade: tentar extrair id (se vier como objeto) ou buscar pelo nome
    if (i['cidade'] is Map) {
      _cidadeId = i['cidade']['id']?.toString();
    }
    if (i['municipioPrestacao'] != null) {
      _municipioCtrl.text = i['municipioPrestacao']?.toString() ?? '';
    }

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
      _loadList(
          '${ApiLinks.baseUrl}/api/parceiro?tamanho=500${empId != null ? '&empId=$empId' : ''}',
          (d) => setState(() => _tomadores = d)),
      _loadProdutosServico(empId),
      _loadList(
          '${ApiLinks.baseUrl}/api/nfse-serie?tamanho=100${empId != null ? '&empId=$empId' : ''}',
          (d) => setState(() => _series = d)),
      _loadList('${ApiLinks.baseUrl}/api/cidade?tamanho=5000',
          (d) => setState(() => _cidades = d)),
    ]);
  }

  /// Busca produtos de serviço via /api/produto_contabil (retorna entity completa com isServico)
  Future<void> _loadProdutosServico(String? empId) async {
    final base = '${ApiLinks.baseUrl}/api/produto-contabil?tamanho=500'
        '${empId != null ? '&empId=$empId' : ''}&isServico=true';
    List<Map<String, dynamic>> produtos = [];
    await _loadList(base, (d) => produtos = d);
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
        cb(raw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList());
      }
    } catch (_) {}
  }

  Future<void> _loadItens() async {
    try {
      final r = await TenantContext.get(
          '${ApiLinks.baseUrl}/api/nfse_item?nfseId=$_nfseId&tamanho=100');
      if (r.statusCode == 200) {
        final b = jsonDecode(r.body);
        final d =
            b is Map ? (b['data'] is Map ? b['data']['dados'] : b['data']) : b;
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
      if (_empresaId != null)
        'empresa': {'id': int.tryParse(_empresaId!) ?? _empresaId},
      if (_tomadorId != null)
        'tomador': {'id': int.tryParse(_tomadorId!) ?? _tomadorId},
      if (_dataEmissao != null)
        'dataEmissao': _dataEmissao!.toIso8601String().substring(0, 10),
      if (_dataCompetencia != null)
        'dataCompetencia': _dataCompetencia!.toIso8601String().substring(0, 10),
    };
    try {
      final r = _isNovo
          ? await TenantContext.post('${ApiLinks.baseUrl}/api/nfse', body)
          : await TenantContext.put(
              '${ApiLinks.baseUrl}/api/nfse/${widget.item['id']}', body);
      if (!mounted) return;
      if (r.statusCode == 200 || r.statusCode == 201) {
        if (_isNovo) {
          try {
            final b = jsonDecode(r.body);
            final newId = b is Map
                ? (b['data'] is Map ? b['data']['id'] : (b['data'] ?? b['id']))
                : null;
            if (newId != null) {
              setState(() => widget.item['id'] = newId);
              _loadItens();
            }
          } catch (_) {}
        }
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Salvo!'), backgroundColor: _green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ${r.statusCode}: ${r.body}'),
            backgroundColor: _red));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
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
      'valorUnitario': double.tryParse(
          (item['valorUnitario'] ?? item['valor_unitario'] ?? '').toString()),
      'valorTotal': double.tryParse(
          (item['valorTotal'] ?? item['valor_total'] ?? '').toString()),
      'aliquotaIss': double.tryParse(
          (item['aliquotaIss'] ?? item['aliquota_iss'] ?? '').toString()),
      'valorIss': double.tryParse(
          (item['valorIss'] ?? item['valor_iss'] ?? '').toString()),
      'codigoTributacaoMunicipal': item['codigoTributacaoMunicipal'] ??
          item['codigo_tributacao_municipal'] ??
          '',
      'issRetido': item['issRetido'] == true || item['iss_retido'] == true,
    };
    try {
      final r = isNew
          ? await TenantContext.post('${ApiLinks.baseUrl}/api/nfse_item', body)
          : await TenantContext.put(
              '${ApiLinks.baseUrl}/api/nfse_item/${item['id']}', body);
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
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
    }
  }

  void _novoItem() => setState(() {
        _itens.add({'nfse_id': int.tryParse(_nfseId) ?? 0});
        _selItem = _itens.length - 1;
        _itensGrid = false;
      });

  // ── Build ─────────────────────────────────────────────────────────────────
  //
  // Layout em seções sequenciais (Dados da Nota → Itens → Impostos →
  // Totais), cada uma em um card de largura total, com os campos internos
  // organizados em um grid responsivo (Wrap). Substitui o antigo layout de
  // coluna estreita fixa (320px) + grid lateral redimensionável, que ficava
  // assimétrico e comprimia os campos do cabeçalho.

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
            label: const Text('Salvar',
                style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _secaoDadosDaNota(),
                const SizedBox(height: 16),
                _secaoItens(),
                const SizedBox(height: 16),
                _secaoImpostos(),
                const SizedBox(height: 16),
                _secaoTotais(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Card de seção padrão — cabeçalho colorido + conteúdo, usado por todas
  /// as seções desta tela para manter consistência visual (mesmo padrão do
  /// cabeçalho verde já usado no restante do app).
  Widget _secao({
    required String titulo,
    required Widget child,
    Widget? trailing,
    Key? key,
  }) {
    return Container(
      key: key,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _bord),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: _green,
          child: LayoutBuilder(builder: (context, constraints) {
            final tituloWidget = Text(
              titulo,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            );
            if (trailing == null) return tituloWidget;

            if (constraints.maxWidth < 640) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  tituloWidget,
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: trailing,
                  ),
                ],
              );
            }

            return Row(children: [
              Expanded(child: tituloWidget),
              trailing,
            ]);
          }),
        ),
        Padding(padding: const EdgeInsets.all(14), child: child),
      ]),
    );
  }

  /// Grid responsivo de campos: quebra em colunas conforme a largura
  /// disponível, em vez da coluna única estreita do layout antigo.
  Widget _grid(List<Widget> campos) {
    return LayoutBuilder(builder: (context, constraints) {
      final double largura = constraints.maxWidth;
      double colWidth;
      if (largura < _kCampoMinWidth) {
        colWidth = largura;
      } else if ((largura - 24) / 3 >= _kCampoMinWidth) {
        colWidth = (largura - 24) / 3;
      } else if ((largura - 12) / 2 >= _kCampoMinWidth) {
        colWidth = (largura - 12) / 2;
      } else {
        colWidth = largura;
      }
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children:
            campos.map((c) => SizedBox(width: colWidth, child: c)).toList(),
      );
    });
  }

  // ── SEÇÃO: Dados da Nota ──
  Widget _secaoDadosDaNota() {
    final hasSession = AuthUtility.userInfo?.login != null;
    return _secao(
      key: const Key('secao_dados_nota'),
      titulo: 'Dados da Nota',
      trailing: SizedBox(
        height: 26,
        child: ElevatedButton.icon(
          onPressed: _salvarCabecalho,
          icon: const Icon(Icons.save, size: 12),
          label: const Text('Salvar', style: TextStyle(fontSize: 11)),
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _green,
              padding: const EdgeInsets.symmetric(horizontal: 8)),
        ),
      ),
      child: _grid([
        hasSession && _empresaNome != null
            ? _inpDisabledText('Empresa', _empresaNome!)
            : _ddObj('Empresa', _empresaId, _empresas, 'nome',
                (v) => setState(() => _empresaId = v)),
        _ddObj('Tomador / Parceiro', _tomadorId, _tomadores, 'nome',
            (v) => setState(() => _tomadorId = v)),
        _ddSerie(),
        _inp('Número', _numeroCtrl),
        _dateField('Data Emissão', _dataEmissao,
            (d) => setState(() => _dataEmissao = d)),
        _dateField('Data Competência', _dataCompetencia,
            (d) => setState(() => _dataCompetencia = d)),
        _ddCidade(),
        _inp('Código de Serviço Municipal', _codigoServicoCtrl),
        _inpDisabledText('Status', _statusVal ?? 'PENDENTE'),
        _dd('Ambiente', _ambienteVal, ['HOMOLOGACAO', 'PRODUCAO'],
            (v) => setState(() => _ambienteVal = v)),
      ]),
    );
  }

  Widget _inp(String label, TextEditingController ctrl) => TextFormField(
        controller: ctrl,
        style: const TextStyle(fontSize: 12, color: _dark),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 11, color: _grey),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: _bord)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: _green, width: 1.5)),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
      );

  Widget _inpDisabledText(String label, String value) => InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 11, color: _grey),
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: _bord)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: _bord)),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
        child: Text(value, style: const TextStyle(fontSize: 12, color: _grey)),
      );

  Widget _dd(String label, String? val, List<String> opts,
          void Function(String?) cb) =>
      SearchableDropdownField(
        label: label,
        value: val,
        items: opts.map((o) => <String, dynamic>{'id': o, 'nome': o}).toList(),
        valueField: 'id',
        displayField: 'nome',
        nullable: true,
        nullLabel: '— Selecione —',
        onChanged: cb,
      );

  Widget _ddObj(String label, String? val, List<Map<String, dynamic>> opts,
      String displayField, void Function(String?) cb) {
    return SearchableDropdownField(
      label: label,
      value: opts.any((o) => o['id']?.toString() == val) ? val : null,
      items: opts
          .map((o) => <String, dynamic>{
                'id': o['id']?.toString() ?? '',
                'nome': o[displayField]?.toString() ?? ''
              })
          .toList(),
      valueField: 'id',
      displayField: 'nome',
      nullable: true,
      nullLabel: '— Selecione —',
      onChanged: cb,
    );
  }

  /// Dropdown de Série NFSe — carrega de /api/nfse-serie
  Widget _ddSerie() {
    return SearchableDropdownField(
      label: 'Série',
      value:
          _series.any((o) => o['id']?.toString() == _serieId) ? _serieId : null,
      items: _series
          .map((s) => <String, dynamic>{
                'id': s['id']?.toString() ?? '',
                'nome': '${s['serie'] ?? ''} (atual: ${s['numeroAtual'] ?? 1})',
              })
          .toList(),
      valueField: 'id',
      displayField: 'nome',
      nullable: true,
      nullLabel: '— Selecione —',
      onChanged: (v) {
        setState(() => _serieId = v);
        final s = _series.firstWhere((o) => o['id']?.toString() == v,
            orElse: () => {});
        if (s.isNotEmpty) {
          _serieCtrl.text = s['serie']?.toString() ?? '';
          // Auto-preencher próximo número
          final proximo = int.tryParse(s['numeroAtual'].toString()) ?? 1;
          _numeroCtrl.text = proximo.toString();
        }
      },
    );
  }

  /// Dropdown de Município (Cidade) — carrega de /api/cidade
  /// Ao selecionar, preenche o código de serviço municipal se a cidade tiver
  Widget _ddCidade() {
    return SearchableDropdownField(
      label: 'Município de Prestação',
      value: _cidades.any((o) => o['id']?.toString() == _cidadeId)
          ? _cidadeId
          : null,
      items: _cidades
          .map((c) => <String, dynamic>{
                'id': c['id']?.toString() ?? '',
                'nome': c['nome']?.toString() ?? '',
              })
          .toList(),
      valueField: 'id',
      displayField: 'nome',
      nullable: true,
      nullLabel: '— Selecione —',
      onChanged: (v) {
        setState(() => _cidadeId = v);
        final c = _cidades.firstWhere((o) => o['id']?.toString() == v,
            orElse: () => {});
        if (c.isNotEmpty) {
          _municipioCtrl.text = c['nome']?.toString() ?? '';
          // Auto-preencher código de serviço municipal se a cidade tiver
          final codServico = c['codigoServicoMunicipal']?.toString();
          if (codServico != null && codServico.isNotEmpty) {
            _codigoServicoCtrl.text = codServico;
          }
        }
      },
    );
  }

  Widget _dateField(String label, DateTime? val, void Function(DateTime?) cb) {
    return GestureDetector(
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
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: _bord)),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
    );
  }

  // ── SEÇÃO: Itens (Serviços) ──
  Widget _secaoItens() {
    return _secao(
      key: const Key('secao_itens'),
      titulo: 'Itens (Serviços)',
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        _togBtn(Icons.view_list, _itensGrid,
            () => setState(() => _itensGrid = true)),
        const SizedBox(width: 4),
        _togBtn(Icons.edit_note, !_itensGrid,
            () => setState(() => _itensGrid = false)),
        const SizedBox(width: 8),
        SizedBox(
            height: 26,
            child: ElevatedButton.icon(
                onPressed: _novoItem,
                icon: const Icon(Icons.add, size: 12),
                label: const Text('Novo', style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _green,
                    padding: const EdgeInsets.symmetric(horizontal: 10)))),
        if (!_itensGrid && _itens.isNotEmpty) ...[
          const SizedBox(width: 4),
          SizedBox(
              height: 26,
              child: ElevatedButton.icon(
                  onPressed: () => _salvarItem(_itens[_selItem]),
                  icon: const Icon(Icons.save, size: 12),
                  label: const Text('Salvar', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _green,
                      padding: const EdgeInsets.symmetric(horizontal: 8)))),
        ],
        if (!_itensGrid && _itens.isNotEmpty) ...[
          const SizedBox(width: 8),
          _nb(Icons.first_page, () => setState(() => _selItem = 0)),
          _nb(
              Icons.chevron_left,
              () => setState(() {
                    if (_selItem > 0) _selItem--;
                  })),
          Text(' ${_selItem + 1}/${_itens.length} ',
              style: const TextStyle(fontSize: 11, color: Colors.white)),
          _nb(
              Icons.chevron_right,
              () => setState(() {
                    if (_selItem < _itens.length - 1) _selItem++;
                  })),
          _nb(Icons.last_page,
              () => setState(() => _selItem = _itens.length - 1)),
        ],
      ]),
      child: SizedBox(
        height: 420,
        child: _itensGrid
            ? _gridSemHeader(
                telaNome: 'nfse_item',
                extraParams: {'nfseId': _nfseId, 'nfse_id': _nfseId})
            : (_itens.isEmpty
                ? const Center(
                    child: Text('Nenhum item', style: TextStyle(color: _grey)))
                : _iForm()),
      ),
    );
  }

  Widget _iForm() {
    if (_selItem >= _itens.length) return const SizedBox();
    final item = _itens[_selItem];
    final prodId =
        (item['produto'] is Map ? item['produto']['id'] : item['produto_id'])
            ?.toString();
    return SingleChildScrollView(
      child: Column(children: [
        _grid([
          // Produto — somente os marcados como serviço (Produto.isServico == true)
          _ddObjItem('Produto (Serviço)', prodId, _produtos, 'nome', (v) {
            final prod = _produtos.firstWhere((p) => p['id']?.toString() == v,
                orElse: () => {});
            setState(() {
              item['produto'] = {'id': int.tryParse(v ?? '') ?? v};
              if (prod.isNotEmpty) {
                item['descricao'] = prod['nome']?.toString() ?? '';
                item['valorUnitario'] = prod['preco']?.toString() ?? '';
                item['aliquotaIss'] = prod['aliquotaIss']?.toString() ??
                    prod['aliquota_iss']?.toString() ??
                    '';
                item['codigoTributacaoMunicipal'] =
                    prod['codigoTributacaoMunicipal']?.toString() ?? '';
              }
            });
          }),
          _iInp('Descrição', item, 'descricao'),
          _iInp('Quantidade', item, 'quantidade'),
          _iInp('Vl. Unitário', item, 'valorUnitario'),
          _iInp('Vl. Total', item, 'valorTotal'),
        ]),
        const SizedBox(height: 12),
        SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
                onPressed: () => _salvarItem(item),
                icon: const Icon(Icons.save, size: 14),
                label: const Text('Salvar Item',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10)))),
      ]),
    );
  }

  Widget _iInp(String label, Map<String, dynamic> item, String key) {
    final ctrl = TextEditingController(text: item[key]?.toString() ?? '');
    ctrl.addListener(() => item[key] = ctrl.text);
    return TextFormField(
      controller: ctrl,
      style: const TextStyle(fontSize: 12, color: _dark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 11, color: _grey),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: _bord)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
    );
  }

  Widget _ddObjItem(String label, String? val, List<Map<String, dynamic>> opts,
      String df, void Function(String?) cb) {
    return SearchableDropdownField(
      label: label,
      value: opts.any((o) => o['id']?.toString() == val) ? val : null,
      items: opts.map((o) {
        final nome = o[df]?.toString() ?? '';
        final preco = o['preco']?.toString() ?? '';
        final codigo = o['codigoTributacaoMunicipal']?.toString() ??
            o['cnae']?.toString() ??
            '';
        final display = codigo.isNotEmpty
            ? '$nome (R\$ $preco) [$codigo]'
            : '$nome (R\$ $preco)';
        return <String, dynamic>{
          'id': o['id']?.toString() ?? '',
          'nome': display
        };
      }).toList(),
      valueField: 'id',
      displayField: 'nome',
      nullable: true,
      nullLabel: '— Selecione Serviço —',
      onChanged: cb,
    );
  }

  Widget _gridSemHeader(
      {required String telaNome, Map<String, dynamic>? extraParams}) {
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
          decoration: BoxDecoration(
              color: on ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white)),
          child: Icon(ic, size: 16, color: on ? _green : Colors.white),
        ),
      );

  Widget _nb(IconData ic, VoidCallback cb) => InkWell(
        onTap: cb,
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Icon(ic, size: 18, color: Colors.white)),
      );

  // ── SEÇÃO: Impostos ──
  Widget _secaoImpostos() {
    return _secao(
      key: const Key('secao_impostos'),
      titulo: 'Impostos',
      child: _impostosConteudo(),
    );
  }

  /// Impostos (ISS / alíquota ISS / código de tributação municipal / ISS
  /// retido) por item.
  Widget _impostosConteudo() {
    if (_itens.isEmpty) {
      return const Text('Impostos (ISS) calculados a partir dos itens.',
          style: TextStyle(color: _grey, fontSize: 12));
    }
    return Column(
      children: _itens.asMap().entries.map((e) {
        final i = e.key;
        final item = e.value;
        final descricao = item['descricao']?.toString() ?? 'Item ${i + 1}';
        final aliquota = item['aliquotaIss']?.toString() ??
            item['aliquota_iss']?.toString() ??
            '-';
        final valorIss = item['valorIss']?.toString() ??
            item['valor_iss']?.toString() ??
            '-';
        final codTrib = item['codigoTributacaoMunicipal']?.toString() ??
            item['codigo_tributacao_municipal']?.toString() ??
            '-';
        final retido = item['issRetido'] == true || item['iss_retido'] == true;
        return Container(
          margin: EdgeInsets.only(bottom: i == _itens.length - 1 ? 0 : 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _bord)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(descricao,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 6),
            Wrap(spacing: 16, runSpacing: 6, children: [
              _impInfo('Alíquota ISS', '$aliquota%'),
              _impInfo('Valor ISS', valorIss),
              _impInfo('Cód. Tributação Municipal', codTrib),
              _impInfo('ISS Retido', retido ? 'Sim' : 'Não'),
            ]),
          ]),
        );
      }).toList(),
    );
  }

  Widget _impInfo(String label, String value) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 10, color: _grey)),
        Text(value,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: _dark)),
      ]);

  // ── SEÇÃO: Totais ──
  Widget _secaoTotais() {
    final vt = widget.item['valorTotal']?.toString() ?? '0,00';
    return _secao(
      key: const Key('secao_totais'),
      titulo: 'Totais',
      child: Wrap(spacing: 10, runSpacing: 10, children: [
        _card('Vlr. NFSe', vt),
        _card('Total Serviços', vt),
      ]),
    );
  }

  Widget _card(String label, String value) => Container(
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(minWidth: 160),
        decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _bord)),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: _grey)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold, color: _dark)),
            ]),
      );
}
