import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../utils/api_links.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/fiscal_error_message.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/tenant_context.dart';
import '../../../widgets/generic_grid_windows_screen.dart'
    show CustomAction, BulkAction;
import 'details/nfe_detail_screen.dart';
import 'nfe_saida_create_screen.dart';
import '../../../widgets/searchable_dropdown.dart';
import '../../utils/grid_texts.dart';

class WebNfeGridScreen extends StatefulWidget {
  final bool entrada;
  const WebNfeGridScreen({super.key, required this.entrada});
  @override
  State<WebNfeGridScreen> createState() => _WebNfeGridScreenState();
}

List<Map<String, dynamic>> nfeHistoricoEventos(Map<String, dynamic> data) {
  final eventos = <Map<String, dynamic>>[];
  for (final key in const ['cancelamentos', 'cartasCorrecao', 'eventos']) {
    final raw = data[key];
    if (raw is! List) continue;
    for (final item in raw) {
      if (item is! Map) continue;
      eventos.add({
        'tipo': key == 'cartasCorrecao' ? 'Carta de Correção' : 'Cancelamento',
        ...Map<String, dynamic>.from(item),
      });
    }
  }
  return eventos;
}

class _WebNfeGridScreenState extends State<WebNfeGridScreen> {
  final _numeroCtrl = TextEditingController();
  final _chaveCtrl = TextEditingController();
  final _parceiroCtrl = TextEditingController();
  final _destCtrl = TextEditingController();
  String? _statusFiltro;
  DateTime? _dtNegIni, _dtNegFim, _dtMovIni, _dtMovFim;
  Map<String, dynamic> _filtros = {};
  int _gridKey = 0;

  @override
  void initState() {
    super.initState();
    _aplicarFiltros();
  }

  void _aplicarFiltros() {
    final f = <String, dynamic>{
      'tipoOperacao': widget.entrada ? 'ENTRADA' : 'SAIDA',
    };
    if (_numeroCtrl.text.isNotEmpty) f['numero'] = _numeroCtrl.text;
    if (_chaveCtrl.text.isNotEmpty) f['chave'] = _chaveCtrl.text;
    if (_statusFiltro != null) f['status'] = _statusFiltro!;
    if (_dtNegIni != null)
      f['dhEmiInicio'] = _dtNegIni!.toIso8601String().substring(0, 10);
    if (_dtNegFim != null)
      f['dhEmiFim'] = _dtNegFim!.toIso8601String().substring(0, 10);
    setState(() {
      _filtros = f;
      _gridKey++;
    });
  }

  void _limpar() {
    _numeroCtrl.clear();
    _chaveCtrl.clear();
    _parceiroCtrl.clear();
    _destCtrl.clear();
    _statusFiltro = null;
    _dtNegIni = null;
    _dtNegFim = null;
    _dtMovIni = null;
    _dtMovFim = null;
    _aplicarFiltros();
  }

