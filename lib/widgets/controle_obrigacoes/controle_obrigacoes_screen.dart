import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../services/session_expired_handler.dart';
import '../../utils/api_links.dart';
import '../../utils/app_logger.dart';
import '../../utils/grid_colors.dart';
import '../../utils/tenant_context.dart';
import '../user_banners.dart';

typedef _Json = Map<String, dynamic>;

/// Situação da entrega. Sempre com ícone e rótulo, nunca só cor.
enum _Situacao {
  atrasada('ATRASADA', 'Atrasada', 'Atrasadas', Icons.error, GridColors.errorDark, GridColors.errorLight),
  pendente('PENDENTE', 'Pendente', 'Pendentes', Icons.schedule, GridColors.info, GridColors.card),
  entregue('ENTREGUE', 'Entregue', 'Entregues', Icons.check_circle, GridColors.success, GridColors.successLight),
  dispensada('DISPENSADA', 'Dispensada', 'Dispensadas', Icons.do_not_disturb_on, GridColors.neutral,
      GridColors.surfaceMuted);

  final String codigo;
  final String rotulo;
  final String plural;
  final IconData icone;
  final Color cor;
  final Color fundo;
  const _Situacao(this.codigo, this.rotulo, this.plural, this.icone, this.cor, this.fundo);

  bool get aberta => this == atrasada || this == pendente;

  static _Situacao de(Object? codigo) =>
      values.firstWhere((s) => s.codigo == codigo, orElse: () => pendente);
}

String _chave(_Json l) => '${l['parceiroId']}-${l['obrigacaoId']}';

_Situacao _situacao(_Json l) => _Situacao.de(l['situacao']);

String _data(Object? iso) => DateFormat('dd/MM/yyyy').format(DateTime.parse('$iso'));

/// Controle interno do escritório: o que cada cliente precisa entregar no mês e o que já saiu.
class ControleObrigacoesScreen extends StatefulWidget {
  /// true quando a tela é aberta pelo menu do celular.
  final bool cabecalhoMobile;

  /// Substituíveis em teste.
  final Future<http.Response> Function(String url)? buscar;
  final Future<http.Response> Function(String url, String corpo)? enviar;

  const ControleObrigacoesScreen({super.key, this.cabecalhoMobile = false, this.buscar, this.enviar});

  @override
  State<ControleObrigacoesScreen> createState() => _ControleObrigacoesScreenState();
}

class _ControleObrigacoesScreenState extends State<ControleObrigacoesScreen> {
  static const _titulo = 'Controle de Obrigações';
  static const _semAcesso = 'Você não tem acesso ao Controle de Obrigações. Solicite ao administrador.';

  DateTime _mes = DateTime(DateTime.now().year, DateTime.now().month);
  List<_Json>? _linhas;
  String? _erro;
  bool _carregando = true;
  int _pedido = 0;

  int? _empresaId;
  int? _regimeId;
  String? _obrigacao;
  _Situacao? _filtroSituacao;
  final Set<String> _selecionadas = {};

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  String _url(String caminho, [Map<String, String> extras = const {}]) =>
      Uri.parse('${ApiLinks.baseUrl}/api/controle-obrigacoes$caminho').replace(queryParameters: {
        'skipTenantParceiro': 'true',
        if (TenantContext.empresaId != null) 'empresaId': '${TenantContext.empresaId}',
        ...extras,
      }).toString();

