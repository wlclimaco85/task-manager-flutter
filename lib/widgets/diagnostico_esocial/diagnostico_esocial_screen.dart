import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../utils/api_links.dart';
import '../../utils/app_logger.dart';
import '../../utils/grid_colors.dart';
import '../../utils/tenant_context.dart';

typedef _Json = Map<String, dynamic>;

enum _Gravidade {
  todas('Todas as gravidades'),
  impede('Impede o envio'),
  revisar('Revisar');

  final String rotulo;
  const _Gravidade(this.rotulo);
}

/// Confere o cadastro dos funcionários antes do eSocial. Não transmite nem consulta o governo.
class DiagnosticoEsocialScreen extends StatefulWidget {
  /// Substituível em teste.
  final Future<http.Response> Function(String url)? buscar;

  const DiagnosticoEsocialScreen({super.key, this.buscar});

  @override
  State<DiagnosticoEsocialScreen> createState() => _DiagnosticoEsocialScreenState();
}

class _DiagnosticoEsocialScreenState extends State<DiagnosticoEsocialScreen> {
  List<_Json>? _todos;
  String? _erro;
  bool _carregando = false;

  int? _contratanteId;
  bool? _ativo;
  _Gravidade _gravidade = _Gravidade.todas;
  String _busca = '';
  String? _codigo;
  int _limite = 20;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    final url = Uri.parse('${ApiLinks.baseUrl}/api/diagnostico-esocial').replace(queryParameters: {
      'skipTenantParceiro': 'true',
      if (TenantContext.empresaId != null) 'empresaId': '${TenantContext.empresaId}',
    }).toString();
    try {
      final r = await (widget.buscar ?? TenantContext.get)(url);
      if (!mounted) return;
      if (r.statusCode == 403) {
        setState(() {
          _todos = null; // sem acesso não pode sobrar dado antigo na tela
          _erro = 'Você não tem acesso ao Diagnóstico eSocial. Solicite ao administrador.';
          _carregando = false;
        });
        return;
      }
      if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
      final corpo = jsonDecode(utf8.decode(r.bodyBytes)) as _Json;
      setState(() {
        _todos = (corpo['funcionarios'] as List).cast<_Json>();
        _erro = null;
        _carregando = false;
      });
    } catch (e, st) {
      // Não registrar o corpo: há dado pessoal.
      AppLogger.i.error('Diagnóstico eSocial: falha ao carregar (${e.runtimeType})', st);
      if (!mounted) return;
      setState(() {
        _erro = 'Não foi possível conferir os cadastros.';
        _carregando = false;
      });
    }
  }

  static List<_Json> _pendencias(_Json f, String chave) => (f[chave] as List).cast<_Json>();

  List<_Json> get _recorte => _todos!
      .where((f) => _contratanteId == null || f['contratanteId'] == _contratanteId)
      .where((f) => _ativo == null || f['ativo'] == _ativo)
      .toList();

  List<String> get _grupos => switch (_gravidade) {
        _Gravidade.todas => const ['impede', 'revisar'],
        _Gravidade.impede => const ['impede'],
        _Gravidade.revisar => const ['revisar'],
      };

  List<_Json> get _ranking {
    final lista = _recorte.where((f) {
      final itens = [for (final g in _grupos) ..._pendencias(f, g)];
      return itens.isNotEmpty &&
          (_codigo == null || itens.any((p) => p['codigo'] == _codigo)) &&
          '${f['nome']}'.toLowerCase().contains(_busca.toLowerCase());
    }).toList();
    lista.sort((a, b) {
      var c = _pendencias(b, 'impede').length.compareTo(_pendencias(a, 'impede').length);
      if (c == 0) c = _pendencias(b, 'revisar').length.compareTo(_pendencias(a, 'revisar').length);
      return c != 0 ? c : '${a['nome']}'.compareTo('${b['nome']}');
    });
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.pageBackground,
      appBar: AppBar(
        title: const Text('Diagnóstico eSocial'),
        backgroundColor: GridColors.primary,
        foregroundColor: GridColors.textPrimary,
        actions: [
          IconButton(
              tooltip: 'Atualizar',
              onPressed: _carregando ? null : _carregar,
              icon: const Icon(Icons.refresh)),
        ],
      ),
      body: LayoutBuilder(builder: (context, limites) {
        if (_todos == null) {
          return Center(
            child: _erro == null
                ? const CircularProgressIndicator(semanticsLabel: 'Conferindo cadastros')
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
              children: _blocos(largura),
            ),
          ),
        ]);
      }),
    );
  }

  Widget _cartao(String? titulo, List<Widget> filhos) => Card(
        color: GridColors.card,
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (titulo != null) ...[
              Semantics(
                header: true,
                child: Text(titulo,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold, color: GridColors.textSecondary)),
              ),
              const SizedBox(height: 8),
            ],
            ...filhos,
          ]),
        ),
      );

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

  Widget _contador(String titulo, String valor, String detalhe, IconData icone, Color cor) =>
      _cartao(null, [
        Row(children: [
          Icon(icone, color: cor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(titulo, style: const TextStyle(color: GridColors.textMuted)),
              Text(valor, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              Text(detalhe, style: const TextStyle(fontSize: 12, color: GridColors.textMuted)),
            ]),
          ),
        ]),
      ]);

  List<Widget> _blocos(double largura) {
    final aviso = _faixa(
        Icons.info,
        GridColors.info,
        GridColors.card,
        'Esta tela confere apenas o cadastro. Ela não transmite eventos nem consulta o eSocial ou outro '
        'órgão do governo. Passar na conferência não garante a aceitação do envio.');
    final erro = _erro == null
        ? null
        : _faixa(Icons.warning, GridColors.errorDark, GridColors.errorLight,
            '$_erro Exibindo os dados carregados antes.');
    if (_todos!.isEmpty) {
      return [aviso, if (erro != null) erro, _cartao(null, const [Text('Nenhum funcionário cadastrado.')])];
    }

    final recorte = _recorte;
    final semImpedimento = recorte.where((f) => _pendencias(f, 'impede').isEmpty).length;
    final soRevisar = recorte
        .where((f) => _pendencias(f, 'impede').isEmpty && _pendencias(f, 'revisar').isNotEmpty)
        .length;
    final contadores = [
      _contador(
          'Índice de cadastro',
          recorte.isEmpty ? 'Sem dados' : '${semImpedimento * 100 ~/ recorte.length}%',
          '$semImpedimento de ${recorte.length} sem impedimento',
          Icons.check_circle,
          GridColors.success),
      _contador('Com impedimento', '${recorte.length - semImpedimento}', 'corrigir antes do envio',
          Icons.error, GridColors.errorDark),
      _contador('Só revisar', '$soRevisar', 'não impedem o envio', Icons.warning,
          GridColors.warningDark),
    ];

    final verificacoes = _verificacoes(recorte);
    final funcionarios = _funcionarios(largura);
    return [
      aviso,
      if (erro != null) erro,
      _filtros(largura),
      if (largura >= 700)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (var i = 0; i < contadores.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: contadores[i]),
          ],
        ])
      else
        ...contadores,
      if (largura >= 1100)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 2, child: verificacoes),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: funcionarios),
        ])
      else ...[
        verificacoes,
        funcionarios,
      ],
    ];
  }

  Widget _filtros(double largura) {
    final contratantes = <int, String>{
      for (final f in _todos!)
        if (f['contratanteId'] != null) f['contratanteId'] as int: '${f['contratante']}',
    };
    final campo = largura < 700 ? largura - 52 : 250.0;
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
            onChanged: (v) => setState(() {
              aoMudar(v as T);
              _limite = 20;
            }),
          ),
        );
    final filtrado = _contratanteId != null ||
        _ativo != null ||
        _gravidade != _Gravidade.todas ||
        _busca.isNotEmpty ||
        _codigo != null;
    return _cartao(null, [
      Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
        lista<int?>('Empresa-cliente', _contratanteId,
            {null: 'Todas as empresas-clientes', ...contratantes}, (v) => _contratanteId = v),
        lista<bool?>('Situação', _ativo, const {null: 'Todos', true: 'Ativos', false: 'Inativos'},
            (v) => _ativo = v),
        lista<_Gravidade>('Gravidade', _gravidade,
            {for (final g in _Gravidade.values) g: g.rotulo}, (v) => _gravidade = v),
        SizedBox(
          width: campo,
          child: TextFormField(
            key: ValueKey('busca-${_busca.isEmpty}'),
            initialValue: _busca,
            decoration: const InputDecoration(
                labelText: 'Buscar funcionário', border: OutlineInputBorder(), isDense: true),
            onChanged: (v) => setState(() => _busca = v),
          ),
        ),
        if (filtrado)
          TextButton.icon(
            onPressed: () => setState(() {
              _contratanteId = null;
              _ativo = null;
              _gravidade = _Gravidade.todas;
              _busca = '';
              _codigo = null;
            }),
            icon: const Icon(Icons.filter_alt_off),
            label: const Text('Limpar filtros'),
          ),
      ]),
    ]);
  }

  Widget _verificacoes(List<_Json> recorte) {
    final linhas = <Widget>[];
    for (final grupo in _grupos) {
      final contagem = <String, int>{};
      final rotulos = <String, String>{};
      for (final f in recorte) {
        final vistos = <String>{};
        for (final p in _pendencias(f, grupo)) {
          final codigo = '${p['codigo']}';
          rotulos[codigo] = '${p['problema']}';
          if (vistos.add(codigo)) contagem.update(codigo, (n) => n + 1, ifAbsent: () => 1);
        }
      }
      if (contagem.isEmpty) continue;
      final impede = grupo == 'impede';
      linhas.add(Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(impede ? 'Impede o envio' : 'Revisar',
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ));
      for (final codigo in contagem.keys.toList()..sort((a, b) => contagem[b]!.compareTo(contagem[a]!))) {
        linhas.add(ListTile(
          contentPadding: EdgeInsets.zero,
          selected: _codigo == codigo,
          leading: Icon(impede ? Icons.error : Icons.warning,
              color: impede ? GridColors.errorDark : GridColors.warningDark),
          title: Text(rotulos[codigo]!),
          trailing: Text('${contagem[codigo]}', style: const TextStyle(fontWeight: FontWeight.bold)),
          onTap: () => setState(() => _codigo = _codigo == codigo ? null : codigo),
        ));
      }
    }
    return _cartao('Verificações', [
      if (linhas.isEmpty) const Text('Nenhuma pendência nas verificações desta tela.'),
      ...linhas,
    ]);
  }

  Widget _funcionarios(double largura) {
    final ranking = _ranking;
    return _cartao('Funcionários com pendência', [
      if (_codigo != null)
        Align(
          alignment: Alignment.centerLeft,
          child: InputChip(
              label: const Text('Mostrando a verificação escolhida'),
              onDeleted: () => setState(() => _codigo = null)),
        ),
      if (ranking.isEmpty) const Text('Nenhum funcionário corresponde aos filtros.'),
      for (final f in ranking.take(_limite))
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('${f['nome']}'),
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${f['contratante'] ?? 'Sem empresa-cliente'}'),
            const SizedBox(height: 4),
            Wrap(spacing: 6, runSpacing: 4, children: [
              if (_pendencias(f, 'impede').isNotEmpty)
                _selo('${_pendencias(f, 'impede').length} impeditiva(s)', Icons.error,
                    GridColors.errorDark, GridColors.errorLight),
              if (_pendencias(f, 'revisar').isNotEmpty)
                _selo('${_pendencias(f, 'revisar').length} revisar', Icons.warning,
                    GridColors.warningDark, GridColors.suggestionMedium),
            ]),
          ]),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _detalhe(f),
        ),
      if (ranking.length > _limite)
        TextButton(
            onPressed: () => setState(() => _limite += 20),
            child: Text('Ver mais (${ranking.length - _limite})')),
    ]);
  }

  Widget _selo(String texto, IconData icone, Color cor, Color fundo) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: fundo, border: Border.all(color: cor), borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icone, size: 16, color: cor),
          const SizedBox(width: 4),
          Text(texto, style: const TextStyle(fontSize: 12, color: GridColors.textSecondary)),
        ]),
      );

  Future<void> _detalhe(_Json f) => showDialog<void>(
        context: context,
        builder: (dialogo) => AlertDialog(
          title: Text('${f['nome']}'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${f['contratante'] ?? 'Sem empresa-cliente'}'),
                Text('CPF ${f['cpf']} · matrícula ${f['matricula'] ?? 'não informada'}'),
                for (final grupo in const ['impede', 'revisar'])
                  if (_pendencias(f, grupo).isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(grupo == 'impede' ? 'Impede o envio' : 'Revisar',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    for (final p in _pendencias(f, grupo))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(grupo == 'impede' ? Icons.error : Icons.warning,
                            color: grupo == 'impede' ? GridColors.errorDark : GridColors.warningDark),
                        title: Text('${p['campo']}: ${p['problema']}'),
                        subtitle: Text('${p['correcao']} (Cadastro do funcionário)'),
                      ),
                  ],
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogo), child: const Text('Fechar')),
          ],
        ),
      );
}
