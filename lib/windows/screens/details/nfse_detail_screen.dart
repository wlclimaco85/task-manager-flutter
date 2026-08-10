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
const _bord = GridColors.borderSubtle;
const _grey = GridColors.neutral;
const _dark = GridColors.textDefault;
const _bg = GridColors.surfaceAlt;

const _codigoServicoMunicipalNfseKeys = [
  'codigoServicoMunicipal',
  'codigo_servico_municipal',
  'codigoServico',
  'codigo_servico',
  'ibge',
];

String? resolveCodigoServicoMunicipalNfse(Map<String, dynamic>? cidade) {
  if (cidade == null) return null;
  for (final chave in _codigoServicoMunicipalNfseKeys) {
    final texto = cidade[chave]?.toString().trim();
    if (texto != null && texto.isNotEmpty) return texto;
  }
  return null;
}

/// Tela de inserção/detalhe de NFSe.
///
/// Layout em 6 seções sequenciais tipo card (sem abas, sem paineis lado a
/// lado assimétricos): Dados da nota / Cliente-Tomador / Dados fiscais do
/// serviço / Serviços da nota / Impostos retidos / Totais — organização
/// inspirada nos fluxos públicos de NFS-e de Conta Azul e Omie (card
/// 6F94hyxf). Buscas de campos relacionados (empresa, tomador, série,
/// município, produto/serviço) abrem como autocomplete inline ancorado no
/// próprio campo (ver [SearchableDropdownField.inline]), não mais como
/// [Dialog] modal cobrindo a tela.
class NfseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  const NfseDetailScreen({super.key, required this.item});
  @override
  State<NfseDetailScreen> createState() => _NfseDetailScreenState();
}

class _NfseDetailScreenState extends State<NfseDetailScreen> {
  bool _itensGrid = true;
  int _selItem = 0;
  int _novoItemSeq = 0;

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
    _codigoServicoCtrl.text = _codigoServicoMunicipalInicial(i);

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
      final cidade = Map<String, dynamic>.from(i['cidade'] as Map);
      _cidadeId = cidade['id']?.toString();
      final nomeCidade = cidade['nome']?.toString();
      if (nomeCidade != null && nomeCidade.isNotEmpty) {
        _municipioCtrl.text = nomeCidade;
      }
      final codigoMunicipal = resolveCodigoServicoMunicipalNfse(cidade);
      if (_codigoServicoCtrl.text.isEmpty && codigoMunicipal != null) {
        _codigoServicoCtrl.text = codigoMunicipal;
      }
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

  String _codigoServicoMunicipalInicial(Map<String, dynamic> item) {
    final codigoDireto = resolveCodigoServicoMunicipalNfse(item);
    if (codigoDireto != null) return codigoDireto;

    final cidade = item['cidade'];
    if (cidade is Map) {
      return _codigoServicoMunicipalDaCidade(Map<String, dynamic>.from(cidade));
    }
    return '';
  }

  String _codigoServicoMunicipalDaCidade(Map<String, dynamic> cidade) {
    return resolveCodigoServicoMunicipalNfse(cidade) ?? '';
  }

