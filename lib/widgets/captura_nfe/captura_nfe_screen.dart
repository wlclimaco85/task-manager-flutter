import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

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

const _semAcesso = 'Você não tem acesso à Captura de NF-e. Solicite ao administrador.';

const _tipos = {
  'NOTA': ('Nota', Icons.description, GridColors.success, GridColors.successLight),
  'RESUMO': ('Resumo', Icons.short_text, GridColors.warningDark, GridColors.suggestionMedium),
  'EVENTO': ('Evento', Icons.bolt, GridColors.info, GridColors.card),
  'ERRO': ('Ilegível', Icons.error, GridColors.errorDark, GridColors.errorLight),
};

String _dataHora(Object? iso) => DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse('$iso'));

String _data(Object? iso) => DateFormat('dd/MM/yyyy').format(DateTime.parse('$iso'));

String _cnpj(String v) => v.length != 14
    ? v
    : '${v.substring(0, 2)}.${v.substring(2, 5)}.${v.substring(5, 8)}/${v.substring(8, 12)}-${v.substring(12)}';

/// 0 representa a própria empresa nos filtros (o servidor usa o mesmo critério).
int _id(Object? parceiroId) => (parceiroId as int?) ?? 0;

/// Liga a busca automática de NF-e por CNPJ e mostra o que a SEFAZ já entregou.
class CapturaNfeScreen extends StatefulWidget {
  /// true quando a tela é aberta pelo menu do celular.
  final bool cabecalhoMobile;

  /// Substituíveis em teste.
  final Future<http.Response> Function(String url)? buscar;
  final Future<http.Response> Function(String url, String corpo)? enviar;
  final Future<void> Function(String nome, Uint8List bytes)? salvar;

  const CapturaNfeScreen(
      {super.key, this.cabecalhoMobile = false, this.buscar, this.enviar, this.salvar});

  @override
  State<CapturaNfeScreen> createState() => _CapturaNfeScreenState();
}

class _CapturaNfeScreenState extends State<CapturaNfeScreen> with SingleTickerProviderStateMixin {
  late final _abas = TabController(length: 2, vsync: this);

  List<_Json>? _cnpjs;
  String? _erroCnpjs;
  String _pesquisa = '';
  final Set<int> _salvando = {};

  List<_Json>? _documentos;
  String? _erroDocumentos;
  int? _filtroEmpresa;
  String? _filtroTipo;
  int _pagina = 0;
  bool _temMais = false;
  bool _carregandoDocumentos = false;
  final Set<int> _baixando = {};
  int _pedido = 0;

  @override
  void initState() {
    super.initState();
    _carregarCnpjs();
    _carregarDocumentos();
  }

  @override
  void dispose() {
    _abas.dispose();
    super.dispose();
  }

  String _url(String caminho, [Map<String, String> extras = const {}]) =>
      Uri.parse('${ApiLinks.baseUrl}/api/captura-dfe$caminho').replace(queryParameters: {
        'skipTenantParceiro': 'true',
        if (TenantContext.empresaId != null) 'empresaId': '${TenantContext.empresaId}',
        ...extras,
      }).toString();

  Future<http.Response> _get(String url) => (widget.buscar ?? TenantContext.get)(url);

  Future<void> _carregarCnpjs() async {
    try {
      final r = await _get(_url(''));
      if (!mounted) return;
      setState(() {
        if (r.statusCode == 200) {
          _cnpjs = ((jsonDecode(utf8.decode(r.bodyBytes)) as _Json)['cnpjs'] as List).cast<_Json>();
          _erroCnpjs = null;
        } else {
          _cnpjs = null;
          _erroCnpjs = r.statusCode == 403 ? _semAcesso : 'Não foi possível carregar os dados.';
        }
      });
    } catch (e, st) {
      AppLogger.i.error('Captura de NF-e: falha ao carregar os CNPJs ($e)', st);
      if (!mounted) return;
      setState(() {
        _cnpjs = null;
        _erroCnpjs = 'Não foi possível carregar os dados.';
      });
    }
  }