  void _abrirNovo(BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NfeSankhyaDetailScreen(item: {
            'tipoOperacao': widget.entrada ? 'ENTRADA' : 'SAIDA',
          }),
        )).then((_) => _aplicarFiltros());
  }

  void _abrirNovoComTop(BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const NfeSaidaCreateScreen(),
        )).then((_) => _aplicarFiltros());
  }

  @override
  Widget build(BuildContext context) {
    final titulo = widget.entrada ? 'NF-e Entrada' : 'NF-e Saída';
    return Column(
      children: [
        // ── Header unificado — mesma cor e altura do header da grid ──────
        Container(
          height: 56,
          color: GridColors.error,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                widget.entrada ? Icons.file_download : Icons.file_upload,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                titulo,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // ── Conteúdo: filtros laterais + grid ────────────────────────────
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Painel de filtros lateral
              SizedBox(width: 200, child: _buildFiltros()),
              // Grid dinâmica sem AppBar próprio
              Expanded(
                child: DynamicGridWindowsScreen<Map<String, dynamic>>(
                  key: ValueKey(_gridKey),
                  telaNome: 'nfe',
                  hasPermission: (p) => p == 'create' ? false : true,
                  fromJson: (json) => json,
                  toJson: (a) => a,
                  extraParams: _filtros,
                  detailScreenBuilder: (item) =>
                      NfeSankhyaDetailScreen(item: item),
                  customActions: () => _buildCustomActions(context),
                  // Ações em massa só fazem sentido para NF-e de SAÍDA
                  // (emitida por nós). NF-e de ENTRADA é recebida de
                  // terceiros — o fluxo é Aceitar/Recusar, não
                  // cancelar/emitir/gerar PDF em lote, então o dropdown
                  // "Ações" fica de fora e a grid de entrada continua só
                  // com "Excluir selecionados".
                  bulkActions:
                      widget.entrada ? null : _buildBulkActions(context),
                  showAppBar: false,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Ações em massa (dropdown "Ações" ao lado de Excluir selecionados,
  // NF-e SAÍDA apenas) ────────────────────────────────────────────────────
  //
  // Decisão: não existe endpoint de lote no backend para PDF/cancelar/emitir
  // NF-e — cada ação chama o endpoint por-id já existente (mesmo usado pelas
  // ações individuais _cancelar/_emitir/_imprimirDanfe acima), item a item
  // num loop, agregando sucesso/falha num único SnackBar de resumo.
  // "Excluir" foi OMITIDO deste dropdown de propósito: o botão padrão
  // "Excluir selecionados" já cobre exclusão em massa e não deve ser
  // duplicado aqui.

  List<BulkAction<Map<String, dynamic>>> _buildBulkActions(
      BuildContext context) {
    return [
      BulkAction<Map<String, dynamic>>(
        icon: Icons.print,
        label: 'Gerar PDF',
        onPressed: _bulkGerarPdf,
      ),
      BulkAction<Map<String, dynamic>>(
        icon: Icons.send,
        label: 'Enviar',
        onPressed: _bulkEmitir,
      ),
      BulkAction<Map<String, dynamic>>(
        icon: Icons.cancel_outlined,
        label: 'Cancelar',
        isEnabled: (items) => items.every((i) =>
            (i['status']?.toString().toUpperCase() ?? '') != 'CANCELADA'),
        onPressed: _bulkCancelar,
      ),
    ];
  }

  /// Baixa o DANFE (`GET /api/nfe/{id}/danfe`) item a item — sem endpoint de
  /// lote no backend. Mesmo endpoint de `_imprimirDanfe`.
  Future<void> _bulkGerarPdf(
    BuildContext context,
    List<Map<String, dynamic>> items,
  ) async {
    var ok = 0;
    final falhas = <String>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final id = item['id']?.toString() ?? '';
      if (id.isEmpty) {
        falhas.add('item sem id');
        continue;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(
            content: Text('Gerando PDF ${i + 1} de ${items.length}...'),
            duration: const Duration(seconds: 2),
          ));
      }
      try {
        final r = await TenantContext.get(ApiLinks.danfeNfe(id));
        if (r.statusCode == 200) {
          await FileSaver.instance.saveFile(
            name: 'danfe_$id',
            bytes: r.bodyBytes,
            fileExtension: 'pdf',
          );
          ok++;
        } else {
          falhas.add('#$id (${fiscalErrorMessage(r.statusCode, r.body)})');
          AppLogger.i.warn(
              'Ação em massa "Gerar PDF" NF-e #$id falhou: status ${r.statusCode}');
        }
      } catch (e, st) {
        falhas.add('#$id ($e)');
        AppLogger.i.error('Ação em massa "Gerar PDF" NF-e #$id: $e', st);
      }
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(falhas.isEmpty
            ? '$ok PDF(s) gerado(s) com sucesso'
            : '$ok gerado(s), ${falhas.length} falharam: ${falhas.join(', ')}'),
        backgroundColor:
            falhas.isEmpty ? GridColors.success : GridColors.error,
      ));
  }

  /// Emite (`POST /api/nfe/{id}/emitir`) item a item — mesmo endpoint de
  /// `_emitir`, geração/assinatura de XML real, sem endpoint de lote.
  Future<void> _bulkEmitir(
    BuildContext context,
    List<Map<String, dynamic>> items,
  ) async {
    var ok = 0;
    final falhas = <String>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final id = item['id']?.toString() ?? '';
      if (id.isEmpty) {
        falhas.add('item sem id');
        continue;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(
            content: Text('Emitindo ${i + 1} de ${items.length}...'),
            duration: const Duration(seconds: 2),
          ));
      }
      try {
        final r = await TenantContext.post(ApiLinks.emitirNfe(id), {});
        if (r.statusCode == 200 || r.statusCode == 201) {
          ok++;
        } else {
          String msg = 'status ${r.statusCode}';
          try {
            final body = jsonDecode(r.body);
            msg = body['message']?.toString() ??
                body['mensagem']?.toString() ??
                body['error']?.toString() ??
                msg;
          } catch (_) {}
          falhas.add('#$id ($msg)');
          AppLogger.i
              .warn('Ação em massa "Enviar" NF-e #$id falhou: $msg');
        }
      } catch (e, st) {
        falhas.add('#$id ($e)');
        AppLogger.i.error('Ação em massa "Enviar" NF-e #$id: $e', st);
      }
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(falhas.isEmpty
            ? '$ok NF-e(s) emitida(s) com sucesso'
            : '$ok emitida(s), ${falhas.length} falharam: ${falhas.join(', ')}'),
        backgroundColor:
            falhas.isEmpty ? GridColors.success : GridColors.error,
      ));
  }

  /// Cancela (`POST /api/nfe/{id}/cancelar`) item a item, pedindo a
  /// justificativa (mín. 15 caracteres) UMA ÚNICA VEZ — mesma regra e
  /// endpoint de `_cancelar`.
  Future<void> _bulkCancelar(
    BuildContext context,
    List<Map<String, dynamic>> items,
  ) async {
    final motivoCtrl = TextEditingController();
    final motivo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cancelar ${items.length} NF-e(s)',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 360,
          child: TextField(
            controller: motivoCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Motivo do cancelamento *',
              labelStyle: TextStyle(fontSize: 12),
              border: OutlineInputBorder(),
              isDense: true,
              hintText: 'Mínimo 15 caracteres — aplicado a todas selecionadas',
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(GridTexts.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.error,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, motivoCtrl.text.trim()),
            child: const Text('Cancelar NF-e(s)'),
          ),
        ],
      ),
    );
    motivoCtrl.dispose();
    if (motivo == null || !context.mounted) return;
    if (motivo.length < 15) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Motivo deve ter pelo menos 15 caracteres'),
          backgroundColor: GridColors.error));
      return;
    }

    var ok = 0;
    final falhas = <String>[];
    for (final item in items) {
      final id = item['id']?.toString() ?? '';
      if (id.isEmpty) {
        falhas.add('item sem id');
        continue;
      }
      try {
        final r = await TenantContext.post(
            ApiLinks.cancelarNfe(id), {'justificativa': motivo});
        if (r.statusCode == 200) {
          ok++;
        } else {
          falhas.add('#$id (status ${r.statusCode})');
          AppLogger.i.warn(
              'Ação em massa "Cancelar" NF-e #$id falhou: status ${r.statusCode} - ${r.body}');
        }
      } catch (e, st) {
        falhas.add('#$id ($e)');
        AppLogger.i.error('Ação em massa "Cancelar" NF-e #$id: $e', st);
      }
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(falhas.isEmpty
          ? '$ok NF-e(s) cancelada(s) com sucesso'
          : '$ok cancelada(s), ${falhas.length} falharam: ${falhas.join(', ')}'),
      backgroundColor: falhas.isEmpty ? GridColors.success : GridColors.error,
    ));
  }

  List<CustomAction<Map<String, dynamic>>> _buildCustomActions(
      BuildContext ctx) {
    if (widget.entrada) {
      return [
        CustomAction<Map<String, dynamic>>(
          icon: Icons.manage_search,
          label: "Consultar status",
          onPressed: (context, item) => _consultarStatus(context, item),
        ),
        CustomAction<Map<String, dynamic>>(
          icon: Icons.upload_file,
          label: "Importar XML",
          onPressed: (context, item) => _importarXml(context),
        ),
        CustomAction<Map<String, dynamic>>(
          icon: Icons.check_circle_outline,
          label: "Aceitar",
          onPressed: (context, item) => _aceitar(context, item),
        ),
        CustomAction<Map<String, dynamic>>(
          icon: Icons.cancel_outlined,
          label: "Recusar",
          onPressed: (context, item) => _recusar(context, item),
        ),
        CustomAction<Map<String, dynamic>>(
          icon: Icons.print,
          label: "DANFE",
          onPressed: (context, item) => _imprimirDanfe(context, item),
        ),
        CustomAction<Map<String, dynamic>>(
          icon: Icons.code,
          label: "XML",
          onPressed: (context, item) => _baixarXml(context, item),
        ),
      ];
    }
    return [
      CustomAction<Map<String, dynamic>>(
        icon: Icons.manage_search,
        label: "Consultar status",
        onPressed: (context, item) => _consultarStatus(context, item),
      ),
      CustomAction<Map<String, dynamic>>(
        icon: Icons.send,
        label: "Emitir",
        onPressed: (context, item) => _emitir(context, item),
      ),
      CustomAction<Map<String, dynamic>>(
        icon: Icons.cancel_outlined,
        label: "Cancelar",
        onPressed: (context, item) => _cancelar(context, item),
      ),
      CustomAction<Map<String, dynamic>>(
        icon: Icons.edit_note,
        label: "Carta de Correção",
        onPressed: (context, item) => _emitirCce(context, item),
      ),
      CustomAction<Map<String, dynamic>>(
        icon: Icons.history,
        label: "Histórico de eventos",
        onPressed: (context, item) => _historicoEventos(context, item),
      ),
      CustomAction<Map<String, dynamic>>(
        icon: Icons.print,
        label: "Imprimir DANFE",
        onPressed: (context, item) => _imprimirDanfe(context, item),
      ),
      CustomAction<Map<String, dynamic>>(
        icon: Icons.code,
        label: "Exportar XML",
        onPressed: (context, item) => _baixarXml(context, item),
      ),
    ];
  }
  // ── Ações NF-e SAÍDA ──────────────────────────────────────────────────────

  Future<void> _consultarStatus(
      BuildContext context, Map<String, dynamic> item) async {
    final id = item['id']?.toString() ?? '';
    if (id.isEmpty) return;
    try {
      final r = await TenantContext.get(ApiLinks.nfeById(id));
      if (!context.mounted) return;
      if (r.statusCode == 200) {
        final body = jsonDecode(r.body);
        final data = body is Map<String, dynamic>
            ? (body['dados'] is Map<String, dynamic>
                ? body['dados'] as Map<String, dynamic>
                : body)
            : <String, dynamic>{'retorno': body.toString()};
        _showDataDialog(context, 'Status NF-e', {
          'id': data['id'] ?? id,
          'numero': data['numero'] ?? item['numero'] ?? '-',
          'serie': data['serie'] ?? item['serie'] ?? '-',
          'status': data['status'] ?? item['status'] ?? '-',
          'chave': data['chave'] ?? item['chave'] ?? '-',
          'protocolo': data['protocolo'] ?? item['protocolo'] ?? '-',
          'motivo': data['motivoRejeicao'] ?? data['motivo'] ?? '-',
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ${r.statusCode}: ${r.body}'),
            backgroundColor: GridColors.error));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro: $e'), backgroundColor: GridColors.error));
      }
    }
  }

  Future<void> _cancelar(
      BuildContext context, Map<String, dynamic> item) async {
    final id = item['id']?.toString() ?? '';
    final motivoCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar NF-e',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: SizedBox(
            width: 360,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('NF-e #$id — ${item['numero'] ?? ''}',
                  style:
                      const TextStyle(fontSize: 12, color: GridColors.divider)),
              const SizedBox(height: 12),
              TextField(
                controller: motivoCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Motivo do cancelamento *',
                  labelStyle: TextStyle(fontSize: 12),
                  border: OutlineInputBorder(),
                  isDense: true,
                  hintText: 'Mínimo 15 caracteres',
                ),
              ),
            ])),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Voltar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.error,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar NF-e'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    if (motivoCtrl.text.trim().length < 15) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Motivo deve ter pelo menos 15 caracteres'),
          backgroundColor: GridColors.error));
      return;
    }
    try {
      final r = await TenantContext.post(
          ApiLinks.cancelarNfe(id), {'justificativa': motivoCtrl.text.trim()});
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(r.statusCode == 200
              ? 'NF-e cancelada com sucesso!'
              : 'Erro ${r.statusCode}: ${r.body}'),
          backgroundColor:
              r.statusCode == 200 ? GridColors.success : GridColors.error));
      if (r.statusCode == 200) setState(() => _gridKey++);
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro: $e'), backgroundColor: GridColors.error));
    }
  }

  Future<void> _emitir(BuildContext context, Map<String, dynamic> item) async {
    final id = item['id']?.toString() ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Emitir NF-e',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Text('Confirma a emissão da NF-e #$id?',
            style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(GridTexts.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.success,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Emitir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      // NF08: usa POST /api/nfe/{id}/emitir (geração de XML real e assinatura digital)
      final r = await TenantContext.post(ApiLinks.emitirNfe(id), {});
      if (!context.mounted) return;
      if (r.statusCode == 200 || r.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('NF-e emitida com sucesso! XML gerado e assinado.'),
            backgroundColor: GridColors.success));
        setState(() => _gridKey++);
      } else {
        String msg = 'Erro ${r.statusCode}';
        try {
          final body = jsonDecode(r.body);
          msg = body['message']?.toString() ??
              body['mensagem']?.toString() ??
              body['error']?.toString() ??
              msg;
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: GridColors.error));
      }
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro: $e'), backgroundColor: GridColors.error));
    }
  }

  Future<void> _imprimirDanfe(
      BuildContext context, Map<String, dynamic> item) async {
    final id = item['id']?.toString() ?? '';
    try {
      final r = await TenantContext.get(ApiLinks.danfeNfe(id));
      if (!context.mounted) return;
      if (r.statusCode == 200) {
        await FileSaver.instance.saveFile(
          name: 'danfe_$id',
          bytes: r.bodyBytes,
          fileExtension: 'pdf',
        );
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('DANFE baixado!'),
            backgroundColor: GridColors.success));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(fiscalErrorMessage(r.statusCode, r.body)),
            backgroundColor: GridColors.error));
      }
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro: $e'), backgroundColor: GridColors.error));
    }
  }

  Future<void> _baixarXml(
      BuildContext context, Map<String, dynamic> item) async {
    final id = item['id']?.toString() ?? '';
    try {
      final r = await TenantContext.get(ApiLinks.xmlNfe(id));
      if (!context.mounted) return;
      if (r.statusCode == 200) {
        await FileSaver.instance.saveFile(
          name: 'nfe_$id',
          bytes: Uint8List.fromList(r.body.codeUnits),
          fileExtension: 'xml',
        );
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('XML baixado!'),
            backgroundColor: GridColors.success));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(fiscalErrorMessage(r.statusCode, r.body)),
            backgroundColor: GridColors.error));
      }
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro: $e'), backgroundColor: GridColors.error));
    }
  }

  Future<void> _emitirCce(
      BuildContext context, Map<String, dynamic> item) async {
    final id = item['id']?.toString() ?? '';
    final correcaoCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Carta de Correção NF-e',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: correcaoCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Correção *',
              border: OutlineInputBorder(),
              isDense: true,
              hintText: 'Mínimo 15 caracteres',
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Voltar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.success,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enviar CC-e'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    if (correcaoCtrl.text.trim().length < 15) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Correção deve ter pelo menos 15 caracteres'),
          backgroundColor: GridColors.error));
      return;
    }
    try {
      final r = await TenantContext.post(ApiLinks.cancelamentoNfeCce(id),
          {'correcao': correcaoCtrl.text.trim()});
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(r.statusCode == 200
              ? 'CC-e enviada com sucesso!'
              : 'Erro ${r.statusCode}: ${r.body}'),
          backgroundColor:
              r.statusCode == 200 ? GridColors.success : GridColors.error));
      if (r.statusCode == 200) setState(() => _gridKey++);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro: $e'), backgroundColor: GridColors.error));
      }
    }
  }

  Future<void> _historicoEventos(
      BuildContext context, Map<String, dynamic> item) async {
    final id = item['id']?.toString() ?? '';
    if (id.isEmpty) return;
    try {
      final r = await TenantContext.get(ApiLinks.cancelamentoNfeHistorico(id));
      if (!context.mounted) return;
      if (r.statusCode == 200) {
        final body = jsonDecode(r.body);
        _showHistoricoEventosDialog(
          context,
          'Histórico de eventos NF-e',
          body is Map<String, dynamic> ? body : {'eventos': body.toString()},
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ${r.statusCode}: ${r.body}'),
            backgroundColor: GridColors.error));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro: $e'), backgroundColor: GridColors.error));
      }
    }
  }

  // ── Ações NF-e ENTRADA ────────────────────────────────────────────────────

  Future<void> _importarXml(BuildContext context) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xml'],
      withData: true,
    );
    if (result == null || result.files.isEmpty || !context.mounted) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    try {
      final r = await TenantContext.postMultipart(
        '${ApiLinks.baseUrl}/api/nfe/entrada/import',
        fileBytes: file.bytes!,
        fileName: file.name,
        fileField: 'xml',
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(r.statusCode == 200
              ? 'XML importado com sucesso!'
              : 'Erro ${r.statusCode}: ${r.body}'),
          backgroundColor:
              r.statusCode == 200 ? GridColors.success : GridColors.error));
      if (r.statusCode == 200) setState(() => _gridKey++);
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro: $e'), backgroundColor: GridColors.error));
    }
  }

  Future<void> _aceitar(BuildContext context, Map<String, dynamic> item) async {
    final id = item['id']?.toString() ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Aceitar NF-e',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Text('Confirma o aceite da NF-e #$id?',
            style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(GridTexts.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.success,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Aceitar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      final r = await TenantContext.post(ApiLinks.aceitarNfe(id), {});
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              r.statusCode == 200 ? 'NF-e aceita!' : 'Erro ${r.statusCode}'),
          backgroundColor:
              r.statusCode == 200 ? GridColors.success : GridColors.error));
      if (r.statusCode == 200) setState(() => _gridKey++);
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro: $e'), backgroundColor: GridColors.error));
    }
  }

  Future<void> _recusar(BuildContext context, Map<String, dynamic> item) async {
    final id = item['id']?.toString() ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Recusar NF-e',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Text('Confirma a recusa da NF-e #$id?',
            style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(GridTexts.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.error,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Recusar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      final r = await TenantContext.post(ApiLinks.recusarNfe(id), {});
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              r.statusCode == 200 ? 'NF-e recusada!' : 'Erro ${r.statusCode}'),
          backgroundColor:
              r.statusCode == 200 ? GridColors.success : GridColors.error));
      if (r.statusCode == 200) setState(() => _gridKey++);
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro: $e'), backgroundColor: GridColors.error));
    }
  }

  Future<void> _exportarXmlLote(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Para exportar o XML de uma nota, abra a nota e clique em "XML" no cabeçalho.'),
        duration: Duration(seconds: 4),
      ),
    );
  }

  Future<void> _importarReceita(BuildContext context) async {
    DateTime? dataIni = DateTime.now().subtract(const Duration(days: 30));
    DateTime? dataFim = DateTime.now();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Importar da Receita Federal',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          content: SizedBox(
              width: 340,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Selecione o período para importar NF-e:',
                    style: TextStyle(fontSize: 12, color: GridColors.divider)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: _dpDialog(ctx, dataIni, 'Data Início',
                          (d) => setS(() => dataIni = d))),
                  const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('até', style: TextStyle(fontSize: 12))),
                  Expanded(
                      child: _dpDialog(ctx, dataFim, 'Data Fim',
                          (d) => setS(() => dataFim = d))),
                ]),
              ])),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(GridTexts.cancel)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: GridColors.success,
                  foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Importar'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      final ini = dataIni?.toIso8601String().substring(0, 10) ?? '';
      final fim = dataFim?.toIso8601String().substring(0, 10) ?? '';
      final r = await TenantContext.post(
          '${ApiLinks.baseUrl}/api/nfe/receita/importar?dataInicio=$ini&dataFim=$fim',
          {});
      if (!context.mounted) return;
      final body = jsonDecode(r.body);
      final total = body['response']?['total'] ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(r.statusCode == 200
              ? 'Importação concluída: $total nota(s) importada(s)'
              : 'Erro ${r.statusCode}'),
          backgroundColor:
              r.statusCode == 200 ? GridColors.success : GridColors.error));
      if (r.statusCode == 200) setState(() => _gridKey++);
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro: $e'), backgroundColor: GridColors.error));
    }
  }

  Widget _dpDialog(BuildContext context, DateTime? val, String hint,
          void Function(DateTime?) cb) =>
      GestureDetector(
          onTap: () async {
            final d = await showDatePicker(
                context: context,
                initialDate: val ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030));
            cb(d);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: GridColors.divider)),
            child: Row(children: [
              const Icon(Icons.calendar_today,
                  size: 12, color: GridColors.divider),
              const SizedBox(width: 4),
              Text(
                  val != null
                      ? '${val.day.toString().padLeft(2, '0')}/${val.month.toString().padLeft(2, '0')}/${val.year}'
                      : hint,
                  style: TextStyle(
                      fontSize: 11,
                      color: val != null
                          ? GridColors.textSecondary
                          : GridColors.divider)),
            ]),
          ));

  Widget _buildFiltros() {
    return Container(
      color: GridColors.filterBackground,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _lbl('Data de Negociação'),
          _dateRange(
              _dtNegIni,
              _dtNegFim,
              (s, e) => setState(() {
                    _dtNegIni = s;
                    _dtNegFim = e;
                  })),
          const SizedBox(height: 8),
          _lbl('Data do Movimento'),
          _dateRange(
              _dtMovIni,
              _dtMovFim,
              (s, e) => setState(() {
                    _dtMovIni = s;
                    _dtMovFim = e;
                  })),
          const SizedBox(height: 8),
          _lbl('Número da Nota'),
          _inp(_numeroCtrl, 'Nro. Nota'),
          const SizedBox(height: 8),
          _lbl('Chave de Acesso'),
          _inp(_chaveCtrl, 'Chave NF-e'),
          const SizedBox(height: 8),
          _lbl('Parceiro'),
          _inp(_parceiroCtrl, 'Nome do parceiro'),
          const SizedBox(height: 8),
          _lbl('Destinatário'),
          _inp(_destCtrl, 'Nome do destinatário'),
          const SizedBox(height: 8),
          _lbl('Status'),
          _drop(
              _statusFiltro,
              ['PENDENTE', 'AUTORIZADA', 'CANCELADA', 'REJEITADA'],
              (v) => setState(() => _statusFiltro = v)),
          const SizedBox(height: 12),
          SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _abrirNovo(context),
                icon: const Icon(Icons.add, size: 14),
                label:
                    const Text('+ Nova NF-e', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8)),
              )),
          const SizedBox(height: 6),
          if (!widget.entrada) ...[
            SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _abrirNovoComTop(context),
                  icon: const Icon(Icons.add_circle_outline, size: 14),
                  label: const Text('+ Nova c/ TOP',
                      style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8)),
                )),
            const SizedBox(height: 6),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _exportarXmlLote(context),
                  icon: const Icon(Icons.code, size: 14),
                  label: const Text('Exportar XML',
                      style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8)),
                )),
            const SizedBox(height: 6),
          ],
          if (widget.entrada) ...[
            SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _importarReceita(context),
                  icon: const Icon(Icons.cloud_download, size: 14),
                  label: const Text('Importar Receita',
                      style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8)),
                )),
            const SizedBox(height: 6),
          ],
          SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _aplicarFiltros,
                icon: const Icon(Icons.search, size: 14),
                label: const Text('Filtrar', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8)),
              )),
          const SizedBox(height: 6),
          SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _limpar,
                icon: const Icon(Icons.clear, size: 14),
                label: const Text('Limpar', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                    foregroundColor: GridColors.divider,
                    padding: const EdgeInsets.symmetric(vertical: 8)),
              )),
        ]),
      ),
    );
  }

  Widget _lbl(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(t,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: GridColors.textSecondary)));

  Widget _inp(TextEditingController c, String h) => TextField(
      controller: c,
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
          hintText: h,
          hintStyle: const TextStyle(fontSize: 11, color: GridColors.divider),
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: GridColors.divider)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: GridColors.divider))));

  Widget _drop(String? val, List<String> opts, void Function(String?) cb) =>
      SearchableDropdownField(
        label: '',
        value: val,
        items: opts.map((o) => <String, dynamic>{'id': o, 'nome': o}).toList(),
        valueField: 'id',
        displayField: 'nome',
        nullable: true,
        nullLabel: 'Todos',
        hintText: 'Todos',
        onChanged: cb,
      );

  Widget _dateRange(DateTime? ini, DateTime? fim,
          void Function(DateTime?, DateTime?) cb) =>
      Row(children: [
        Expanded(child: _dp(ini, 'Início', (d) => cb(d, fim))),
        const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text('a', style: TextStyle(fontSize: 11))),
        Expanded(child: _dp(fim, 'Fim', (d) => cb(ini, d))),
      ]);

  Widget _dp(DateTime? val, String hint, void Function(DateTime?) cb) =>
      GestureDetector(
        onTap: () async {
          final d = await showDatePicker(
              context: context,
              initialDate: val ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030));
          cb(d);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: GridColors.divider),
          ),
          child: Row(children: [
            const Icon(Icons.calendar_today,
                size: 10, color: GridColors.divider),
            const SizedBox(width: 3),
            Text(
              val != null
                  ? '${val.day.toString().padLeft(2, '0')}/${val.month.toString().padLeft(2, '0')}'
                  : hint,
              style: TextStyle(
                fontSize: 10,
                color:
                    val != null ? GridColors.textSecondary : GridColors.divider,
              ),
            ),
          ]),
        ),
      );

  void _showDataDialog(
    BuildContext context,
    String title,
    Map<String, dynamic> data,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: data.entries
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text('${e.key}: ${e.value}'),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showHistoricoEventosDialog(
    BuildContext context,
    String title,
    Map<String, dynamic> data,
  ) {
    final eventos = nfeHistoricoEventos(data);
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eventos.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAF8),
                      border: Border.all(color: GridColors.divider),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Nenhum evento registrado para esta NF-e.',
                      style: TextStyle(color: GridColors.textSecondary),
                    ),
                  )
                else
                  ...eventos.map(_eventTile),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _eventTile(Map<String, dynamic> evento) {
    String firstOf(List<String> keys) {
      for (final key in keys) {
        final value = evento[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
      return '-';
    }

    final tipo = firstOf(['tipo', 'evento', 'descricao']);
    final data = firstOf(['dataEvento', 'data', 'createdAt', 'dhEvento']);
    final protocolo = firstOf(['protocolo', 'protocoloEvento', 'nProt']);
    final motivo =
        firstOf(['motivo', 'justificativa', 'correcao', 'xCorrecao']);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: GridColors.divider),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.history, size: 16, color: GridColors.secondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(tipo,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: GridColors.textPrimary)),
            ),
            Text(data,
                style: const TextStyle(
                    fontSize: 12, color: GridColors.textSecondary)),
          ]),
          const SizedBox(height: 6),
          Text('Protocolo: $protocolo',
              style: const TextStyle(
                  fontSize: 12, color: GridColors.textSecondary)),
          if (motivo != '-')
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(motivo, style: const TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
