import 'package:flutter/material.dart';
import '../utils/grid_colors.dart';

/// Reusable searchable dropdown widget.
///
/// Opens a dialog with a text search field so users can quickly filter
/// through long option lists.  Works with any [List<Map<String, dynamic>>]
/// where each map has a [valueField] key (unique ID) and a [displayField]
/// key (human-readable label).
///
/// ```dart
/// SearchableDropdownField(
///   label: 'Empresa',
///   value: _selectedId,
///   items: _empresas,          // [{'id': '1', 'nome': 'Empresa A'}, ...]
///   valueField: 'id',
///   displayField: 'nome',
///   onChanged: (v) => setState(() => _selectedId = v),
/// )
/// ```
class SearchableDropdownField extends StatefulWidget {
  final String label;

  /// Currently selected value — the string representation of [valueField].
  final String? value;

  /// The full list of options.
  final List<Map<String, dynamic>> items;

  /// Key inside each map that holds the option's unique identifier.
  final String valueField;

  /// Key inside each map that holds the human-readable label.
  final String displayField;

  /// Called whenever the user picks a new item (or clears the selection).
  /// Receives [null] only when [nullable] is true and the user taps "Limpar".
  final ValueChanged<String?> onChanged;

  final bool enabled;
  final bool isRequired;

  /// When [true] a "Limpar seleção" button is shown inside the dialog,
  /// allowing the user to set the value back to [null].
  final bool nullable;

  /// Label shown for the clear-selection button (only relevant when
  /// [nullable] is [true]).
  final String nullLabel;

  /// Placeholder text shown when no item is selected.
  final String? hintText;

  /// Optional validator — receives the current string value and returns an
  /// error message or [null] if valid.  Integrates with [Form] / [FormState].
  final String? Function(String?)? validator;

  const SearchableDropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.valueField,
    required this.displayField,
    required this.onChanged,
    this.value,
    this.enabled = true,
    this.isRequired = false,
    this.nullable = false,
    this.nullLabel = '— Nenhum —',
    this.hintText,
    this.validator,
  });

  @override
  State<SearchableDropdownField> createState() =>
      _SearchableDropdownFieldState();
}

class _SearchableDropdownFieldState extends State<SearchableDropdownField> {
  String? _displayLabel;

  @override
  void initState() {
    super.initState();
    _resolveLabel(widget.value);
  }

  @override
  void didUpdateWidget(SearchableDropdownField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value || oldWidget.items != widget.items) {
      setState(() => _resolveLabel(widget.value));
    }
  }

  void _resolveLabel(String? val) {
    if (val == null || val.isEmpty) {
      _displayLabel = null;
      return;
    }
    for (final item in widget.items) {
      if (item[widget.valueField]?.toString() == val) {
        _displayLabel = item[widget.displayField]?.toString();
        return;
      }
    }
    _displayLabel = null;
  }

  Future<void> _openSearch() async {
    if (!widget.enabled) return;
    final result = await showDialog<_DropResult>(
      context: context,
      builder: (_) => _SearchDialog(
        title: widget.label,
        items: widget.items,
        valueField: widget.valueField,
        displayField: widget.displayField,
        currentValue: widget.value,
        nullable: widget.nullable,
        nullLabel: widget.nullLabel,
      ),
    );
    if (result == null) return; // dialog dismissed — no change
    setState(() => _resolveLabel(result.value));
    widget.onChanged(result.value);
  }

  @override
  Widget build(BuildContext context) {
    final primary = GridColors.primary;
    final labelText = widget.label + (widget.isRequired ? ' *' : '');
    final displayText = _displayLabel ?? '';
    final isEmpty = displayText.isEmpty;
    final isDisabled = !widget.enabled;

    return FormField<String>(
      initialValue: widget.value,
      validator: (v) {
        if (widget.validator != null) return widget.validator!(widget.value);
        if (widget.isRequired && (widget.value == null || widget.value!.isEmpty)) {
          return '${widget.label} é obrigatório';
        }
        return null;
      },
      builder: (state) => InkWell(
        onTap: isDisabled ? null : _openSearch,
        borderRadius: BorderRadius.circular(6),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: labelText,
            labelStyle: const TextStyle(fontSize: 13),
            filled: true,
            fillColor: isDisabled ? const Color(0xFFF5F5F5) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: primary, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: primary, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: GridColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            suffixIcon: isDisabled
                ? const Icon(Icons.lock_outline, size: 16, color: Colors.grey)
                : Icon(Icons.search, size: 18, color: primary),
            errorText: state.errorText,
          ),
          child: Text(
            isEmpty ? (widget.hintText ?? '— Selecione —') : displayText,
            style: TextStyle(
              fontSize: 13,
              color: isEmpty
                  ? Colors.grey.shade500
                  : isDisabled
                      ? Colors.grey
                      : const Color(0xFF212121),
              overflow: TextOverflow.ellipsis,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

// ─── Internal result wrapper ──────────────────────────────────────────────────
// Distinguishes "dialog dismissed (no change)" from "user explicitly cleared".

class _DropResult {
  final String? value;
  const _DropResult(this.value);
}

// ─── Search dialog ────────────────────────────────────────────────────────────

class _SearchDialog extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final String valueField;
  final String displayField;
  final String? currentValue;
  final bool nullable;
  final String nullLabel;

  const _SearchDialog({
    required this.title,
    required this.items,
    required this.valueField,
    required this.displayField,
    this.currentValue,
    this.nullable = false,
    this.nullLabel = '— Nenhum —',
  });

  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    final query = q.toLowerCase().trim();
    setState(() {
      _filtered = query.isEmpty
          ? widget.items
          : widget.items
              .where((o) => (o[widget.displayField]?.toString() ?? '')
                  .toLowerCase()
                  .contains(query))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = GridColors.primary;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 540),
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: primary,
                borderRadius: const BorderRadius.only(
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
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // ── Search field ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                onChanged: _onSearch,
                decoration: InputDecoration(
                  hintText: 'Buscar ${widget.title.toLowerCase()}...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchCtrl.clear();
                            _onSearch('');
                          },
                        )
                      : null,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
            ),

            // ── Count + optional clear button ────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '${_filtered.length} resultado(s)',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const Spacer(),
                  if (widget.nullable)
                    TextButton(
                      onPressed: () => Navigator.of(context)
                          .pop(const _DropResult(null)),
                      child: Text(
                        widget.nullLabel,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ── Results list ─────────────────────────────────────────────
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
                        final isSelected = val == widget.currentValue;
                        return ListTile(
                          dense: true,
                          selected: isSelected,
                          selectedTileColor: primary.withValues(alpha: 0.08),
                          leading: isSelected
                              ? Icon(Icons.check_circle,
                                  color: primary, size: 18)
                              : const Icon(Icons.radio_button_unchecked,
                                  color: Colors.grey, size: 18),
                          title: Text(
                            lbl,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? primary
                                  : const Color(0xFF212121),
                            ),
                          ),
                          onTap: () => Navigator.of(context)
                              .pop(_DropResult(val)),
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
