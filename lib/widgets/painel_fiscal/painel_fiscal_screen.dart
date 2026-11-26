import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../utils/api_links.dart';
import '../../utils/app_logger.dart';
import '../../utils/grid_colors.dart';
import '../../utils/tenant_context.dart';

typedef _Json = Map<String, dynamic>;

/// Aparência de cada nível do índice. Status sempre leva ícone e rótulo, nunca só cor.
class NivelFiscal {
  final String codigo;
  final String rotulo;
  final IconData icone;
  final Color cor;
  final Color fundo;

  const NivelFiscal._(this.codigo, this.rotulo, this.icone, this.cor, this.fundo);

  static const todos = [
    NivelFiscal._('EM_DIA', 'Em dia', Icons.verified, GridColors.success, GridColors.successLight),
    NivelFiscal._('ATENCAO', 'Atenção', Icons.info, GridColors.info, GridColors.card),
    NivelFiscal._('RISCO', 'Em risco', Icons.warning, GridColors.warningDark, GridColors.suggestionMedium),
    NivelFiscal._('CRITICO', 'Crítico', Icons.error, GridColors.errorDark, GridColors.errorLight),
    NivelFiscal._('SEM_DADOS', 'Sem dados', Icons.help_outline, GridColors.neutral, GridColors.surfaceMuted),
  ];

  static NivelFiscal de(String? codigo) =>
      todos.firstWhere((n) => n.codigo == codigo, orElse: () => todos.last);
}

enum _Aba {
  obrigacoes('Obrigações'),
  guias('Guias'),
  documentos('Certificados e alvarás'),
  vencidos('Vencidos');

  final String rotulo;
  const _Aba(this.rotulo);

  bool aceita(_Json item) => switch (this) {
        _Aba.obrigacoes => item['tipo'] == 'OBRIGACAO',
        _Aba.guias => item['tipo'] == 'GUIA',
        _Aba.documentos => item['tipo'] == 'CERTIFICADO' || item['tipo'] == 'ALVARA',
        _Aba.vencidos => item['situacao'] == 'VENCIDO',
      };
}

const _semRegime = -1;

/// Painel Fiscal: a carteira de clientes em um só lugar. Os números vêm calculados do backend.
class PainelFiscalScreen extends StatefulWidget {
  /// Substituível em teste.
  final Future<http.Response> Function(String url)? buscar;

  const PainelFiscalScreen({super.key, this.buscar});

  @override
  State<PainelFiscalScreen> createState() => _PainelFiscalScreenState();
}

class _PainelFiscalScreenState extends State<PainelFiscalScreen> {
  _Json? _dados;
  String? _erro;
  bool _carregando = false;
  int _pedido = 0;
  DateTime? _atualizadoEm;

  // Filtros nascem em "Todas": nunca são preenchidos com o usuário logado.
  int? _clienteId;
  int? _regimeId;
  DateTime _mes = DateTime(DateTime.now().year, DateTime.now().month);

