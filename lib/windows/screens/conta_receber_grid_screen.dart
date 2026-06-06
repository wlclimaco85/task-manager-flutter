import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/conta_receber_model.dart';
import '../../../utils/api_links.dart';
import '../../../utils/dropdown_helpers.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/tenant_context.dart';
import '../../../utils/grid_texts.dart';
import '../../../widgets/finance/billing_charge_dialog.dart';
import '../../../widgets/generic_grid_windows_screen.dart' show CustomAction, FieldConfigWindows, FieldType;
import '../../../windows/screens/baixa_dialog_receber.dart';
import '../../../windows/dialogs/parcelar_receber_dialog.dart';
import '../../../windows/dialogs/recorrencia_receber_dialog.dart';
import '../../../windows/dialogs/renegociacao_receber_dialog.dart';
import 'package:http/http.dart' as http;

class WindowsContaReceberGridScreen extends StatefulWidget {
  final SecurityCheck hasPermission;

  const WindowsContaReceberGridScreen({super.key, required this.hasPermission});

  @override
  State<WindowsContaReceberGridScreen> createState() =>
      _WindowsContaReceberGridScreenState();
}

class _WindowsContaReceberGridScreenState extends State<WindowsContaReceberGridScreen> {
  bool _importing = false;

  String _statusFilter = GridTexts.all;
  DateTime? _dataInicio;
  DateTime? _dataFim;
  int? _parceiroId;
  String _tipoFilter = GridTexts.all;
  final _statusOptions = [
    GridTexts.all,
    GridTexts.accountStatusOpen,
    GridTexts.accountStatusPaid,
    GridTexts.accountStatusOverdue,
    GridTexts.accountStatusPartial,
    GridTexts.accountStatusCancelled,
  ];
  final _tipoOptions = [
    GridTexts.all,
    GridTexts.accountTypeSingle,
    GridTexts.accountTypeRecurring,
    GridTexts.accountTypeInstallment,
  ];

  Key _gridKey = UniqueKey();

  Map<String, dynamic> get _filterParams {
    final params = <String, dynamic>{};
    if (_statusFilter != GridTexts.all) params['status'] = _statusFilter;
    if (_dataInicio != null) params['dataInicio'] = _dataInicio!.toIso8601String().substring(0, 10);
    if (_dataFim != null) params['dataFim'] = _dataFim!.toIso8601String().substring(0, 10);
    if (_parceiroId != null) params['parceiroId'] = _parceiroId.toString();
    if (_tipoFilter != GridTexts.all) params['tipo'] = _tipoFilter;
    return params;
  }

