import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../services/session_expired_handler.dart';
import '../../utils/app_logger.dart';
import '../../utils/grid_colors.dart';

typedef _Json = Map<String, dynamic>;
typedef Buscar = Future<http.Response> Function(String url);
typedef Enviar = Future<http.Response> Function(String url, String corpo);
typedef MontarUrl = String Function(String caminho, [Map<String, String> extras]);

/// Resultado de um POST de ZIP ou de e-mail: os bytes quando deu certo, senão a mensagem.
class RespostaXml {
  final http.Response? resposta;
  final String? erro;
  const RespostaXml(this.resposta, this.erro);
}

/// Envia o pedido e traduz a falha. No e-mail, queda de conexão não prova que nada saiu.
Future<RespostaXml> pedirXml(Enviar enviar, String url, Object corpo, {required bool porEmail}) async {
  final padrao = porEmail ? 'Não foi possível enviar o e-mail.' : 'Não foi possível gerar o ZIP.';
  try {
    final r = await enviar(url, jsonEncode(corpo)).timeout(const Duration(minutes: 3));
    if (r.statusCode == 401) SessionExpiredHandler.handle();
    if (r.statusCode == 200) return RespostaXml(r, null);
    if (r.statusCode == 403) {
      return RespostaXml(null,
          porEmail ? 'Você não tem permissão para enviar XML por e-mail.' : 'Você não tem permissão para esta ação.');
    }
    if (r.statusCode == 400) {
      // Um 400 significa que nada saiu: corpo ilegível não pode virar "não sei se enviou".
      try {
        final json = jsonDecode(utf8.decode(r.bodyBytes));
        return RespostaXml(null, '${json['message'] ?? json['mensagem'] ?? padrao}');
      } on Object {
        return RespostaXml(null, padrao);
      }
    }
    AppLogger.i.warn('Gestão de XML: pedido recusado (${r.statusCode}), e-mail=$porEmail');
  } catch (e, st) {
    AppLogger.i.error('Gestão de XML: falha no pedido, e-mail=$porEmail (${e.runtimeType})', st);
  }
  return RespostaXml(
      null,
      porEmail
          ? 'Não foi possível confirmar o envio. Verifique com o destinatário antes de reenviar.'
          : padrao);
}

/// Pede o endereço duas vezes: depois de enviado não há como desfazer. Devolve null se desistir.
Future<String?> pedirDestinatario(BuildContext context, String resumo) =>
    showDialog<String>(context: context, barrierDismissible: false, builder: (_) => _Destinatario(resumo));

class _Destinatario extends StatefulWidget {
  final String resumo;
  const _Destinatario(this.resumo);

  @override
  State<_Destinatario> createState() => _DestinatarioState();
}

class _DestinatarioState extends State<_Destinatario> {
  static final _formato = RegExp(r'^[^\s@,;<>"]+@[^\s@,;<>"]+\.[^\s@,;<>"]+$');
  final _email = TextEditingController();
  final _repetido = TextEditingController();
  String? _erro;

  @override
  void dispose() {
    _email.dispose();
    _repetido.dispose();
    super.dispose();
  }

  void _confirmar() {
    final email = _email.text.trim();
    if (!_formato.hasMatch(email)) {
      setState(() => _erro = 'Informe um e-mail válido.');
    } else if (email.toLowerCase() != _repetido.text.trim().toLowerCase()) {
      setState(() => _erro = 'Os e-mails não conferem.');
    } else {
      Navigator.pop(context, email);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Enviar por e-mail'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('${widget.resumo}\nApós o envio, não é possível desfazer.'),
              TextField(
                  controller: _email,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-mail do destinatário*')),
              TextField(
                  controller: _repetido,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Confirme o e-mail*')),
              if (_erro != null) _erroNaTela(_erro!),
            ]),
          ),
        ),
        actions: [
          TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: () => Navigator.pop(context),
              child: const Text('Voltar')),
          FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: _confirmar,
              child: const Text('Enviar para este e-mail')),
        ],
      );
}

Widget _erroNaTela(String texto) => Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(children: [
          const Icon(Icons.error, color: GridColors.errorDark),
          const SizedBox(width: 8),
          Expanded(child: Text(texto)),
        ]),
      ),
    );

/// Exportação por período de todos os tipos de documento.
class ExportarXmlDialog extends StatefulWidget {
  final MontarUrl url;
  final Buscar buscar;
  final Enviar enviar;
  final Future<void> Function(http.Response resposta) salvar;

