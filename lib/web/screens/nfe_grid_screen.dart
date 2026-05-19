import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../utils/api_links.dart';
import '../../../utils/tenant_context.dart';
import '../../../widgets/generic_grid_windows_screen.dart' show CustomAction;
import 'details/nfe_detail_screen.dart';
import '../../../widgets/searchable_dropdown.dart';

const _red   = Color(0xFF93070A);
const _green = Color(0xFF005826);
const _side  = Color(0xFFF0F0F0);
const _bord  = Color(0xFFDDDDDD);
const _grey  = Color(0xFF757575);
const _dark  = Color(0xFF212121);

class WebNfeGridScreen extends StatefulWidget {
  final bool entrada;
  const WebNfeGridScreen({super.key, required this.entrada});
  @override
  State<WebNfeGridScreen> createState() => _WebNfeGridScreenState();
}

class _WebNfeGridScreenState extends State<WebNfeGridScreen> {
  final _numeroCtrl   = TextEditingController();
  final _chaveCtrl    = TextEditingController();
  final _parceiroCtrl = TextEditingController();
  final _destCtrl     = TextEditingController();
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
    if (_dtNegIni != null) f['dhEmiInicio'] = _dtNegIni!.toIso8601String().substring(0, 10);
    if (_dtNegFim != null) f['dhEmiFim'] = _dtNegFim!.toIso8601String().substring(0, 10);
    setState(() { _filtros = f; _gridKey++; });
  }

  void _limpar() {
    _numeroCtrl.clear(); _chaveCtrl.clear(); _parceiroCtrl.clear(); _destCtrl.clear();
    _statusFiltro = null; _dtNegIni = null; _dtNegFim = null; _dtMovIni = null; _dtMovFim = null;
    _aplicarFiltros();
  }

  void _abrirNovo(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => NfeSankhyaDetailScreen(item: {
        'tipoOperacao': widget.entrada ? 'ENTRADA' : 'SAIDA',
      }),
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
          color: _red,
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
                  showAppBar: false,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<CustomAction<Map<String, dynamic>>> _buildCustomActions(BuildContext ctx) {
    if (widget.entrada) {
      // NF-e ENTRADA
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
      // NF-e SAÍDA
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
          label: 'Imprimir DANFE',
          onPressed: (context, item) => _imprimirDanfe(context, item),
        ),
        CustomAction<Map<String, dynamic>>(
          icon: Icons.code,
          label: 'Exportar XML',
          onPressed: (context, item) => _baixarXml(context, item),
        ),
      ];
    }
  }

  // ── Ações NF-e SAÍDA ──────────────────────────────────────────────────────

  Future<void> _cancelar(BuildContext context, Map<String, dynamic> item) async {
    final id = item['id']?.toString() ?? '';
    final motivoCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar NF-e', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: SizedBox(width: 360, child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('NF-e #$id — ${item['numero'] ?? ''}', style: const TextStyle(fontSize: 12, color: _grey)),
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Voltar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar NF-e'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    if (motivoCtrl.text.trim().length < 15) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Motivo deve ter pelo menos 15 caracteres'), backgroundColor: _red));
      return;
    }
    try {
      final r = await TenantContext.post(ApiLinks.cancelarNfe(id), {'justificativa': motivoCtrl.text.trim()});
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(r.statusCode == 200 ? 'NF-e cancelada com sucesso!' : 'Erro ${r.statusCode}: ${r.body}'),
        backgroundColor: r.statusCode == 200 ? _green : _red));
      if (r.statusCode == 200) setState(() => _gridKey++);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
    }
  }

  Future<void> _emitir(BuildContext context, Map<String, dynamic> item) async {
    final id = item['id']?.toString() ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Emitir NF-e', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Text('Confirma a emissão da NF-e #$id?', style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white),
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
          backgroundColor: _green));
        setState(() => _gridKey++);
      } else {
        String msg = 'Erro ${r.statusCode}';
        try {
          final body = jsonDecode(r.body);
          msg = body['message']?.toString() ?? body['mensagem']?.toString() ?? body['error']?.toString() ?? msg;
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: _red));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
    }
  }

  Future<void> _imprimirDanfe(BuildContext context, Map<String, dynamic> item) async {
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('DANFE baixado!'), backgroundColor: _green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ${r.statusCode}'), backgroundColor: _red));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
    }
  }

  Future<void> _baixarXml(BuildContext context, Map<String, dynamic> item) async {
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('XML baixado!'), backgroundColor: _green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ${r.statusCode}'), backgroundColor: _red));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
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
        content: Text(r.statusCode == 200 ? 'XML importado com sucesso!' : 'Erro ${r.statusCode}: ${r.body}'),
        backgroundColor: r.statusCode == 200 ? _green : _red));
      if (r.statusCode == 200) setState(() => _gridKey++);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
    }
  }

  Future<void> _aceitar(BuildContext context, Map<String, dynamic> item) async {
    final id = item['id']?.toString() ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Aceitar NF-e', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Text('Confirma o aceite da NF-e #$id?', style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white),
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
        content: Text(r.statusCode == 200 ? 'NF-e aceita!' : 'Erro ${r.statusCode}'),
        backgroundColor: r.statusCode == 200 ? _green : _red));
      if (r.statusCode == 200) setState(() => _gridKey++);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
    }
  }

  Future<void> _recusar(BuildContext context, Map<String, dynamic> item) async {
    final id = item['id']?.toString() ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Recusar NF-e', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Text('Confirma a recusa da NF-e #$id?', style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _red, foregroundColor: Colors.white),
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
        content: Text(r.statusCode == 200 ? 'NF-e recusada!' : 'Erro ${r.statusCode}'),
        backgroundColor: r.statusCode == 200 ? _green : _red));
      if (r.statusCode == 200) setState(() => _gridKey++);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
    }
  }

  Future<void> _exportarXmlLote(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Para exportar o XML de uma nota, abra a nota e clique em "XML" no cabeçalho.'),
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
          title: const Text('Importar da Receita Federal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          content: SizedBox(width: 340, child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Selecione o período para importar NF-e:', style: TextStyle(fontSize: 12, color: _grey)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _dpDialog(ctx, dataIni, 'Data Início', (d) => setS(() => dataIni = d))),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('até', style: TextStyle(fontSize: 12))),
              Expanded(child: _dpDialog(ctx, dataFim, 'Data Fim', (d) => setS(() => dataFim = d))),
            ]),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white),
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
      final r = await TenantContext.post('${ApiLinks.baseUrl}/api/nfe/receita/importar?dataInicio=$ini&dataFim=$fim', {});
      if (!context.mounted) return;
      final body = jsonDecode(r.body);
      final total = body['response']?['total'] ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(r.statusCode == 200 ? 'Importação concluída: $total nota(s) importada(s)' : 'Erro ${r.statusCode}'),
        backgroundColor: r.statusCode == 200 ? _green : _red));
      if (r.statusCode == 200) setState(() => _gridKey++);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
    }
  }

  Widget _dpDialog(BuildContext context, DateTime? val, String hint, void Function(DateTime?) cb) =>
    GestureDetector(
      onTap: () async {
        final d = await showDatePicker(context: context, initialDate: val ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
        cb(d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: _bord)),
        child: Row(children: [
          const Icon(Icons.calendar_today, size: 12, color: _grey), const SizedBox(width: 4),
          Text(val != null ? '${val.day.toString().padLeft(2,'0')}/${val.month.toString().padLeft(2,'0')}/${val.year}' : hint,
              style: TextStyle(fontSize: 11, color: val != null ? _dark : _grey)),
        ]),
      ));

  Widget _buildFiltros() {
    return Container(
      color: _side,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _lbl('Data de Negociação'),
          _dateRange(_dtNegIni, _dtNegFim, (s, e) => setState(() { _dtNegIni = s; _dtNegFim = e; })),
          const SizedBox(height: 8),
          _lbl('Data do Movimento'),
          _dateRange(_dtMovIni, _dtMovFim, (s, e) => setState(() { _dtMovIni = s; _dtMovFim = e; })),
          const SizedBox(height: 8),
          _lbl('Número da Nota'), _inp(_numeroCtrl, 'Nro. Nota'),
          const SizedBox(height: 8),
          _lbl('Chave de Acesso'), _inp(_chaveCtrl, 'Chave NF-e'),
          const SizedBox(height: 8),
          _lbl('Parceiro'), _inp(_parceiroCtrl, 'Nome do parceiro'),
          const SizedBox(height: 8),
          _lbl('Destinatário'), _inp(_destCtrl, 'Nome do destinatário'),
          const SizedBox(height: 8),
          _lbl('Status'),
          _drop(_statusFiltro, ['PENDENTE','AUTORIZADA','CANCELADA','REJEITADA'],
              (v) => setState(() => _statusFiltro = v)),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            onPressed: () => _abrirNovo(context),
            icon: const Icon(Icons.add, size: 14),
            label: const Text('+ Nova NF-e', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 8)),
          )),
          const SizedBox(height: 6),
          if (!widget.entrada) ...[
            SizedBox(width: double.infinity, child: ElevatedButton.icon(
              onPressed: () => _exportarXmlLote(context),
              icon: const Icon(Icons.code, size: 14),
              label: const Text('Exportar XML', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 8)),
            )),
            const SizedBox(height: 6),
          ],
          if (widget.entrada) ...[
            SizedBox(width: double.infinity, child: ElevatedButton.icon(
              onPressed: () => _importarReceita(context),
              icon: const Icon(Icons.cloud_download, size: 14),
              label: const Text('Importar Receita', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 8)),
            )),
            const SizedBox(height: 6),
          ],
          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            onPressed: _aplicarFiltros,
            icon: const Icon(Icons.search, size: 14),
            label: const Text('Filtrar', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(backgroundColor: _red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 8)),
          )),
          const SizedBox(height: 6),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: _limpar,
            icon: const Icon(Icons.clear, size: 14),
            label: const Text('Limpar', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(foregroundColor: _grey, padding: const EdgeInsets.symmetric(vertical: 8)),
          )),
        ]),
      ),
    );
  }

  Widget _lbl(String t) => Padding(padding: const EdgeInsets.only(bottom: 4),
      child: Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _dark)));

  Widget _inp(TextEditingController c, String h) => TextField(controller: c,
    style: const TextStyle(fontSize: 12),
    decoration: InputDecoration(hintText: h, hintStyle: const TextStyle(fontSize: 11, color: _grey),
      filled: true, fillColor: Colors.white, isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: _bord)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: _bord))));

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

  Widget _dateRange(DateTime? ini, DateTime? fim, void Function(DateTime?, DateTime?) cb) =>
    Row(children: [
      Expanded(child: _dp(ini, 'Início', (d) => cb(d, fim))),
      const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('a', style: TextStyle(fontSize: 11))),
      Expanded(child: _dp(fim, 'Fim', (d) => cb(ini, d))),
    ]);

  Widget _dp(DateTime? val, String hint, void Function(DateTime?) cb) => GestureDetector(
    onTap: () async {
      final d = await showDatePicker(context: context, initialDate: val ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
      cb(d);
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: _bord)),
      child: Row(children: [
        const Icon(Icons.calendar_today, size: 10, color: _grey), const SizedBox(width: 3),
        Text(val != null ? '${val.day.toString().padLeft(2,'0')}/${val.month.toString().padLeft(2,'0')}' : hint,
            style: TextStyle(fontSize: 10, color: val != null ? _dark : _grey)),
      ]),
    ));
}