  Future<void> _carregar() async {
    final pedido = ++_pedido;
    setState(() => _carregando = true);
    try {
      final r = await (widget.buscar ?? TenantContext.get)(
          _url('', {'mes': DateFormat('yyyy-MM').format(_mes)}));
      if (!mounted || pedido != _pedido) return; // resposta de mês antigo
      if (r.statusCode != 200) {
        setState(() {
          _linhas = null;
          _erro = r.statusCode == 403 ? _semAcesso : 'Não foi possível carregar as obrigações.';
          _carregando = false;
        });
        return;
      }
      final corpo = jsonDecode(utf8.decode(r.bodyBytes)) as _Json;
      final linhas = (corpo['linhas'] as List).cast<_Json>().toList()
        ..sort((a, b) {
          final s = _situacao(a).index.compareTo(_situacao(b).index);
          if (s != 0) return s;
          final v = '${a['vencimento']}'.compareTo('${b['vencimento']}');
          return v != 0 ? v : '${a['empresa']}'.compareTo('${b['empresa']}');
        });
      setState(() {
        // Filtro que não existe no mês carregado ficaria ativo sem aparecer na tela.
        if (!linhas.any((l) => l['parceiroId'] == _empresaId)) _empresaId = null;
        if (!linhas.any((l) => l['regimeId'] == _regimeId)) _regimeId = null;
        if (!linhas.any((l) => l['obrigacao'] == _obrigacao)) _obrigacao = null;
        _linhas = linhas;
        _erro = null;
        _carregando = false;
      });
    } catch (e, st) {
      AppLogger.i.error('Controle de Obrigações: falha ao carregar ($e)', st);
      if (!mounted || pedido != _pedido) return;
      setState(() {
        _linhas = null;
        _erro = 'Não foi possível carregar as obrigações.';
        _carregando = false;
      });
    }
  }

  void _trocarMes(int passo) {
    setState(() {
      _mes = DateTime(_mes.year, _mes.month + passo);
      _selecionadas.clear();
      _linhas = null; // lista de outro mês não pode ficar na tela
      _erro = null;
    });
    _carregar();
  }

  void _filtrar(VoidCallback mudanca) => setState(() {
        mudanca();
        _selecionadas.clear();
      });

  /// Recorte dos filtros, sem a situação: é a base dos contadores.
  List<_Json> get _recorte => (_linhas ?? const [])
      .where((l) =>
          (_empresaId == null || l['parceiroId'] == _empresaId) &&
          (_regimeId == null || l['regimeId'] == _regimeId) &&
          (_obrigacao == null || l['obrigacao'] == _obrigacao))
      .toList();

  // ── Ações ────────────────────────────────────────────────────────────────

  /// Envia o registro; devolve a mensagem de erro, ou null quando gravou.
  Future<String?> _registrar(String acao, List<_Json> itens,
      {DateTime? dataEntrega, String? protocolo, String? observacao}) async {
    try {
      final url = _url('/registro');
      final corpo = jsonEncode({
        'competencia': DateFormat('yyyy-MM').format(_mes),
        'acao': acao,
        'itens': [
          for (final l in itens) {'parceiroId': l['parceiroId'], 'obrigacaoId': l['obrigacaoId']}
        ],
        if (dataEntrega != null) 'dataEntrega': DateFormat('yyyy-MM-dd').format(dataEntrega),
        if (protocolo != null && protocolo.isNotEmpty) 'protocolo': protocolo,
        if (observacao != null && observacao.isNotEmpty) 'observacao': observacao,
      });
      final r = widget.enviar != null
          ? await widget.enviar!(url, corpo)
          : await http
              .post(Uri.parse(url), headers: TenantContext.jsonHeaders, body: corpo)
              .timeout(const Duration(minutes: 1));
      // Este POST não passa pelo TenantContext.post (que alteraria o corpo): o 401 é tratado aqui.
      if (r.statusCode == 401) SessionExpiredHandler.handle();
      if (r.statusCode == 200) return null;
      if (r.statusCode == 403) return 'Você não tem permissão para registrar. Solicite ao administrador.';
      if (r.statusCode == 400) {
        final json = jsonDecode(utf8.decode(r.bodyBytes));
        final texto = json['message'] ?? json['mensagem'] ?? json['response']?['message'];
        if (texto != null) return '$texto';
      }
      AppLogger.i.warn('Controle de Obrigações: registro $acao recusado (${r.statusCode})');
    } catch (e, st) {
      AppLogger.i.error('Controle de Obrigações: falha ao registrar $acao ($e)', st);
    }
    return 'Não foi possível salvar. Tente novamente.';
  }

