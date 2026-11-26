import 'dart:convert';

import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../services/session_expired_handler.dart';
import '../../utils/api_links.dart';
import '../../utils/app_logger.dart';
import '../../utils/file_saver_compat.dart';
import '../../utils/grid_colors.dart';
import '../../utils/tenant_context.dart';

typedef _Json = Map<String, dynamic>;

const _limiteZip = 500;

const _status = {
  'CRIADA': 'Criada',
  'ENVIADA': 'Enviada',
  'AUTORIZADA': 'Autorizada',
  'CANCELADA': 'Cancelada',
  'DENEGADA': 'Denegada',
  'REJEITADA': 'Rejeitada',
  'RASCUNHO_IMPORTACAO': 'Rascunho de importação',
};

/// Central dos XMLs de NF-e guardados no sistema, com download em ZIP.
class GestaoXmlScreen extends StatefulWidget {
  /// Substituíveis em teste.
  final Future<http.Response> Function(String url)? buscar;
  final Future<http.Response> Function(String url, String corpo)? enviar;
  final Future<void> Function(Uint8List bytes)? salvar;

  const GestaoXmlScreen({super.key, this.buscar, this.enviar, this.salvar});

  @override
  State<GestaoXmlScreen> createState() => _GestaoXmlScreenState();
}

class _GestaoXmlScreenState extends State<GestaoXmlScreen> {
  _Json? _dados;
  String? _erro;
  bool _carregando = false;
  bool _baixando = false;
  int _pedido = 0;

  int? _clienteId;
  String? _filtroStatus;
  String? _tipo;
  DateTimeRange? _periodo;
  bool _somenteSemXml = false;
  int _pagina = 0;
  final _busca = TextEditingController();
  final Set<int> _selecionadas = {};

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  String _url(String caminho, [Map<String, String> extras = const {}]) =>
      Uri.parse('${ApiLinks.baseUrl}$caminho').replace(queryParameters: {
        'skipTenantParceiro': 'true',
        if (TenantContext.empresaId != null) 'empresaId': '${TenantContext.empresaId}',
        ...extras,
      }).toString();

  Future<void> _carregar() async {
    final pedido = ++_pedido;
    setState(() => _carregando = true);
    final iso = DateFormat('yyyy-MM-dd');
    final url = _url('/api/gestao-xml', {
      'pagina': '$_pagina',
      if (_clienteId != null) 'clienteId': '$_clienteId',
      if (_filtroStatus != null) 'status': _filtroStatus!,
      if (_tipo != null) 'tipo': _tipo!,
      if (_periodo != null) 'inicio': iso.format(_periodo!.start),
      if (_periodo != null) 'fim': iso.format(_periodo!.end),
      if (_busca.text.trim().isNotEmpty) 'busca': _busca.text.trim(),
      if (_somenteSemXml) 'somenteSemXml': 'true',
    });
    try {
      final r = await (widget.buscar ?? TenantContext.get)(url);
      if (!mounted || pedido != _pedido) return;
      if (r.statusCode == 403) {
        setState(() {
          _dados = null;
          _erro = 'Você não tem acesso à Gestão de XML. Solicite ao administrador.';
          _carregando = false;
        });
        return;
      }
      if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
      final corpo = jsonDecode(utf8.decode(r.bodyBytes)) as _Json;
      setState(() {
        _dados = corpo;
        _erro = null;
        _carregando = false;
      });
    } catch (e, st) {
      AppLogger.i.error('Gestão de XML: falha ao carregar ($e)', st);
      if (!mounted || pedido != _pedido) return;
      setState(() {
        _erro = 'Não foi possível carregar as NF-e.';
        _carregando = false;
      });
    }
  }

  /// Mudar filtro ou busca limpa a seleção: nada escondido entra no ZIP.
  void _filtrar(VoidCallback mudanca) {
    setState(() {
      mudanca();
      _pagina = 0;
      _selecionadas.clear();
    });
    _carregar();
  }