  /// [mais] acrescenta a página seguinte; sem ele a lista recomeça.
  Future<void> _carregarDocumentos({bool mais = false}) async {
    final pedido = ++_pedido;
    final pagina = mais ? _pagina + 1 : 0;
    setState(() {
      _carregandoDocumentos = true;
      _erroDocumentos = null;
      if (!mais) _documentos = null;
    });
    String? erro;
    try {
      final r = await _get(_url('/documentos', {
        'pagina': '$pagina',
        if (_filtroEmpresa != null) 'parceiroId': '$_filtroEmpresa',
        if (_filtroTipo != null) 'tipo': _filtroTipo!,
      }));
      if (!mounted || pedido != _pedido) return; // resposta de filtro antigo
      if (r.statusCode == 200) {
        final corpo = jsonDecode(utf8.decode(r.bodyBytes)) as _Json;
        final itens = (corpo['itens'] as List).cast<_Json>();
        _documentos = mais ? [...?_documentos, ...itens] : itens;
        _temMais = corpo['temMais'] == true;
        _pagina = pagina;
      } else {
        erro = r.statusCode == 403 ? _semAcesso : 'Não foi possível carregar os dados.';
      }
    } catch (e, st) {
      AppLogger.i.error('Captura de NF-e: falha ao carregar os documentos ($e)', st);
      if (!mounted || pedido != _pedido) return;
      erro = 'Não foi possível carregar os dados.';
    }
    setState(() {
      _erroDocumentos = erro;
      _carregandoDocumentos = false;
    });
  }

  void _filtrar(VoidCallback mudanca) {
    mudanca();
    _carregarDocumentos();
  }