  Map<String, dynamic> _cidadeDropdownItem(Map<String, dynamic> cidade) {
    final item = <String, dynamic>{
      'id': cidade['id']?.toString() ?? '',
      'nome': cidade['nome']?.toString() ?? '',
    };
    final codigo = _codigoServicoMunicipalDaCidade(cidade);
    if (codigo.isNotEmpty) item['codigoServicoMunicipal'] = codigo;
    return item;
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
      // Carrega apenas um lote inicial (primeiras cidades em ordem alfabética)
      // para exibição rápida do dropdown. A base tem 5571 cidades (seed IBGE) —
      // carregar tudo e filtrar no cliente truncava a lista e a busca por
      // cidades fora desse corte (ex: "Uberaba") nunca encontrava resultado.
      // A busca de fato acontece no servidor via _buscarCidadesServidor.
      _loadList('${ApiLinks.baseUrl}/api/cidade?tamanho=100',
          (d) => setState(() => _cidades = d)),
    ]);
    _garantirCidadeSelecionadaNaLista();
  }

  /// Garante que a cidade já selecionada (ex: ao editar uma NFSe existente)
  /// apareça no dropdown mesmo que não esteja no lote inicial de 100 cidades
  /// — usa o nome já salvo no registro (_municipioCtrl) como rótulo.
  void _garantirCidadeSelecionadaNaLista() {
    if (_cidadeId == null || _cidadeId!.isEmpty) return;
    final jaPresente = _cidades.any((c) => c['id']?.toString() == _cidadeId);
    if (jaPresente) return;
    final nome = _municipioCtrl.text;
    if (nome.isEmpty) return;
    setState(() => _cidades = [
          {'id': _cidadeId, 'nome': nome},
          ..._cidades,
        ]);
  }

  /// Busca cidades no servidor pelo termo digitado (debounce feito pelo
  /// SearchableDropdownField). Usada pelo popover "Município de Prestação"
  /// para não depender de carregar as 5571 cidades no cliente.
  Future<List<Map<String, dynamic>>> _buscarCidadesServidor(
      String termo) async {
    List<Map<String, dynamic>> resultado = [];
    await _loadList(
      '${ApiLinks.baseUrl}/api/cidade?nome=${Uri.encodeQueryComponent(termo)}&tamanho=50',
      (d) => resultado = d,
    );
    return resultado;
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
      if (_cidadeId != null)
        'cidade': {'id': int.tryParse(_cidadeId!) ?? _cidadeId},
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
            content: Text(_mensagemErro(r.statusCode, r.body)),
            backgroundColor: _red));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
    }
  }

  /// Extrai mensagem de erro legível do corpo da resposta (ex: validação
  /// municipal recusada pelo backend), caindo no status HTTP cru quando o
  /// corpo não trouxer um campo de mensagem reconhecido.
  String _mensagemErro(int statusCode, String body) {
    try {
      final b = jsonDecode(body);
      if (b is Map) {
        final msg = b['message']?.toString() ??
            b['mensagem']?.toString() ??
            b['error']?.toString();
        if (msg != null && msg.isNotEmpty) return msg;
      }
    } catch (_) {}
    return 'Erro $statusCode: $body';
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

  /// Cria um novo item local com `_localId` estável (gerado uma única vez,
  /// antes de o item ter `id` do backend) — garante uma [Key] estável para
  /// o formulário do item mesmo antes do primeiro salvamento, evitando que
  /// o Flutter reconcilie o Element errado entre itens diferentes da lista.
  void _novoItem() => setState(() {
        _novoItemSeq++;
        _itens.add({
          'nfse_id': int.tryParse(_nfseId) ?? 0,
          '_localId': 'novo_$_novoItemSeq',
        });
        _selItem = _itens.length - 1;
        _itensGrid = false;
      });

  /// Identidade estável do item (id do backend quando existir, senão o
  /// `_localId` gerado localmente) — usada como [Key] do formulário do item
  /// para que cada item tenha seus próprios [TextEditingController],
  /// evitando o memory leak e a corrupção de dados entre itens (CR-01/CR-02).
  String _itemKey(Map<String, dynamic> item) =>
      item['id']?.toString() ?? item['_localId']?.toString() ?? '_sem_id';

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.background,
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth =
              constraints.maxWidth >= 1180 ? 1120.0 : constraints.maxWidth;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _cardDadosDaNota(),
                    const SizedBox(height: 12),
                    _cardClienteTomador(),
                    const SizedBox(height: 12),
                    _cardDadosFiscaisServico(),
                    const SizedBox(height: 12),
                    _cardServicosDaNota(),
                    const SizedBox(height: 12),
                    _cardImpostosRetidos(),
                    const SizedBox(height: 12),
                    _cardTotais(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionCard(
      {required String title,
      required IconData icon,
      required Widget child,
      Widget? action}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _bord),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Icon(icon, size: 18, color: _red),
            const SizedBox(width: 8),
            Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: GridColors.textSecondary))),
            if (action != null) action,
          ]),
        ),
        Container(height: 1, color: _bord),
        Padding(padding: const EdgeInsets.all(16), child: child),
      ]),
    );
  }

  // 1) DADOS DA NOTA — número, série, datas, status, ambiente.
  Widget _cardDadosDaNota() {
    return _sectionCard(
      title: 'Dados da nota',
      icon: Icons.receipt_long,
      action: ElevatedButton.icon(
        onPressed: _salvarCabecalho,
        icon: const Icon(Icons.save, size: 14),
        label: const Text('Salvar'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
      child: _formGrid([
        _ddSerie(),
        _inp('Número', _numeroCtrl),
        _dateField('Data Emissão', _dataEmissao,
            (d) => setState(() => _dataEmissao = d)),
        _dateField('Data Competência', _dataCompetencia,
            (d) => setState(() => _dataCompetencia = d)),
        _statusChip(_statusVal ?? 'PENDENTE'),
        _dd('Ambiente', _ambienteVal, ['HOMOLOGACAO', 'PRODUCAO'],
            (v) => setState(() => _ambienteVal = v)),
      ]),
    );
  }

  // 2) CLIENTE / TOMADOR — empresa emitente e tomador do serviço.
  Widget _cardClienteTomador() {
    final hasSession = AuthUtility.userInfo?.login != null;
    return _sectionCard(
      title: 'Cliente / Tomador',
      icon: Icons.people_alt,
      child: _formGrid([
        hasSession && _empresaNome != null
            ? _inpDisabledText('Empresa', _empresaNome!)
            : _ddObj('Empresa', _empresaId, _empresas, 'nome',
                (v) => setState(() => _empresaId = v)),
        _ddObj('Tomador / Parceiro', _tomadorId, _tomadores, 'nome',
            (v) => setState(() => _tomadorId = v)),
      ]),
    );
  }

  // 3) DADOS FISCAIS DO SERVIÇO — município de prestação e código de serviço municipal.
  Widget _cardDadosFiscaisServico() {
    return _sectionCard(
      title: 'Dados fiscais do serviço',
      icon: Icons.gavel,
      child: _formGrid([
        _ddCidade(),
        _inp('Código de Serviço Municipal', _codigoServicoCtrl,
            icon: Icons.location_city),
      ]),
    );
  }

  Widget _formGrid(List<Widget> children) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth >= 900
          ? (constraints.maxWidth - 24) / 3
          : constraints.maxWidth >= 620
              ? (constraints.maxWidth - 12) / 2
              : constraints.maxWidth;
      return Wrap(
          spacing: 12,
          runSpacing: 4,
          children:
              children.map((w) => SizedBox(width: width, child: w)).toList());
    });
  }

  Widget _inp(String label, TextEditingController ctrl, {IconData? icon}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextFormField(
          controller: ctrl,
          style: const TextStyle(fontSize: 12, color: _dark),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(fontSize: 11, color: _grey),
            prefixIcon:
                icon != null ? Icon(icon, size: 16, color: _red) : null,
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
        ),
      );

  /// Chip de status com cor/ícone conforme o retorno da prefeitura —
  /// substitui o texto cinza puro anterior para dar clareza visual imediata
  /// (critério de aceite: "retorno prefeitura mapeado e exibido").
  Widget _statusChip(String status) {
    final upper = status.toUpperCase();
    Color cor;
    IconData icone;
    String descricaoAcessivel;
    if (upper.contains('AUTORIZAD')) {
      cor = _green;
      icone = Icons.check_circle;
      descricaoAcessivel = 'Status: autorizado';
    } else if (upper.contains('REJEITAD') || upper.contains('ERRO')) {
      cor = _red;
      icone = Icons.error;
      descricaoAcessivel = 'Status: rejeitado ou com erro';
    } else if (upper.contains('CANCELAD')) {
      cor = _grey;
      icone = Icons.cancel;
      descricaoAcessivel = 'Status: cancelado';
    } else {
      cor = _grey;
      icone = Icons.hourglass_empty;
      descricaoAcessivel = 'Status: pendente';
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Status',
          labelStyle: const TextStyle(fontSize: 11, color: _grey),
          filled: true,
          fillColor: _bg,
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
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icone, size: 14, color: cor, semanticLabel: descricaoAcessivel),
          const SizedBox(width: 6),
          Text(status,
              style: TextStyle(
                  fontSize: 12, color: cor, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _inpDisabledText(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(fontSize: 11, color: _grey),
            filled: true,
            fillColor: _bg,
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
          child:
              Text(value, style: const TextStyle(fontSize: 12, color: _grey)),
        ),
      );

  Widget _dd(String label, String? val, List<String> opts,
          void Function(String?) cb) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SearchableDropdownField(
          label: label,
          value: val,
          items:
              opts.map((o) => <String, dynamic>{'id': o, 'nome': o}).toList(),
          valueField: 'id',
          displayField: 'nome',
          nullable: true,
          nullLabel: '— Selecione —',
          inline: true,
          onChanged: cb,
        ),
      );

  Widget _ddObj(String label, String? val, List<Map<String, dynamic>> opts,
      String displayField, void Function(String?) cb) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SearchableDropdownField(
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
        inline: true,
        onChanged: cb,
      ),
    );
  }

  /// Dropdown de Série NFSe — carrega de /api/nfse-serie
  Widget _ddSerie() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SearchableDropdownField(
        label: 'Série',
        value: _series.any((o) => o['id']?.toString() == _serieId)
            ? _serieId
            : null,
        items: _series
            .map((s) => <String, dynamic>{
                  'id': s['id']?.toString() ?? '',
                  'nome':
                      '${s['serie'] ?? ''} (atual: ${s['numeroAtual'] ?? 1})',
                })
            .toList(),
        valueField: 'id',
        displayField: 'nome',
        nullable: true,
        nullLabel: '— Selecione —',
        inline: true,
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
      ),
    );
  }

  /// Dropdown de Município (Cidade) — carrega de /api/cidade
  /// Ao selecionar, preenche o código de serviço municipal se a cidade tiver
  Widget _ddCidade() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SearchableDropdownField(
        label: 'Município de Prestação',
        prefixIcon: Icons.location_city,
        value: _cidades.any((o) => o['id']?.toString() == _cidadeId)
            ? _cidadeId
            : null,
        items: _cidades.map(_cidadeDropdownItem).toList(),
        valueField: 'id',
        displayField: 'nome',
        nullable: true,
        nullLabel: '— Selecione —',
        inline: true,
        onSearch: _buscarCidadesServidor,
        onChanged: (v) => setState(() => _cidadeId = v),
        // Usa o item completo devolvido pelo widget (local ou vindo da busca
        // server-side) em vez de procurá-lo em _cidades — a busca remota pode
        // retornar cidades que ainda não estão no lote local (ex: "Uberaba").
        onItemSelected: (item) {
          if (item == null) return;
          final id = item['id']?.toString();
          final nome = item['nome']?.toString();
          if (nome != null && nome.isNotEmpty) {
            _municipioCtrl.text = nome;
          }
          if (id != null && !_cidades.any((o) => o['id']?.toString() == id)) {
            setState(() => _cidades = [item, ..._cidades]);
          }
          // Auto-preencher código de serviço municipal se a cidade tiver
          final codServico = _codigoServicoMunicipalDaCidade(item);
          if (codServico.isNotEmpty) {
            _codigoServicoCtrl.text = codServico;
          }
        },
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
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: _bord)),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          child: Row(children: [
            Icon(Icons.calendar_today,
                size: 14, color: _grey, semanticLabel: 'Selecionar data'),
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

  // 4) SERVIÇOS DA NOTA — lista/formulário de itens.
  Widget _cardServicosDaNota() {
    return _sectionCard(
      title: 'Serviços da nota',
      icon: Icons.design_services,
      child: Column(children: [
        Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Itens (Serviços)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(width: 8),
              _togBtn(Icons.view_list, _itensGrid,
                  () => setState(() => _itensGrid = true), 'Ver em grade'),
              const SizedBox(width: 4),
              _togBtn(Icons.edit_note, !_itensGrid,
                  () => setState(() => _itensGrid = false), 'Ver em formulário'),
              const SizedBox(width: 8),
              SizedBox(
                  height: 28,
                  child: ElevatedButton.icon(
                      onPressed: _novoItem,
                      icon: const Icon(Icons.add, size: 12),
                      label: const Text('Novo', style: TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 10)))),
              if (!_itensGrid && _itens.isNotEmpty) ...[
                const SizedBox(width: 4),
                SizedBox(
                    height: 28,
                    child: ElevatedButton.icon(
                        onPressed: () => _salvarItem(_itens[_selItem]),
                        icon: const Icon(Icons.save, size: 12),
                        label: const Text('Salvar',
                            style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _green,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8)))),
              ],
              if (!_itensGrid && _itens.isNotEmpty) ...[
                _nb(Icons.first_page, () => setState(() => _selItem = 0),
                    'Primeiro item'),
                _nb(
                    Icons.chevron_left,
                    () => setState(() {
                          if (_selItem > 0) _selItem--;
                        }),
                    'Item anterior'),
                Text(' ${_selItem + 1}/${_itens.length} ',
                    style: const TextStyle(fontSize: 11)),
                _nb(
                    Icons.chevron_right,
                    () => setState(() {
                          if (_selItem < _itens.length - 1) _selItem++;
                        }),
                    'Próximo item'),
                _nb(Icons.last_page,
                    () => setState(() => _selItem = _itens.length - 1),
                    'Último item'),
              ],
            ]),
        const SizedBox(height: 12),
        SizedBox(
          height: _itensGrid ? 420 : 360,
          child: _itensGrid
              ? _gridSemHeader(
                  telaNome: 'nfse_item',
                  extraParams: {'nfseId': _nfseId, 'nfse_id': _nfseId})
              : (_itens.isEmpty
                  ? const Center(
                      child: Text('Nenhum item',
                          style: TextStyle(color: GridColors.neutral)))
                  : _iForm()),
        ),
      ]),
    );
  }

  /// Renderiza o formulário do item atualmente selecionado usando uma
  /// [Key] estável por item ([_itemKey]) — ao navegar para outro item, o
  /// Flutter desmonta o [_NfseItemFormFields] anterior (chamando
  /// `dispose()` em seus controllers) e monta um novo com seus próprios
  /// controllers, eliminando o memory leak e a corrupção de dados entre
  /// itens (CR-01/CR-02 do card).
  Widget _iForm() {
    if (_selItem >= _itens.length) return const SizedBox();
    final item = _itens[_selItem];
    return _NfseItemFormFields(
      key: ValueKey(_itemKey(item)),
      item: item,
      produtos: _produtos,
      onSalvar: () => _salvarItem(item),
      onProdutoSelecionado: (prod) => setState(() {}),
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

  Widget _togBtn(IconData ic, bool on, VoidCallback cb, String label) =>
      Tooltip(
        message: label,
        child: InkWell(
          onTap: cb,
          child: Semantics(
            button: true,
            label: label,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                  color: on ? _green : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: on ? _green : _bord)),
              child: Icon(ic, size: 16, color: on ? Colors.white : _grey),
            ),
          ),
        ),
      );

  Widget _nb(IconData ic, VoidCallback cb, String label) => Tooltip(
        message: label,
        child: InkWell(
          onTap: cb,
          child: Semantics(
            button: true,
            label: label,
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Icon(ic, size: 18, color: _dark)),
          ),
        ),
      );

  // 5) IMPOSTOS RETIDOS — ISS por item, como card sequencial próprio (não
  // mais aba interna do card de resumo).
  Widget _cardImpostosRetidos() {
    return _sectionCard(
      title: 'Impostos retidos',
      icon: Icons.account_balance,
      child: _impostosConteudo(),
    );
  }

  /// Aba Impostos — ISS / alíquota ISS / código de tributação municipal /
  /// ISS retido por item (espelha _impostosTab do NfeSankhyaDetailScreen,
  /// mas exibindo os campos de ISS de cada item da NFSe).
  Widget _impostosConteudo() {
    if (_itens.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Text('Impostos (ISS) calculados a partir dos itens.',
            style: TextStyle(color: _grey, fontSize: 12)),
      );
    }
    return Column(
      children: _itens.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
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
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.white,
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

  // 6) TOTAIS — resumo de valores da nota, como card sequencial próprio.
  Widget _cardTotais() {
    final vt = widget.item['valorTotal']?.toString() ?? '0,00';
    return _sectionCard(
      title: 'Totais',
      icon: Icons.summarize,
      child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [_card('Vlr. NFSe', vt), _card('Total Serviços', vt)]),
    );
  }

  Widget _card(String label, String value) => Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _bord)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: _grey)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: _dark)),
        ]),
      );
}

