import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/conta_pagar_model.dart';
import '../../../utils/api_links.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/tenant_context.dart';
import '../../../widgets/generic_grid_windows_screen.dart'
    show CustomAction, FieldConfigWindows;
import '../../../web/screens/baixa_dialog.dart';
import '../../../web/dialogs/parcelar_conta_dialog.dart';
import '../../../web/dialogs/recorrencia_conta_dialog.dart';
import '../../../web/dialogs/renegociacao_conta_dialog.dart';
import 'package:http/http.dart' as http;

class WebContaPagarGridScreen extends StatefulWidget {
  final SecurityCheck hasPermission;
  const WebContaPagarGridScreen({super.key, required this.hasPermission});

  @override
  State<WebContaPagarGridScreen> createState() =>
      _WebContaPagarGridScreenState();
}

class _WebContaPagarGridScreenState extends State<WebContaPagarGridScreen> {
  bool _importing = false;

  String _statusFilter = 'Todos';
  DateTime? _dataInicio;
  DateTime? _dataFim;
  int? _parceiroId;
  String _tipoFilter = 'Todos';
  final _statusOptions = [
    'Todos',
    'ABERTA',
    'BAIXADA',
    'VENCIDO',
    'PARCIAL',
    'CANCELADA'
  ];
  final _tipoOptions = ['Todos', 'AVULSO', 'RECORRENTE', 'PARCELADO'];

  Key _gridKey = UniqueKey();

  Map<String, dynamic> get _filterParams {
    final params = <String, dynamic>{};
    if (_statusFilter != 'Todos') params['status'] = _statusFilter;
    if (_dataInicio != null)
      params['dataInicio'] = _dataInicio!.toIso8601String().substring(0, 10);
    if (_dataFim != null)
      params['dataFim'] = _dataFim!.toIso8601String().substring(0, 10);
    if (_parceiroId != null) params['parceiroId'] = _parceiroId.toString();
    if (_tipoFilter != 'Todos') params['tipo'] = _tipoFilter;
    return params;
  }

  void _clearFilters() {
    setState(() {
      _statusFilter = 'Todos';
      _dataInicio = null;
      _dataFim = null;
      _parceiroId = null;
      _tipoFilter = 'Todos';
      _gridKey = UniqueKey();
    });
  }

  void _applyFilters() {
    setState(() => _gridKey = UniqueKey());
  }

