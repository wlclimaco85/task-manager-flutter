// lib/data/customization/grid_form.dart
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../utils/app_logger.dart';

import 'grid_theme.dart';
import 'grid_models.dart';
import 'grid_network.dart';
import 'grid_utils.dart';

class GridFormDialog extends StatefulWidget {
  final String titleNew;
  final String titleEdit;
  final List<FieldConfig> fieldConfigs;
  final String createEndpoint;
  final String updateEndpoint; // ':id'
  final Future<Map<String, String>> Function()? authHeadersProvider;
  final String? baseUrlForMultipart;
  final Map<String, dynamic>? additionalFormData;
  final Map<String, dynamic> Function(Map<String, dynamic>? item)?
      dynamicAdditionalFormData;
  final Map<String, dynamic>? editingItem;
  final String idFieldName;

  const GridFormDialog({
    super.key,
    required this.titleNew,
    required this.titleEdit,
    required this.fieldConfigs,
    required this.createEndpoint,
    required this.updateEndpoint,
    this.authHeadersProvider,
    this.baseUrlForMultipart,
    this.additionalFormData,
    this.dynamicAdditionalFormData,
    required this.editingItem,
    required this.idFieldName,
  });

  @override
  State<GridFormDialog> createState() => _GridFormDialogState();
}

