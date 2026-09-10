import 'package:flutter/material.dart';
import 'package:task_manager_flutter/core/design/design_tokens.dart';
import 'package:task_manager_flutter/core/responsive/responsive_helper.dart';
import 'package:task_manager_flutter/utils/app_logger.dart';

typedef FilterChangedCallback = void Function(
  String? status,
  DateTime? dataInicio,
  DateTime? dataFim,
  String? sortBy,
  bool sortAsc,
);

/// Barra de filtros sticky para NfeListScreen
/// Responsivo: Column em mobile, Row em desktop
/// Elementos:
/// - Status dropdown (Todos, Rascunho, Autorizada, Rejeitada, Cancelada)
/// - DateRange picker (data início → fim)
/// - Sort menu (Número, Data, Valor, Status | ASC/DESC)
/// - Reset button
class NfeFilterBar extends StatefulWidget {
  final Breakpoint breakpoint;
  final FilterChangedCallback? onFilterChanged;
  final String? initialStatus;
  final DateTime? initialDataInicio;
  final DateTime? initialDataFim;
  final String? initialSortBy;
  final bool initialSortAsc;

  const NfeFilterBar({
    super.key,
    required this.breakpoint,
    this.onFilterChanged,
    this.initialStatus,
    this.initialDataInicio,
    this.initialDataFim,
    this.initialSortBy = 'dataHora',
    this.initialSortAsc = false,
  });

  @override
  State<NfeFilterBar> createState() => _NfeFilterBarState();
}

class _NfeFilterBarState extends State<NfeFilterBar> {
  late String? _selectedStatus;
  late DateTime? _dataInicio;
  late DateTime? _dataFim;
  late String _sortBy;
  late bool _sortAsc;

  final List<String> _statusOptions = ['Todos', 'Rascunho', 'Autorizada', 'Rejeitada', 'Cancelada'];
  final List<String> _sortOptions = ['Número', 'Data', 'Valor', 'Status'];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus;
    _dataInicio = widget.initialDataInicio;
    _dataFim = widget.initialDataFim;
    _sortBy = widget.initialSortBy ?? 'dataHora';
    _sortAsc = widget.initialSortAsc;
  }

  void _notifyChanges() {
    widget.onFilterChanged?.call(
      _selectedStatus,
      _dataInicio,
      _dataFim,
      _sortBy,
      _sortAsc,
    );
  }

  void _resetFilters() {
    L.d('[NfeFilterBar] Resetando filtros');
    setState(() {
      _selectedStatus = null;
      _dataInicio = null;
      _dataFim = null;
      _sortBy = 'dataHora';
      _sortAsc = false;
    });
    _notifyChanges();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dataInicio != null && _dataFim != null
          ? DateTimeRange(start: _dataInicio!, end: _dataFim!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _dataInicio = picked.start;
        _dataFim = picked.end;
      });
      _notifyChanges();
    }
  }

  String _formatDateRange() {
    if (_dataInicio == null || _dataFim == null) return 'Período';
    final start = '${_dataInicio!.day}/${_dataInicio!.month}';
    final end = '${_dataFim!.day}/${_dataFim!.month}/${_dataFim!.year}';
    return '$start - $end';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = widget.breakpoint == Breakpoint.mobile;
    final isTablet = widget.breakpoint == Breakpoint.tablet;

    if (isMobile) {
      // Mobile: Column layout (2 linhas)
      return Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingMd),
        child: Column(
          spacing: DesignTokens.spacingMd,
          children: [
            // Linha 1: Status + DateRange
            Row(
              spacing: DesignTokens.spacingSm,
              children: [
                // Status dropdown
                Expanded(
                  child: Semantics(
                    label: 'Filtro de status',
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedStatus,
                      hint: const Text('Status'),
                      items: _statusOptions.map((status) {
                        return DropdownMenuItem(value: status == 'Todos' ? null : status, child: Text(status));
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedStatus = value);
                        _notifyChanges();
                      },
                    ),
                  ),
                ),
                // DateRange picker
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDateRange,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(_formatDateRange(), overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            ),

            // Linha 2: Sort + Reset
            Row(
              spacing: DesignTokens.spacingSm,
              children: [
                // Sort dropdown
                Expanded(
                  child: Semantics(
                    label: 'Ordenação',
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _sortBy,
                      items: _sortOptions.map((opt) {
                        return DropdownMenuItem(value: opt.toLowerCase(), child: Text(opt));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _sortBy = value);
                          _notifyChanges();
                        }
                      },
                    ),
                  ),
                ),
                // Reset button
                OutlinedButton.icon(
                  onPressed: _resetFilters,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Limpar'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Desktop/Tablet: Row layout
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingMd,
        vertical: DesignTokens.spacingSm,
      ),
      child: Semantics(
        label: 'Barra de filtros',
        child: Wrap(
          spacing: DesignTokens.spacingMd,
          runSpacing: DesignTokens.spacingSm,
          children: [
            // Status dropdown
            SizedBox(
              width: 150,
              child: Semantics(
                label: 'Filtro de status',
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedStatus,
                  hint: const Text('Status'),
                  items: _statusOptions.map((status) {
                    return DropdownMenuItem(
                      value: status == 'Todos' ? null : status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedStatus = value);
                    _notifyChanges();
                  },
                ),
              ),
            ),

            // DateRange picker
            OutlinedButton.icon(
              onPressed: _pickDateRange,
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(_formatDateRange()),
            ),

            // Sort menu
            PopupMenuButton<String>(
              itemBuilder: (context) => [
                ..._sortOptions.map((opt) {
                  final value = opt.toLowerCase();
                  final isSelected = _sortBy == value;
                  return CheckedPopupMenuItem(
                    checked: isSelected,
                    value: value,
                    child: Text(opt),
                  );
                }).toList(),
                const PopupMenuDivider(),
                CheckedPopupMenuItem(
                  checked: _sortAsc,
                  value: 'asc',
                  child: const Text('Crescente (A→Z)'),
                ),
                CheckedPopupMenuItem(
                  checked: !_sortAsc,
                  value: 'desc',
                  child: const Text('Decrescente (Z→A)'),
                ),
              ],
              onSelected: (value) {
                setState(() {
                  if (value == 'asc') {
                    _sortAsc = true;
                  } else if (value == 'desc') {
                    _sortAsc = false;
                  } else {
                    _sortBy = value;
                  }
                });
                _notifyChanges();
              },
              icon: const Icon(Icons.sort),
              tooltip: 'Ordenação',
            ),

            // Reset button
            OutlinedButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.refresh),
              label: const Text('Limpar'),
            ),
          ],
        ),
      ),
    );
  }
}
