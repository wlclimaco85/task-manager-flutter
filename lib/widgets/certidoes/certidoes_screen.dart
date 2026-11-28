import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/session_expired_handler.dart';
import '../../utils/api_links.dart';
import '../../utils/app_logger.dart';
import '../../utils/file_saver_compat.dart';
import '../../utils/grid_colors.dart';
import '../../utils/tenant_context.dart';
import '../user_banners.dart';

typedef _Json = Map<String, dynamic>;

const _semAcesso = 'Você não tem acesso a Certidões. Solicite ao administrador.';

/// Situação de cada par empresa x tipo, na ordem de urgência. Sempre com ícone e texto.
enum _Situacao {
  vencida('VENCIDA', 'Vencida', 'Vencidas', Icons.error, GridColors.errorDark, GridColors.errorLight),
  irregular('IRREGULAR', 'Irregular', 'Irregulares', Icons.gpp_bad, GridColors.errorDark, GridColors.errorLight),
  vencendo('VENCENDO', 'Vencendo', 'Vencendo (30 dias)', Icons.warning, GridColors.warningDark,
      GridColors.suggestionMedium),
  ausente('SEM', 'Sem certidão', 'Sem certidão', Icons.help_outline, GridColors.neutral, GridColors.surfaceMuted),
  valida('VALIDA', 'Válida', 'Válidas', Icons.verified, GridColors.success, GridColors.successLight);

  final String codigo;
  final String rotulo;
  final String plural;
  final IconData icone;
  final Color cor;
  final Color fundo;
  const _Situacao(this.codigo, this.rotulo, this.plural, this.icone, this.cor, this.fundo);

  static _Situacao de(Object? codigo) =>
      values.firstWhere((s) => s.codigo == codigo, orElse: () => vencida);
}

const _resultados = {
  'NEGATIVA': 'Negativa',
  'POSITIVA_EFEITO_NEGATIVA': 'Positiva com efeito de negativa',
  'POSITIVA': 'Positiva',
};

String _data(Object? iso) => DateFormat('dd/MM/yyyy').format(DateTime.parse('$iso'));

/// Par empresa x tipo; [certidao] nula quando não há nenhuma registrada.
class _Par {
  final int empresa; // 0 = a própria empresa
  final String nome;
  final String tipo;
  final String tipoNome;
  final _Json? certidao;
  const _Par(this.empresa, this.nome, this.tipo, this.tipoNome, this.certidao);

  _Situacao get situacao => certidao == null ? _Situacao.ausente : _Situacao.de(certidao!['situacao']);
}

/// PDF escolhido pelo usuário.
class ArquivoPdf {
  final String nome;
  final Uint8List bytes;
  const ArquivoPdf(this.nome, this.bytes);
}

/// Certidões enviadas pelo escritório, por empresa e tipo, com a situação de validade.
class CertidoesScreen extends StatefulWidget {
  /// true quando a tela é aberta pelo menu do celular.
  final bool cabecalhoMobile;

  /// Substituíveis em teste.
  final Future<http.Response> Function(String url)? buscar;
  final Future<http.Response> Function(String url, Map<String, String> campos, ArquivoPdf arquivo)? enviar;
  final Future<http.Response> Function(String url)? excluir;
  final Future<ArquivoPdf?> Function()? escolherArquivo;
  final Future<void> Function(String nome, Uint8List bytes)? salvar;

  const CertidoesScreen(
      {super.key,
      this.cabecalhoMobile = false,
      this.buscar,
      this.enviar,
      this.excluir,
      this.escolherArquivo,
      this.salvar});

  @override
  State<CertidoesScreen> createState() => _CertidoesScreenState();
}

class _CertidoesScreenState extends State<CertidoesScreen> {
  _Json? _dados;
  String? _erro;
  bool _carregando = true;

  int? _empresa;
  String? _tipo;
  _Situacao? _situacao;
  final Set<int> _abertas = {};

