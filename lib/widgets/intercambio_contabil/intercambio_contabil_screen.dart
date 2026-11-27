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

enum _Secao {
  plano('Plano de contas', 'plano-contas', 'codigo;descricao;tipo;natureza;codigo_pai;ativo',
      '1;Ativo;ATIVO;DEVEDORA;;sim\r\n1.01;Caixa;ATIVO;DEVEDORA;1;sim'),
  lancamentos('Lançamentos', 'lancamentos', 'data;codigo_conta;natureza;valor;historico',
      '05/11/2026;1.01;DEBITO;150,00;Exemplo de recebimento');

  final String rotulo;
  final String caminho;
  final String colunas;
  final String exemplo;
  const _Secao(this.rotulo, this.caminho, this.colunas, this.exemplo);
}

/// Arquivo escolhido pelo usuário.
class ArquivoCsv {
  final String nome;
  final Uint8List bytes;
  const ArquivoCsv(this.nome, this.bytes);
}

/// Importação e exportação de plano de contas e lançamentos em CSV genérico.
class IntercambioContabilScreen extends StatefulWidget {
  /// true quando a tela é aberta pelo menu do celular.
  final bool cabecalhoMobile;

  /// Substituíveis em teste.
  final Future<http.Response> Function(String url)? buscar;
  final Future<http.Response> Function(String url, String corpo)? enviar;
  final Future<ArquivoCsv?> Function()? escolherArquivo;
  final Future<void> Function(String nome, Uint8List bytes)? salvar;

  const IntercambioContabilScreen(
      {super.key,
      this.cabecalhoMobile = false,
      this.buscar,
      this.enviar,
      this.escolherArquivo,
      this.salvar});

  @override
  State<IntercambioContabilScreen> createState() => _IntercambioContabilScreenState();
}

class _IntercambioContabilScreenState extends State<IntercambioContabilScreen> {
  _Secao _secao = _Secao.plano;
  DateTimeRange? _periodo;
  String? _nomeArquivo;
  String? _conteudo;
  _Json? _previa;
  String? _erro;
  String? _sucesso;
  String? _ocupado;
  bool _gravando = false;

  String _url([Map<String, String> extras = const {}]) =>
      Uri.parse('${ApiLinks.baseUrl}/api/intercambio-contabil/${_secao.caminho}').replace(queryParameters: {
        'skipTenantParceiro': 'true',
        if (TenantContext.empresaId != null) 'empresaId': '${TenantContext.empresaId}',
        ...extras,
      }).toString();

  void _limparImportacao() {
    _nomeArquivo = null;
    _conteudo = null;
    _previa = null;
    _erro = null;
    _sucesso = null;
  }

  static String _mensagem(http.Response r, String padrao) {
    if (r.statusCode == 403) return 'Você não tem acesso a esta função. Solicite ao administrador.';
    try {
      final corpo = jsonDecode(utf8.decode(r.bodyBytes));
      final texto = corpo['message'] ?? corpo['mensagem'] ?? corpo['response']?['message'];
      if (r.statusCode == 400 && texto != null) return '$texto';
    } catch (_) {
      // corpo sem JSON: fica a mensagem padrão
    }
    return padrao;
  }

  // ── Arquivos ─────────────────────────────────────────────────────────────