class _GridFormDialogState extends State<GridFormDialog> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, List<PlatformFile>> _fileCache = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    L.d('[GridForm] initState');
    for (final c in widget.fieldConfigs.where((x) => x.isInForm)) {
      final initial =
          getNestedValue(widget.editingItem, c.fieldName)?.toString() ??
              (c.defaultValue?.toString() ?? '');
      _controllers[c.fieldName] = TextEditingController(text: initial);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editingItem != null;

    return Dialog(
      backgroundColor: GridColors.primary, // fundo banco
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.of(context).size.height * 0.84,
        ),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: GridColors.primary, // fundo banco
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              const Icon(Icons.edit, color: GridColors.textPrimary),
              const SizedBox(width: 8),
              Text(
                isEditing ? widget.titleEdit : widget.titleNew,
                style: const TextStyle(
                  color: GridColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: GridColors.textPrimary),
              ),
            ]),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: widget.fieldConfigs
                      .where((c) => c.isInForm)
                      .map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildFormField(c),
                          ))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: GridColors.textPrimary),
                    foregroundColor: GridColors.textPrimary,
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.success, // verde padrão
                    foregroundColor: GridColors.textPrimary,
                  ),
                  child: Text(isEditing ? 'Salvar' : 'Adicionar'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField(FieldConfig c) {
    final ctrl = _controllers[c.fieldName]!;

    switch (c.fieldType) {
      case FieldType.dropdown:
        return _buildDropdown(c, ctrl);
      case FieldType.boolean:
        final v = ctrl.text.toLowerCase() == 'true';
        return Row(children: [
          Checkbox(
            value: v,
            onChanged: c.enabled
                ? (nv) {
                    ctrl.text = (nv ?? false).toString();
                    setState(() {});
                  }
                : null,
          ),
          Text(c.label, style: const TextStyle(color: GridColors.textPrimary)),
        ]);
      case FieldType.multiline:
        return _textField(c, ctrl, maxLines: 4);
      case FieldType.date:
        return _dateField(c, ctrl);
      case FieldType.file:
        return _fileField(c, ctrl);
      case FieldType.multiselect:
        return _buildMultiselect(c, ctrl);
      default:
        return _textField(c, ctrl);
    }
  }

  InputBorder _redBorder() => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide:
            const BorderSide(color: GridColors.error, width: 2), // vermelho
      );

  Widget _textField(FieldConfig c, TextEditingController ctrl,
      {int? maxLines}) {
    return TextField(
      controller: ctrl,
      enabled: c.enabled,
      maxLines: maxLines ?? c.maxLines,
      decoration: InputDecoration(
        labelText: c.label + (c.isRequired ? ' *' : ''),
        filled: true,
        fillColor: Colors.white,
        border: _redBorder(), // borda vermelha padrão
        enabledBorder: _redBorder(), // borda vermelha
        focusedBorder: _redBorder(), // borda vermelha focada
      ),
      keyboardType: keyboardForFieldType(c.fieldType),
    );
  }

  Widget _dateField(FieldConfig c, TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      readOnly: true,
      enabled: c.enabled,
      decoration: InputDecoration(
        labelText: c.label + (c.isRequired ? ' *' : ''),
        suffixIcon: const Icon(Icons.calendar_today, color: GridColors.error),
        filled: true,
        fillColor: Colors.white,
        border: _redBorder(),
        enabledBorder: _redBorder(),
        focusedBorder: _redBorder(),
      ),
      onTap: c.enabled
          ? () async {
              final picked = await showDatePicker(
                context: context,
                initialDate:
                    tryParseDate(ctrl.text, c.dateFormat) ?? DateTime.now(),
                firstDate: c.firstDate ?? DateTime(1900),
                lastDate: c.lastDate ?? DateTime(2100),
                locale: const Locale('pt', 'BR'),
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: GridColors.primary,
                      onPrimary: Colors.white,
                      secondary: GridColors.secondary,
                      onSecondary: Colors.white,
                      surface: Colors.white,
                      onSurface: GridColors.textSecondary,
                    ),
                    dialogBackgroundColor: Colors.white,
                  ),
                  child: child!,
                ),
              );
              if (picked != null) {
                ctrl.text = DateFormat(c.dateFormat).format(picked);
                setState(() {});
              }
            }
          : null,
      validator: c.validator,
    );
  }

  Widget _fileField(FieldConfig c, TextEditingController ctrl) {
    final picked = _fileCache[c.fieldName] ?? [];
    final cfg = c.fileConfig ?? const FileConfig();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (picked.isNotEmpty)
        ...picked.map((f) => Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                leading: const Icon(Icons.attach_file),
                title: Text(f.name, overflow: TextOverflow.ellipsis),
                subtitle: Text('${(f.size / 1024).toStringAsFixed(1)} KB'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: GridColors.error),
                  onPressed: () {
                    setState(() {
                      _fileCache[c.fieldName]?.remove(f);
                      if (_fileCache[c.fieldName]!.isEmpty) {
                        _fileCache.remove(c.fieldName);
                      }
                      ctrl.clear();
                    });
                  },
                ),
              ),
            )),
      ElevatedButton.icon(
        onPressed: c.enabled
            ? () async {
                try {
                  final res = await FilePicker.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: cfg.allowedExtensions,
                    allowMultiple: cfg.allowMultiple,
                    withData: true,
                  );
                  if (res != null && res.files.isNotEmpty) {
                    final valid = res.files
                        .where((f) => f.size <= cfg.maxFileSize)
                        .toList();
                    if (valid.length != res.files.length) {
                      _snack('Alguns arquivos excedem o tamanho permitido.');
                    }
                    setState(() {
                      _fileCache[c.fieldName] = valid;
                      ctrl.text = valid.map((e) => e.name).join(', ');
                    });
                  }
                } catch (e) {
                  _snack('Erro ao selecionar arquivo: $e');
                }
              }
            : null,
        icon: const Icon(Icons.attach_file),
        label:
            Text(picked.isEmpty ? 'Selecionar Arquivo' : 'Adicionar Arquivo'),
      ),
      if (cfg.allowedExtensions.isNotEmpty) const SizedBox(height: 6),
      if (cfg.allowedExtensions.isNotEmpty)
        const Text(
          'Extensões permitidas: pdf, doc, docx, jpg, jpeg, png',
          style: TextStyle(fontSize: 12, color: Colors.white),
        ),
    ]);
  }

  Widget _buildDropdown(FieldConfig c, TextEditingController ctrl) {
    Future<List<Map<String, dynamic>>> fetchOptions() async {
      if (c.dropdownFutureBuilder != null) return await c.dropdownFutureBuilder!();
      return c.dropdownOptions ?? [];
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchOptions(),
      builder: (context, s) {
        if (s.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }
        final opts = s.data ?? [];
        final valueField = c.dropdownValueField.isNotEmpty ? c.dropdownValueField : 'id';
        final displayField = c.dropdownDisplayField.isNotEmpty ? c.dropdownDisplayField : 'nome';

        // Resolve initial label
        String? initVal = ctrl.text.isNotEmpty
            ? ctrl.text
            : (c.defaultValue ?? c.dropdownSelectedValue)?.toString();
        String? initLabel;
        for (final o in opts) {
          if (o[valueField]?.toString() == initVal) {
            initLabel = o[displayField]?.toString();
            break;
          }
        }
        if (ctrl.text.isEmpty && initVal != null) ctrl.text = initVal;

        return _SearchableDropdownForm(
          config: c,
          controller: ctrl,
          options: opts,
          valueField: valueField,
          displayField: displayField,
          initialLabel: initLabel,
          redBorder: _redBorder(),
          onChanged: (v) {
            ctrl.text = v ?? '';
            setState(() {});
          },
        );
      },
    );
  }

  Widget _buildMultiselect(FieldConfig c, TextEditingController ctrl) {
    Future<List<Map<String, dynamic>>> fetchOptions() async {
      if (c.dropdownFutureBuilder != null) return await c.dropdownFutureBuilder!();
      return c.dropdownOptions ?? [];
    }
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchOptions(),
      builder: (context, s) {
        if (s.connectionState == ConnectionState.waiting) return const LinearProgressIndicator();
        final opts = s.data ?? [];
        final valueField = c.dropdownValueField.isNotEmpty ? c.dropdownValueField : 'id';
        final displayField = c.dropdownDisplayField.isNotEmpty ? c.dropdownDisplayField : 'nome';
        final selectedValues = ctrl.text.isNotEmpty
            ? ctrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
            : <String>[];
        final labels = opts
            .where((o) => selectedValues.contains(o[valueField]?.toString()))
            .map((o) => o[displayField]?.toString() ?? '')
            .join(', ');
        return InkWell(
          onTap: () async {
            final result = await showDialog<List<String>>(
              context: context,
              builder: (ctx) => _GridMultiSelectDialog(
                title: c.label,
                options: opts,
                valueField: valueField,
                displayField: displayField,
                initialSelected: selectedValues,
              ),
            );
            if (result != null) {
              ctrl.text = result.join(', ');
              setState(() {});
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: c.label + (c.isRequired ? ' *' : ''),
              filled: true,
              fillColor: Colors.white,
              border: _redBorder(),
              enabledBorder: _redBorder(),
              focusedBorder: _redBorder(),
              suffixIcon: const Icon(Icons.arrow_drop_down),
            ),
            child: Text(
              labels.isEmpty ? 'Selecione...' : labels,
              style: TextStyle(color: labels.isEmpty ? Colors.grey : null),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final isEditing = widget.editingItem != null;
      final endpoint = isEditing
          ? widget.updateEndpoint.replaceFirst(
              ':id',
              (getNestedValue(widget.editingItem, widget.idFieldName) ?? '')
                  .toString())
          : widget.createEndpoint;

      final formData = <String, dynamic>{};

      // extra fixos
      if (widget.additionalFormData != null) {
        addAllNested(formData, widget.additionalFormData!);
      }
      // extra dinâmicos (dependem do item editado)
      if (widget.dynamicAdditionalFormData != null) {
        final dyn = widget.dynamicAdditionalFormData!(widget.editingItem);
        addAllNested(formData, dyn);
      }

      // dropdowns que usam selectedValue default
      for (final c in widget.fieldConfigs) {
        if (c.fieldType == FieldType.dropdown &&
            c.dropdownSelectedValue != null) {
          addToFormData(formData, c.fieldName, c.dropdownSelectedValue);
        }
      }

      // campos normais
      for (final c in widget.fieldConfigs
          .where((x) => x.isInForm && x.fieldType != FieldType.file)) {
        final ctrl = _controllers[c.fieldName];
        final valueText = ctrl?.text ?? '';
        if (valueText.isEmpty) continue;

        if (c.fieldType == FieldType.date) {
          final iso = tryDateToIso(valueText, c.dateFormat);
          addToFormData(formData, c.fieldName, iso ?? valueText);
        } else if (c.fieldType == FieldType.number) {
          final numVal = num.tryParse(valueText);
          addToFormData(formData, c.fieldName, numVal ?? valueText);
        } else {
          addToFormData(formData, c.fieldName, valueText);
        }
      }

      // arquivos
      final filesToUpload = <MultipartFieldFile>[];
      for (final c
          in widget.fieldConfigs.where((x) => x.fieldType == FieldType.file)) {
        final picked = _fileCache[c.fieldName];
        if (picked != null && picked.isNotEmpty) {
          final cfg = c.fileConfig ?? const FileConfig();
          for (final f in picked) {
            filesToUpload.add(
              MultipartFieldFile(fieldName: cfg.fileFieldName, file: f),
            );
          }
        }
      }

      dynamic resp;
      if (filesToUpload.isNotEmpty) {
        L.d('[GridForm] sending MULTIPART to: $endpoint');
        resp = await sendMultipart(
          endpoint: endpoint,
          isUpdate: isEditing,
          fields: flattenForMultipart(formData),
          files: filesToUpload,
          baseUrlForMultipart: widget.baseUrlForMultipart,
          authHeadersProvider: widget.authHeadersProvider,
        );
      } else {
        final normalized = normalizeDotted(formData);
        L.d('[GridForm] sending JSON to: $endpoint payload: ${jsonEncode(normalized)}');
        resp = isEditing
            ? await putJson(endpoint, normalized)
            : await postJson(endpoint, normalized);
      }

      if (respSuccess(resp)) {
        if (mounted) Navigator.pop(context, true);
        _snack(isEditing ? 'Item atualizado!' : 'Item criado!');
      } else {
        _snack('Erro ao salvar: ${respBody(resp) ?? respStatus(resp)}');
      }
    } catch (e, st) {
      L.e('[GridForm] save error: $e', st);
      _snack('Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: GridColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _GridMultiSelectDialog extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> options;
  final String valueField;
  final String displayField;
  final List<String> initialSelected;

  const _GridMultiSelectDialog({
    required this.title,
    required this.options,
    required this.valueField,
    required this.displayField,
    required this.initialSelected,
  });

  @override
  State<_GridMultiSelectDialog> createState() => _GridMultiSelectDialogState();
}

class _GridMultiSelectDialogState extends State<_GridMultiSelectDialog> {
  late List<String> _selected;
  late List<Map<String, dynamic>> _filtered;
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.initialSelected);
    _filtered = widget.options;
    _ctrl.addListener(() {
      final q = _ctrl.text.toLowerCase();
      setState(() {
        _filtered = q.isEmpty
            ? widget.options
            : widget.options
                .where((o) => o[widget.displayField]?.toString().toLowerCase().contains(q) ?? false)
                .toList();
      });
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  bool _isSelected(String val) => _selected.contains(val);

  void _toggle(String val) {
    setState(() {
      if (_isSelected(val)) {
        _selected.remove(val);
      } else {
        _selected.add(val);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 520, maxWidth: 400),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(widget.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Buscar...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (ctx, i) {
                final opt = _filtered[i];
                final val = opt[widget.valueField]?.toString() ?? '';
                final label = opt[widget.displayField]?.toString() ?? val;
                return CheckboxListTile(
                  title: Text(label),
                  value: _isSelected(val),
                  onChanged: (_) => _toggle(val),
                  dense: true,
                );
              },
            ),
          ),
          const Divider(height: 1),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, _selected),
              child: const Text('Confirmar'),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ─── Searchable Dropdown for grid_form ───────────────────────────────────────

class _SearchableDropdownForm extends StatefulWidget {
  final FieldConfig config;
  final TextEditingController controller;
  final List<Map<String, dynamic>> options;
  final String valueField;
  final String displayField;
  final String? initialLabel;
  final InputBorder redBorder;
  final void Function(String?) onChanged;

  const _SearchableDropdownForm({
    required this.config,
    required this.controller,
    required this.options,
    required this.valueField,
    required this.displayField,
    required this.redBorder,
    required this.onChanged,
    this.initialLabel,
  });

  @override
  State<_SearchableDropdownForm> createState() =>
      _SearchableDropdownFormState();
}

class _SearchableDropdownFormState extends State<_SearchableDropdownForm> {
  String? _label;

  @override
  void initState() {
    super.initState();
    _label = widget.initialLabel;
  }

  Future<void> _open() async {
    if (!widget.config.enabled) return;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _GridDropdownSearchDialog(
        title: widget.config.label,
        options: widget.options,
        valueField: widget.valueField,
        displayField: widget.displayField,
        currentValue: widget.controller.text,
      ),
    );
    if (result != null) {
      final val = result[widget.valueField]?.toString() ?? '';
      final lbl = result[widget.displayField]?.toString() ?? '';
      setState(() => _label = lbl.isEmpty ? null : lbl);
      widget.onChanged(val.isEmpty ? null : val);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.config.label + (widget.config.isRequired ? ' *' : '');
    final display = _label ?? widget.controller.text;
    final isEmpty = display.isEmpty;
    final isDisabled = !widget.config.enabled;

    return FormField<String>(
      initialValue: widget.controller.text,
      validator: (v) {
        if (widget.config.isRequired &&
            (widget.controller.text.isEmpty)) {
          return '${widget.config.label} é obrigatório';
        }
        return widget.config.validator?.call(widget.controller.text);
      },
      builder: (state) => InkWell(
        onTap: isDisabled ? null : _open,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: isDisabled ? const Color(0xFFF5F5F5) : Colors.white,
            border: widget.redBorder,
            enabledBorder: widget.redBorder,
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
            ),
            suffixIcon: isDisabled
                ? const Icon(Icons.lock_outline, size: 16, color: Colors.grey)
                : const Icon(Icons.search, size: 18,
                    color: GridColors.error),
            errorText: state.errorText,
          ),
          child: Text(
            isEmpty ? 'Selecione...' : display,
            style: TextStyle(
              fontSize: 13,
              color: isEmpty || isDisabled ? Colors.grey : const Color(0xFF212121),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

// ─── Dialog de busca para grid_form ──────────────────────────────────────────

class _GridDropdownSearchDialog extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> options;
  final String valueField;
  final String displayField;
  final String? currentValue;

  const _GridDropdownSearchDialog({
    required this.title,
    required this.options,
    required this.valueField,
    required this.displayField,
    this.currentValue,
  });

  @override
  State<_GridDropdownSearchDialog> createState() =>
      _GridDropdownSearchDialogState();
}

class _GridDropdownSearchDialogState
    extends State<_GridDropdownSearchDialog> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.options;
  }

  void _search(String q) {
    final query = q.toLowerCase().trim();
    setState(() {
      _filtered = query.isEmpty
          ? widget.options
          : widget.options
              .where((o) => (o[widget.displayField]?.toString() ?? '')
                  .toLowerCase()
                  .contains(query))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
        child: Column(
          children: [
            // Header
            Container(
              decoration: const BoxDecoration(
                color: GridColors.error,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: Colors.white, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Search
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                onChanged: _search,
                decoration: InputDecoration(
                  hintText: 'Buscar...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: _ctrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _ctrl.clear();
                            _search('');
                          },
                        )
                      : null,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: GridColors.error),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: GridColors.error, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('${_filtered.length} resultado(s)',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey)),
                  const Spacer(),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pop(<String, dynamic>{}),
                    child: const Text('Limpar',
                        style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _filtered.isEmpty
                  ? const Center(
                      child: Text('Nenhum resultado',
                          style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final o = _filtered[i];
                        final val = o[widget.valueField]?.toString();
                        final lbl =
                            o[widget.displayField]?.toString() ?? val ?? '';
                        final isSel = val == widget.currentValue;
                        return ListTile(
                          dense: true,
                          selected: isSel,
                          selectedTileColor:
                              GridColors.error.withValues(alpha: 0.08),
                          leading: isSel
                              ? const Icon(Icons.check_circle,
                                  color: GridColors.error, size: 18)
                              : const Icon(Icons.radio_button_unchecked,
                                  color: Colors.grey, size: 18),
                          title: Text(lbl,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSel
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSel
                                    ? GridColors.error
                                    : const Color(0xFF212121),
                              )),
                          onTap: () => Navigator.of(context).pop(o),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