/// Formulário dos campos de um item (serviço) da NFSe, isolado em um
/// [StatefulWidget] próprio e instanciado com uma [Key] estável por item
/// (ver [_NfseDetailScreenState._itemKey]).
///
/// Antes desta extração, cada campo do item criava um [TextEditingController]
/// novo a cada rebuild do widget pai (sem cache por item e sem `dispose()`),
/// causando memory leak (CR-01) e corrupção de dados/cursor pulando entre
/// itens diferentes por falta de identidade estável (CR-02). Agora os
/// controllers são criados uma única vez em [initState], atualizados sem
/// recriação em [didUpdateWidget] e liberados em [dispose] — o próprio
/// framework do Flutter chama `dispose()` automaticamente quando este
/// widget sai da árvore (ex: ao trocar de item selecionado, já que a
/// [Key] muda).
class _NfseItemFormFields extends StatefulWidget {
  final Map<String, dynamic> item;
  final List<Map<String, dynamic>> produtos;
  final VoidCallback onSalvar;
  final ValueChanged<Map<String, dynamic>> onProdutoSelecionado;

  const _NfseItemFormFields({
    required super.key,
    required this.item,
    required this.produtos,
    required this.onSalvar,
    required this.onProdutoSelecionado,
  });

  @override
  State<_NfseItemFormFields> createState() => _NfseItemFormFieldsState();
}

