import 'package:flutter/material.dart';

import '../services/network_caller.dart';
import '../utils/api_links.dart';
import '../utils/app_logger.dart';
import '../utils/file_saver_compat.dart';
import '../utils/tenant_context.dart';
import '../web/screens/transporte_veiculo_grid_screen.dart'
    show kTransporteUfs;
import 'transporte_config_tab.dart'
    show kTransporteTiposEmitente, kTransporteTiposTransportador;

/// Situacoes do MDF-e (espelho de `MdfeStatus` no backend).
const String kMdfeAutorizado = 'AUTORIZADO';
const int kMdfeTamanhoMinimoJustificativa = 15;

/// Monta o corpo do POST /api/mdfe a partir dos campos do formulario.
/// Dados rodoviarios vem do cadastro (veiculoId + motoristaIds); numero e
/// emissao sao definidos pelo backend.
Map<String, dynamic> montarCorpoEmissaoMdfe({
  required int tpAmb,
  required int tpEmit,
  int? tpTransp,
  required int serie,
  required String ufIni,
  required String ufFim,
  required String municipioCarregamentoIbge,
  required String municipioCarregamentoNome,
  required String municipioDescargaIbge,
  required String municipioDescargaNome,
  required List<String> chavesCte,
  required List<String> chavesNfe,
  required num valorCarga,
  required String unidadeCarga,
  required num quantidadeCarga,
  String? infoComplementar,
  required int veiculoId,
  required List<int> motoristaIds,
}) {
  return {
    'tpAmb': tpAmb,
    'tpEmit': tpEmit,
    'tpTransp': tpTransp,
    'serie': serie,
    'ufIni': ufIni,
    'ufFim': ufFim,
    'municipiosCarregamento': [
      {
        'codigoIbge': municipioCarregamentoIbge,
        'nome': municipioCarregamentoNome,
      }
    ],
    'descargas': [
      {
        'municipio': {
          'codigoIbge': municipioDescargaIbge,
          'nome': municipioDescargaNome,
        },
        'chavesCte': chavesCte,
        'chavesNfe': chavesNfe,
      }
    ],
    'valorCarga': valorCarga,
    'unidadeCarga': unidadeCarga,
    'quantidadeCarga': quantidadeCarga,
    if (infoComplementar != null && infoComplementar.trim().isNotEmpty)
      'infoComplementar': infoComplementar.trim(),
    'veiculoId': veiculoId,
    'motoristaIds': motoristaIds,
  };
}

/// Separa um texto com uma chave por linha; devolve so as de 44 digitos e
/// registra as invalidas em [invalidas].
List<String> extrairChaves(String texto, {List<String>? invalidas}) {
  final chaves = <String>[];
  for (final linha in texto.split(RegExp(r'[\n;,\s]+'))) {
    final limpa = linha.replaceAll(RegExp(r'\D'), '');
    if (limpa.isEmpty) continue;
    if (limpa.length == 44) {
      chaves.add(limpa);
    } else {
      invalidas?.add(linha);
    }
  }
  return chaves;
}