  Future<void> _abrirRegistro(String acao, List<_Json> itens) async {
    if (itens.isEmpty) return;
    final gravou = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DialogoRegistro(
        acao: acao,
        itens: itens,
        enviar: (data, protocolo, observacao) =>
            _registrar(acao, itens, dataEntrega: data, protocolo: protocolo, observacao: observacao),
      ),
    );
    if (gravou != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(switch (acao) {
      'ENTREGAR' => itens.length == 1 ? 'Entrega registrada.' : '${itens.length} entregas registradas.',
      'DISPENSAR' => 'Obrigação dispensada.',
      _ => 'Obrigação reaberta.',
    })));
    setState(_selecionadas.clear);
    await _carregar();
  }

  void _detalhes(_Json l) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${l['obrigacao']}'),
        content: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final (rotulo, valor) in [
              ('Empresa', l['empresa']),
              ('Regime', l['regime']),
              ('Vencimento', _data(l['vencimento'])),
              ('Situação', _situacao(l).rotulo),
              ('Data de entrega', l['dataEntrega'] == null ? null : _data(l['dataEntrega'])),
              ('Protocolo', l['protocolo']),
              ('Observação', l['observacao']),
              ('Registrado por', l['registradoPor']),
            ])
              if (valor != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: SelectableText('$rotulo: $valor'),
                ),
          ]),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar'))],
      ),
    );
  }

  Future<void> _escolherEmpresa(List<MapEntry<int, String>> empresas) async {
    final id = await showDialog<int>(
      context: context,
      builder: (context) {
        var termo = '';
        return StatefulBuilder(builder: (context, atualizar) {
          final achadas =
              empresas.where((e) => e.value.toLowerCase().contains(termo.toLowerCase())).toList();
          return AlertDialog(
            title: const Text('Escolher empresa'),
            content: SizedBox(
              width: 420,
              height: 420,
              child: Column(children: [
                TextField(
                  autofocus: true,
                  decoration: const InputDecoration(
                      labelText: 'Pesquisar empresa', prefixIcon: Icon(Icons.search)),
                  onChanged: (v) => atualizar(() => termo = v),
                ),
                ListTile(title: const Text('Todas as empresas'), onTap: () => Navigator.pop(context, -1)),
                Expanded(
                  child: achadas.isEmpty
                      ? const Center(child: Text('Nenhuma empresa encontrada.'))
                      : ListView.builder(
                          itemCount: achadas.length,
                          itemBuilder: (_, i) => ListTile(
                            title: Text(achadas[i].value),
                            onTap: () => Navigator.pop(context, achadas[i].key),
                          ),
                        ),
                ),
              ]),
            ),
          );
        });
      },
    );
    if (id == null || !mounted) return;
    _filtrar(() {
      _empresaId = id == -1 ? null : id;
      if (_empresaId != null) _regimeId = null;
    });
  }

  // ── Tela ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final atualizar = IconButton(
      tooltip: 'Atualizar',
      color: GridColors.textPrimary,
      onPressed: _carregando ? null : _carregar,
      icon: const Icon(Icons.refresh),
    );
    return Scaffold(
      backgroundColor: GridColors.pageBackground,
      // No celular usa o cabeçalho padrão do app (usuário, avisos e sair).
      appBar: widget.cabecalhoMobile
          ? UserBannerAppBar(
              screenTitle: _titulo, showBackButton: true, showFilterButton: false, actions: [atualizar])
          : AppBar(
              title: const Text(_titulo),
              backgroundColor: GridColors.primary,
              foregroundColor: GridColors.textPrimary,
              actions: [atualizar],
            ),
      body: LayoutBuilder(builder: (context, limites) => _corpo(limites.maxWidth)),
      bottomNavigationBar: _selecionadas.isEmpty ? null : _barraSelecao(),
    );
  }

  Widget _corpo(double largura) {
    final margem = largura < 700 ? 12.0 : 20.0;
    final recorte = _recorte;
    final visiveis = _filtroSituacao == null
        ? recorte
        : recorte.where((l) => _situacao(l) == _filtroSituacao).toList();
    final abertas = visiveis.where((l) => _situacao(l).aberta).toList();

    final topo = <Widget>[
      _faixa(Icons.info, GridColors.info, GridColors.card,
          'Controle interno do escritório. Marcar como entregue não transmite nada ao governo.'),
      _filtros(largura, margem),
      if (_erro != null) ...[
        _faixa(Icons.error, GridColors.errorDark, GridColors.errorLight, _erro!),
        if (_erro != _semAcesso)
          Center(
              child: FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                  onPressed: _carregar,
                  child: const Text('Tentar novamente'))),
      ] else if (_linhas == null)
        const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator(semanticsLabel: 'Carregando obrigações')),
        )
      else ...[
        _contadores(recorte),
        if (_linhas!.isEmpty)
          _texto('Nenhuma obrigação vence neste mês. Confira o regime das empresas-clientes.')
        else if (visiveis.isEmpty)
          _texto('Nenhuma obrigação corresponde aos filtros.')
        else if (abertas.isNotEmpty)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text('Selecionar pendentes e atrasadas (${abertas.length})'),
            value: abertas.every((l) => _selecionadas.contains(_chave(l))),
            onChanged: (v) => setState(() {
              _selecionadas.clear();
              if (v == true) _selecionadas.addAll(abertas.map(_chave));
            }),
          ),
      ],
    ];

    return Column(children: [
      if (_carregando && _linhas != null) const LinearProgressIndicator(minHeight: 3),
      Expanded(
        // A carteira pode ter centenas de linhas: a lista é construída sob demanda.
        child: CustomScrollView(slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(margem, margem, margem, 0),
            sliver: SliverList.list(children: topo),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(margem, 4, margem, margem),
            sliver: SliverList.builder(
              itemCount: _erro != null || _linhas == null ? 0 : visiveis.length,
              itemBuilder: (_, i) => _item(visiveis[i], largura),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _filtros(double largura, double margem) {
    final linhas = _linhas ?? const <_Json>[];
    final empresas = {for (final l in linhas) l['parceiroId'] as int: '${l['empresa']}'}.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final regimes = {for (final l in linhas) l['regimeId'] as int: '${l['regime']}'};
    final obrigacoes = linhas.map((l) => '${l['obrigacao']}').toSet().toList()..sort();
    final campo = largura < 700 ? largura - 2 * margem - 28 : 260.0;
    final escolhida = empresas.where((e) => e.key == _empresaId).firstOrNull;
    final temFiltro = _empresaId != null || _regimeId != null || _obrigacao != null || _filtroSituacao != null;

    Widget lista<T>(String rotulo, String todos, T? valor, Map<T, String> opcoes, ValueChanged<T?>? mudar) =>
        SizedBox(
          width: campo,
          child: DropdownButtonFormField<T?>(
            // Recria o campo quando o valor muda por fora (limpar, trocar de mês).
            key: ValueKey('$rotulo-$valor-${opcoes.length}'),
            initialValue: opcoes.containsKey(valor) ? valor : null,
            isExpanded: true,
            decoration: InputDecoration(labelText: rotulo, border: const OutlineInputBorder()),
            items: [
              DropdownMenuItem<T?>(value: null, child: Text(todos)),
              for (final o in opcoes.entries)
                DropdownMenuItem<T?>(value: o.key, child: Text(o.value, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: mudar,
          ),
        );

    return Card(
      color: GridColors.card,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(
                tooltip: 'Mês anterior', onPressed: () => _trocarMes(-1), icon: const Icon(Icons.chevron_left)),
            Flexible(
              child: Text('Vencimentos em ${DateFormat('MM/yyyy').format(_mes)}',
                  textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            IconButton(
                tooltip: 'Próximo mês', onPressed: () => _trocarMes(1), icon: const Icon(Icons.chevron_right)),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
            SizedBox(
              width: campo,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                onPressed: () => _escolherEmpresa(empresas),
                icon: const Icon(Icons.business),
                label: Text(escolhida?.value ?? 'Empresa: Todas', overflow: TextOverflow.ellipsis),
              ),
            ),
            lista<int>('Regime', 'Todos', _regimeId, regimes,
                _empresaId != null ? null : (v) => _filtrar(() => _regimeId = v)),
            lista<String>('Obrigação', 'Todas', _obrigacao, {for (final o in obrigacoes) o: o},
                (v) => _filtrar(() => _obrigacao = v)),
            lista<_Situacao>('Situação', 'Todas', _filtroSituacao,
                {for (final s in _Situacao.values) s: s.rotulo}, (v) => _filtrar(() => _filtroSituacao = v)),
            if (temFiltro)
              TextButton.icon(
                style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                onPressed: () => _filtrar(() {
                  _empresaId = null;
                  _regimeId = null;
                  _obrigacao = null;
                  _filtroSituacao = null;
                }),
                icon: const Icon(Icons.filter_alt_off),
                label: const Text('Limpar filtros'),
              ),
          ]),
        ]),
      ),
    );
  }

  Widget _contadores(List<_Json> recorte) {
    int total(_Situacao s) => recorte.where((l) => _situacao(l) == s).length;
    final devidas = recorte.length - total(_Situacao.dispensada);
    final entregues = total(_Situacao.entregue);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final s in _Situacao.values)
          Semantics(
            selected: _filtroSituacao == s,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 48),
                backgroundColor: s.fundo,
                foregroundColor: GridColors.textSecondary,
                side: BorderSide(color: s.cor, width: _filtroSituacao == s ? 3 : 1),
              ),
              onPressed: () => _filtrar(() => _filtroSituacao = _filtroSituacao == s ? null : s),
              icon: Icon(s.icone, color: s.cor),
              label: Text('${s.plural}: ${total(s)}'),
            ),
          ),
      ]),
      const SizedBox(height: 10),
      if (devidas > 0) ...[
        Text('$entregues de $devidas entregues'),
        const SizedBox(height: 4),
        LinearProgressIndicator(
            value: entregues / devidas,
            minHeight: 8,
            color: GridColors.success,
            backgroundColor: GridColors.surfaceMuted,
            semanticsLabel: '$entregues de $devidas obrigações entregues'),
      ] else
        const Text('Nada a entregar neste recorte'),
      const SizedBox(height: 8),
    ]);
  }

  Widget _item(_Json l, double largura) {
    final s = _situacao(l);
    final estreito = largura < 700;
    final selo = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: s.fundo,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(s.icone, size: 16, color: s.cor),
        const SizedBox(width: 4),
        Text(s.rotulo),
      ]),
    );
    final dados = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${l['empresa']}',
          maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
      Text('${l['obrigacao']}', maxLines: 2, overflow: TextOverflow.ellipsis),
      const SizedBox(height: 4),
      Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
        selo,
        Text('Vence ${_data(l['vencimento'])}'),
        if (l['dataEntrega'] != null) Text('Entregue em ${_data(l['dataEntrega'])}'),
      ]),
    ]);
    final acoes = Wrap(spacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
      if (s.aberta)
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
          onPressed: () => _abrirRegistro('ENTREGAR', [l]),
          child: Text(estreito ? 'Entregar' : 'Marcar como entregue'),
        ),
      TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: () => _detalhes(l),
          child: const Text('Detalhes')),
      PopupMenuButton<String>(
        tooltip: 'Mais ações',
        onSelected: (acao) => _abrirRegistro(acao, [l]),
        itemBuilder: (_) => [
          s.aberta
              ? const PopupMenuItem(value: 'DISPENSAR', child: Text('Dispensar'))
              : const PopupMenuItem(value: 'REABRIR', child: Text('Reabrir')),
        ],
      ),
    ]);
    final marcar = SizedBox(
      width: 48,
      child: s.aberta
          ? Checkbox(
              semanticLabel: 'Selecionar ${l['obrigacao']} de ${l['empresa']}',
              value: _selecionadas.contains(_chave(l)),
              onChanged: (v) => setState(() =>
                  v == true ? _selecionadas.add(_chave(l)) : _selecionadas.remove(_chave(l))),
            )
          : null,
    );

    return Card(
      key: ValueKey(_chave(l)),
      color: GridColors.card,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 10, 8, 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          marcar,
          Expanded(
            child: largura >= 1100
                ? Row(children: [Expanded(child: dados), acoes])
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    dados,
                    const SizedBox(height: 6),
                    acoes,
                  ]),
          ),
        ]),
      ),
    );
  }

  Widget _barraSelecao() => Material(
        color: GridColors.card,
        elevation: 8,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text('${_selecionadas.length} selecionadas'),
                TextButton(
                    style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                    onPressed: () => setState(_selecionadas.clear),
                    child: const Text('Limpar')),
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                  onPressed: () => _abrirRegistro('ENTREGAR',
                      (_linhas ?? const <_Json>[]).where((l) => _selecionadas.contains(_chave(l))).toList()),
                  child: const Text('Marcar como entregues'),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _texto(String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(t, textAlign: TextAlign.center, style: const TextStyle(color: GridColors.textMuted)),
      );

  Widget _faixa(IconData icone, Color cor, Color fundo, String texto) => Semantics(
        liveRegion: true,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          color: fundo,
          child: Row(children: [
            Icon(icone, color: cor),
            const SizedBox(width: 8),
            Expanded(child: Text(texto)),
          ]),
        ),
      );
}