  void _avisar(String texto) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));

  // ── Ligar e desligar ─────────────────────────────────────────────────────

  Future<void> _alternar(_Json cnpj, bool ativo) async {
    if (ativo) {
      final confirmou = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ativar captura de NF-e?'),
          content: SingleChildScrollView(
            child: Text('${cnpj['nome']}\n\n'
                'O sistema passa a consultar a SEFAZ automaticamente e apenas guarda o XML recebido.\n\n'
                'Se outro programa consultar o mesmo CNPJ com este certificado, a SEFAZ pode retornar '
                'erro 656 (consumo indevido).'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ativar captura')),
          ],
        ),
      );
      if (confirmou != true || !mounted) return;
    }
    final id = _id(cnpj['parceiroId']);
    setState(() => _salvando.add(id));
    var mensagem = 'Não foi possível salvar. Tente novamente.';
    var recarregar = false;
    try {
      final url = _url('/config');
      // parceiroId nulo significa a própria empresa: o corpo não pode passar pelo TenantContext.
      final corpo = jsonEncode({'parceiroId': cnpj['parceiroId'], 'ativo': ativo});
      final r = widget.enviar != null
          ? await widget.enviar!(url, corpo)
          : await http
              .put(Uri.parse(url), headers: TenantContext.jsonHeaders, body: corpo)
              .timeout(const Duration(minutes: 1));
      if (r.statusCode == 401) SessionExpiredHandler.handle();
      if (r.statusCode == 200) {
        mensagem = ativo ? 'Captura ativada.' : 'Captura desativada.';
        recarregar = true;
      } else if (r.statusCode == 403) {
        mensagem = 'Você não tem permissão para alterar a captura.';
      } else if (r.statusCode == 400 || r.statusCode == 404) {
        final json = jsonDecode(utf8.decode(r.bodyBytes));
        mensagem = '${json['message'] ?? json['mensagem'] ?? mensagem}';
        recarregar = r.statusCode == 404;
      } else {
        AppLogger.i.warn('Captura de NF-e: alteração recusada (${r.statusCode})');
      }
    } catch (e, st) {
      AppLogger.i.error('Captura de NF-e: falha ao alterar a captura ($e)', st);
    }
    if (!mounted) return;
    _avisar(mensagem);
    if (recarregar) await _carregarCnpjs();
    if (mounted) setState(() => _salvando.remove(id));
  }

  // ── Download ─────────────────────────────────────────────────────────────

  Future<void> _baixar(_Json d) async {
    final id = d['id'] as int;
    setState(() => _baixando.add(id));
    try {
      final r = await _get(_url('/documentos/$id/xml'));
      if (r.statusCode != 200) {
        AppLogger.i.warn('Captura de NF-e: download do documento $id recusado (${r.statusCode})');
        if (mounted) _avisar('Não foi possível baixar o XML.');
        return;
      }
      final nome = '${d['chave'] ?? 'nsu-${d['nsu']}'}-${'${d['tipo']}'.toLowerCase()}.xml';
      if (widget.salvar != null) {
        await widget.salvar!(nome, r.bodyBytes);
      } else {
        final caminho =
            await FileSaver.instance.saveFile(name: nome, bytes: r.bodyBytes, mimeType: MimeType.xml);
        // No celular o arquivo é compartilhado: a pasta do app não é acessível ao usuário.
        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
          // ignore: deprecated_member_use
          await Share.shareXFiles([XFile(caminho, name: nome)], sharePositionOrigin: ui.Rect.largest);
          return;
        }
        if (mounted) _avisar(kIsWeb ? 'XML gerado.' : 'XML salvo em $caminho');
        return;
      }
      if (mounted) _avisar('XML gerado.');
    } catch (e, st) {
      AppLogger.i.error('Captura de NF-e: falha ao baixar o documento $id ($e)', st);
      if (mounted) _avisar('Não foi possível baixar o XML.');
    } finally {
      if (mounted) setState(() => _baixando.remove(id));
    }
  }

  // ── Tela ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    const titulo = 'Captura de NF-e';
    final atualizar = IconButton(
      tooltip: 'Atualizar',
      color: GridColors.textPrimary,
      onPressed: () {
        _carregarCnpjs();
        _carregarDocumentos();
      },
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
      body: LayoutBuilder(builder: (context, limites) {
        final largura = limites.maxWidth;
        final margem = largura < 700 ? 12.0 : 20.0;
        return Column(children: [
          Padding(
            padding: EdgeInsets.fromLTRB(margem, margem, margem, 0),
            child: _faixa(Icons.info, GridColors.info, GridColors.card,
                'Somente NF-e. O sistema só busca e guarda o XML: não envia ciência, não importa a nota e não altera estoque nem financeiro.'),
          ),
          Material(
            color: GridColors.card,
            child: TabBar(
              controller: _abas,
              labelColor: GridColors.textSecondary,
              unselectedLabelColor: GridColors.textMuted,
              tabs: const [Tab(text: 'Captura por CNPJ'), Tab(text: 'Documentos capturados')],
            ),
          ),
          Expanded(
            child: TabBarView(controller: _abas, children: [
              _abaCnpjs(largura, margem),
              _abaDocumentos(largura, margem),
            ]),
          ),
        ]);
      }),
    );
  }

  Widget _lista(double margem, List<Widget> topo, int quantidade, Widget Function(int) item,
          [List<Widget> rodape = const []]) =>
      CustomScrollView(slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(margem, margem, margem, 0),
          sliver: SliverList.list(children: topo),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: margem),
          sliver: SliverList.builder(itemCount: quantidade, itemBuilder: (_, i) => item(i)),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(margem, 0, margem, margem),
          sliver: SliverList.list(children: rodape),
        ),
      ]);

  List<Widget> _falha(String erro, VoidCallback repetir) => [
        _faixa(Icons.error, GridColors.errorDark, GridColors.errorLight, erro),
        if (erro != _semAcesso)
          Center(
            child: FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                onPressed: repetir,
                child: const Text('Tentar novamente')),
          ),
      ];

  Widget get _carregandoWidget => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator(semanticsLabel: 'Carregando')),
      );

  Widget _abaCnpjs(double largura, double margem) {
    final todos = _cnpjs;
    final visiveis = (todos ?? const <_Json>[])
        .where((c) => '${c['nome']}'.toLowerCase().contains(_pesquisa.toLowerCase()))
        .toList();
    return _lista(margem, [
      const Text('Os CNPJs ativos são consultados automaticamente: a cada 10 min enquanto houver '
          'documentos pendentes. Sem pendências, o sistema aguarda 1 h, como exige a SEFAZ.'),
      const SizedBox(height: 8),
      _faixa(Icons.warning, GridColors.warningDark, GridColors.suggestionMedium,
          'Se outro programa consultar o mesmo CNPJ com este certificado, a SEFAZ pode retornar erro 656 (consumo indevido).'),
      if (_erroCnpjs != null)
        ..._falha(_erroCnpjs!, _carregarCnpjs)
      else if (todos == null)
        _carregandoWidget
      else if (todos.isEmpty)
        _texto('Nenhum CNPJ disponível para captura. Cadastre o certificado digital.')
      else ...[
        if (todos.every((c) => c['temCertificado'] != true))
          _texto('Nenhum certificado digital cadastrado. Cadastre o certificado para ativar a captura.'),
        TextField(
          decoration: const InputDecoration(
              labelText: 'Pesquisar empresa',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder()),
          onChanged: (v) => setState(() => _pesquisa = v),
        ),
        const SizedBox(height: 12),
      ],
    ], _erroCnpjs != null ? 0 : visiveis.length, (i) => _cartaoCnpj(visiveis[i], largura));
  }

  Widget _cartaoCnpj(_Json c, double largura) {
    final id = _id(c['parceiroId']);
    final ativo = c['ativo'] == true;
    final validade = c['certificadoValidade'];
    final hoje = DateUtils.dateOnly(DateTime.now());
    final vencido = validade != null && DateTime.parse('$validade').isBefore(hoje);
    final semCertificado = c['temCertificado'] != true;
    final (icone, cor, fundo, texto) = semCertificado
        ? (Icons.help_outline, GridColors.neutral, GridColors.surfaceMuted, 'Sem certificado')
        : vencido
            ? (Icons.error, GridColors.errorDark, GridColors.errorLight,
                'Certificado vencido em ${_data(validade)}')
            : (Icons.verified, GridColors.success, GridColors.successLight,
                validade == null ? 'Validade não informada' : 'Certificado válido até ${_data(validade)}');
    final bloqueado = !ativo && (semCertificado || vencido);

    final dados = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${c['nome']}', style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      _selo(icone, cor, fundo, texto),
      const SizedBox(height: 4),
      Text(c['ultimaExecucao'] == null
          ? 'Ainda não executada'
          : 'Última execução: ${_dataHora(c['ultimaExecucao'])}'),
      SelectableText('Último resultado: ${c['ultimoResultado'] ?? 'Sem resultado'}'),
      if (bloqueado)
        const Text('Cadastre um certificado válido para ativar a captura.',
            style: TextStyle(color: GridColors.textMuted)),
    ]);
    final acoes = Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
      Semantics(
        label: 'Captura ativa de ${c['nome']}',
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Switch(
            value: ativo,
            onChanged: bloqueado || _salvando.contains(id) ? null : (v) => _alternar(c, v),
          ),
          Text(ativo ? 'Captura ativa' : 'Captura inativa'),
        ]),
      ),
      if (_salvando.contains(id))
        const SizedBox(
            width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, semanticsLabel: 'Salvando')),
      TextButton(
        style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
        onPressed: () {
          _filtrar(() => _filtroEmpresa = id);
          _abas.animateTo(1);
        },
        child: const Text('Ver documentos'),
      ),
    ]);
    return _cartao(largura, dados, acoes, ValueKey('cnpj-$id'));
  }

  Widget _abaDocumentos(double largura, double margem) {
    final nomes = {for (final c in _cnpjs ?? const <_Json>[]) _id(c['parceiroId']): '${c['nome']}'};
    final campo = largura < 700 ? double.infinity : 280.0;
    final filtrado = _filtroEmpresa != null || _filtroTipo != null;
    final documentos = _documentos ?? const <_Json>[];

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

    return _lista(
      margem,
      [
        Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
          lista<int>('Empresa', 'Todas', _filtroEmpresa, nomes, (v) => _filtrar(() => _filtroEmpresa = v)),
          lista<String>('Tipo', 'Todos', _filtroTipo, {for (final t in _tipos.entries) t.key: t.value.$1},
              (v) => _filtrar(() => _filtroTipo = v)),
          if (filtrado)
            TextButton.icon(
              style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: () => _filtrar(() {
                _filtroEmpresa = null;
                _filtroTipo = null;
              }),
              icon: const Icon(Icons.filter_alt_off),
              label: const Text('Limpar filtros'),
            ),
        ]),
        const SizedBox(height: 12),
        if (_documentos == null && _erroDocumentos != null)
          ..._falha(_erroDocumentos!, _carregarDocumentos)
        else if (_documentos == null)
          _carregandoWidget
        else if (documentos.isEmpty)
          _texto(filtrado ? 'Nenhum documento corresponde aos filtros.' : 'Nenhum documento capturado ainda.'),
      ],
      documentos.length,
      (i) => _cartaoDocumento(documentos[i], nomes, largura),
      [
        // Falha ao carregar mais mantém o que já está na tela.
        if (_documentos != null && _erroDocumentos != null)
          ..._falha(_erroDocumentos!, () => _carregarDocumentos(mais: true))
        else if (_documentos != null && _temMais)
          Center(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: _carregandoDocumentos ? null : () => _carregarDocumentos(mais: true),
              child: Text(_carregandoDocumentos ? 'Carregando...' : 'Carregar mais'),
            ),
          ),
      ],
    );
  }

  Widget _cartaoDocumento(_Json d, Map<int, String> nomes, double largura) {
    final tipo = _tipos[d['tipo']] ?? _tipos['EVENTO']!;
    final id = d['id'] as int;
    final resumo = d['tipo'] == 'RESUMO';
    final emitente = '${d['emitenteNome'] ?? 'Emitente não informado'}';
    final dados = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _selo(tipo.$2, tipo.$3, tipo.$4, tipo.$1),
      const SizedBox(height: 4),
      Text(emitente, style: const TextStyle(fontWeight: FontWeight.bold)),
      if (d['emitenteCnpj'] != null) Text(_cnpj('${d['emitenteCnpj']}')),
      Text('Empresa: ${nomes[_id(d['parceiroId'])] ?? '—'}'),
      Wrap(spacing: 12, children: [
        Text(d['valor'] == null
            ? 'Valor: —'
            : 'Valor: ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(d['valor'])}'),
        if (d['dhEmissao'] != null) Text('Emissão: ${_data(d['dhEmissao'])}'),
        Text('Capturado em ${_dataHora(d['capturadoEm'])}'),
        Text('NSU ${d['nsu']}'),
      ]),
      if (d['chave'] != null) SelectableText('Chave: ${d['chave']}'),
      if (resumo)
        const Text(
            'A SEFAZ enviou apenas o resumo. Para obter o XML completo, faça a manifestação na tela Manifestação do Destinatário.',
            style: TextStyle(color: GridColors.textMuted)),
    ]);
    final acao = Semantics(
      label: 'Baixar XML de $emitente',
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
        onPressed: _baixando.contains(id) ? null : () => _baixar(d),
        icon: _baixando.contains(id)
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.download),
        label: Text(resumo ? 'Baixar XML do resumo' : 'Baixar XML'),
      ),
    );
    return _cartao(largura, dados, acao, ValueKey('doc-$id'));
  }

  Widget _cartao(double largura, Widget dados, Widget acoes, Key chave) => Card(
        key: chave,
        color: GridColors.card,
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: largura >= 1100
              ? Row(children: [Expanded(child: dados), acoes])
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  dados,
                  const SizedBox(height: 8),
                  acoes,
                ]),
        ),
      );

  Widget _selo(IconData icone, Color cor, Color fundo, String texto) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: fundo,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icone, size: 16, color: cor),
          const SizedBox(width: 4),
          Flexible(child: Text(texto)),
        ]),
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