  List<_Par> _pares = const [];
  Map<int, String> _nomes = const {};
  Map<String, String> _tipos = const {};

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  String _url([String caminho = '']) =>
      Uri.parse('${ApiLinks.baseUrl}/api/certidoes$caminho').replace(queryParameters: {
        'skipTenantParceiro': 'true',
        if (TenantContext.empresaId != null) 'empresaId': '${TenantContext.empresaId}',
      }).toString();

  Future<http.Response> _get(String url) => (widget.buscar ?? TenantContext.get)(url);

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final r = await _get(_url());
      if (!mounted) return;
      if (r.statusCode != 200) {
        setState(() {
          _dados = null;
          _erro = r.statusCode == 403 ? _semAcesso : 'Não foi possível carregar as certidões.';
          _carregando = false;
        });
        return;
      }
      final corpo = jsonDecode(utf8.decode(r.bodyBytes)) as _Json;
      setState(() {
        _montar(corpo);
        _dados = corpo;
        _erro = null;
        _carregando = false;
      });
    } catch (e, st) {
      AppLogger.i.error('Certidões: falha ao carregar ($e)', st);
      if (!mounted) return;
      setState(() {
        _dados = null;
        _erro = 'Não foi possível carregar as certidões.';
        _carregando = false;
      });
    }
  }

  /// Cruza empresas e tipos uma única vez por carga.
  void _montar(_Json corpo) {
    _tipos = {for (final t in (corpo['tipos'] as List).cast<_Json>()) '${t['codigo']}': '${t['nome']}'};
    _nomes = {
      0: 'Minha empresa',
      for (final c in (corpo['clientes'] as List).cast<_Json>()) c['parceiroId'] as int: '${c['nome']}',
    };
    final vigentes = <String, _Json>{};
    // O servidor manda da validade mais longa para a mais curta.
    for (final c in (corpo['certidoes'] as List).cast<_Json>()) {
      vigentes.putIfAbsent('${c['parceiroId'] ?? 0}-${c['tipo']}', () => c);
    }
    _pares = [
      for (final e in _nomes.entries)
        for (final t in _tipos.entries) _Par(e.key, e.value, t.key, t.value, vigentes['${e.key}-${t.key}']),
    ];
  }

  void _avisar(String texto) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));

  // ── Ações ────────────────────────────────────────────────────────────────

  static Future<ArquivoPdf?> _escolherNoAparelho() async {
    final r = await FilePicker.pickFiles(
        type: FileType.custom, allowedExtensions: const ['pdf'], withData: true);
    final arquivo = r?.files.firstOrNull;
    if (arquivo?.bytes == null) return null;
    return ArquivoPdf(arquivo!.name, arquivo.bytes!);
  }

  static Future<http.Response> _enviarPeloServidor(
      String url, Map<String, String> campos, ArquivoPdf arquivo) async {
    final pedido = http.MultipartRequest('POST', Uri.parse(url))
      ..headers.addAll(Map.of(TenantContext.jsonHeaders)
        ..removeWhere((k, _) => k.toLowerCase() == 'content-type'))
      ..fields.addAll(campos)
      ..files.add(http.MultipartFile.fromBytes('file', arquivo.bytes, filename: arquivo.nome));
    return http.Response.fromStream(await pedido.send().timeout(const Duration(minutes: 2)));
  }

  /// Devolve a mensagem de erro, ou null quando gravou.
  Future<String?> _registrar(Map<String, String> campos, ArquivoPdf arquivo) async {
    try {
      final r = await (widget.enviar ?? _enviarPeloServidor)(_url(), campos, arquivo);
      if (r.statusCode == 401) SessionExpiredHandler.handle();
      if (r.statusCode == 200) return null;
      if (r.statusCode == 403) return 'Você não tem permissão para esta ação.';
      if (r.statusCode == 400 || r.statusCode == 404) {
        final json = jsonDecode(utf8.decode(r.bodyBytes));
        final texto = json['message'] ?? json['mensagem'];
        if (texto != null) return '$texto';
      }
      AppLogger.i.warn('Certidões: envio recusado (${r.statusCode})');
    } catch (e, st) {
      AppLogger.i.error('Certidões: falha ao enviar (${e.runtimeType})', st);
    }
    return 'Não foi possível enviar a certidão. Confira a lista antes de tentar de novo.';
  }

  Future<void> _abrirEnvio({int? empresa, String? tipo}) async {
    final gravou = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DialogoEnvio(
        nomes: _nomes,
        tipos: _tipos,
        pares: _pares,
        empresa: empresa,
        tipo: tipo,
        escolher: widget.escolherArquivo ?? _escolherNoAparelho,
        registrar: _registrar,
      ),
    );
    if (gravou != true || !mounted) return;
    _avisar('Certidão registrada.');
    await _carregar();
  }

  Future<void> _excluir(_Par par) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir certidão?'),
        content: Text('${par.nome}\n${par.tipoNome}, vence em ${_data(par.certidao!['dataVencimento'])}\n\n'
            'O registro será excluído. Se houver uma certidão anterior, ela voltará a ser a atual.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir registro')),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;
    var mensagem = 'Não foi possível excluir a certidão.';
    try {
      final url = _url('/${par.certidao!['id']}');
      final r = widget.excluir != null
          ? await widget.excluir!(url)
          : await http
              .delete(Uri.parse(url), headers: TenantContext.jsonHeaders)
              .timeout(const Duration(minutes: 1));
      if (r.statusCode == 401) SessionExpiredHandler.handle();
      if (r.statusCode == 200) {
        mensagem = 'Certidão excluída.';
      } else if (r.statusCode == 403) {
        mensagem = 'Você não tem permissão para esta ação.';
      } else {
        AppLogger.i.warn('Certidões: exclusão recusada (${r.statusCode})');
      }
    } catch (e, st) {
      AppLogger.i.error('Certidões: falha ao excluir ($e)', st);
    }
    if (!mounted) return;
    _avisar(mensagem);
    await _carregar();
  }

  Future<void> _baixar(_Par par) async {
    try {
      final r = await _get(_url('/${par.certidao!['id']}/pdf'));
      if (r.statusCode != 200) {
        AppLogger.i.warn('Certidões: download recusado (${r.statusCode})');
        if (mounted) {
          _avisar(r.statusCode == 403
              ? 'Você não tem permissão para esta ação.'
              : 'Não foi possível baixar o PDF.');
        }
        return;
      }
      final nome = 'certidao_${par.tipoNome.toLowerCase()}_${par.certidao!['id']}.pdf';
      if (widget.salvar != null) {
        await widget.salvar!(nome, r.bodyBytes);
        return;
      }
      final caminho =
          await FileSaver.instance.saveFile(name: nome, bytes: r.bodyBytes, mimeType: MimeType.pdf);
      // No celular o arquivo é compartilhado: a pasta do app não é acessível ao usuário.
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        // ignore: deprecated_member_use
        await Share.shareXFiles([XFile(caminho, name: nome)], sharePositionOrigin: ui.Rect.largest);
      } else if (mounted) {
        _avisar(kIsWeb ? 'PDF gerado.' : 'PDF salvo em $caminho');
      }
    } catch (e, st) {
      AppLogger.i.error('Certidões: falha ao baixar ($e)', st);
      if (mounted) _avisar('Não foi possível baixar o PDF.');
    }
  }

  void _detalhes(_Par par) {
    final c = par.certidao!;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${par.tipoNome}: ${par.nome}'),
        content: SingleChildScrollView(
          child: SelectableText([
            'Situação: ${par.situacao.rotulo}',
            'Resultado: ${_resultados[c['resultado']] ?? 'Não informado'}',
            if (c['numero'] != null) 'Número: ${c['numero']}',
            if (c['dataEmissao'] != null) 'Emissão: ${_data(c['dataEmissao'])}',
            if (c['dataVencimento'] != null) 'Vencimento: ${_data(c['dataVencimento'])}',
            if (c['observacao'] != null) 'Observação: ${c['observacao']}',
          ].join('\n')),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar'))],
      ),
    );
  }

  Future<void> _escolherEmpresa() async {
    final id = await showDialog<int>(
      context: context,
      builder: (_) => _BuscaEmpresa(nomes: _nomes, todas: true),
    );
    if (id == null || !mounted) return;
    setState(() => _empresa = id < 0 ? null : id);
  }

  // ── Tela ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    const titulo = 'Certidões (CND)';
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
              screenTitle: titulo, showBackButton: true, showFilterButton: false, actions: [atualizar])
          : AppBar(
              title: const Text(titulo),
              backgroundColor: GridColors.primary,
              foregroundColor: GridColors.textPrimary,
              actions: [atualizar],
            ),
      body: LayoutBuilder(builder: (context, limites) => _corpo(limites.maxWidth)),
    );
  }

  Widget _corpo(double largura) {
    final margem = largura < 700 ? 12.0 : 20.0;
    final recorte = _pares
        .where((p) => (_empresa == null || p.empresa == _empresa) && (_tipo == null || p.tipo == _tipo))
        .toList();
    final grupos = <int, List<_Par>>{};
    for (final p in recorte) {
      if (_situacao == null || p.situacao == _situacao) grupos.putIfAbsent(p.empresa, () => []).add(p);
    }
    int urgencia(List<_Par> g) => g.map((p) => p.situacao.index).reduce((a, b) => a < b ? a : b);
    final ordem = grupos.keys.toList()
      ..sort((a, b) {
        if (a == 0 || b == 0) return a == 0 ? -1 : 1;
        final u = urgencia(grupos[a]!).compareTo(urgencia(grupos[b]!));
        return u != 0 ? u : _nomes[a]!.toLowerCase().compareTo(_nomes[b]!.toLowerCase());
      });
    final filtrado = _tipo != null || _situacao != null;

    final topo = <Widget>[
      _faixa(Icons.info, GridColors.info, GridColors.card,
          'Dados digitados pelo escritório: nada é consultado no órgão emissor. Usuários do cliente e quem '
          'enviou são avisados 30, 15 e 5 dias antes do vencimento. Os registros também aparecem em Alvarás.'),
      if (_erro != null) ...[
        _faixa(Icons.error, GridColors.errorDark, GridColors.errorLight, _erro!),
        if (_erro != _semAcesso)
          Center(
              child: FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                  onPressed: _carregar,
                  child: const Text('Tentar novamente'))),
      ] else if (_dados == null)
        const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator(semanticsLabel: 'Carregando certidões')),
        )
      else ...[
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: () => _abrirEnvio(),
            icon: const Icon(Icons.upload_file),
            label: const Text('Enviar certidão'),
          ),
        ),
        const SizedBox(height: 12),
        _filtros(largura, margem),
        _contadores(recorte),
        if ((_dados!['certidoes'] as List).isEmpty) _texto('Nenhuma certidão registrada. Use Enviar certidão.'),
        if (_nomes.length == 1) _texto('Nenhum cliente disponível.'),
        if (ordem.isEmpty) _texto('Nenhuma empresa corresponde aos filtros.'),
      ],
    ];

    return Column(children: [
      if (_carregando && _dados != null) const LinearProgressIndicator(minHeight: 3),
      Expanded(
        // A carteira pode ter centenas de empresas: a lista é construída sob demanda.
        child: CustomScrollView(slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(margem, margem, margem, 0),
            sliver: SliverList.list(children: topo),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(margem, 4, margem, margem),
            sliver: SliverList.builder(
              itemCount: _dados == null ? 0 : ordem.length,
              itemBuilder: (_, i) => _cartao(ordem[i], grupos[ordem[i]]!, filtrado, largura),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _filtros(double largura, double margem) {
    final campo = largura < 700 ? largura - 2 * margem : 260.0;
    Widget lista<T>(String rotulo, String todos, T? valor, Map<T, String> opcoes, ValueChanged<T?> mudar) =>
        SizedBox(
          width: campo,
          child: DropdownButtonFormField<T?>(
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
        SizedBox(
          width: campo,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: _escolherEmpresa,
            icon: const Icon(Icons.business),
            label: Text(_empresa == null ? 'Empresa: Todas' : _nomes[_empresa] ?? 'Empresa: Todas',
                overflow: TextOverflow.ellipsis),
          ),
        ),
        lista<String>('Tipo', 'Todos', _tipo, _tipos, (v) => setState(() => _tipo = v)),
        lista<_Situacao>('Situação', 'Todas', _situacao,
            {for (final s in _Situacao.values) s: s.rotulo}, (v) => setState(() => _situacao = v)),
        if (_empresa != null || _tipo != null || _situacao != null)
          TextButton.icon(
            style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: () => setState(() {
              _empresa = null;
              _tipo = null;
              _situacao = null;
            }),
            icon: const Icon(Icons.filter_alt_off),
            label: const Text('Limpar filtros'),
          ),
      ]),
    );
  }

  Widget _contadores(List<_Par> recorte) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          for (final s in _Situacao.values)
            Semantics(
              selected: _situacao == s,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  backgroundColor: s.fundo,
                  foregroundColor: GridColors.textSecondary,
                  side: BorderSide(color: s.cor, width: _situacao == s ? 3 : 1),
                ),
                onPressed: () => setState(() => _situacao = _situacao == s ? null : s),
                icon: Icon(s.icone, color: s.cor),
                label: Text('${s.plural}: ${recorte.where((p) => p.situacao == s).length}'),
              ),
            ),
        ]),
      );

  Widget _cartao(int empresa, List<_Par> pares, bool filtrado, double largura) {
    final aberta = filtrado || _empresa == empresa || _abertas.contains(empresa);
    final resumo = [
      for (final s in _Situacao.values)
        if (pares.any((p) => p.situacao == s))
          '${pares.where((p) => p.situacao == s).length} ${s.rotulo.toLowerCase()}'
    ].join(' · ');
    return Card(
      key: ValueKey('empresa-$empresa'),
      color: GridColors.card,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ListTile(
          title: Text(_nomes[empresa]!, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(resumo),
          trailing: Icon(aberta ? Icons.expand_less : Icons.expand_more,
              semanticLabel: aberta ? 'Aberto' : 'Fechado'),
          onTap: () => setState(() => _abertas.remove(empresa) ? null : _abertas.add(empresa)),
        ),
        if (aberta)
          for (final p in pares) _linha(p, largura),
      ]),
    );
  }

  Widget _linha(_Par p, double largura) {
    final c = p.certidao;
    final s = p.situacao;
    final dados = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Text(p.tipoNome, style: const TextStyle(fontWeight: FontWeight.bold)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: s.fundo,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(s.icone, size: 16, color: s.cor),
            const SizedBox(width: 4),
            Text(s.rotulo),
          ]),
        ),
        if (c?['dataVencimento'] != null) Text('Vence ${_data(c!['dataVencimento'])}'),
        if (c?['resultado'] != null) Text(_resultados[c!['resultado']] ?? '${c['resultado']}'),
        if (c?['numero'] != null) Text('Nº ${c!['numero']}'),
      ]),
      if (c?['observacao'] != null) Text('${c!['observacao']}', maxLines: 2, overflow: TextOverflow.ellipsis),
    ]);
    final acoes = Wrap(spacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
      Semantics(
        label: 'Enviar certidão ${p.tipoNome} de ${p.nome}',
        child: TextButton.icon(
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: () => _abrirEnvio(empresa: p.empresa, tipo: p.tipo),
          icon: const Icon(Icons.upload_file),
          label: Text(c == null ? 'Enviar' : 'Enviar nova'),
        ),
      ),
      if (c != null) ...[
        if (c['temArquivo'] == true)
          IconButton(
              tooltip: 'Baixar PDF, ${p.tipoNome}, ${p.nome}',
              onPressed: () => _baixar(p),
              icon: const Icon(Icons.download)),
        IconButton(
            tooltip: 'Detalhes, ${p.tipoNome}, ${p.nome}',
            onPressed: () => _detalhes(p),
            icon: const Icon(Icons.info_outline)),
        IconButton(
            tooltip: 'Excluir, ${p.tipoNome}, ${p.nome}',
            onPressed: () => _excluir(p),
            icon: const Icon(Icons.delete_outline)),
      ],
    ]);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
      child: largura >= 1100
          ? Row(children: [Expanded(child: dados), acoes])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [dados, acoes]),
    );
  }

  Widget _texto(String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
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

/// Lista de empresas com busca. Devolve o id (0 = a própria empresa; -1 = todas).
class _BuscaEmpresa extends StatefulWidget {
  final Map<int, String> nomes;
  final bool todas;
  const _BuscaEmpresa({required this.nomes, required this.todas});

  @override
  State<_BuscaEmpresa> createState() => _BuscaEmpresaState();
}

class _BuscaEmpresaState extends State<_BuscaEmpresa> {
  String _termo = '';

  @override
  Widget build(BuildContext context) {
    final achadas = widget.nomes.entries
        .where((e) => e.value.toLowerCase().contains(_termo.toLowerCase()))
        .toList();
    return AlertDialog(
      title: const Text('Escolher empresa'),
      content: SizedBox(
        width: 420,
        height: 420,
        child: Column(children: [
          TextField(
            autofocus: true,
            decoration:
                const InputDecoration(labelText: 'Pesquisar empresa', prefixIcon: Icon(Icons.search)),
            onChanged: (v) => setState(() => _termo = v),
          ),
          if (widget.todas)
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
  }
}

class _DialogoEnvio extends StatefulWidget {
  final Map<int, String> nomes;
  final Map<String, String> tipos;
  final List<_Par> pares;
  final int? empresa;
  final String? tipo;
  final Future<ArquivoPdf?> Function() escolher;
  final Future<String?> Function(Map<String, String> campos, ArquivoPdf arquivo) registrar;

  const _DialogoEnvio(
      {required this.nomes,
      required this.tipos,
      required this.pares,
      required this.empresa,
      required this.tipo,
      required this.escolher,
      required this.registrar});

  @override
  State<_DialogoEnvio> createState() => _DialogoEnvioState();
}

class _DialogoEnvioState extends State<_DialogoEnvio> {
  late int? _empresa = widget.empresa;
  late String? _tipo = widget.tipo;
  String? _resultado;
  DateTime? _emissao;
  DateTime? _vencimento;
  ArquivoPdf? _arquivo;
  final _numero = TextEditingController();
  final _observacao = TextEditingController();
  String? _erro;
  bool _enviando = false;

  @override
  void dispose() {
    _numero.dispose();
    _observacao.dispose();
    super.dispose();
  }

  String? get _aviso {
    final v = _vencimento;
    if (v == null) return null;
    final atual = widget.pares
        .where((p) => p.empresa == _empresa && p.tipo == _tipo)
        .firstOrNull
        ?.certidao?['dataVencimento'];
    if (atual != null && v.isBefore(DateTime.parse('$atual'))) {
      return 'Este envio não substituirá a certidão atual, que vale até ${_data(atual)}.';
    }
    return v.isBefore(DateUtils.dateOnly(DateTime.now())) ? 'Esta certidão já está vencida.' : null;
  }

  Future<void> _salvar() async {
    final arquivo = _arquivo;
    if (_empresa == null || _tipo == null || _resultado == null || _emissao == null || _vencimento == null ||
        arquivo == null) {
      setState(() => _erro = 'Preencha os campos com * e selecione o PDF.');
      return;
    }
    if (_vencimento!.isBefore(_emissao!)) {
      setState(() => _erro = 'O vencimento não pode ser anterior à emissão.');
      return;
    }
    if (!arquivo.nome.toLowerCase().endsWith('.pdf') || arquivo.bytes.length > 10 * 1024 * 1024) {
      setState(() => _erro = 'Envie a certidão em PDF de até 10 MB.');
      return;
    }
    setState(() {
      _enviando = true;
      _erro = null;
    });
    final iso = DateFormat('yyyy-MM-dd');
    final erro = await widget.registrar({
      if (_empresa != 0) 'titularId': '$_empresa',
      'tipo': _tipo!,
      'resultado': _resultado!,
      'dataEmissao': iso.format(_emissao!),
      'dataVencimento': iso.format(_vencimento!),
      if (_numero.text.trim().isNotEmpty) 'numero': _numero.text.trim(),
      if (_observacao.text.trim().isNotEmpty) 'observacao': _observacao.text.trim(),
    }, arquivo);
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

  Widget _botaoData(String rotulo, DateTime? valor, DateTime ultimo, ValueChanged<DateTime> escolhido) =>
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        onPressed: _enviando
            ? null
            : () async {
                final d = await showDatePicker(
                    context: context,
                    initialDate: valor ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: ultimo);
                if (d != null && mounted) setState(() => escolhido(d));
              },
        icon: const Icon(Icons.event),
        label: Text(valor == null ? '$rotulo*' : '$rotulo: ${DateFormat('dd/MM/yyyy').format(valor)}'),
      );

  Widget _lista(String rotulo, String? valor, Map<String, String> opcoes, ValueChanged<String?> mudar) =>
      DropdownButtonFormField<String>(
        initialValue: valor,
        isExpanded: true,
        decoration: InputDecoration(labelText: rotulo),
        items: [
          for (final o in opcoes.entries)
            DropdownMenuItem(value: o.key, child: Text(o.value, overflow: TextOverflow.ellipsis)),
        ],
        onChanged: _enviando ? null : mudar,
      );

  @override
  Widget build(BuildContext context) {
    final aviso = _aviso;
    return PopScope(
      canPop: !_enviando,
      child: AlertDialog(
        insetPadding: const EdgeInsets.all(12),
        title: const Text('Enviar certidão'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('Cada envio cria um novo registro. Vale como atual o de maior validade.'),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                onPressed: _enviando
                    ? null
                    : () async {
                        final id = await showDialog<int>(
                            context: context,
                            builder: (_) => _BuscaEmpresa(nomes: widget.nomes, todas: false));
                        if (id != null && mounted) setState(() => _empresa = id);
                      },
                icon: const Icon(Icons.business),
                label: Text(widget.nomes[_empresa] ?? 'Empresa*', overflow: TextOverflow.ellipsis),
              ),
              _lista('Tipo*', _tipo, widget.tipos, (v) => setState(() => _tipo = v)),
              _lista('Resultado*', _resultado, _resultados, (v) => setState(() => _resultado = v)),
              TextField(
                  controller: _numero,
                  enabled: !_enviando,
                  maxLength: 100,
                  decoration: const InputDecoration(labelText: 'Número')),
              _botaoData('Data de emissão', _emissao, DateTime.now(), (d) => _emissao = d),
              const SizedBox(height: 8),
              _botaoData('Data de vencimento', _vencimento, DateTime(2100), (d) => _vencimento = d),
              TextField(
                  controller: _observacao,
                  enabled: !_enviando,
                  maxLength: 500,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Observação')),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                onPressed: _enviando
                    ? null
                    : () async {
                        try {
                          final a = await widget.escolher();
                          if (a != null && mounted) setState(() => _arquivo = a);
                        } catch (e, st) {
                          AppLogger.i.error('Certidões: falha ao ler o arquivo (${e.runtimeType})', st);
                          if (mounted) setState(() => _erro = 'Não foi possível ler o arquivo.');
                        }
                      },
                icon: const Icon(Icons.picture_as_pdf),
                label: Text(_arquivo?.nome ?? 'Selecionar PDF* (até 10 MB)', overflow: TextOverflow.ellipsis),
              ),
              for (final (icone, cor, texto) in [
                if (aviso != null) (Icons.warning, GridColors.warningDark, aviso),
                if (_erro != null) (Icons.error, GridColors.errorDark, _erro!),
              ])
                Semantics(
                  liveRegion: true,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(children: [
                      Icon(icone, color: cor),
                      const SizedBox(width: 8),
                      Expanded(child: Text(texto)),
                    ]),
                  ),
                ),
              if (_enviando) const LinearProgressIndicator(semanticsLabel: 'Enviando'),
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
              onPressed: _enviando ? null : _salvar,
              child: const Text('Salvar')),
        ],
      ),
    );
  }
}