  /// No celular o arquivo é compartilhado (a pasta do app não é acessível ao usuário).
  Future<void> _entregar(String nome, Uint8List bytes) async {
    if (widget.salvar != null) {
      await widget.salvar!(nome, bytes);
      return;
    }
    final caminho =
        await FileSaver.instance.saveFile(name: nome, bytes: bytes, mimeType: MimeType.csv);
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(caminho, name: nome)], sharePositionOrigin: ui.Rect.largest);
    } else if (mounted) {
      _avisar(kIsWeb ? 'CSV gerado.' : 'CSV salvo em $caminho');
    }
  }

  void _avisar(String texto) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));

  Future<void> _exportar() async {
    final iso = DateFormat('yyyy-MM-dd');
    final url = _url(_secao == _Secao.lancamentos
        ? {'inicio': iso.format(_periodo!.start), 'fim': iso.format(_periodo!.end)}
        : const {});
    final nome = _secao == _Secao.plano ? 'plano_de_contas.csv' : 'lancamentos.csv';
    setState(() {
      _ocupado = 'Gerando CSV';
      _erro = null;
    });
    try {
      final r = await (widget.buscar ?? TenantContext.get)(url);
      if (!mounted) return;
      if (r.statusCode != 200) {
        setState(() => _erro = _mensagem(r, 'Não foi possível gerar o CSV.'));
        return;
      }
      await _entregar(nome, r.bodyBytes);
    } catch (e, st) {
      AppLogger.i.error('Intercâmbio contábil: falha ao exportar ($e)', st);
      if (mounted) setState(() => _erro = 'Não foi possível gerar o CSV.');
    } finally {
      if (mounted) setState(() => _ocupado = null);
    }
  }

  Future<void> _baixarModelo() async {
    try {
      await _entregar('modelo_${_secao.caminho}.csv',
          Uint8List.fromList(utf8.encode('﻿${_secao.colunas}\r\n${_secao.exemplo}\r\n')));
    } catch (e, st) {
      AppLogger.i.error('Intercâmbio contábil: falha ao gerar modelo ($e)', st);
      if (mounted) setState(() => _erro = 'Não foi possível gerar o modelo.');
    }
  }

  static Future<ArquivoCsv?> _escolherNoAparelho() async {
    final r = await FilePicker.pickFiles(
        type: FileType.custom, allowedExtensions: const ['csv'], withData: true);
    final arquivo = r?.files.firstOrNull;
    if (arquivo?.bytes == null) return null;
    return ArquivoCsv(arquivo!.name, arquivo.bytes!);
  }

  /// O Excel em português costuma salvar CSV em Windows-1252, não em UTF-8.
  static String decodificar(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return latin1.decode(bytes);
    }
  }

  Future<void> _escolher() async {
    try {
      final arquivo = await (widget.escolherArquivo ?? _escolherNoAparelho)();
      if (arquivo == null || !mounted) return;
      setState(() {
        _limparImportacao();
        _nomeArquivo = arquivo.nome;
        _conteudo = decodificar(arquivo.bytes);
      });
      await _enviar(confirmar: false);
    } catch (e, st) {
      AppLogger.i.error('Intercâmbio contábil: falha ao ler o arquivo (${e.runtimeType})', st);
      if (mounted) setState(() => _erro = 'Não foi possível ler o arquivo.');
    }
  }

  // ── Prévia e confirmação ─────────────────────────────────────────────────

  Future<void> _enviar({required bool confirmar}) async {
    final conteudo = _conteudo;
    if (conteudo == null) return;
    setState(() {
      _ocupado = confirmar ? 'Importando' : 'Analisando arquivo. Nada será gravado.';
      _gravando = confirmar;
      _erro = null;
    });
    try {
      final url = _url({'confirmar': '$confirmar'});
      final corpo = jsonEncode({'conteudo': conteudo});
      final r = widget.enviar != null
          ? await widget.enviar!(url, corpo)
          : await http
              .post(Uri.parse(url), headers: TenantContext.jsonHeaders, body: corpo)
              .timeout(const Duration(minutes: 2));
      // Este POST não passa pelo TenantContext.post (que alteraria o corpo): o 401 é tratado aqui.
      if (r.statusCode == 401) SessionExpiredHandler.handle();
      if (!mounted) return;
      if (r.statusCode != 200) {
        setState(() {
          _previa = null;
          _erro = confirmar && r.statusCode >= 500
              ? 'Não foi possível confirmar o resultado. Verifique os dados antes de importar novamente.'
              : _mensagem(r, 'Não foi possível analisar o arquivo.');
        });
        return;
      }
      final resultado = jsonDecode(utf8.decode(r.bodyBytes)) as _Json;
      setState(() {
        if (resultado['gravado'] == true) {
          _limparImportacao();
          _sucesso = 'Importação concluída: ${resultado['novas']} novas, '
              '${resultado['atualizadas']} atualizadas, ${resultado['ignoradas']} ignoradas.';
        } else {
          _previa = resultado;
          if (confirmar) _erro = 'Nenhuma linha foi gravada.';
        }
      });
    } catch (e, st) {
      AppLogger.i.error('Intercâmbio contábil: falha no envio, confirmar=$confirmar (${e.runtimeType})', st);
      if (!mounted) return;
      setState(() {
        _previa = null;
        _erro = confirmar
            ? 'Não foi possível confirmar o resultado. Verifique os dados antes de importar novamente.'
            : 'Não foi possível analisar o arquivo.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _ocupado = null;
          _gravando = false;
        });
      }
    }
  }

  // ── Tela ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    const titulo = 'Importar e Exportar Contábil';
    return PopScope(
      canPop: !_gravando,
      child: Scaffold(
        backgroundColor: GridColors.pageBackground,
        // No celular usa o cabeçalho padrão do app (usuário, avisos e sair).
        appBar: widget.cabecalhoMobile
            ? UserBannerAppBar(screenTitle: titulo, showBackButton: true, showFilterButton: false)
            : AppBar(
                title: const Text(titulo),
                backgroundColor: GridColors.primary,
                foregroundColor: GridColors.textPrimary,
              ),
        body: LayoutBuilder(builder: (context, limites) {
          final largo = limites.maxWidth >= 700;
          return Column(children: [
            if (_ocupado != null)
              LinearProgressIndicator(minHeight: 3, semanticsLabel: _ocupado),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(largo ? 20 : 12),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: _conteudoDaTela(largo),
                    ),
                  ),
                ],
              ),
            ),
          ]);
        }),
      ),
    );
  }

  Widget _conteudoDaTela(bool largo) {
    final travado = _ocupado != null;
    final exportar = _cartao('Exportar', [
      if (_secao == _Secao.plano)
        const Text('Exporta o plano de contas inteiro.')
      else ...[
        _botao(
          Icons.date_range,
          _periodo == null
              ? 'Selecionar período (obrigatório)'
              : '${DateFormat('dd/MM/yyyy').format(_periodo!.start)} a '
                  '${DateFormat('dd/MM/yyyy').format(_periodo!.end)}',
          travado
              ? null
              : () async {
                  final escolhido = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
                      initialDateRange: _periodo);
                  if (escolhido != null && mounted) setState(() => _periodo = escolhido);
                },
        ),
        if (_periodo == null) const Text('Selecione o período para exportar.'),
      ],
      FilledButton.icon(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        onPressed: travado || (_secao == _Secao.lancamentos && _periodo == null) ? null : _exportar,
        icon: const Icon(Icons.download),
        label: const Text('Exportar CSV'),
      ),
    ]);
    final importar = _cartao('Importar', [
      _botao(Icons.description, 'Baixar modelo', travado ? null : _baixarModelo),
      _botao(Icons.upload_file, _nomeArquivo == null ? 'Escolher arquivo CSV' : 'Trocar arquivo',
          travado ? null : _escolher),
      if (_nomeArquivo != null) Text(_nomeArquivo!),
      Text('Colunas: ${_secao.colunas}',
          style: const TextStyle(fontSize: 12, color: GridColors.textMuted)),
      const Text(
          'A importação é tudo ou nada: se houver erro, nenhuma linha é gravada. '
          'Períodos contábeis fechados são recusados.'),
    ]);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _faixa(Icons.info, GridColors.info, GridColors.card,
          'Arquivo CSV genérico, separado por ponto e vírgula. Não é um layout oficial do Domínio '
          'nem de outro sistema.'),
      Center(
        child: SegmentedButton<_Secao>(
          style: const ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(0, 48))),
          segments: [
            for (final s in _Secao.values) ButtonSegment(value: s, label: Text(s.rotulo)),
          ],
          selected: {_secao},
          onSelectionChanged: travado
              ? null
              : (s) => setState(() {
                    _secao = s.first;
                    _limparImportacao();
                  }),
        ),
      ),
      const SizedBox(height: 12),
      if (_erro != null)
        _faixa(Icons.error, GridColors.errorDark, GridColors.errorLight, _erro!),
      if (_sucesso != null)
        _faixa(Icons.check_circle, GridColors.success, GridColors.successLight, _sucesso!),
      if (largo)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: exportar),
          const SizedBox(width: 12),
          Expanded(child: importar),
        ])
      else ...[
        exportar,
        importar,
      ],
      if (_previa != null) _cartaoPrevia(_previa!),
    ]);
  }

  Widget _cartaoPrevia(_Json p) {
    final erros = (p['erros'] as List).cast<_Json>();
    final totalErros = (p['totalErros'] as num).toInt();
    final nada = (p['novas'] as num) == 0 && (p['atualizadas'] as num) == 0;
    final motivo = totalErros > 0
        ? 'Corrija $totalErros erro(s) no arquivo e escolha-o novamente.'
        : nada
            ? 'Nada novo para importar.'
            : null;
    return _cartao('Prévia: nada foi gravado ainda', [
      Semantics(
        liveRegion: true,
        child: Wrap(spacing: 16, runSpacing: 8, children: [
          Text('Total de linhas: ${p['total']}'),
          Text('Novas: ${p['novas']}'),
          Text('Atualizadas: ${p['atualizadas']}'),
          Text('Já existentes (ignoradas): ${p['ignoradas']}'),
        ]),
      ),
      for (final aviso in (p['avisos'] as List))
        _faixa(Icons.warning, GridColors.warningDark, GridColors.suggestionMedium, '$aviso'),
      if (totalErros > 0) ...[
        Text('Erros ($totalErros)${totalErros > erros.length ? ', mostrando ${erros.length}' : ''}:',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(
          height: erros.length > 6 ? 320 : erros.length * 48,
          child: ListView.builder(
            itemCount: erros.length,
            itemBuilder: (_, i) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.error, color: GridColors.errorDark),
              title: Text('Linha ${erros[i]['linha']}: ${erros[i]['mensagem']}'),
            ),
          ),
        ),
      ],
      if (motivo != null) Text(motivo),
      Wrap(alignment: WrapAlignment.end, spacing: 8, runSpacing: 8, children: [
        TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: _ocupado != null ? null : () => setState(_limparImportacao),
            child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
          onPressed: _ocupado != null || motivo != null ? null : () => _enviar(confirmar: true),
          child: const Text('Confirmar importação'),
        ),
      ]),
    ]);
  }

  Widget _botao(IconData icone, String rotulo, VoidCallback? acao) => OutlinedButton.icon(
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        onPressed: acao,
        icon: Icon(icone),
        label: Text(rotulo, textAlign: TextAlign.center),
      );

  Widget _cartao(String titulo, List<Widget> filhos) => Card(
        color: GridColors.card,
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Semantics(
              header: true,
              child: Text(titulo,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold, color: GridColors.textSecondary)),
            ),
            for (final f in filhos) ...[const SizedBox(height: 10), f],
          ]),
        ),
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