/// Confirmação de entrega (uma ou várias), dispensa ou reabertura.
class _DialogoRegistro extends StatefulWidget {
  final String acao;
  final List<_Json> itens;
  final Future<String?> Function(DateTime? data, String? protocolo, String? observacao) enviar;

  const _DialogoRegistro({required this.acao, required this.itens, required this.enviar});

  @override
  State<_DialogoRegistro> createState() => _DialogoRegistroState();
}

class _DialogoRegistroState extends State<_DialogoRegistro> {
  final _protocolo = TextEditingController();
  final _observacao = TextEditingController();
  DateTime _entrega = DateTime.now();
  String? _erro;
  bool _enviando = false;

  @override
  void dispose() {
    _protocolo.dispose();
    _observacao.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    if (widget.acao == 'DISPENSAR' && _observacao.text.trim().isEmpty) {
      setState(() => _erro = 'Informe o motivo da dispensa.');
      return;
    }
    setState(() {
      _enviando = true;
      _erro = null;
    });
    final erro = await widget.enviar(widget.acao == 'ENTREGAR' ? _entrega : null,
        _protocolo.text.trim(), _observacao.text.trim());
    if (!mounted) return;
    if (erro == null) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _enviando = false;
      _erro = erro;
    });
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.itens.length;
    final entregar = widget.acao == 'ENTREGAR';
    final reabrir = widget.acao == 'REABRIR';
    final primeiro = widget.itens.first;
    final (titulo, botao) = switch (widget.acao) {
      'ENTREGAR' => n == 1
          ? ('Marcar como entregue', 'Registrar entrega')
          : ('Registrar $n entregas?', 'Registrar $n entregas'),
      'DISPENSAR' => ('Dispensar obrigação', 'Dispensar'),
      _ => ('Reabrir obrigação?', 'Reabrir'),
    };
    return PopScope(
      canPop: !_enviando,
      child: AlertDialog(
        title: Text(titulo),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (n == 1) Text('${primeiro['empresa']}\n${primeiro['obrigacao']}'),
              const SizedBox(height: 8),
              if (entregar) ...[
                const Text('Apenas registra que a entrega foi feita fora desta tela.'),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  onPressed: _enviando
                      ? null
                      : () async {
                          final escolhida = await showDatePicker(
                              context: context,
                              initialDate: _entrega,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now());
                          if (escolhida != null && mounted) setState(() => _entrega = escolhida);
                        },
                  icon: const Icon(Icons.event),
                  label: Text('Data de entrega: ${DateFormat('dd/MM/yyyy').format(_entrega)}'),
                ),
              ],
              if (reabrir)
                const Text('A obrigação volta a ficar em aberto. O registro anterior (data, protocolo e '
                    'observação) será apagado.'),
              if (entregar && n == 1) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _protocolo,
                  enabled: !_enviando,
                  maxLength: 80,
                  decoration: const InputDecoration(labelText: 'Protocolo (opcional)'),
                ),
              ],
              if (!reabrir) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _observacao,
                  enabled: !_enviando,
                  maxLength: 500,
                  maxLines: 3,
                  decoration: InputDecoration(
                      labelText: entregar ? 'Observação (opcional)' : 'Motivo da dispensa'),
                ),
              ],
              if (_erro != null)
                Semantics(
                  liveRegion: true,
                  child: Row(children: [
                    const Icon(Icons.error, color: GridColors.errorDark),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_erro!)),
                  ]),
                ),
              if (_enviando) const LinearProgressIndicator(semanticsLabel: 'Salvando'),
            ]),
          ),
        ),
        actions: [
          TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: _enviando ? null : () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: _enviando ? null : _confirmar,
              child: Text(botao)),
        ],
      ),
    );
  }
}