  const ExportarXmlDialog(
      {super.key, required this.url, required this.buscar, required this.enviar, required this.salvar});

  @override
  State<ExportarXmlDialog> createState() => _ExportarXmlDialogState();
}

class _ExportarXmlDialogState extends State<ExportarXmlDialog> {
  DateTime? _inicio;
  DateTime? _fim;
  int? _clienteId;
  List<_Json> _clientes = const [];
  List<_Json>? _tipos;
  final Set<String> _marcados = {};
  int _limite = 2000;
  bool _consultando = false;
  String? _ocupado;
  String? _erro;
  String? _sucesso;
  int _pedido = 0;

  static final _iso = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _carregarClientes();
  }

  Future<void> _carregarClientes() async {
    try {
      final r = await widget.buscar(widget.url('/api/gestao-xml/lote/clientes'));
      if (!mounted || r.statusCode != 200) return;
      setState(() =>
          _clientes = ((jsonDecode(utf8.decode(r.bodyBytes)) as _Json)['clientes'] as List).cast<_Json>());
    } catch (e, st) {
      // Sem a lista ainda dá para exportar todos os clientes.
      AppLogger.i.error('Gestão de XML: falha ao listar clientes ($e)', st);
    }
  }

  String? get _erroPeriodo {
    if (_inicio == null || _fim == null) return 'Informe as datas inicial e final.';
    if (_fim!.isBefore(_inicio!)) return 'A data final deve ser igual ou posterior à inicial.';
    if (_fim!.difference(_inicio!).inDays > 366) return 'O período máximo é de 1 ano.';
    return null;
  }

  Future<void> _consultar() async {
    final pedido = ++_pedido;
    setState(() {
      _tipos = null;
      _marcados.clear();
      _erro = null;
      _sucesso = null;
      _consultando = _erroPeriodo == null;
    });
    if (_erroPeriodo != null) return;
    String? erro;
    try {
      final r = await widget.buscar(widget.url('/api/gestao-xml/lote', {
        'inicio': _iso.format(_inicio!),
        'fim': _iso.format(_fim!),
        if (_clienteId != null) 'clienteId': '$_clienteId',
      }));
      if (!mounted || pedido != _pedido) return; // resposta de filtro antigo
      if (r.statusCode == 200) {
        final corpo = jsonDecode(utf8.decode(r.bodyBytes)) as _Json;
        _tipos = (corpo['tipos'] as List).cast<_Json>();
        _limite = (corpo['limite'] as num).toInt();
        _marcados.addAll(_tipos!.where((t) => (t['total'] as num) > 0).map((t) => '${t['codigo']}'));
      } else {
        erro = 'Não foi possível consultar.';
      }
    } catch (e, st) {
      AppLogger.i.error('Gestão de XML: falha ao contar documentos ($e)', st);
      if (!mounted || pedido != _pedido) return;
      erro = 'Não foi possível consultar.';
    }
    setState(() {
      _erro = erro;
      _consultando = false;
    });
  }

  int _soma(String campo) => (_tipos ?? const [])
      .where((t) => _marcados.contains(t['codigo']))
      .fold(0, (s, t) => s + (t[campo] as num).toInt());

  Future<void> _gerar({required bool porEmail}) async {
    String? destinatario;
    if (porEmail) {
      destinatario = await pedirDestinatario(context,
          '${_soma('total')} documentos de ${DateFormat('dd/MM/yyyy').format(_inicio!)} a '
          '${DateFormat('dd/MM/yyyy').format(_fim!)}.');
      if (destinatario == null || !mounted) return;
    }
    setState(() {
      _ocupado = porEmail ? 'Enviando e-mail...' : 'Gerando ZIP...';
      _erro = null;
      _sucesso = null;
    });
    final r = await pedirXml(
        widget.enviar,
        widget.url('/api/gestao-xml/lote/${porEmail ? 'email' : 'zip'}'),
        {
          'inicio': _iso.format(_inicio!),
          'fim': _iso.format(_fim!),
          if (_clienteId != null) 'clienteId': _clienteId,
          'tipos': _marcados.toList(),
          if (destinatario != null) 'destinatario': destinatario,
        },
        porEmail: porEmail);
    var erro = r.erro;
    if (r.resposta != null && !porEmail) {
      try {
        await widget.salvar(r.resposta!);
      } catch (e, st) {
        AppLogger.i.error('Gestão de XML: falha ao salvar o ZIP ($e)', st);
        erro = 'Não foi possível salvar o ZIP.';
      }
    }
    if (!mounted) return;
    setState(() {
      _ocupado = null;
      _erro = erro;
      _sucesso = erro != null ? null : porEmail ? 'E-mail enviado para $destinatario.' : 'ZIP gerado.';
    });
  }

  Widget _data(String rotulo, DateTime? valor, ValueChanged<DateTime> escolhida) => OutlinedButton.icon(
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        onPressed: _ocupado != null
            ? null
            : () async {
                final d = await showDatePicker(
                    context: context,
                    initialDate: valor ?? DateTime.now(),
                    firstDate: DateTime(2010),
                    lastDate: DateTime(DateTime.now().year + 1, 12, 31));
                if (d == null || !mounted) return;
                escolhida(d);
                await _consultar();
              },
        icon: const Icon(Icons.event),
        label: Text(valor == null ? '$rotulo*' : '$rotulo: ${DateFormat('dd/MM/yyyy').format(valor)}'),
      );

  @override
  Widget build(BuildContext context) {
    final total = _soma('total');
    final vazio = _tipos != null && _tipos!.every((t) => (t['total'] as num) == 0);
    final motivo = _erroPeriodo ??
        (_tipos == null
            ? null
            : vazio
                ? 'Nenhum documento no período.'
                : _marcados.isEmpty
                    ? 'Selecione ao menos um tipo.'
                    : total > _limite
                        ? 'A seleção tem $total documentos; o limite é $_limite. Reduza o período ou os tipos.'
                        : null);
    final pode = _tipos != null && motivo == null && _ocupado == null;
    final estreito = MediaQuery.sizeOf(context).width < 600;

    return PopScope(
      canPop: _ocupado == null,
      child: AlertDialog(
        insetPadding: EdgeInsets.all(estreito ? 8 : 24),
        title: const Text('Exportar por período'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _data('Data inicial', _inicio, (d) => _inicio = d),
              const SizedBox(height: 8),
              _data('Data final', _fim, (d) => _fim = d),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (_, limites) => DropdownMenu<int>(
                  width: limites.maxWidth,
                  enabled: _ocupado == null,
                  enableFilter: true,
                  requestFocusOnTap: true,
                  label: const Text('Cliente (opcional)'),
                  initialSelection: -1,
                  dropdownMenuEntries: [
                    const DropdownMenuEntry(value: -1, label: 'Todos os clientes'),
                    for (final c in _clientes) DropdownMenuEntry(value: c['id'] as int, label: '${c['nome']}'),
                  ],
                  onSelected: (v) {
                    _clienteId = v == null || v < 0 ? null : v;
                    _consultar();
                  },
                ),
              ),
              if (_consultando) ...[
                const SizedBox(height: 8),
                const Text('Consultando documentos...'),
                const LinearProgressIndicator(),
              ],
              if (_tipos != null && !vazio) ...[
                for (final t in _tipos!)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text('${t['nome']}: ${t['total']} (${t['semXml']} sem XML)'),
                    value: _marcados.contains(t['codigo']),
                    onChanged: (t['total'] as num) == 0 || _ocupado != null
                        ? null
                        : (v) => setState(() => v == true
                            ? _marcados.add('${t['codigo']}')
                            : _marcados.remove(t['codigo'])),
                  ),
                Text('$total documentos · ${_soma('semXml')} sem XML autorizado'),
                const Text(
                    'O ZIP tem uma pasta por tipo e o arquivo relacao.csv. Documento sem XML autorizado '
                    'aparece só no CSV. XML de cancelamento: somente NF-e. Homologação não entra. '
                    'Em NFC-e, CT-e e MDF-e, o filtro de cliente vale para o cliente emitente.',
                    style: TextStyle(color: GridColors.textMuted)),
              ],
              if (motivo != null) _erroNaTela(motivo),
              if (_erro != null) ...[
                _erroNaTela(_erro!),
                if (_tipos == null)
                  TextButton(onPressed: _consultar, child: const Text('Tentar novamente')),
              ],
              if (_sucesso != null)
                Semantics(liveRegion: true, child: Text(_sucesso!)),
              if (_ocupado != null) ...[
                Text(_ocupado!),
                const LinearProgressIndicator(),
              ],
            ]),
          ),
        ),
        actions: [
          TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: _ocupado != null ? null : () => Navigator.pop(context),
              child: const Text('Fechar')),
          OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: pode ? () => _gerar(porEmail: true) : null,
              child: const Text('Enviar por e-mail')),
          FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: pode ? () => _gerar(porEmail: false) : null,
              child: const Text('Baixar ZIP')),
        ],
      ),
    );
  }
}