  _Aba _aba = _Aba.obrigacoes;
  DateTime? _dia;
  String? _nivelFiltrado;
  bool _soComOcorrencia = false;
  bool _rankingCompleto = false;
  bool _todasMissoes = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final pedido = ++_pedido;
    setState(() => _carregando = true);
    final params = {
      'mes': DateFormat('yyyy-MM').format(_mes),
      // O parceiro da sessão não vira filtro; o backend já prende o cliente ao próprio cadastro.
      'skipTenantParceiro': 'true',
      if (TenantContext.empresaId != null) 'empresaId': '${TenantContext.empresaId}',
      if (_clienteId != null) 'clienteId': '$_clienteId',
      if (_regimeId != null) 'regimeId': '$_regimeId',
    };
    final url = Uri.parse('${ApiLinks.baseUrl}/api/painel-fiscal')
        .replace(queryParameters: params)
        .toString();
    try {
      final resposta = await (widget.buscar ?? TenantContext.get)(url);
      if (!mounted || pedido != _pedido) return; // resposta de filtro antigo
      if (resposta.statusCode != 200) {
        throw _FalhaPainel(resposta.statusCode == 403
            ? 'Você não tem acesso ao Painel Fiscal. Solicite ao administrador.'
            : 'Não foi possível carregar o painel fiscal (erro ${resposta.statusCode}).');
      }
      final corpo = jsonDecode(utf8.decode(resposta.bodyBytes)) as _Json;
      setState(() {
        _dados = corpo;
        _erro = null;
        _carregando = false;
        _atualizadoEm = DateTime.now();
      });
    } catch (e, st) {
      AppLogger.i.error('Painel Fiscal: falha ao carregar ($e)', st);
      if (!mounted || pedido != _pedido) return;
      setState(() {
        _erro = e is _FalhaPainel ? e.mensagem : 'Não foi possível carregar o painel fiscal.';
        _carregando = false;
      });
    }
  }

  void _filtrar(VoidCallback mudanca) {
    setState(() {
      mudanca();
      _dia = null;
      // Dados de outro filtro não podem continuar na tela como se fossem deste.
      _dados = _dados == null ? null : {..._dados!, 'desatualizado': true};
    });
    _carregar();
  }

  List<_Json> _lista(String chave) =>
      ((_dados?[chave] as List?) ?? const []).cast<_Json>();

  _Json _mapa(String chave) => (_dados?[chave] as _Json?) ?? const {};

  List<_Json> _filtroLista(String chave) =>
      ((_mapa('filtros')[chave] as List?) ?? const []).cast<_Json>();

  static String _data(String iso) => DateFormat('dd/MM/yyyy').format(DateTime.parse(iso));

  static String _reais(num valor) =>
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(valor);

  // ── Estrutura ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.pageBackground,
      appBar: AppBar(
        title: const Text('Painel Fiscal'),
        backgroundColor: GridColors.primary,
        foregroundColor: GridColors.textPrimary,
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _carregando ? null : _carregar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: LayoutBuilder(builder: (context, limites) {
        final largura = limites.maxWidth;
        if (_dados == null) {
          return Center(
            child: _erro == null
                ? const CircularProgressIndicator(semanticsLabel: 'Carregando painel fiscal')
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
        return Column(children: [
          if (_carregando) const LinearProgressIndicator(minHeight: 3),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(largura < 700 ? 12 : 20),
              children: _blocos(largura),
            ),
          ),
        ]);
      }),
    );
  }

  List<Widget> _blocos(double largura) {
    final desatualizado = _dados?['desatualizado'] == true;
    final topo = <Widget>[
      _filtros(largura),
      if (_erro != null)
        _aviso(desatualizado
            ? '$_erro Os números abaixo são do filtro anterior.'
            : '$_erro Exibindo dados de ${DateFormat('HH:mm').format(_atualizadoEm!)}.'),
    ];
    if (_lista('empresas').isEmpty) {
      final filtrado = _clienteId != null || _regimeId != null;
      return [
        ...topo,
        _painel(null, [
          Text(filtrado
              ? 'Nenhuma empresa corresponde aos filtros.'
              : 'Nenhuma empresa-cliente com regime ou dado fiscal cadastrado.'),
        ]),
      ];
    }

    final largo = largura >= 1100;
    Widget par(Widget a, Widget b, {int fa = 1, int fb = 1}) => largo
        ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: fa, child: a),
            const SizedBox(width: 12),
            Expanded(flex: fb, child: b),
          ])
        : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [a, b]);

    final contadores = _contadores(largura >= 700);
    return [
      ...topo,
      if (largo)
        par(_saude(), Column(children: [contadores, _progresso()]), fa: 2, fb: 5)
      else ...[
        _saude(),
        _progresso(),
      ],
      par(_missoes(), _ranking(), fa: 3, fb: 2),
      if (!largo) contadores,
      _rotina(largo),
      if (_clienteId == null) _niveis(),
      _integracoes(),
    ];
  }

  Widget _painel(String? titulo, List<Widget> filhos, {Widget? acao}) => Card(
        color: GridColors.card,
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (titulo != null)
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Semantics(
                    header: true,
                    child: Text(titulo,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: GridColors.textSecondary)),
                  ),
                  if (acao != null) acao,
                ],
              ),
            if (titulo != null) const SizedBox(height: 8),
            ...filhos,
          ]),
        ),
      );

  Widget _aviso(String texto) => Semantics(
        liveRegion: true,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          color: GridColors.errorLight,
          child: Row(children: [
            const Icon(Icons.warning, color: GridColors.errorDark),
            const SizedBox(width: 8),
            Expanded(child: Text(texto)),
          ]),
        ),
      );

  Widget _texto(String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(t, style: const TextStyle(color: GridColors.textMuted)),
      );

  // ── Filtros ──────────────────────────────────────────────────────────────

  Widget _filtros(double largura) {
    final empresas = _filtroLista('empresas');
    final regimes = _filtroLista('regimes');
    final escolhida = empresas.where((e) => e['id'] == _clienteId).firstOrNull;
    final campo = largura < 700 ? largura - 52 : 280.0;
    return _painel(null, [
      Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
        SizedBox(
          width: campo,
          child: OutlinedButton.icon(
            key: const Key('filtro-empresa'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: () => _escolherEmpresa(empresas),
            icon: const Icon(Icons.business),
            label: Text(escolhida?['nome']?.toString() ?? 'Todas as empresas',
                overflow: TextOverflow.ellipsis),
          ),
        ),
        SizedBox(
          width: campo,
          child: DropdownButtonFormField<int?>(
            key: ValueKey('regime-$_regimeId-$_clienteId'),
            initialValue: _regimeId,
            isExpanded: true,
            decoration: const InputDecoration(
                labelText: 'Regime tributário', border: OutlineInputBorder(), isDense: true),
            items: [
              const DropdownMenuItem(value: null, child: Text('Todos os regimes')),
              for (final r in regimes)
                DropdownMenuItem(
                    value: r['id'] as int,
                    child: Text('${r['descricao']}', overflow: TextOverflow.ellipsis)),
              const DropdownMenuItem(value: _semRegime, child: Text('Sem regime informado')),
            ],
            // Com uma empresa escolhida o regime não filtra nada.
            onChanged: _clienteId != null ? null : (v) => _filtrar(() => _regimeId = v),
          ),
        ),
        Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            tooltip: 'Mês anterior',
            onPressed: () => _filtrar(() => _mes = DateTime(_mes.year, _mes.month - 1)),
            icon: const Icon(Icons.chevron_left),
          ),
          Flexible(child: Text('Vencimentos em ${DateFormat('MM/yyyy').format(_mes)}')),
          IconButton(
            tooltip: 'Próximo mês',
            onPressed: () => _filtrar(() => _mes = DateTime(_mes.year, _mes.month + 1)),
            icon: const Icon(Icons.chevron_right),
          ),
        ]),
        if (_clienteId != null || _regimeId != null)
          TextButton.icon(
            onPressed: () => _filtrar(() {
              _clienteId = null;
              _regimeId = null;
            }),
            icon: const Icon(Icons.filter_alt_off),
            label: Text(_clienteId != null ? 'Voltar à carteira' : 'Limpar filtros'),
          ),
      ]),
    ]);
  }

  Future<void> _escolherEmpresa(List<_Json> empresas) async {
    var busca = '';
    final id = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, atualizar) {
        final achadas = empresas
            .where((e) => '${e['nome']}'.toLowerCase().contains(busca.toLowerCase()))
            .toList();
        return AlertDialog(
          title: const Text('Escolher empresa'),
          content: SizedBox(
            width: 420,
            height: 420,
            child: Column(children: [
              TextField(
                autofocus: true,
                decoration: const InputDecoration(
                    labelText: 'Buscar por nome', prefixIcon: Icon(Icons.search)),
                onChanged: (v) => atualizar(() => busca = v),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: achadas.length + 1,
                  itemBuilder: (context, i) => ListTile(
                    title: Text(i == 0 ? 'Todas as empresas' : '${achadas[i - 1]['nome']}'),
                    onTap: () => Navigator.pop(context, i == 0 ? 0 : achadas[i - 1]['id'] as int),
                  ),
                ),
              ),
            ]),
          ),
        );
      }),
    );
    if (id == null || !mounted) return;
    _verEmpresa(id == 0 ? null : id);
  }

  void _verEmpresa(int? id) => _filtrar(() {
        _clienteId = id;
        _regimeId = null;
        _nivelFiltrado = null;
        _soComOcorrencia = false;
      });

  // ── Saúde, contadores e progresso ────────────────────────────────────────

  Widget _selo(NivelFiscal n, [String? texto]) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: n.fundo,
            border: Border.all(color: n.cor),
            borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(n.icone, size: 16, color: n.cor),
          const SizedBox(width: 4),
          Text(texto ?? n.rotulo,
              style: const TextStyle(fontSize: 12, color: GridColors.textSecondary)),
        ]),
      );

  Widget _saude() {
    // Pelo id: enquanto o filtro carrega, os dados na tela ainda são os anteriores.
    final uma = _lista('empresas').where((e) => e['id'] == _clienteId).firstOrNull;
    final carteira = _mapa('carteira');
    final indice = (uma ?? carteira)['indice'] as int?;
    final nivel = NivelFiscal.de((uma ?? carteira)['nivel'] as String?);
    return _painel(uma == null ? 'Saúde da carteira' : 'Saúde da empresa', [
      Semantics(
        label: indice == null
            ? 'Sem dados para calcular o índice'
            : 'Índice de saúde fiscal $indice de 100, ${nivel.rotulo}',
        child: ExcludeSemantics(
          child: SizedBox(
            height: 150,
            child: Stack(alignment: Alignment.center, children: [
              PieChart(PieChartData(
                startDegreeOffset: -90,
                sectionsSpace: 0,
                centerSpaceRadius: 52,
                sections: [
                  PieChartSectionData(
                      value: (indice ?? 0).toDouble(),
                      color: nivel.cor,
                      radius: 16,
                      showTitle: false),
                  PieChartSectionData(
                      value: (100 - (indice ?? 0)).toDouble(),
                      color: GridColors.surfaceMuted,
                      radius: 16,
                      showTitle: false),
                ],
              )),
              Text(indice?.toString() ?? '—',
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      ),
      Center(child: _selo(nivel)),
      const SizedBox(height: 8),
      Text(
        uma != null
            ? (uma['parcial'] == true ? 'Avaliação parcial: cadastro incompleto' : 'Avaliação completa')
            : '${carteira['avaliadas']} de ${carteira['total']} avaliadas'
                ' · ${carteira['parciais']} parciais',
        textAlign: TextAlign.center,
        style: const TextStyle(color: GridColors.textMuted),
      ),
      if (uma != null) ...[
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: [
          for (final s in (uma['selos'] as List)) _selo(NivelFiscal.todos.first, '$s'),
        ]),
        for (final c in (uma['componentes'] as List).cast<_Json>())
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text('${c['rotulo']} (peso ${c['peso']})'),
            subtitle: c['nota'] == null
                ? null
                : LinearProgressIndicator(value: (c['nota'] as int) / 100),
            trailing: Text(c['nota'] == null ? 'Sem dados' : '${c['nota']}'),
          ),
      ],
      TextButton(onPressed: _explicarIndice, child: const Text('Como é calculado?')),
    ]);
  }

  void _explicarIndice() => _detalhe('Como o índice é calculado', const [
        'Pesos: obrigações 40, guias 30, certificado A1 20, alvarás e documentos 10.',
        'Obrigações e guias: no prazo vale 100%, com atraso 50%, vencida em aberto 0%. Entram as vencidas de qualquer mês e as concluídas do mês escolhido.',
        'Certificado e documentos usam a situação de hoje e perdem nota perto do vencimento.',
        'Componente sem dado não conta. Com algo vencido, o máximo é 79. Sem regime, sem certificado ou sem obrigação e guia avaliadas, o máximo é 89.',
        'A nota usa só o que está cadastrado. Não é certidão e não consulta a Receita.',
      ]);

  Future<void> _detalhe(String titulo, List<String> linhas, {int? empresaId}) =>
      showDialog<void>(
        context: context,
        builder: (dialogo) => AlertDialog(
          title: Text(titulo),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final l in linhas)
                  Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(l)),
              ],
            ),
          ),
          actions: [
            if (empresaId != null && _clienteId == null)
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogo);
                  _verEmpresa(empresaId);
                },
                child: const Text('Ver empresa no painel'),
              ),
            TextButton(onPressed: () => Navigator.pop(dialogo), child: const Text('Fechar')),
          ],
        ),
      );

  void _abrirItem(_Json i) => _detalhe(
        '${i['titulo']}',
        [
          'Empresa: ${i['empresa']}',
          'Vencimento: ${_data(i['vencimento'])}',
          'Situação: ${_rotuloSituacao(i)}',
          if (i['tipo'] == 'GUIA')
            'Valor: ${i['valor'] == null ? 'a informar' : _reais(i['valor'] as num)}',
        ],
        empresaId: i['parceiroId'] as int?,
      );

  Widget _contador(String titulo, String numero, String detalhe, IconData icone, Color cor,
          VoidCallback aoTocar) =>
      Card(
        color: GridColors.card,
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: aoTocar,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Icon(icone, color: cor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(titulo, style: const TextStyle(color: GridColors.textMuted)),
                  Text(numero,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  Text(detalhe,
                      style: const TextStyle(fontSize: 12, color: GridColors.textMuted)),
                ]),
              ),
            ]),
          ),
        ),
      );

  Widget _contadores(bool emLinha) {
    final c = _mapa('cards');
    final semValor = (c['guiasVencidasSemValor'] as num?) ?? 0;
    final cartoes = [
      _contador(
          'Certificados vencidos',
          '${c['certificadosVencidos']}',
          '${c['certificadosAVencer']} vencem em 30 dias · ${c['certificadosAusentes']} sem cadastro',
          Icons.badge,
          GridColors.errorDark,
          () => setState(() {
                _aba = _Aba.documentos;
                _dia = null;
              })),
      _contador(
          'Empresas com ocorrências',
          '${c['empresasComOcorrencia']}',
          'de ${_mapa('carteira')['total']} na seleção',
          Icons.report,
          GridColors.warningDark,
          () => setState(() {
                _soComOcorrencia = !_soComOcorrencia;
                _rankingCompleto = true;
              })),
      _contador(
          'Guias vencidas',
          '${c['guiasVencidas']}',
          '${_reais((c['guiasVencidasValor'] as num?) ?? 0)}'
              '${semValor > 0 ? ' · $semValor sem valor' : ''}',
          Icons.receipt_long,
          GridColors.errorDark,
          () => setState(() => _aba = _Aba.vencidos)),
    ];
    return emLinha
        ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (var i = 0; i < cartoes.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: cartoes[i]),
            ],
          ])
        : Column(children: cartoes);
  }

  Widget _progresso() {
    final p = _mapa('progresso');
    final o = p['obrigacoes'] as _Json, g = p['guias'] as _Json;
    final feitas = (o['feitas'] as int) + (g['feitas'] as int);
    final total = (o['total'] as int) + (g['total'] as int);
    return _painel('Progresso do mês', [
      if (total == 0)
        _texto('Nenhum vencimento registrado em ${DateFormat('MM/yyyy').format(_mes)}.')
      else ...[
        Semantics(
          label: '$feitas de $total concluídas',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
                value: feitas / total, minHeight: 14, color: GridColors.primary,
                backgroundColor: GridColors.surfaceMuted),
          ),
        ),
        const SizedBox(height: 8),
        Text('$feitas de $total concluídas (${(feitas * 100 / total).round()}%) · '
            'obrigações ${o['feitas']}/${o['total']} · guias ${g['feitas']}/${g['total']}'),
      ],
    ]);
  }

  // ── Missões e ranking ────────────────────────────────────────────────────

  Widget _missoes() {
    final missoes = _lista('missoes');
    final visiveis = _todasMissoes ? missoes : missoes.take(5).toList();
    return _painel(
      'Próximas missões',
      [
        if (missoes.isEmpty) _texto('Nenhuma pendência encontrada nos dados cadastrados.'),
        for (var i = 0; i < visiveis.length; i++)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: visiveis[i]['situacao'] == 'VENCIDO'
                  ? GridColors.errorLight
                  : GridColors.surfaceMuted,
              child: Text('${i + 1}', style: const TextStyle(color: GridColors.textSecondary)),
            ),
            title: Text('${visiveis[i]['titulo']}'),
            subtitle: Text('${visiveis[i]['motivo']} · ${visiveis[i]['empresa']}'),
            trailing: Icon(
                visiveis[i]['situacao'] == 'VENCIDO' ? Icons.error : Icons.schedule,
                color: visiveis[i]['situacao'] == 'VENCIDO'
                    ? GridColors.errorDark
                    : GridColors.neutral),
            onTap: () => _abrirItem(visiveis[i]),
          ),
      ],
      acao: missoes.length > 5
          ? TextButton(
              onPressed: () => setState(() => _todasMissoes = !_todasMissoes),
              child: Text(_todasMissoes ? 'Ver menos' : 'Ver todas (${missoes.length})'))
          : null,
    );
  }

  Widget _ranking() {
    final todas = _lista('empresas')
        .where((e) => _nivelFiltrado == null || e['nivel'] == _nivelFiltrado)
        .where((e) => !_soComOcorrencia || (e['vencidos'] as int) > 0)
        .toList();
    final visiveis = _rankingCompleto ? todas : todas.take(5).toList();
    final filtro = [
      if (_nivelFiltrado != null) NivelFiscal.de(_nivelFiltrado).rotulo,
      if (_soComOcorrencia) 'com ocorrências',
    ].join(', ');
    return _painel(
      _clienteId == null ? 'Precisam de atenção' : 'O que reduz a nota',
      [
        if (filtro.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: InputChip(
              label: Text('Mostrando: $filtro'),
              onDeleted: () => setState(() {
                _nivelFiltrado = null;
                _soComOcorrencia = false;
              }),
            ),
          ),
        if (todas.isEmpty) _texto('Nenhuma empresa neste recorte.'),
        for (final e in visiveis)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('${e['nome']}'),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${e['motivo']}'.isEmpty ? 'Nenhuma pendência cadastrada' : '${e['motivo']}'),
              const SizedBox(height: 4),
              _selo(
                  NivelFiscal.de(e['nivel']),
                  e['indice'] == null
                      ? 'Sem dados'
                      : '${e['indice']} · ${NivelFiscal.de(e['nivel']).rotulo}'),
            ]),
            trailing: _clienteId == null ? const Icon(Icons.chevron_right) : null,
            onTap: _clienteId == null ? () => _verEmpresa(e['id'] as int) : null,
          ),
      ],
      acao: todas.length > 5
          ? TextButton(
              onPressed: () => setState(() => _rankingCompleto = !_rankingCompleto),
              child: Text(_rankingCompleto ? 'Ver menos' : 'Ver ranking completo'))
          : null,
    );
  }

  // ── Rotina fiscal (calendário e listas) ──────────────────────────────────

  bool _noMes(DateTime d) => d.year == _mes.year && d.month == _mes.month;

  Widget _rotina(bool largo) {
    final daAba = _lista('itens').where(_aba.aceita).toList();
    final ignoraData = _aba == _Aba.vencidos;
    final visiveis = daAba.where((i) {
      if (ignoraData) return true;
      final venc = DateTime.parse(i['vencimento']);
      return _dia != null ? isSameDay(venc, _dia) : (_aba == _Aba.documentos || _noMes(venc));
    }).toList();

    final lista = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _texto(ignoraData
          ? 'Vencidos de qualquer mês.'
          : _dia != null
              ? 'Dia ${DateFormat('dd/MM/yyyy').format(_dia!)}'
              : _aba == _Aba.documentos
                  ? 'Todos os documentos cadastrados.'
                  : 'Mês inteiro.'),
      if (visiveis.isEmpty)
        _texto(_dia != null ? 'Nada vence neste dia.' : 'Nada para mostrar.'),
      // Limite de linhas: a lista fica dentro da rolagem da página.
      for (final i in visiveis.take(60)) _linhaItem(i),
      if (visiveis.length > 60)
        _texto('Mostrando 60 de ${visiveis.length}. Escolha um dia ou uma empresa.'),
    ]);

    return _painel('Rotina fiscal', [
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final a in _Aba.values)
          ChoiceChip(
            label: Text('${a.rotulo} (${_lista('itens').where(a.aceita).length})'),
            selected: _aba == a,
            selectedColor: GridColors.primarySoft,
            onSelected: (_) => setState(() => _aba = a),
          ),
      ]),
      const SizedBox(height: 8),
      if (ignoraData)
        lista
      else if (largo)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 2, child: _calendario(daAba)),
          const SizedBox(width: 16),
          Expanded(flex: 3, child: lista),
        ])
      else ...[
        _calendario(daAba),
        lista,
      ],
    ]);
  }

  Widget _calendario(List<_Json> itens) {
    final ultimoDia = DateTime(_mes.year, _mes.month + 1, 0);
    List<_Json> doDia(DateTime d) =>
        itens.where((i) => isSameDay(DateTime.parse(i['vencimento']), d)).toList();
    return TableCalendar<_Json>(
      locale: 'pt_BR',
      firstDay: DateTime(_mes.year, _mes.month),
      lastDay: ultimoDia,
      focusedDay: _dia ?? DateTime(_mes.year, _mes.month),
      headerVisible: false,
      rowHeight: 48,
      daysOfWeekHeight: 24,
      availableGestures: AvailableGestures.none,
      selectedDayPredicate: (d) => isSameDay(d, _dia),
      eventLoader: doDia,
      onDaySelected: (d, _) =>
          setState(() => _dia = isSameDay(d, _dia) ? null : DateTime(d.year, d.month, d.day)),
      calendarStyle: const CalendarStyle(
        selectedDecoration: BoxDecoration(color: GridColors.primary, shape: BoxShape.circle),
        todayDecoration: BoxDecoration(color: GridColors.primarySoft, shape: BoxShape.circle),
        todayTextStyle: TextStyle(color: GridColors.textSecondary),
      ),
      calendarBuilders: CalendarBuilders<_Json>(
        markerBuilder: (context, dia, eventos) {
          if (eventos.isEmpty) return null;
          final atraso = eventos.any((e) => e['situacao'] == 'VENCIDO');
          return Positioned(
            right: 2,
            bottom: 0,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (atraso) const Icon(Icons.error, size: 12, color: GridColors.errorDark),
              Text('${eventos.length}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ]),
          );
        },
      ),
    );
  }

  static String _rotuloSituacao(_Json i) {
    final base = switch (i['situacao']) {
      'CONCLUIDO' => 'Concluído',
      'VENCIDO' => 'Vencido',
      _ => 'Pendente',
    };
    return i['etiqueta'] == null ? base : '$base · ${i['etiqueta']}';
  }

  Widget _linhaItem(_Json i) {
    final n = NivelFiscal.de(switch (i['situacao']) {
      'CONCLUIDO' => 'EM_DIA',
      'VENCIDO' => 'CRITICO',
      _ => 'ATENCAO',
    });
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('${i['titulo']}'),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${i['empresa']} · vence ${_data(i['vencimento'])}'
            '${i['tipo'] == 'GUIA' ? ' · ${i['valor'] == null ? 'valor a informar' : _reais(i['valor'] as num)}' : ''}'),
        const SizedBox(height: 4),
        _selo(n, _rotuloSituacao(i)),
      ]),
      onTap: () => _abrirItem(i),
    );
  }

  // ── Níveis e integrações ─────────────────────────────────────────────────

  Widget _niveis() {
    final empresas = _lista('empresas');
    return _painel('Situação por nível', [
      for (final n in NivelFiscal.todos)
        Builder(builder: (context) {
          final qtd = empresas.where((e) => e['nivel'] == n.codigo).length;
          return InkWell(
            onTap: qtd == 0
                ? null
                : () => setState(() {
                      _nivelFiltrado = n.codigo;
                      _rankingCompleto = true;
                    }),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Row(children: [
                Icon(n.icone, color: n.cor, size: 18),
                const SizedBox(width: 8),
                SizedBox(width: 90, child: Text(n.rotulo)),
                Expanded(
                  child: LinearProgressIndicator(
                    value: empresas.isEmpty ? 0 : qtd / empresas.length,
                    minHeight: 12,
                    color: n.cor,
                    backgroundColor: GridColors.surfaceMuted,
                  ),
                ),
                SizedBox(width: 40, child: Text('$qtd', textAlign: TextAlign.end)),
              ]),
            ),
          );
        }),
    ]);
  }

  Widget _integracoes() => Card(
        color: GridColors.surfaceMuted,
        child: const ExpansionTile(
          leading: Icon(Icons.link_off, color: GridColors.neutral),
          title: Text('Ainda não disponível'),
          subtitle: Text('e-CAC e caixa postal, procurações, CND automática e parcelamentos'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text('Estas integrações ainda não existem no sistema. '
                  'Nenhum dado destes itens entra no índice.'),
            ),
          ],
        ),
      );
}

class _FalhaPainel implements Exception {
  final String mensagem;
  const _FalhaPainel(this.mensagem);

  @override
  String toString() => mensagem;
}