  void _clearFilters() {
    setState(() {
      _statusFilter = GridTexts.all;
      _dataInicio = null;
      _dataFim = null;
      _parceiroId = null;
      _tipoFilter = GridTexts.all;
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
    Uint8List? bytes = file.bytes;
    if (bytes == null && file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    }
    if (bytes == null) {
      _snack(GridTexts.fileReadError, error: true);
      return;
    }

    setState(() => _importing = true);
    try {
      final importUrl = TenantContext.empresaId == null
          ? ApiLinks.importacaoContaReceber
          : '${ApiLinks.importacaoContaReceber}?empId=${TenantContext.empresaId}';
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
        _snack(GridTexts.importCompletedCount(importados));
      } else {
        _snack(GridTexts.errorWithStatus(response.statusCode), error: true);
      }
    } catch (e) {
      if (mounted) _snack(GridTexts.genericError(e.toString()), error: true);
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
        if (isInicio) _dataInicio = picked;
        else _dataFim = picked;
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
            const Text(GridTexts.statusLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            SizedBox(
              width: 140,
              height: 36,
              child: DropdownButtonFormField<String>(
                value: _statusFilter,
                isDense: true,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  border: OutlineInputBorder(),
                ),
                items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (v) => setState(() => _statusFilter = v!),
              ),
            ),
            const SizedBox(width: 12),
            const Text(GridTexts.periodLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            InkWell(
              onTap: () => _pickDate(isInicio: true),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(border: Border.all(color: GridColors.divider), borderRadius: BorderRadius.circular(4)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 4),
                  Text(_dataInicio != null ? '${_dataInicio!.day}/${_dataInicio!.month}/${_dataInicio!.year}' : GridTexts.start, style: const TextStyle(fontSize: 13)),
                ]),
              ),
            ),
            const Text(' ${GridTexts.until} ', style: TextStyle(fontSize: 13)),
            InkWell(
              onTap: () => _pickDate(isInicio: false),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(border: Border.all(color: GridColors.divider), borderRadius: BorderRadius.circular(4)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 4),
                  Text(_dataFim != null ? '${_dataFim!.day}/${_dataFim!.month}/${_dataFim!.year}' : GridTexts.end, style: const TextStyle(fontSize: 13)),
                ]),
              ),
            ),
            const SizedBox(width: 12),
            const Text(GridTexts.typeLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            SizedBox(
              width: 130,
              height: 36,
              child: DropdownButtonFormField<String>(
                value: _tipoFilter,
                isDense: true,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  border: OutlineInputBorder(),
                ),
                items: _tipoOptions.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (v) => setState(() => _tipoFilter = v!),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 36,
              child: ElevatedButton.icon(
                onPressed: _applyFilters,
                icon: const Icon(Icons.search, size: 18),
                label: const Text(GridTexts.filter, style: TextStyle(fontSize: 13)),
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
                label: const Text(GridTexts.clear, style: TextStyle(fontSize: 13)),
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
          child: DynamicGridWindowsScreen<ContaReceber>(
            key: _gridKey,
            telaNome: 'conta_receber',
            hasPermission: widget.hasPermission,
            fromJson: (json) => ContaReceber.fromJson(json),
            toJson: (a) => a.toJson(),
            fetchEndpointOverride: ApiLinks.allContasReceber,
            createEndpointOverride: ApiLinks.createContaReceber,
            updateEndpointOverride: ApiLinks.updateContaReceber(':id'),
            deleteEndpointOverride: ApiLinks.deleteContaReceber(':id'),
            extraParams: _filterParams,
            fieldOverrides: [
              // empresa: pré-selecionado do TenantContext; disabled quando logado em empresa
              FieldConfigWindows(
                fieldName: 'empresa',
                label: 'Empresa',
                displayFieldName: 'empresa.nome',
                fieldType: FieldType.dropdown,
                dropdownValueField: 'id',
                dropdownDisplayField: 'nome',
                enabled: TenantContext.empresaId == null,
                isInForm: true,
                dropdownSelectedValue: TenantContext.empresaId,
                dropdownFutureBuilder: DropdownHelpers.empresas,
                fieldOrder: 10,
              ),
              // parceiro: oculto quando sem parceiro; disabled+pré-preenchido em contexto multi-tenant
              FieldConfigWindows(
                fieldName: 'parceiro',
                label: 'Parceiro',
                isInForm: TenantContext.hasParceiro,
                isVisibleByDefault: false,
                enabled: false,
                defaultValue: TenantContext.hasParceiro
                    ? TenantContext.parceiroId?.toString()
                    : null,
                fieldOrder: 15,
              ),
              // parceiroDev: dropdown principal (cliente devedor — quem vai pagar)
              FieldConfigWindows(
                fieldName: 'parceiroDev',
                label: 'Parceiro',
                isInForm: true,
                isInGrid: false,
                isVisibleByDefault: false,
                fieldType: FieldType.dropdown,
                dropdownFutureBuilder: () => DropdownHelpers.parceirosPorEmpresa(TenantContext.empresaId?.toString()),
                dropdownValueField: 'id',
                dropdownDisplayField: 'nome',
                fieldOrder: 20, // logo abaixo de Empresa (10) e Parceiro tenant (15)
              ),
              // parceiroRec: oculto — backend auto-propaga com o valor de parceiroDev no save()
              // Ambas variantes (camelCase + snake_case) para cobrir DB com diferentes padrões
              const FieldConfigWindows(
                fieldName: 'parceiroRec',
                label: '',
                isInForm: false,
                isVisibleByDefault: false,
              ),
              const FieldConfigWindows(
                fieldName: 'parceiro_rec',
                label: '',
                isInForm: false,
                isVisibleByDefault: false,
              ),
              // tipoRecorrencia: dropdown enum (igual ao conta_pagar)
              FieldConfigWindows(
                fieldName: 'tipoRecorrencia',
                label: 'Tipo Recorrência',
                isInForm: true,
                fieldType: FieldType.dropdown,
                dropdownValueField: 'value',
                dropdownDisplayField: 'label',
                dropdownFutureBuilder: () => DropdownHelpers.load(
                  '${ApiLinks.baseUrl}/api/enums/TipoRecorrenciaEnum',
                  displayField: 'label',
                ),
                fieldOrder: 70,
              ),
              // Campos de baixa: somente leitura — preenchidos via ação "Baixa"
              const FieldConfigWindows(
                fieldName: 'dataBaixa',
                label: 'Data da Baixa',
                isInForm: true,
                enabled: false,
              ),
              const FieldConfigWindows(
                fieldName: 'valorBaixa',
                label: 'Valor da Baixa',
                isInForm: true,
                enabled: false,
              ),
            ],
            headerActions: [
              OutlinedButton.icon(
                onPressed: _importing ? null : _importarBoleto,
                icon: _importing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: GridColors.secondary),
                      )
                    : const Icon(Icons.upload_file, size: 18),
                label: const Text(GridTexts.importBoleto),
                style: OutlinedButton.styleFrom(
                  foregroundColor: GridColors.secondary,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  side: const BorderSide(color: GridColors.divider),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
            customActions: () => [
              CustomAction<ContaReceber>(
                icon: Icons.receipt_long,
                label: GridTexts.charge,
                onPressed: (context, object) => _showBillingDialog(context, object),
                isVisible: (c) => c.status == StatusConta.ABERTA,
              ),
              CustomAction<ContaReceber>(
                icon: Icons.check_circle,
                label: GridTexts.lower,
                onPressed: (context, object) => _showBaixaDialog(context, object),
                isVisible: (c) => c.status == StatusConta.ABERTA,
              ),
              CustomAction<ContaReceber>(
                icon: Icons.credit_card,
                label: GridTexts.installment,
                onPressed: (context, object) => _showParcelarDialog(context, object),
                isVisible: (c) => c.status == StatusConta.ABERTA,
              ),
              CustomAction<ContaReceber>(
                icon: Icons.repeat,
                label: GridTexts.recurrence,
                onPressed: (context, object) => _showRecorrenciaDialog(context, object),
                isVisible: (c) => c.status == StatusConta.ABERTA,
              ),
              CustomAction<ContaReceber>(
                icon: Icons.swap_horiz,
                label: GridTexts.renegotiate,
                onPressed: (context, object) => _showRenegociacaoDialog(context, object),
                isVisible: (c) => c.status == StatusConta.ABERTA,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showBaixaDialog(BuildContext context, ContaReceber conta) {
    showDialog(
      context: context,
      builder: (BuildContext context) => BaixaDialogReceber(conta: conta),
    );
  }

  void _showBillingDialog(BuildContext context, ContaReceber conta) {
    showDialog(
      context: context,
      builder: (BuildContext context) => BillingChargeDialog(conta: conta),
    );
  }

  void _showParcelarDialog(BuildContext context, ContaReceber conta) {
    showDialog(
      context: context,
      builder: (BuildContext context) => ParcelarReceberDialog(conta: conta),
    );
  }

  void _showRecorrenciaDialog(BuildContext context, ContaReceber conta) {
    showDialog(
      context: context,
      builder: (BuildContext context) => RecorrenciaReceberDialog(conta: conta),
    );
  }

  void _showRenegociacaoDialog(BuildContext context, ContaReceber conta) {
    showDialog(
      context: context,
      builder: (BuildContext context) => RenegociacaoReceberDialog(conta: conta),
    );
  }
}