class _NfseItemFormFieldsState extends State<_NfseItemFormFields> {
  static const _campos = ['descricao', 'quantidade', 'valorUnitario', 'valorTotal'];
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (final campo in _campos) {
      _controllers[campo] =
          TextEditingController(text: widget.item[campo]?.toString() ?? '');
    }
  }

  @override
  void didUpdateWidget(covariant _NfseItemFormFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Mesmo item (mesma Key) — sincroniza o texto exibido com o mapa (ex:
    // seleção de produto preenchendo descrição/valor) sem recriar os
    // controllers, preservando posição do cursor e foco do usuário.
    for (final campo in _campos) {
      final novo = widget.item[campo]?.toString() ?? '';
      final ctrl = _controllers[campo];
      if (ctrl != null && ctrl.text != novo) ctrl.text = novo;
    }
  }

  @override
  void dispose() {
    for (final ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final prodId =
        (item['produto'] is Map ? item['produto']['id'] : item['produto_id'])
            ?.toString();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Column(children: [
        // Produto — somente os marcados como serviço (Produto.isServico == true)
        _ddObjItem('Produto (Serviço)', prodId, widget.produtos, 'nome', (v) {
          final prod = widget.produtos
              .firstWhere((p) => p['id']?.toString() == v, orElse: () => {});
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
          widget.onProdutoSelecionado(item);
        }),
        _campoItem('Descrição', 'descricao'),
        _campoItem('Quantidade', 'quantidade'),
        _campoItem('Vl. Unitário', 'valorUnitario'),
        _campoItem('Vl. Total', 'valorTotal'),
        const SizedBox(height: 12),
        SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
                onPressed: widget.onSalvar,
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

  Widget _campoItem(String label, String key) {
    final ctrl = _controllers[key]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        key: ValueKey('item_field_$key'),
        controller: ctrl,
        onChanged: (value) => widget.item[key] = value,
        style: const TextStyle(fontSize: 12, color: _dark),
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
      ),
    );
  }

  Widget _ddObjItem(String label, String? val, List<Map<String, dynamic>> opts,
      String df, void Function(String?) cb) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SearchableDropdownField(
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
        inline: true,
        onChanged: cb,
      ),
    );
  }
}