  Future<void> _importarBoleto() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'rem', 'ret', 'txt'],
      withData: true,
    );
    if (result == null || !mounted) return;

    final file = result.files.first;
    final Uint8List? bytes = file.bytes;
    if (bytes == null) {
      _snack('Não foi possível ler o arquivo', error: true);
      return;
    }

    setState(() => _importing = true);
    try {
      final importUrl = TenantContext.empresaId == null
          ? ApiLinks.importacaoContaPagar
          : '${ApiLinks.importacaoContaPagar}?empId=${TenantContext.empresaId}';
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(importUrl),
      );
      request.headers.addAll(TenantContext.headers);
      request.files.add(
        http.MultipartFile.fromBytes('arquivo', bytes, filename: file.name),
      );
      if (TenantContext.empresaId != null) {
        request.fields['empId'] = TenantContext.empresaId.toString();
        request.fields['empresaId'] = TenantContext.empresaId.toString();
      }

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(body);
        final importados = data['importados'] ?? data['count'] ?? '?';
        _snack('Importação concluída: $importados registro(s)');
      } else {
        _snack('Erro na importação (${response.statusCode})', error: true);
      }
    } catch (e) {
      if (mounted) _snack('Erro: $e', error: true);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: error ? GridColors.error : GridColors.success,
      content: Text(msg),
    ));
  }

  Future<void> _pickDate({required bool isInicio}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isInicio)
          _dataInicio = picked;
        else
          _dataFim = picked;
      });
    }
  }

  List<Widget> _buildFilterBar() {
    return [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: GridColors.filterBackground.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('Status:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            SizedBox(
              width: 140,
              height: 36,
              child: DropdownButtonFormField<String>(
                value: _statusFilter,
                isDense: true,
                decoration: const InputDecoration(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  border: OutlineInputBorder(),
                ),
                items: _statusOptions
                    .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (v) => setState(() => _statusFilter = v!),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Período:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            InkWell(
              onTap: () => _pickDate(isInicio: true),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                    border: Border.all(color: GridColors.divider),
                    borderRadius: BorderRadius.circular(4)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 4),
                  Text(
                      _dataInicio != null
                          ? '${_dataInicio!.day}/${_dataInicio!.month}/${_dataInicio!.year}'
                          : 'Início',
                      style: const TextStyle(fontSize: 13)),
                ]),
              ),
            ),
            const Text(' até ', style: TextStyle(fontSize: 13)),
            InkWell(
              onTap: () => _pickDate(isInicio: false),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                    border: Border.all(color: GridColors.divider),
                    borderRadius: BorderRadius.circular(4)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 4),
                  Text(
                      _dataFim != null
                          ? '${_dataFim!.day}/${_dataFim!.month}/${_dataFim!.year}'
                          : 'Fim',
                      style: const TextStyle(fontSize: 13)),
                ]),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Tipo:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            SizedBox(
              width: 130,
              height: 36,
              child: DropdownButtonFormField<String>(
                value: _tipoFilter,
                isDense: true,
                decoration: const InputDecoration(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  border: OutlineInputBorder(),
                ),
                items: _tipoOptions
                    .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (v) => setState(() => _tipoFilter = v!),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 36,
              child: ElevatedButton.icon(
                onPressed: _applyFilters,
                icon: const Icon(Icons.search, size: 18),
                label: const Text('Filtrar', style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GridColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              height: 36,
              child: OutlinedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('Limpar', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ..._buildFilterBar(),
        const SizedBox(height: 8),
        Expanded(
          child: DynamicGridWindowsScreen<Map<String, dynamic>>(
            key: _gridKey,
            telaNome: 'conta_pagar',
            hasPermission: widget.hasPermission,
            fromJson: (json) => json,
            toJson: (a) => a,
            fetchEndpointOverride: ApiLinks.allContasPagar,
            createEndpointOverride: ApiLinks.createContaPagar,
            updateEndpointOverride: ApiLinks.updateContaPagar(':id'),
            deleteEndpointOverride: ApiLinks.deleteContaPagar(':id'),
            extraParams: _filterParams,
            fieldOverrides: const [
              FieldConfigWindows(
                  fieldName: 'parceiro',
                  label: 'Parceiro',
                  isInForm: true,
                  isInGrid: false,
                  isVisibleByDefault: false),
              FieldConfigWindows(
                  fieldName: 'parceiroDev',
                  label: 'Parceiro Dev',
                  isInForm: true,
                  isInGrid: false,
                  isVisibleByDefault: false),
              FieldConfigWindows(
                  fieldName: 'parceiroRec',
                  label: 'Parceiro Rec',
                  isInForm: true,
                  isInGrid: false,
                  isVisibleByDefault: false),
            ],
            headerActions: [
              OutlinedButton.icon(
                onPressed: _importing ? null : _importarBoleto,
                icon: _importing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: GridColors.secondary),
                      )
                    : const Icon(Icons.upload_file, size: 18),
                label: const Text('Importar Boleto'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: GridColors.secondary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  side: const BorderSide(color: GridColors.divider),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
            customActions: () => [
              CustomAction<Map<String, dynamic>>(
                icon: Icons.check_circle,
                label: 'Baixar',
                onPressed: (context, object) => showDialog(
                  context: context,
                  builder: (_) =>
                      WebBaixaDialog(conta: ContaPagar.fromJson(object)),
                ),
                isVisible: (_) => true,
              ),
              CustomAction<Map<String, dynamic>>(
                icon: Icons.credit_card,
                label: 'Parcelar',
                onPressed: (context, object) => showDialog(
                  context: context,
                  builder: (_) => WebParcelarContaDialog(
                      conta: ContaPagar.fromJson(object)),
                ),
                isVisible: (m) =>
                    ContaPagar.fromJson(m).status == StatusConta.ABERTA,
              ),
              CustomAction<Map<String, dynamic>>(
                icon: Icons.repeat,
                label: 'Recorrência',
                onPressed: (context, object) => showDialog(
                  context: context,
                  builder: (_) => WebRecorrenciaContaDialog(
                      conta: ContaPagar.fromJson(object)),
                ),
                isVisible: (m) =>
                    ContaPagar.fromJson(m).status == StatusConta.ABERTA,
              ),
              CustomAction<Map<String, dynamic>>(
                icon: Icons.swap_horiz,
                label: 'Renegociar',
                onPressed: (context, object) => showDialog(
                  context: context,
                  builder: (_) => WebRenegociacaoContaDialog(
                      conta: ContaPagar.fromJson(object)),
                ),
                isVisible: (m) =>
                    ContaPagar.fromJson(m).status == StatusConta.ABERTA,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
