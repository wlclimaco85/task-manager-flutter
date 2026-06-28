import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../utils/api_links.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/tenant_context.dart';
import '../../../widgets/generic_grid_windows_screen.dart' show CustomAction;
import 'details/nfe_detail_screen.dart';
import '../../../widgets/searchable_dropdown.dart';
import '../../utils/grid_texts.dart';

class MobileNfeGridScreen extends StatefulWidget {
  final bool entrada;
  const MobileNfeGridScreen({super.key, required this.entrada});
  @override
  State<MobileNfeGridScreen> createState() => _MobileNfeGridScreenState();
}

class _MobileNfeGridScreenState extends State<MobileNfeGridScreen> {
  final _numeroCtrl = TextEditingController();
  final _chaveCtrl = TextEditingController();
  String? _statusFiltro;
  DateTime? _dtNegIni, _dtNegFim;
  Map<String, dynamic> _filtros = {};
  int _gridKey = 0;
  bool _expandedFilters = false;

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
    _statusFiltro = null;
    _dtNegIni = null;
    _dtNegFim = null;
    _aplicarFiltros();
  }

  void _abrirNovo(BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MobileNfeSankhyaDetailScreen(item: {
            'tipoOperacao': widget.entrada ? 'ENTRADA' : 'SAIDA',
          }),
        )).then((_) => _aplicarFiltros());
  }

  @override
  Widget build(BuildContext context) {
    final titulo = widget.entrada ? 'NF-e Entrada' : 'NF-e Saída';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: GridColors.error,
        title: Row(
          children: [
            Icon(widget.entrada ? Icons.file_download : Icons.file_upload,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(titulo,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _abrirNovo(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Barra de filtros expansível ──────────────────────────────
          Container(
            color: GridColors.filterBackground,
            child: Column(
              children: [
                // Linha de atalhos rápidos
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 0,
                          child: SizedBox(
                            width: 120,
                            child: TextField(
                              controller: _numeroCtrl,
                              style: const TextStyle(fontSize: 12),
                              decoration: InputDecoration(
                                hintText: 'Nro',
                                hintStyle: const TextStyle(
                                    fontSize: 11, color: GridColors.divider),
                                filled: true,
                                fillColor: Colors.white,
                                isDense: true,
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 6),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: const BorderSide(
                                        color: GridColors.divider)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          flex: 0,
                          child: SizedBox(
                            width: 100,
                            child: ElevatedButton.icon(
                              onPressed: _aplicarFiltros,
                              icon: const Icon(Icons.search, size: 14),
                              label: const Text('Buscar',
                                  style: TextStyle(fontSize: 11)),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: GridColors.error,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          flex: 0,
                          child: SizedBox(
                            width: 80,
                            child: OutlinedButton.icon(
                              onPressed: () => setState(
                                  () => _expandedFilters = !_expandedFilters),
                              icon: Icon(
                                  _expandedFilters
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  size: 14),
                              label: const Text('Filtros',
                                  style: TextStyle(fontSize: 11)),
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: GridColors.divider,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Filtros expandidos
                if (_expandedFilters)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildDatePicker(
                                  'Data Início',
                                  _dtNegIni,
                                  (d) => setState(() => _dtNegIni = d)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildDatePicker(
                                  'Data Fim',
                                  _dtNegFim,
                                  (d) => setState(() => _dtNegFim = d)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _chaveCtrl,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'Chave NF-e',
                            hintStyle: const TextStyle(
                                fontSize: 11, color: GridColors.divider),
                            filled: true,
                            fillColor: Colors.white,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: const BorderSide(
                                    color: GridColors.divider)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SearchableDropdownField(
                          label: 'Status',
                          value: _statusFiltro,
                          items: ['PENDENTE', 'AUTORIZADA', 'CANCELADA', 'REJEITADA']
                              .map((o) =>
                                  <String, dynamic>{'id': o, 'nome': o})
                              .toList(),
                          valueField: 'id',
                          displayField: 'nome',
                          nullable: true,
                          nullLabel: 'Todos',
                          onChanged: (v) => setState(() => _statusFiltro = v),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _aplicarFiltros,
                                icon: const Icon(Icons.search, size: 14),
                                label: const Text('Aplicar',
                                    style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: GridColors.error,
                                    foregroundColor: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _limpar,
                                icon: const Icon(Icons.clear, size: 14),
                                label: const Text('Limpar',
                                    style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // ── Grid dinâmica ────────────────────────────────────────────
          Expanded(
            child: DynamicGridWindowsScreen<Map<String, dynamic>>(
              key: ValueKey(_gridKey),
              telaNome: 'nfe',
              hasPermission: (p) => p == 'create' ? false : true,
              fromJson: (json) => json,
              toJson: (a) => a,
              extraParams: _filtros,
              detailScreenBuilder: (item) =>
                  MobileNfeSankhyaDetailScreen(item: item),
              customActions: () => _buildCustomActions(context),
              showAppBar: false,
            ),
          ),
        ],
      ),
    );
  }

  List<CustomAction<Map<String, dynamic>>> _buildCustomActions(
      BuildContext ctx) {
    if (widget.entrada) {
      return [
        CustomAction<Map<String, dynamic>>(
          icon: Icons.upload_file,
          label: 'Importar XML',
          onPressed: (context, item) => _importarXml(context),
        ),
        CustomAction<Map<String, dynamic>>(
          icon: Icons.check_circle_outline,
          label: 'Aceitar',
          onPressed: (context, item) => _aceitar(context, item),
        ),
        CustomAction<Map<String, dynamic>>(
          icon: Icons.cancel_outlined,
          label: 'Recusar',
          onPressed: (context, item) => _recusar(context, item),
        ),
      ];
    } else {
      return [
        CustomAction<Map<String, dynamic>>(
          icon: Icons.send,
          label: 'Emitir',
          onPressed: (context, item) => _emitir(context, item),
        ),
        CustomAction<Map<String, dynamic>>(
          icon: Icons.cancel_outlined,
          label: 'Cancelar',
          onPressed: (context, item) => _cancelar(context, item),
        ),
        CustomAction<Map<String, dynamic>>(
          icon: Icons.print,
          label: 'DANFE',
          onPressed: (context, item) => _imprimirDanfe(context, item),
        ),
        CustomAction<Map<String, dynamic>>(
          icon: Icons.code,
          label: 'XML',
          onPressed: (context, item) => _baixarXml(context, item),
        ),
      ];
    }
  }

  // ── Ações NF-e SAÍDA ──────────────────────────────────────────────────────

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
            width: double.maxFinite,
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
            content: Text('Erro ${r.statusCode}'),
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
            content: Text('Erro ${r.statusCode}'),
            backgroundColor: GridColors.error));
      }
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro: $e'), backgroundColor: GridColors.error));
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

  Widget _buildDatePicker(String hint, DateTime? val, Function(DateTime?) cb) {
    return GestureDetector(
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
          Expanded(
            child: Text(
                val != null
                    ? '${val.day.toString().padLeft(2, '0')}/${val.month.toString().padLeft(2, '0')}'
                    : hint,
                style: TextStyle(
                    fontSize: 11,
                    color: val != null
                        ? GridColors.textSecondary
                        : GridColors.divider)),
          ),
        ]),
      ),
    );
  }
}