/// Le a lista do envelope `data.dados` devolvido pela API.
List<Map<String, dynamic>> listaMdfeDe(Map<String, dynamic>? body) {
  final dados = (body?['data'] is Map) ? body!['data']['dados'] : null;
  if (dados is! List) return [];
  return dados
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

/// Tela de emissao e acompanhamento do MDF-e (Web, Windows e Mobile).
/// Lista `/api/mdfe`, emite pelo cadastro de veiculos/motoristas e permite
/// consultar, cancelar, encerrar, ver eventos e excluir (so homologacao).
class MdfeEmissaoView extends StatefulWidget {
  const MdfeEmissaoView({super.key});

  @override
  State<MdfeEmissaoView> createState() => _MdfeEmissaoViewState();
}

class _MdfeEmissaoViewState extends State<MdfeEmissaoView> {
  final _net = NetworkCaller();
  List<Map<String, dynamic>> _itens = [];
  bool _loading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final r = await _net.getRequest('${ApiLinks.allMdfe}?pagina=0&tamanho=50');
      if (!mounted) return;
      if (r.isSuccess) {
        _itens = listaMdfeDe(r.body);
      } else {
        _erro = r.statusCode == 403
            ? 'Sem acesso ao módulo Transporte (MDF-e).'
            : 'Não foi possível carregar os MDF-e (HTTP ${r.statusCode}).';
      }
    } catch (e, st) {
      AppLogger.i.error('MdfeEmissaoView: erro ao carregar: $e', st);
      _erro = 'Não foi possível carregar os MDF-e.';
    }
    if (mounted) setState(() => _loading = false);
  }

  void _aviso(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _acao(String descricao, Future<void> Function() corpo) async {
    try {
      await corpo();
    } catch (e, st) {
      AppLogger.i.error('MdfeEmissaoView: erro em $descricao: $e', st);
      _aviso('Não foi possível $descricao.');
    }
  }

  Future<void> _novo() async {
    final criado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _MdfeFormDialog(),
    );
    if (criado == true) _carregar();
  }

  Future<void> _consultar(Map<String, dynamic> m) => _acao('consultar o MDF-e', () async {
        final r = await _net.postRequest(ApiLinks.mdfeConsultar('${m['id']}'), {});
        if (r.isSuccess) {
          _aviso('Consulta concluída: ${r.body?['status'] ?? ''}');
          _carregar();
        } else {
          _aviso(r.statusCode == 502
              ? 'SEFAZ indisponível para consulta. Tente novamente.'
              : 'Falha na consulta (HTTP ${r.statusCode}).');
        }
      });

  Future<void> _cancelar(Map<String, dynamic> m) async {
    final texto = await _pedirTexto(
      titulo: 'Cancelar MDF-e ${m['numero']}',
      rotulo: 'Justificativa (mín. $kMdfeTamanhoMinimoJustificativa caracteres)',
      minimo: kMdfeTamanhoMinimoJustificativa,
    );
    if (texto == null) return;
    await _acao('cancelar o MDF-e', () async {
      final r = await _net.postRequest(
          ApiLinks.mdfeCancelar('${m['id']}'), {'justificativa': texto});
      _aviso(r.isSuccess
          ? 'Cancelamento: ${r.body?['status'] ?? ''} ${r.body?['motivo'] ?? ''}'
          : 'Falha ao cancelar (HTTP ${r.statusCode}).');
      if (r.isSuccess) _carregar();
    });
  }

  Future<void> _encerrar(Map<String, dynamic> m) async {
    final dados = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _EncerrarDialog(ufInicial: '${m['uf'] ?? ''}'),
    );
    if (dados == null) return;
    await _acao('encerrar o MDF-e', () async {
      final r = await _net.postRequest(ApiLinks.mdfeEncerrar('${m['id']}'), dados);
      _aviso(r.isSuccess
          ? 'Encerramento: ${r.body?['status'] ?? ''} ${r.body?['motivo'] ?? ''}'
          : 'Falha ao encerrar (HTTP ${r.statusCode}).');
      if (r.isSuccess) _carregar();
    });
  }

  Future<void> _damdfe(Map<String, dynamic> m) => _acao('gerar o DAMDFE', () async {
        final r = await TenantContext.get(ApiLinks.mdfeDamdfe('${m['id']}'));
        if (r.statusCode != 200) {
          AppLogger.i.warn('MdfeEmissaoView: DAMDFE #${m['id']} falhou: HTTP ${r.statusCode}');
          _aviso('Não foi possível gerar o DAMDFE (HTTP ${r.statusCode}).');
          return;
        }
        await FileSaver.instance.saveFile(
          name: 'damdfe_${m['numero'] ?? m['id']}',
          bytes: r.bodyBytes,
          fileExtension: 'pdf',
          mimeType: MimeType.pdf,
        );
        _aviso('DAMDFE gerado.');
      });

  Future<void> _eventos(Map<String, dynamic> m) => _acao('listar os eventos', () async {
        final r = await _net.getRequest(ApiLinks.mdfeEventos('${m['id']}'));
        if (!r.isSuccess) {
          _aviso('Falha ao buscar eventos (HTTP ${r.statusCode}).');
          return;
        }
        final lista = (r.body?['data'] is List)
            ? (r.body!['data'] as List).whereType<Map>().toList()
            : <Map>[];
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Eventos do MDF-e ${m['numero']}'),
            content: SizedBox(
              width: 420,
              child: lista.isEmpty
                  ? const Text('Nenhum evento registrado.')
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        for (final e in lista)
                          ListTile(
                            dense: true,
                            title: Text('${e['tipoEvento']} — ${e['status']}'),
                            subtitle: Text(
                                '${e['dhEvento'] ?? ''}\n${e['motivo'] ?? ''}'),
                          ),
                      ],
                    ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fechar')),
            ],
          ),
        );
      });

  Future<void> _excluir(Map<String, dynamic> m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir MDF-e de teste'),
        content: Text(
            'Excluir o MDF-e ${m['numero']} (homologação)? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Voltar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir')),
        ],
      ),
    );
    if (ok != true) return;
    await _acao('excluir o MDF-e', () async {
      final r = await _net.deleteRequest(ApiLinks.mdfe('${m['id']}'));
      _aviso(r.isSuccess
          ? 'MDF-e excluído.'
          : 'Não foi possível excluir (HTTP ${r.statusCode}). Só é permitido em homologação sem desfecho fiscal.');
      if (r.isSuccess) _carregar();
    });
  }

  Future<String?> _pedirTexto(
      {required String titulo, required String rotulo, required int minimo}) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        String? erro;
        return StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
            title: Text(titulo),
            content: TextField(
              controller: ctrl,
              maxLines: 3,
              decoration: InputDecoration(labelText: rotulo, errorText: erro),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Voltar')),
              FilledButton(
                onPressed: () {
                  final t = ctrl.text.trim();
                  if (t.length < minimo) {
                    setS(() => erro = 'Mínimo de $minimo caracteres.');
                    return;
                  }
                  Navigator.pop(ctx, t);
                },
                child: const Text('Confirmar'),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _corStatus(String? s) {
    switch (s) {
      case 'AUTORIZADO':
      case 'REGISTRADO':
        return Colors.green.shade700;
      case 'REJEITADO':
      case 'CANCELADO':
        return Colors.red.shade700;
      case 'ENCERRADO':
        return Colors.blueGrey;
      default:
        return Colors.orange.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping),
              const SizedBox(width: 10),
              Expanded(
                child: Text('MDF-e',
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              IconButton(
                  tooltip: 'Atualizar',
                  onPressed: _carregar,
                  icon: const Icon(Icons.refresh)),
              FilledButton.icon(
                onPressed: _novo,
                icon: const Icon(Icons.add),
                label: const Text('Novo MDF-e'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_erro != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_erro!, style: TextStyle(color: Colors.red.shade800)),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _itens.isEmpty
                    ? const Center(child: Text('Nenhum MDF-e emitido.'))
                    : ListView.separated(
                        itemCount: _itens.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _cartao(_itens[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _cartao(Map<String, dynamic> m) {
    final status = m['status']?.toString();
    final autorizado = status == kMdfeAutorizado;
    final homolog = m['tpAmb'] == 2;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'MDF-e nº ${m['numero'] ?? '-'} • série ${m['serie'] ?? '-'}'
                    '${homolog ? ' • HOMOLOGAÇÃO' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Chip(
                  label: Text(status ?? '-',
                      style: const TextStyle(color: Colors.white, fontSize: 12)),
                  backgroundColor: _corStatus(status),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (m['chaveAcesso'] != null)
              SelectableText('Chave: ${m['chaveAcesso']}',
                  style: const TextStyle(fontSize: 12)),
            if (m['protocolo'] != null)
              Text('Protocolo: ${m['protocolo']}',
                  style: const TextStyle(fontSize: 12)),
            if ((m['motivo'] ?? '').toString().isNotEmpty)
              Text('${m['codigoRetorno'] ?? ''} ${m['motivo']}',
                  style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                OutlinedButton.icon(
                    onPressed: () => _consultar(m),
                    icon: const Icon(Icons.sync, size: 18),
                    label: const Text('Consultar')),
                OutlinedButton.icon(
                    onPressed: () => _damdfe(m),
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    label: const Text('DAMDFE')),
                OutlinedButton.icon(
                    onPressed: () => _eventos(m),
                    icon: const Icon(Icons.history, size: 18),
                    label: const Text('Eventos')),
                if (autorizado)
                  OutlinedButton.icon(
                      onPressed: () => _encerrar(m),
                      icon: const Icon(Icons.flag, size: 18),
                      label: const Text('Encerrar')),
                if (autorizado)
                  OutlinedButton.icon(
                      onPressed: () => _cancelar(m),
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('Cancelar')),
                if (homolog)
                  TextButton.icon(
                      onPressed: () => _excluir(m),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Excluir')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EncerrarDialog extends StatefulWidget {
  final String ufInicial;
  const _EncerrarDialog({required this.ufInicial});

  @override
  State<_EncerrarDialog> createState() => _EncerrarDialogState();
}

class _EncerrarDialogState extends State<_EncerrarDialog> {
  late String? _uf =
      kTransporteUfs.contains(widget.ufInicial) ? widget.ufInicial : null;
  final _municipio = TextEditingController();
  DateTime _data = DateTime.now();
  String? _erro;

  @override
  void dispose() {
    _municipio.dispose();
    super.dispose();
  }

  String get _dataIso =>
      '${_data.year.toString().padLeft(4, '0')}-${_data.month.toString().padLeft(2, '0')}-${_data.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Encerrar MDF-e'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Data do encerramento'),
              subtitle: Text(_dataIso),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _data,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now(),
                );
                if (d != null) setState(() => _data = d);
              },
            ),
            DropdownButtonFormField<String>(
              initialValue: _uf,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'UF de encerramento'),
              items: [
                for (final uf in kTransporteUfs)
                  DropdownMenuItem(value: uf, child: Text(uf)),
              ],
              onChanged: (v) => setState(() => _uf = v),
            ),
            TextField(
              controller: _municipio,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Código IBGE do município (7 dígitos)'),
            ),
            if (_erro != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_erro!, style: TextStyle(color: Colors.red.shade800)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Voltar')),
        FilledButton(
          onPressed: () {
            final cod = _municipio.text.trim();
            if (_uf == null || !RegExp(r'^\d{7}$').hasMatch(cod)) {
              setState(() => _erro = 'Informe a UF e o código IBGE de 7 dígitos.');
              return;
            }
            Navigator.pop(context,
                {'data': _dataIso, 'uf': _uf, 'codigoMunicipio': cod});
          },
          child: const Text('Encerrar'),
        ),
      ],
    );
  }
}

class _MdfeFormDialog extends StatefulWidget {
  const _MdfeFormDialog();

  @override
  State<_MdfeFormDialog> createState() => _MdfeFormDialogState();
}

class _MdfeFormDialogState extends State<_MdfeFormDialog> {
  final _net = NetworkCaller();
  final _form = GlobalKey<FormState>();
  final _serie = TextEditingController(text: '1');
  final _carregIbge = TextEditingController();
  final _carregNome = TextEditingController();
  final _descIbge = TextEditingController();
  final _descNome = TextEditingController();
  final _chavesCte = TextEditingController();
  final _chavesNfe = TextEditingController();
  final _valor = TextEditingController();
  final _quantidade = TextEditingController();
  final _info = TextEditingController();

  int _tpAmb = 2;
  int _tpEmit = 1;
  int? _tpTransp;
  String? _ufIni;
  String? _ufFim;
  String _unidade = '01';
  int? _veiculoId;
  final Set<int> _motoristas = {};
  List<Map<String, dynamic>> _veiculos = [];
  List<Map<String, dynamic>> _motoristasDisp = [];
  bool _loading = true;
  bool _enviando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarCadastros();
  }

  @override
  void dispose() {
    for (final c in [
      _serie, _carregIbge, _carregNome, _descIbge, _descNome, _chavesCte,
      _chavesNfe, _valor, _quantidade, _info
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _carregarCadastros() async {
    try {
      final v = await _net
          .getRequest('${ApiLinks.allTransporteVeiculos}?pagina=0&tamanho=100');
      final m = await _net.getRequest(
          '${ApiLinks.allTransporteMotoristas}?pagina=0&tamanho=100');
      final c = await _net.getRequest(ApiLinks.transporteConfig);
      if (!mounted) return;
      if (v.isSuccess) {
        _veiculos = listaMdfeDe(v.body)
            .where((e) => e['ativo'] != false)
            .toList();
      }
      if (m.isSuccess) {
        _motoristasDisp = listaMdfeDe(m.body)
            .where((e) => e['ativo'] != false)
            .toList();
      }
      if (c.isSuccess && c.body != null) {
        _serie.text = c.body!['serieMdfe']?.toString() ?? '1';
        _tpEmit = (c.body!['tpEmit'] as num?)?.toInt() ?? 1;
        _tpTransp = (c.body!['tpTransp'] as num?)?.toInt();
      }
      if (!v.isSuccess || !m.isSuccess) {
        _erro = 'Não foi possível carregar veículos/motoristas.';
      }
    } catch (e, st) {
      AppLogger.i.error('MdfeFormDialog: erro ao carregar cadastros: $e', st);
      _erro = 'Não foi possível carregar veículos/motoristas.';
    }
    if (mounted) setState(() => _loading = false);
  }

  num? _numero(String t) => num.tryParse(t.trim().replaceAll(',', '.'));

  Future<void> _emitir() async {
    if (!_form.currentState!.validate()) return;
    final invalidas = <String>[];
    final cte = extrairChaves(_chavesCte.text, invalidas: invalidas);
    final nfe = extrairChaves(_chavesNfe.text, invalidas: invalidas);
    if (invalidas.isNotEmpty) {
      setState(() => _erro = 'Chave(s) com tamanho inválido (esperado 44 dígitos): '
          '${invalidas.join(', ')}');
      return;
    }
    if (cte.isEmpty && nfe.isEmpty) {
      setState(() => _erro = 'Informe ao menos uma chave de CT-e ou NF-e.');
      return;
    }
    if (_veiculoId == null || _motoristas.isEmpty) {
      setState(() => _erro = 'Selecione o veículo e ao menos um motorista.');
      return;
    }
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      final corpo = montarCorpoEmissaoMdfe(
        tpAmb: _tpAmb,
        tpEmit: _tpEmit,
        tpTransp: _tpTransp,
        serie: int.parse(_serie.text.trim()),
        ufIni: _ufIni!,
        ufFim: _ufFim!,
        municipioCarregamentoIbge: _carregIbge.text.trim(),
        municipioCarregamentoNome: _carregNome.text.trim(),
        municipioDescargaIbge: _descIbge.text.trim(),
        municipioDescargaNome: _descNome.text.trim(),
        chavesCte: cte,
        chavesNfe: nfe,
        valorCarga: _numero(_valor.text)!,
        unidadeCarga: _unidade,
        quantidadeCarga: _numero(_quantidade.text)!,
        infoComplementar: _info.text,
        veiculoId: _veiculoId!,
        motoristaIds: _motoristas.toList(),
      );
      final r = await _net.postRequest(ApiLinks.allMdfe, corpo);
      if (!mounted) return;
      if (r.isSuccess) {
        final status = r.body?['status'];
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'MDF-e ${r.body?['numero'] ?? ''}: $status ${r.body?['motivo'] ?? ''}')));
        Navigator.pop(context, true);
        return;
      }
      _erro = 'Não foi possível emitir (HTTP ${r.statusCode}). '
          'Confira RNTRC, veículo, motoristas, municípios e chaves.';
    } catch (e, st) {
      AppLogger.i.error('MdfeFormDialog: erro ao emitir: $e', st);
      _erro = 'Não foi possível emitir o MDF-e.';
    }
    if (mounted) setState(() => _enviando = false);
  }

  String? _obrig(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Obrigatório' : null;

  String? _ibge(String? v) =>
      RegExp(r'^\d{7}$').hasMatch((v ?? '').trim()) ? null : '7 dígitos';

  String? _positivo(String? v) {
    final n = _numero(v ?? '');
    return (n == null || n <= 0) ? 'Valor inválido' : null;
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
      );

  Widget _linha(List<Widget> filhos) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Wrap(spacing: 12, runSpacing: 12, children: filhos),
      );

  Widget _caixa(Widget child, {double largura = 220}) =>
      SizedBox(width: largura, child: child);

  Widget _ufDrop(String label, String? valor, ValueChanged<String?> onChanged) =>
      _caixa(DropdownButtonFormField<String>(
        initialValue: valor,
        isExpanded: true,
        decoration: _dec(label),
        validator: (v) => v == null ? 'Obrigatório' : null,
        items: [
          for (final uf in kTransporteUfs)
            DropdownMenuItem(value: uf, child: Text(uf)),
        ],
        onChanged: onChanged,
      ), largura: 120);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo MDF-e'),
      content: SizedBox(
        width: 720,
        child: _loading
            ? const SizedBox(
                height: 120, child: Center(child: CircularProgressIndicator()))
            : SingleChildScrollView(
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_erro != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            border: Border.all(color: Colors.red.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(_erro!,
                              style: TextStyle(color: Colors.red.shade800)),
                        ),
                      _linha([
                        _caixa(DropdownButtonFormField<int>(
                          initialValue: _tpAmb,
                          isExpanded: true,
                          decoration: _dec('Ambiente'),
                          items: const [
                            DropdownMenuItem(value: 2, child: Text('2 - Homologação')),
                            DropdownMenuItem(value: 1, child: Text('1 - Produção')),
                          ],
                          onChanged: (v) => setState(() => _tpAmb = v ?? 2),
                        )),
                        _caixa(TextFormField(
                          controller: _serie,
                          keyboardType: TextInputType.number,
                          decoration: _dec('Série'),
                          validator: (v) {
                            final s = int.tryParse((v ?? '').trim());
                            return (s == null || s < 1 || s > 999) ? '1 a 999' : null;
                          },
                        ), largura: 100),
                        _caixa(DropdownButtonFormField<int>(
                          initialValue: _tpEmit,
                          isExpanded: true,
                          decoration: _dec('Tipo de emitente'),
                          items: [
                            for (final o in kTransporteTiposEmitente)
                              DropdownMenuItem<int>(
                                  value: o['value'] as int,
                                  child: Text(o['label'] as String,
                                      overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: (v) => setState(() => _tpEmit = v ?? 1),
                        ), largura: 300),
                        _caixa(DropdownButtonFormField<int?>(
                          initialValue: _tpTransp,
                          isExpanded: true,
                          decoration: _dec('Tipo de transportador'),
                          items: [
                            const DropdownMenuItem<int?>(
                                value: null, child: Text('Não informado')),
                            for (final o in kTransporteTiposTransportador)
                              DropdownMenuItem<int?>(
                                  value: o['value'] as int,
                                  child: Text(o['label'] as String)),
                          ],
                          onChanged: (v) => setState(() => _tpTransp = v),
                        ), largura: 200),
                      ]),
                      _linha([
                        _ufDrop('UF início', _ufIni, (v) => setState(() => _ufIni = v)),
                        _ufDrop('UF fim', _ufFim, (v) => setState(() => _ufFim = v)),
                      ]),
                      _linha([
                        _caixa(TextFormField(
                          controller: _carregIbge,
                          keyboardType: TextInputType.number,
                          decoration: _dec('Carregamento: IBGE'),
                          validator: _ibge,
                        ), largura: 180),
                        _caixa(TextFormField(
                          controller: _carregNome,
                          decoration: _dec('Carregamento: município'),
                          validator: _obrig,
                        ), largura: 260),
                      ]),
                      _linha([
                        _caixa(TextFormField(
                          controller: _descIbge,
                          keyboardType: TextInputType.number,
                          decoration: _dec('Descarga: IBGE'),
                          validator: _ibge,
                        ), largura: 180),
                        _caixa(TextFormField(
                          controller: _descNome,
                          decoration: _dec('Descarga: município'),
                          validator: _obrig,
                        ), largura: 260),
                      ]),
                      _linha([
                        _caixa(TextFormField(
                          controller: _chavesCte,
                          maxLines: 3,
                          decoration: _dec('Chaves CT-e (uma por linha)'),
                        ), largura: 340),
                        _caixa(TextFormField(
                          controller: _chavesNfe,
                          maxLines: 3,
                          decoration: _dec('Chaves NF-e (uma por linha)'),
                        ), largura: 340),
                      ]),
                      _linha([
                        _caixa(TextFormField(
                          controller: _valor,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: _dec('Valor da carga (R\$)'),
                          validator: _positivo,
                        )),
                        _caixa(DropdownButtonFormField<String>(
                          initialValue: _unidade,
                          isExpanded: true,
                          decoration: _dec('Unidade'),
                          items: const [
                            DropdownMenuItem(value: '01', child: Text('01 - KG')),
                            DropdownMenuItem(value: '02', child: Text('02 - TON')),
                          ],
                          onChanged: (v) => setState(() => _unidade = v ?? '01'),
                        ), largura: 140),
                        _caixa(TextFormField(
                          controller: _quantidade,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: _dec('Peso total'),
                          validator: _positivo,
                        ), largura: 160),
                      ]),
                      _linha([
                        _caixa(DropdownButtonFormField<int>(
                          initialValue: _veiculoId,
                          isExpanded: true,
                          decoration: _dec('Veículo'),
                          validator: (v) => v == null ? 'Obrigatório' : null,
                          items: [
                            for (final v in _veiculos)
                              DropdownMenuItem<int>(
                                  value: (v['id'] as num).toInt(),
                                  child: Text('${v['placa']}')),
                          ],
                          onChanged: (v) => setState(() => _veiculoId = v),
                        ), largura: 240),
                      ]),
                      const Text('Motoristas'),
                      if (_motoristasDisp.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text('Nenhum motorista ativo cadastrado.'),
                        ),
                      for (final m in _motoristasDisp)
                        CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text('${m['nome']}'),
                          value: _motoristas.contains((m['id'] as num).toInt()),
                          onChanged: (v) => setState(() {
                            final id = (m['id'] as num).toInt();
                            v == true ? _motoristas.add(id) : _motoristas.remove(id);
                          }),
                        ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _info,
                        maxLines: 2,
                        decoration: _dec('Informações complementares (opcional)'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(
            onPressed: _enviando ? null : () => Navigator.pop(context, false),
            child: const Text('Cancelar')),
        FilledButton.icon(
          onPressed: (_loading || _enviando) ? null : _emitir,
          icon: _enviando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.send),
          label: const Text('Emitir'),
        ),
      ],
    );
  }
}