  void _mensagem(String texto) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));

  Future<void> _baixar(List<int> ids) async {
    setState(() => _baixando = true);
    try {
      final url = _url('/api/gestao-xml/zip');
      final corpo = jsonEncode({'ids': ids});
      final r = widget.enviar != null
          ? await widget.enviar!(url, corpo)
          : await http.post(Uri.parse(url), headers: TenantContext.jsonHeaders, body: corpo);
      // Este POST não passa pelo TenantContext.post: o 401 é tratado aqui.
      if (r.statusCode == 401) SessionExpiredHandler.handle();
      if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
      if (widget.salvar != null) {
        await widget.salvar!(r.bodyBytes);
      } else {
        await FileSaver.instance.saveFile(name: 'xml_nfe.zip', bytes: r.bodyBytes);
      }
      if (mounted) _mensagem('ZIP gerado.');
    } catch (e, st) {
      AppLogger.i.error('Gestão de XML: falha ao gerar ZIP de ${ids.length} nota(s) ($e)', st);
      if (mounted) _mensagem('Não foi possível gerar o ZIP. Sua seleção foi mantida.');
    } finally {
      if (mounted) setState(() => _baixando = false);
    }
  }

  List<_Json> _lista(String chave) => ((_dados?[chave] as List?) ?? const []).cast<_Json>();

  static bool _temXml(_Json n) => n['xmlAutorizado'] == true || n['xmlAssinado'] == true;

  static String _reais(num v) => NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(v);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.pageBackground,
      appBar: AppBar(
        title: const Text('Gestão de XML'),
        backgroundColor: GridColors.primary,
        foregroundColor: GridColors.textPrimary,
        actions: [
          IconButton(
              tooltip: 'Atualizar',
              onPressed: _carregando ? null : _carregar,
              icon: const Icon(Icons.refresh)),
        ],
      ),
      // Barra fixa: a seleção vale entre páginas.
      bottomNavigationBar: _selecionadas.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Semantics(
                        liveRegion: true, child: Text('${_selecionadas.length} selecionada(s)')),
                    TextButton(
                        onPressed: () => setState(_selecionadas.clear), child: const Text('Limpar')),
                    FilledButton.icon(
                      onPressed: _baixando ? null : () => _baixar(_selecionadas.toList()),
                      icon: const Icon(Icons.archive),
                      label: Text(_baixando ? 'Gerando ZIP' : 'Baixar ZIP'),
                    ),
                  ],
                ),
              ),
            ),
      body: LayoutBuilder(builder: (context, limites) {
        if (_dados == null) {
          return Center(
            child: _erro == null
                ? const CircularProgressIndicator(semanticsLabel: 'Carregando XMLs de NF-e')
                : Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(_erro!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _carregar, child: const Text('Tentar novamente')),
                    ]),
                  ),
          );
        }
        final largura = limites.maxWidth;
        return Column(children: [
          if (_carregando) const LinearProgressIndicator(minHeight: 3),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(largura < 700 ? 12 : 20),
              children: [
                _faixa(Icons.info, GridColors.info, GridColors.card,
                    'Somente NF-e. NFS-e, NFC-e, CT-e e MDF-e não aparecem nesta versão.'),
                if (_erro != null)
                  _faixa(Icons.warning, GridColors.errorDark, GridColors.errorLight,
                      '$_erro A lista abaixo é a carregada antes.'),
                _filtros(largura),
                _contadores(largura),
                _notas(),
              ],
            ),
          ),
        ]);
      }),
    );
  }

  Widget _faixa(IconData icone, Color cor, Color fundo, String texto) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        color: fundo,
        child: Row(children: [
          Icon(icone, color: cor),
          const SizedBox(width: 8),
          Expanded(child: Text(texto)),
        ]),
      );

  Widget _cartao(Widget filho) => Card(
        color: GridColors.card,
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(padding: const EdgeInsets.all(14), child: filho),
      );

  bool get _filtrado =>
      _clienteId != null ||
      _filtroStatus != null ||
      _tipo != null ||
      _periodo != null ||
      _somenteSemXml ||
      _busca.text.trim().isNotEmpty;

  void _limpar() => _filtrar(() {
        _clienteId = null;
        _filtroStatus = null;
        _tipo = null;
        _periodo = null;
        _somenteSemXml = false;
        _busca.clear();
      });

  Widget _filtros(double largura) {
    final campo = largura < 700 ? largura - 52 : 240.0;
    Widget lista<T>(String rotulo, T valor, Map<T, String> opcoes, ValueChanged<T> aoMudar) => SizedBox(
          width: campo,
          child: DropdownButtonFormField<T>(
            key: ValueKey('$rotulo-$valor'),
            initialValue: valor,
            isExpanded: true,
            decoration: InputDecoration(
                labelText: rotulo, border: const OutlineInputBorder(), isDense: true),
            items: [
              for (final o in opcoes.entries)
                DropdownMenuItem<T>(value: o.key, child: Text(o.value, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) => _filtrar(() => aoMudar(v as T)),
          ),
        );
    final dia = DateFormat('dd/MM/yyyy');
    return _cartao(Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: campo,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            icon: const Icon(Icons.date_range),
            label: Text(
                _periodo == null
                    ? 'Período: todas'
                    : '${dia.format(_periodo!.start)} a ${dia.format(_periodo!.end)}',
                overflow: TextOverflow.ellipsis),
            onPressed: () async {
              final escolhido = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2010),
                  lastDate: DateTime(DateTime.now().year + 1, 12, 31),
                  initialDateRange: _periodo);
              if (escolhido != null && mounted) _filtrar(() => _periodo = escolhido);
            },
          ),
        ),
        lista<int?>('Empresa-cliente', _clienteId, {
          null: 'Todas as empresas-clientes',
          for (final c in _lista('clientes')) c['id'] as int: '${c['nome']}',
        }, (v) => _clienteId = v),
        lista<String?>('Tipo', _tipo,
            const {null: 'Todos', 'ENTRADA': 'Entrada', 'SAIDA': 'Saída'}, (v) => _tipo = v),
        lista<String?>('Status', _filtroStatus, const {null: 'Todos', ..._status},
            (v) => _filtroStatus = v),
        SizedBox(
          width: campo,
          child: TextField(
            controller: _busca,
            decoration: InputDecoration(
              labelText: 'Chave ou número',
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: IconButton(
                  tooltip: 'Buscar',
                  icon: const Icon(Icons.search),
                  onPressed: () => _filtrar(() {})),
            ),
            onSubmitted: (_) => _filtrar(() {}),
          ),
        ),
        if (_filtrado)
          TextButton.icon(
              onPressed: _limpar,
              icon: const Icon(Icons.filter_alt_off),
              label: const Text('Limpar filtros')),
      ],
    ));
  }

  Widget _contadores(double largura) {
    final c = (_dados!['contadores'] as _Json);
    Widget contador(String titulo, String valor, IconData icone, Color cor, [VoidCallback? toque]) =>
        SizedBox(
          width: largura < 700 ? double.infinity : (largura - 40 - 36) / 4,
          child: Card(
            color: GridColors.card,
            child: ListTile(
              leading: Icon(icone, color: cor),
              title: Text(titulo, style: const TextStyle(color: GridColors.textMuted)),
              subtitle: Text(valor,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: GridColors.textSecondary)),
              onTap: toque,
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(spacing: 12, runSpacing: 8, children: [
        contador(_periodo == null ? 'Notas' : 'Notas no período', '${c['notas']}', Icons.description,
            GridColors.info),
        contador('Sem XML', '${c['semXml']}', Icons.warning, GridColors.warningDark,
            () => _filtrar(() => _somenteSemXml = !_somenteSemXml)),
        contador('Canceladas', '${c['canceladas']}', Icons.block, GridColors.errorDark,
            () => _filtrar(
                () => _filtroStatus = _filtroStatus == 'CANCELADA' ? null : 'CANCELADA')),
        contador('Valor (autorizadas)', _reais((c['valorAutorizadas'] as num?) ?? 0),
            Icons.attach_money, GridColors.success),
      ]),
    );
  }

  Widget _notas() {
    final itens = _lista('itens');
    final total = ((_dados!['contadores'] as _Json)['notas'] as num).toInt();
    final porPagina = (_dados!['porPagina'] as num).toInt();
    final paginas = total == 0 ? 1 : ((total - 1) ~/ porPagina) + 1;
    final selecionaveis = itens.where(_temXml).map((n) => n['id'] as int).toList();
    final paginaToda = selecionaveis.isNotEmpty && selecionaveis.every(_selecionadas.contains);
    return _cartao(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (_somenteSemXml)
        Align(
          alignment: Alignment.centerLeft,
          child: InputChip(
              label: const Text('Mostrando: sem XML'),
              onDeleted: () => _filtrar(() => _somenteSemXml = false)),
        ),
      if (itens.isEmpty) ...[
        Text(_filtrado
            ? 'Nenhuma NF-e corresponde aos filtros.'
            : 'Nenhuma NF-e encontrada no sistema.'),
      ] else ...[
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: paginaToda,
          title: const Text('Selecionar página'),
          onChanged: selecionaveis.isEmpty ? null : (v) => _marcar(selecionaveis, v == true),
        ),
        for (final n in itens) _linha(n),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(
              tooltip: 'Página anterior',
              onPressed: _pagina == 0 || _carregando
                  ? null
                  : () {
                      _pagina--;
                      _carregar();
                    },
              icon: const Icon(Icons.chevron_left)),
          Text('Página ${_pagina + 1} de $paginas'),
          IconButton(
              tooltip: 'Próxima página',
              onPressed: _pagina + 1 >= paginas || _carregando
                  ? null
                  : () {
                      _pagina++;
                      _carregar();
                    },
              icon: const Icon(Icons.chevron_right)),
        ]),
      ],
    ]));
  }

  void _marcar(List<int> ids, bool marcar) {
    if (marcar && {..._selecionadas, ...ids}.length > _limiteZip) {
      _mensagem('Selecione até $_limiteZip notas por download.');
      return;
    }
    setState(() => marcar ? _selecionadas.addAll(ids) : _selecionadas.removeAll(ids));
  }

  Widget _linha(_Json n) {
    final id = n['id'] as int;
    final status = '${n['status']}';
    final emissao = n['emissao'] == null
        ? 'sem data'
        : DateFormat('dd/MM/yyyy').format(DateTime.parse(n['emissao']));
    final situacaoXml = n['xmlAutorizado'] == true
        ? 'XML autorizado'
        : n['xmlAssinado'] == true
            ? 'Só assinado, sem protocolo'
            : 'Sem XML';
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Checkbox(
        semanticLabel: 'Selecionar NF-e ${n['numero']}, série ${n['serie']}',
        value: _selecionadas.contains(id),
        onChanged: _temXml(n) ? (v) => _marcar([id], v == true) : null,
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
                'NF-e ${n['numero'] ?? '-'} · série ${n['serie'] ?? '-'} · '
                '${_reais((n['valor'] as num?) ?? 0)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('$emissao · ${n['tipo'] == 'ENTRADA' ? 'Entrada' : 'Saída'} · '
                '${n['emitente'] ?? '-'} > ${n['destinatario'] ?? '-'}'),
            if (n['chave'] != null)
              SelectableText('${n['chave']}',
                  style: const TextStyle(fontSize: 11, color: GridColors.textMuted)),
            const SizedBox(height: 4),
            Wrap(spacing: 6, runSpacing: 4, children: [
              _selo(
                  _status[status] ?? status,
                  status == 'AUTORIZADA'
                      ? Icons.check_circle
                      : status == 'CANCELADA'
                          ? Icons.block
                          : Icons.info,
                  status == 'AUTORIZADA'
                      ? GridColors.success
                      : const {'CANCELADA', 'DENEGADA', 'REJEITADA'}.contains(status)
                          ? GridColors.errorDark
                          : GridColors.neutral),
              _selo(
                  situacaoXml,
                  n['xmlAutorizado'] == true ? Icons.check_circle : Icons.warning,
                  n['xmlAutorizado'] == true ? GridColors.success : GridColors.warningDark),
              if (status == 'CANCELADA')
                _selo(
                    n['xmlCancelamento'] == true
                        ? 'XML de cancelamento'
                        : 'Sem XML de cancelamento',
                    n['xmlCancelamento'] == true ? Icons.check_circle : Icons.warning,
                    n['xmlCancelamento'] == true ? GridColors.success : GridColors.warningDark),
            ]),
          ]),
        ),
      ),
      IconButton(
        tooltip: 'Baixar XML desta nota',
        onPressed: _temXml(n) && !_baixando ? () => _baixar([id]) : null,
        icon: const Icon(Icons.download),
      ),
    ]);
  }

  Widget _selo(String texto, IconData icone, Color cor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            border: Border.all(color: cor), borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icone, size: 14, color: cor),
          const SizedBox(width: 4),
          Flexible(
              child: Text(texto,
                  style: const TextStyle(fontSize: 12, color: GridColors.textSecondary))),
        ]),
      );
}
