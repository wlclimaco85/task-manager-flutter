import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/api_links.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/tenant_context.dart';
import '../../../services/network_caller.dart';
import '../models/telas_model.dart';
import '../services/tela_caller.dart';
import '../customization/dynamic_grid_dynamic_screen.dart' as mobile_dyn;
import '../customization/dynamic_grid_windows_screen.dart' as dyn;
import 'generic_grid_windows_screen.dart'
    show FieldConfigWindows, FieldType, SecurityCheck;

/// Avalia a expressão `visibleWhen` (formato "<fieldName>==<valor>") contra o
/// estado atual do formulário. Sem expressão, o campo é sempre visível.
///
/// Quando o campo referenciado não existe no estado, usa o valor padrão do
/// tipo esperado: bool ausente == false; demais tipos ausentes == null.
bool avaliarVisibleWhen(
    String? expressao, Map<String, dynamic> estadoFormulario) {
  if (expressao == null || expressao.trim().isEmpty) return true;

  final partes = expressao.split('==');
  if (partes.length != 2) return true;

  final fieldName = partes[0].trim();
  final valorEsperadoTexto = partes[1].trim();

  dynamic valorEsperado;
  if (valorEsperadoTexto == 'true') {
    valorEsperado = true;
  } else if (valorEsperadoTexto == 'false') {
    valorEsperado = false;
  } else {
    valorEsperado = valorEsperadoTexto;
  }

  dynamic valorAtual = estadoFormulario[fieldName];
  if (!estadoFormulario.containsKey(fieldName)) {
    valorAtual = valorEsperado is bool ? false : null;
  }

  return valorAtual == valorEsperado;
}

// ---------------------------------------------------------------
// GenericDetailFormScreen
// ---------------------------------------------------------------
/// Explicit grid tab — shown as a full DynamicGridWindowsScreen tab.
/// [extraParamKey] is the query param name sent to the backend (e.g. 'loginId').
/// [extraParamValue] is the value (usually the parent id).
class RelatedGridTab {
  final String title;
  final IconData icon;
  final String? telaNome;
  final Map<String, dynamic>? extraParams;
  final List<FieldConfigWindows>? fieldOverrides;

  /// Sobrescreve o endpoint de exclusão do grid. Use `:id` como placeholder do
  /// id da linha. Útil quando "excluir" nesta aba deve DESVINCULAR em vez de
  /// apagar a entidade (ex.: aba Roles do login → DELETE /api/logins/{loginId}/roles/:id).
  final String? deleteEndpointOverride;

  /// Widget customizado — quando informado, ignora telaNome e exibe este widget na aba
  final Widget? customWidget;

  /// Ver GenericGridScreen.prefetchExtraFields/onAfterSave — repassados como
  /// estão até o grid (Map<String,dynamic> porque RelatedGridTab sempre usa o
  /// grid dinâmico genérico, nunca um T tipado).
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> item)?
      prefetchExtraFields;
  final Future<void> Function(
      Map<String, dynamic> formData, Map<String, dynamic>? item)? onAfterSave;

  const RelatedGridTab({
    required this.title,
    required this.icon,
    this.telaNome,
    this.extraParams,
    this.fieldOverrides,
    this.deleteEndpointOverride,
    this.customWidget,
    this.prefetchExtraFields,
    this.onAfterSave,
  }) : assert(telaNome != null || customWidget != null,
            'RelatedGridTab requer telaNome ou customWidget');
}

class GenericDetailFormScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  final String telaNome;
  final SecurityCheck hasPermission;
  final List<FieldConfigWindows>? fieldOverrides;

  /// Explicit related grid tabs (e.g. roles, chamados).
  final List<RelatedGridTab>? relatedTabs;

  const GenericDetailFormScreen({
    super.key,
    required this.item,
    required this.telaNome,
    required this.hasPermission,
    this.fieldOverrides,
    this.relatedTabs,
  });

  @override
  State<GenericDetailFormScreen> createState() =>
      _GenericDetailFormScreenState();
}

class _GenericDetailFormScreenState extends State<GenericDetailFormScreen>
    with SingleTickerProviderStateMixin {
  late Future<TelaConfig> _telaFuture;
  TabController? _tabController;

  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  final _dropdownValues = <String, dynamic>{};
  final _multiValues = <String, List<dynamic>>{};
  final _checkboxValues = <String, bool>{};
  final _dropdownCache = <String, List<Map<String, dynamic>>>{};
  // Memoiza o Future em andamento por campo: evita recriar a requisição HTTP
  // (e reiniciar o FutureBuilder em ConnectionState.waiting) a cada rebuild
  // do formulário enquanto o fetch ainda não terminou.
  final _dropdownFutures = <String, Future<List<Map<String, dynamic>>>>{};

  bool _saving = false;

  Map<String, FieldConfigWindows> _overrideMap = {};
  Set<String> _suppressedFkFields = {};

  @override
  void initState() {
    super.initState();
    _buildOverrideMaps();
    _telaFuture = _loadTela();
  }

  void _buildOverrideMaps() {
    _overrideMap = {
      for (final o in (widget.fieldOverrides ?? [])) o.fieldName: o,
    };
    final dropdownNames = (widget.fieldOverrides ?? [])
        .where((o) => o.fieldType == FieldType.dropdown)
        .map((o) => o.fieldName.toLowerCase())
        .toSet();
    final suppressed = <String>{};
    for (final name in dropdownNames) {
      suppressed.add('${name}_id');
      suppressed.add('id_$name');
    }
    _suppressedFkFields = suppressed;
  }

  Future<TelaConfig> _loadTela() async {
    final svc = await _TelaServiceHelper.load(widget.telaNome);
    return svc;
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _tabController?.dispose();
    super.dispose();
  }

  void _initControllers(TelaConfig tela) {
    final item = widget.item;
    for (final f in tela.fields) {
      final fn = f.fieldName;
      final fnL = fn.toLowerCase();
      if (fnL == 'dhcreatedat' ||
          fnL == 'dhupdatedat' ||
          fnL == 'dh_created_at' ||
          fnL == 'dh_updated_at') {
        continue;
      }
      final val = item[fn];
      if (f.fieldType == TelaFieldType.boolean) {
        _checkboxValues.putIfAbsent(fn, () => val == true);
      } else if (f.fieldType == TelaFieldType.dropdown ||
          f.fieldType == TelaFieldType.multiselect) {
        // handled below
      } else {
        _controllers.putIfAbsent(
            fn, () => TextEditingController(text: _getValue(val)));
      }
    }
    // Init overrides
    for (final o in (widget.fieldOverrides ?? [])) {
      final fn = o.fieldName;
      final val = item[fn];
      if (o.fieldType == FieldType.dropdown) {
        if (!_dropdownValues.containsKey(fn)) {
          if (val is Map) {
            _dropdownValues[fn] = val['id']?.toString();
          } else if (val != null) {
            _dropdownValues[fn] = val.toString();
          }
        }
      } else if (o.fieldType == FieldType.multiselect) {
        if (!_multiValues.containsKey(fn)) {
          if (val is List) {
            _multiValues[fn] = val
                .map((e) {
                  if (e is Map)
                    return (e['id'] ?? e[o.dropdownValueField])?.toString();
                  return e?.toString();
                })
                .whereType<String>()
                .toList();
          } else {
            _multiValues[fn] = [];
          }
        }
      } else {
        _controllers.putIfAbsent(
            fn, () => TextEditingController(text: _getValue(val)));
      }
    }
  }

  String _getValue(dynamic val) {
    if (val == null) return '';
    if (val is Map)
      return val['nome']?.toString() ??
          val['name']?.toString() ??
          val['id']?.toString() ??
          '';
    return val.toString();
  }

  FieldType _telaType(TelaFieldType tft, String fieldName) {
    final fn = fieldName.toLowerCase();
    if (fn == 'senha' || fn == 'password') return FieldType.password;
    if (fn == 'email') return FieldType.email;
    if (fn == 'cpf') return FieldType.cpf;
    if (fn == 'cnpj') return FieldType.cnpj;
    if (fn == 'cpfcnpj' || fn == 'cpf_cnpj') return FieldType.text;
    if (fn == 'telefone' || fn == 'celular') return FieldType.phone;
    if (tft.index < FieldType.values.length) return FieldType.values[tft.index];
    return FieldType.text;
  }

  Future<void> _save(TelaConfig tela) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final body = <String, dynamic>{};
      final id = widget.item['id'];
      if (id != null) body['id'] = id;

      for (final entry in _controllers.entries) {
        body[entry.key] = entry.value.text;
      }
      for (final entry in _checkboxValues.entries) {
        body[entry.key] = entry.value;
      }
      for (final entry in _dropdownValues.entries) {
        if (entry.value != null) body[entry.key] = {'id': entry.value};
      }
      for (final entry in _multiValues.entries) {
        body[entry.key] = entry.value.map((v) => {'id': v}).toList();
      }

      final endpoint =
          tela.updateEndpoint.replaceAll(':id', id?.toString() ?? '');
      final url =
          endpoint.startsWith('http') ? endpoint : ApiLinks.baseUrl + endpoint;
      final resp = await NetworkCaller().putRequest(url, body);
      if (!mounted) return;
      if (resp.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Salvo com sucesso'),
              backgroundColor: GridColors.secondary),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao salvar: ${resp.statusCode}'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<_AutoTab> _detectAutoTabs(TelaConfig tela) {
    final tabs = <_AutoTab>[];
    // Apenas relatedGrids do backend — sem auto-detect de listas do JSON
    // (evita duplicação com explicitTabs)
    for (final rg in tela.relatedGrids) {
      if (rg.gridTelaNome.isNotEmpty) {
        tabs.add(_AutoTab(
          title: rg.title,
          icon: _iconFromName(rg.icon),
          gridTelaNome: rg.gridTelaNome,
        ));
      }
    }
    return tabs;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TelaConfig>(
      future: _telaFuture,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError || !snap.hasData) {
          return Scaffold(body: Center(child: Text('Erro: ${snap.error}')));
        }
        final tela = snap.data!;
        _initControllers(tela);

        // Explicit relatedTabs from widget (highest priority)
        final explicitTabs = (widget.relatedTabs ?? []).map((rt) {
          return _AutoTab(
            title: rt.title,
            icon: rt.icon,
            gridTelaNome: rt.telaNome,
            extraParams: rt.extraParams,
            fieldOverrides: rt.fieldOverrides,
            deleteEndpointOverride: rt.deleteEndpointOverride,
            customWidget: rt.customWidget,
            prefetchExtraFields: rt.prefetchExtraFields,
            onAfterSave: rt.onAfterSave,
          );
        }).toList();

        // Se há explicitTabs, usa APENAS eles — sem auto-detect do backend para evitar duplicação
        final autoTabs =
            explicitTabs.isNotEmpty ? <_AutoTab>[] : _detectAutoTabs(tela);

        final allTabs = [...explicitTabs, ...autoTabs];
        final tabCount = 1 + allTabs.length;

        if (_tabController == null || _tabController!.length != tabCount) {
          _tabController?.dispose();
          _tabController = TabController(length: tabCount, vsync: this);
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF6F8FB),
          appBar: AppBar(
            title: Text(tela.titulo),
            backgroundColor: GridColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: Column(
            children: [
              if (tabCount > 1) _buildTopTabs(allTabs),
              Expanded(
                child: tabCount > 1
                    ? TabBarView(
                        controller: _tabController,
                        children: [
                          _buildFormTab(tela),
                          for (var i = 0; i < allTabs.length; i++)
                            _LazyTab(
                              controller: _tabController!,
                              tabIndex: i + 1,
                              builder: () => _buildAutoTab(allTabs[i]),
                            ),
                        ],
                      )
                    : _buildFormTab(tela),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopTabs(List<_AutoTab> tabs) {
    return Container(
      width: double.infinity,
      color: GridColors.card,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: GridColors.primaryLight,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: GridColors.divider),
          ),
          labelColor: GridColors.primary,
          unselectedLabelColor: GridColors.textSecondary,
          labelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          unselectedLabelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          labelPadding: const EdgeInsets.symmetric(horizontal: 10),
          tabs: [
            const Tab(
              height: 56,
              icon: Icon(Icons.edit_note, size: 16),
              text: 'Cadastro',
            ),
            ...tabs.map(
              (t) => Tab(
                height: 56,
                icon: Icon(t.icon, size: 16),
                text: t.title,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Monta o estado atual do formulário (checkbox, dropdown, multiselect,
  /// texto) para avaliação de `visibleWhen`.
  Map<String, dynamic> _estadoFormularioAtual() {
    final estado = <String, dynamic>{};
    estado.addAll(_checkboxValues);
    estado.addAll(_dropdownValues);
    estado.addAll(_multiValues);
    for (final entry in _controllers.entries) {
      estado[entry.key] = entry.value.text;
    }
    return estado;
  }

  Widget _buildFormTab(TelaConfig tela) {
    final effectiveFields = <_EF>[];
    final inserted = <String>{};

    // Pré-computa todos os nomes de dropdown (overrides + backend) para suprimir IDs brutos
    final allDropdownNames = <String>{
      for (final o in (widget.fieldOverrides ?? []))
        if (o.fieldType == FieldType.dropdown ||
            o.fieldType == FieldType.multiselect)
          o.fieldName.toLowerCase(),
      for (final f in tela.fields)
        if (f.dropdownEndpoint != null && f.dropdownEndpoint!.isNotEmpty)
          f.fieldName.toLowerCase(),
    };

    for (final f in tela.fields) {
      if (!f.isInForm) continue;
      final fnL = f.fieldName.toLowerCase();
      if (fnL == 'dh_created_at' ||
          fnL == 'dh_updated_at' ||
          fnL == 'dhcreatedat' ||
          fnL == 'dhupdatedat') {
        continue;
      }
      if (fnL == 'id') continue;

      // 1. Override explícito
      if (_overrideMap.containsKey(f.fieldName)) {
        if (!inserted.contains(f.fieldName)) {
          effectiveFields.add(_EF.fromOverride(_overrideMap[f.fieldName]!));
          inserted.add(f.fieldName);
        }
        continue;
      }

      // 2. Campo FK de um override (ex: empresa_id → override 'empresa')
      if (_suppressedFkFields.contains(fnL)) {
        final base = fnL.endsWith('_id')
            ? fnL.substring(0, fnL.length - 3)
            : fnL.substring(3);
        if (_overrideMap.containsKey(base) && !inserted.contains(base)) {
          effectiveFields.add(_EF.fromOverride(_overrideMap[base]!));
          inserted.add(base);
        }
        continue;
      }

      // 3. Suprimir IDs brutos quando já existe dropdown correspondente
      if (_isRawIdField(fnL, allDropdownNames)) continue;

      // 4. Skip list fields (handled as tabs)
      final val = widget.item[f.fieldName];
      if (val is List) continue;

      // 5. Auto-dropdown: campo com dropdownEndpoint do backend
      if (f.dropdownEndpoint != null &&
          f.dropdownEndpoint!.isNotEmpty &&
          !inserted.contains(f.fieldName)) {
        final isMulti =
            f.multiSelect || f.fieldType == TelaFieldType.multiselect;
        effectiveFields.add(_EF(
          fieldName: f.fieldName,
          label: f.label,
          type: isMulti ? FieldType.multiselect : FieldType.dropdown,
          isRequired: f.isRequired,
          vField:
              f.dropdownValueField.isNotEmpty && f.dropdownValueField != 'value'
                  ? f.dropdownValueField
                  : 'id',
          dField: f.dropdownDisplayField.isNotEmpty &&
                  f.dropdownDisplayField != 'label'
              ? f.dropdownDisplayField
              : 'nome',
          dropdownEndpoint: f.dropdownEndpoint,
        ));
        inserted.add(f.fieldName);
        continue;
      }

      effectiveFields
          .add(_EF.fromTelaField(f, _telaType(f.fieldType, f.fieldName)));
      inserted.add(f.fieldName);
    }

    // Overrides não inseridos
    for (final o in (widget.fieldOverrides ?? [])) {
      if (!inserted.contains(o.fieldName)) {
        effectiveFields.add(_EF.fromOverride(o));
        inserted.add(o.fieldName);
      }
    }

    // Aplica visibilidade condicional (visibleWhen) com base no estado atual
    final estadoFormulario = _estadoFormularioAtual();
    effectiveFields.removeWhere(
        (f) => !avaliarVisibleWhen(f.visibleWhen, estadoFormulario));

    return Form(
      key: _formKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            primary: false,
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Container(
                  decoration: BoxDecoration(
                    color: GridColors.card,
                    border: Border.all(color: GridColors.divider),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: GridColors.primaryLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.edit_note,
                                color: GridColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cadastro',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: GridColors.secondary,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Edite os dados principais do registro selecionado.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: GridColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: GridColors.divider),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: LayoutBuilder(
                          builder: (context, formConstraints) {
                            final maxWidth = formConstraints.maxWidth;
                            final columnCount = maxWidth >= 1100
                                ? 3
                                : maxWidth >= 720
                                    ? 2
                                    : 1;
                            final gap = columnCount == 1 ? 0.0 : 12.0;
                            final fieldWidth =
                                (maxWidth - ((columnCount - 1) * gap)) /
                                    columnCount;

                            return Wrap(
                              spacing: gap,
                              runSpacing: 0,
                              children: [
                                for (final field in effectiveFields)
                                  SizedBox(
                                    width: _isWideField(field)
                                        ? maxWidth
                                        : fieldWidth,
                                    child: _buildField(field),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                      const Divider(height: 1, color: GridColors.divider),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            width: constraints.maxWidth < 560
                                ? double.infinity
                                : 220,
                            child: ElevatedButton.icon(
                              onPressed: _saving ? null : () => _save(tela),
                              icon: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: Text(
                                _saving ? 'Salvando...' : 'Salvar alterações',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: GridColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isWideField(_EF field) {
    final name = field.fieldName.toLowerCase();
    return field.type == FieldType.multiline ||
        name.contains('observacao') ||
        name.contains('descricao') ||
        name.contains('complemento');
  }

  Widget _buildAutoTab(_AutoTab tab) {
    // Widget customizado (ex: CertificadoEmpresaScreen)
    if (tab.customWidget != null) {
      return tab.customWidget!;
    }
    if (tab.gridTelaNome != null) {
      final isMobileWidth = MediaQuery.of(context).size.width < 720;
      // Quando há deleteEndpointOverride (ex.: desvincular role do login) usa
      // sempre o grid desktop, pois só ele aplica o override — evita que o grid
      // mobile faça o delete destrutivo padrão (apagar a entidade global).
      if (isMobileWidth &&
          tab.fieldOverrides == null &&
          tab.deleteEndpointOverride == null &&
          tab.prefetchExtraFields == null &&
          tab.onAfterSave == null) {
        return mobile_dyn.DynamicGridDynamicScreen(
          telaNome: tab.gridTelaNome!,
          hasPermission: widget.hasPermission,
          extraParams: tab.extraParams,
          showAppBar: false,
        );
      }
      return dyn.DynamicGridWindowsScreen<Map<String, dynamic>>(
        telaNome: tab.gridTelaNome!,
        hasPermission: widget.hasPermission,
        fromJson: (json) => json,
        toJson: (obj) => obj,
        extraParams: tab.extraParams,
        fieldOverrides: tab.fieldOverrides,
        deleteEndpointOverride: tab.deleteEndpointOverride,
        showAppBar: false,
        prefetchExtraFields: tab.prefetchExtraFields,
        onAfterSave: tab.onAfterSave,
      );
    }
    final rows = tab.listData ?? [];
    if (rows.isEmpty) {
      return const Center(
          child: Text('Nenhum item', style: TextStyle(color: Colors.grey)));
    }
    final cols = rows.first.keys.where((k) {
      final v = rows.first[k];
      return v is! Map && v is! List;
    }).toList();
    return SingleChildScrollView(
      primary: false,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        primary: false,
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(GridColors.primary),
          headingTextStyle:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          columns: cols
              .map((c) => DataColumn(label: Text(_toTitleCase(c))))
              .toList(),
          rows: rows
              .map((row) => DataRow(
                    cells: cols
                        .map((c) => DataCell(
                              Text(row[c]?.toString() ?? '',
                                  style: const TextStyle(fontSize: 13)),
                            ))
                        .toList(),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildField(_EF ef) {
    switch (ef.type) {
      case FieldType.boolean:
        return _buildCheckbox(ef);
      case FieldType.dropdown:
        return _buildDropdown(ef);
      case FieldType.multiselect:
        return _buildMultiSelect(ef);
      case FieldType.date:
        return _buildDate(ef);
      case FieldType.password:
        return _buildPassword(ef);
      case FieldType.email:
        return _buildText(ef,
            keyboardType: TextInputType.emailAddress,
            prefix: const Icon(Icons.email_outlined));
      case FieldType.phone:
        return _buildText(ef,
            keyboardType: TextInputType.phone,
            prefix: const Icon(Icons.phone_outlined));
      case FieldType.cpf:
      case FieldType.cnpj:
        return _buildText(ef,
            keyboardType: TextInputType.number,
            formatters: [FilteringTextInputFormatter.digitsOnly]);
      case FieldType.number:
        return _buildText(ef,
            keyboardType: TextInputType.number,
            formatters: [FilteringTextInputFormatter.digitsOnly]);
      case FieldType.currency:
        return _buildText(ef,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefix: const Icon(Icons.attach_money));
      case FieldType.multiline:
        return _buildText(ef,
            maxLines: 4, keyboardType: TextInputType.multiline);
      default:
        return _buildText(ef);
    }
  }

  InputDecoration _dec(String label,
          {Widget? prefix, Widget? suffix, bool req = false}) =>
      InputDecoration(
        labelText: label + (req ? ' *' : ''),
        filled: true,
        fillColor: const Color(0xFFFBFCFE),
        labelStyle: const TextStyle(color: GridColors.textSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: GridColors.divider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide:
                const BorderSide(color: GridColors.primary, width: 1.5)),
        prefixIcon: prefix,
        suffixIcon: suffix,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
      );

  Widget _buildText(_EF ef,
      {TextInputType? keyboardType,
      List<TextInputFormatter>? formatters,
      Widget? prefix,
      int? maxLines}) {
    _controllers.putIfAbsent(ef.fieldName, () => TextEditingController());
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[ef.fieldName],
        keyboardType: keyboardType,
        inputFormatters: formatters,
        maxLines: maxLines ?? 1,
        decoration: _dec(ef.label, prefix: prefix, req: ef.isRequired),
        validator: ef.isRequired
            ? (v) => (v == null || v.trim().isEmpty)
                ? '${ef.label} é obrigatório'
                : null
            : null,
      ),
    );
  }

  Widget _buildPassword(_EF ef) {
    _controllers.putIfAbsent(ef.fieldName, () => TextEditingController());
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _PasswordField(
          controller: _controllers[ef.fieldName]!,
          label: ef.label,
          isRequired: ef.isRequired),
    );
  }

  Widget _buildDate(_EF ef) {
    _controllers.putIfAbsent(ef.fieldName, () => TextEditingController());
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[ef.fieldName],
        readOnly: true,
        decoration: _dec(ef.label,
            prefix: const Icon(Icons.calendar_today_outlined),
            suffix: const Icon(Icons.arrow_drop_down),
            req: ef.isRequired),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate:
                DateTime.tryParse(_controllers[ef.fieldName]?.text ?? '') ??
                    DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            _controllers[ef.fieldName]?.text =
                '${picked.year.toString().padLeft(4, '0')}-'
                '${picked.month.toString().padLeft(2, '0')}-'
                '${picked.day.toString().padLeft(2, '0')}';
          }
        },
      ),
    );
  }

  Widget _buildCheckbox(_EF ef) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFBFCFE),
            border: Border.all(color: GridColors.divider),
            borderRadius: BorderRadius.circular(6),
          ),
          child: CheckboxListTile(
            title: Text(ef.label),
            value: _checkboxValues[ef.fieldName] ?? false,
            activeColor: GridColors.primary,
            onChanged: (v) =>
                setState(() => _checkboxValues[ef.fieldName] = v ?? false),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ),
      );

  Widget _buildDropdown(_EF ef) {
    if (_dropdownCache.containsKey(ef.fieldName)) {
      return _dropdownWidget(ef, _dropdownCache[ef.fieldName]!);
    }
    final future = _dropdownFutures.putIfAbsent(
      ef.fieldName,
      () => ef.dropdownFutureBuilder != null
          ? ef.dropdownFutureBuilder!()
          : ef.dropdownEndpoint != null
              ? _loadEndpoint(ef.dropdownEndpoint!)
              : Future.value(ef.dropdownOptions ?? <Map<String, dynamic>>[]),
    );
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: InputDecorator(
                  decoration: _dec(ef.label),
                  child: const LinearProgressIndicator()));
        }
        final opts = snap.data ?? [];
        _dropdownCache[ef.fieldName] = opts;
        return _dropdownWidget(ef, opts);
      },
    );
  }

  Widget _dropdownWidget(_EF ef, List<Map<String, dynamic>> options) {
    final vf = ef.vField;
    final df = ef.dField;
    final seen = <dynamic>{};
    final unique = options.where((o) {
      final k = o[vf];
      return k != null && seen.add(k);
    }).toList();
    dynamic current = _dropdownValues[ef.fieldName];
    if (!unique.any((o) => o[vf]?.toString() == current?.toString()))
      current = null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<dynamic>(
        initialValue: current,
        decoration: _dec(ef.label, req: ef.isRequired),
        isExpanded: true,
        menuMaxHeight: 300,
        items: unique
            .map((o) => DropdownMenuItem(
                  value: o[vf]?.toString(),
                  child: Text(o[df]?.toString() ?? o[vf].toString(),
                      overflow: TextOverflow.ellipsis),
                ))
            .toList(),
        onChanged: (val) => setState(() => _dropdownValues[ef.fieldName] = val),
        validator: ef.isRequired
            ? (v) => v == null ? '${ef.label} é obrigatório' : null
            : null,
      ),
    );
  }

  Widget _buildMultiSelect(_EF ef) {
    final cacheKey = '${ef.fieldName}_ms';
    if (_dropdownCache.containsKey(cacheKey)) {
      return _multiWidget(ef, _dropdownCache[cacheKey]!);
    }
    final future = _dropdownFutures.putIfAbsent(
      cacheKey,
      () => ef.dropdownFutureBuilder != null
          ? ef.dropdownFutureBuilder!()
          : ef.dropdownEndpoint != null
              ? _loadEndpoint(ef.dropdownEndpoint!)
              : Future.value(ef.dropdownOptions ?? <Map<String, dynamic>>[]),
    );
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: InputDecorator(
                  decoration: _dec(ef.label),
                  child: const LinearProgressIndicator()));
        }
        final opts = snap.data ?? [];
        _dropdownCache[cacheKey] = opts;
        return _multiWidget(ef, opts);
      },
    );
  }

  Widget _multiWidget(_EF ef, List<Map<String, dynamic>> options) {
    final vf = ef.vField;
    final df = ef.dField;
    final selected = _multiValues[ef.fieldName] ?? [];
    final chips = options
        .where((o) => selected.any((s) => s.toString() == o[vf]?.toString()))
        .map((o) => Container(
              margin: const EdgeInsets.only(right: 4, bottom: 2),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: GridColors.secondary,
                  borderRadius: BorderRadius.circular(12)),
              child: Text(o[df]?.toString() ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
            ))
        .toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _openMultiDialog(ef, options, vf, df),
        borderRadius: BorderRadius.circular(8),
        child: InputDecorator(
          decoration: _dec(ef.label,
              suffix: const Icon(Icons.arrow_drop_down), req: ef.isRequired),
          child: chips.isEmpty
              ? Text('Selecione...',
                  style: TextStyle(color: Colors.grey.shade500))
              : Wrap(spacing: 4, runSpacing: 4, children: chips),
        ),
      ),
    );
  }

  Future<void> _openMultiDialog(
      _EF ef, List<Map<String, dynamic>> options, String vf, String df) async {
    final result = await showDialog<List<dynamic>>(
      context: context,
      builder: (ctx) => _MultiSelectDialog(
        title: ef.label,
        options: options,
        valueField: vf,
        displayField: df,
        initialSelected: List.from(_multiValues[ef.fieldName] ?? []),
      ),
    );
    if (result != null) setState(() => _multiValues[ef.fieldName] = result);
  }

  Future<List<Map<String, dynamic>>> _loadEndpoint(String endpoint) async {
    final url =
        endpoint.startsWith('http') ? endpoint : ApiLinks.baseUrl + endpoint;
    final resp = await NetworkCaller().getRequest(url);
    if (!resp.isSuccess || resp.body == null) return [];
    dynamic raw = resp.body;
    List lista = [];
    if (raw is List) {
      lista = raw;
    } else if (raw is Map) {
      final d = raw['data'] ?? raw['dados'] ?? raw['items'] ?? raw['content'];
      if (d is List) {
        lista = d;
      } else if (d is Map && d['dados'] is List) {
        lista = d['dados'];
      }
    }
    return lista
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  IconData _iconFromName(String? name) {
    switch (name) {
      case 'people':
        return Icons.people;
      case 'support_agent':
        return Icons.support_agent;
      case 'account_balance':
        return Icons.account_balance;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'inventory':
        return Icons.inventory;
      case 'receipt':
        return Icons.receipt;
      case 'description':
        return Icons.description;
      case 'person':
        return Icons.person;
      case 'location_on':
        return Icons.location_on;
      case 'security':
        return Icons.security;
      case 'roles':
        return Icons.security;
      case 'chamados':
        return Icons.support_agent;
      default:
        return Icons.list;
    }
  }

  String _toTitleCase(String text) => text
      .split(RegExp(r'[_\s]+'))
      .map((w) =>
          w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');

  /// Suprime campos que são IDs brutos de FK quando já existe dropdown correspondente
  static bool _isRawIdField(String fnLower, Set<String> allDropdownNames) {
    const alwaysHide = {
      'file_id',
      'foto_id',
      'foto_perfil_id',
      'academia_id',
      'cod_personal',
      'cod_produtor',
      'parent_id',
      'user_id',
      'audit_id',
    };
    if (alwaysHide.contains(fnLower)) return true;

    final isIdPattern = (fnLower.endsWith('_id') && fnLower != 'id') ||
        fnLower.startsWith('id_') ||
        fnLower.startsWith('cod_');
    if (!isIdPattern) return false;

    String base;
    if (fnLower.endsWith('_id')) {
      base = fnLower.substring(0, fnLower.length - 3);
    } else if (fnLower.startsWith('id_'))
      base = fnLower.substring(3);
    else
      base = fnLower.substring(4); // cod_

    if (base.length < 2) return false;

    for (final name in allDropdownNames) {
      if (name == base || name.contains(base) || base.contains(name))
        return true;
    }
    return false;
  }
}

// ---------------------------------------------------------------
// Helper to load TelaConfig — uses SharedPreferences cache (same as DynamicGridWindowsScreen)
// ---------------------------------------------------------------
class _TelaServiceHelper {
  static Future<TelaConfig> load(String telaNome) async {
    final tela =
        await TelaService(networkCaller: NetworkCaller()).getTelaFromCache(
      telaNome,
      empId: TenantContext.empresaId,
      clienteId: TenantContext.parceiroId,
    );
    if (tela == null) throw Exception('Tela $telaNome não encontrada no cache');
    return tela;
  }
}

// ---------------------------------------------------------------
// Lazy tab — só constrói (e dispara fetch) o conteúdo da aba quando ela é
// selecionada pela primeira vez. Evita que TODAS as abas relacionadas
// (Parceiros, Logins, Contas a Pagar, etc.) disparem requisições HTTP ao
// montar a tela de detalhe — TabBarView constrói todos os children de
// imediato, então sem essa proteção cada DynamicGridWindowsScreen chamaria
// initState/fetch simultaneamente, causando lentidão e loaders concorrentes.
// Uma vez construída, a aba permanece viva (AutomaticKeepAlive) para não
// recarregar ao trocar de aba.
// ---------------------------------------------------------------
class _LazyTab extends StatefulWidget {
  final TabController controller;
  final int tabIndex;
  final WidgetBuilder0 builder;

  const _LazyTab({
    required this.controller,
    required this.tabIndex,
    required this.builder,
  });

  @override
  State<_LazyTab> createState() => _LazyTabState();
}

typedef WidgetBuilder0 = Widget Function();

class _LazyTabState extends State<_LazyTab>
    with AutomaticKeepAliveClientMixin {
  bool _activated = false;

  @override
  bool get wantKeepAlive => _activated;

  @override
  void initState() {
    super.initState();
    _checkActive();
    widget.controller.addListener(_onTabChanged);
  }

  @override
  void didUpdateWidget(covariant _LazyTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTabChanged);
      widget.controller.addListener(_onTabChanged);
      _checkActive();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() => _checkActive();

  void _checkActive() {
    final isActive = widget.controller.index == widget.tabIndex;
    if (isActive && !_activated) {
      setState(() => _activated = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!_activated) {
      return const Center(child: CircularProgressIndicator());
    }
    return widget.builder();
  }
}

// ---------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------
class _AutoTab {
  final String title;
  final IconData icon;
  final List<Map<String, dynamic>>? listData;
  final String? gridTelaNome;
  final Map<String, dynamic>? extraParams;
  final List<FieldConfigWindows>? fieldOverrides;
  final String? deleteEndpointOverride;
  final Widget? customWidget;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> item)?
      prefetchExtraFields;
  final Future<void> Function(
      Map<String, dynamic> formData, Map<String, dynamic>? item)? onAfterSave;
  _AutoTab(
      {required this.title,
      required this.icon,
      this.listData,
      this.gridTelaNome,
      this.extraParams,
      this.fieldOverrides,
      this.deleteEndpointOverride,
      this.customWidget,
      this.prefetchExtraFields,
      this.onAfterSave});
}

class _EF {
  final String fieldName;
  final String label;
  final FieldType type;
  final bool isRequired;
  final String vField;
  final String dField;
  final String? dropdownEndpoint;
  final Future<List<Map<String, dynamic>>> Function()? dropdownFutureBuilder;
  final List<Map<String, dynamic>>? dropdownOptions;
  final String? visibleWhen;

  _EF(
      {required this.fieldName,
      required this.label,
      required this.type,
      this.isRequired = false,
      this.vField = 'id',
      this.dField = 'nome',
      this.dropdownEndpoint,
      this.dropdownFutureBuilder,
      this.dropdownOptions,
      this.visibleWhen});

  factory _EF.fromTelaField(TelaField f, FieldType type) => _EF(
        fieldName: f.fieldName,
        label: f.label,
        type: type,
        isRequired: f.isRequired,
        vField: f.dropdownValueField.isNotEmpty ? f.dropdownValueField : 'id',
        dField:
            f.dropdownDisplayField.isNotEmpty ? f.dropdownDisplayField : 'nome',
        dropdownEndpoint: f.dropdownEndpoint,
        dropdownOptions: f.dropdownOptions
            .map((e) => <String, dynamic>{
                  'id': e.optionValue,
                  'nome': e.optionLabel ?? e.optionValue.toString()
                })
            .toList(),
        visibleWhen: f.visibleWhen,
      );

  factory _EF.fromOverride(FieldConfigWindows o) => _EF(
        fieldName: o.fieldName,
        label: o.label,
        type: o.fieldType,
        isRequired: o.isRequired,
        vField: o.dropdownValueField.isNotEmpty ? o.dropdownValueField : 'id',
        dField:
            o.dropdownDisplayField.isNotEmpty ? o.dropdownDisplayField : 'nome',
        dropdownFutureBuilder: o.dropdownFutureBuilder,
        dropdownOptions: o.dropdownOptions
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        visibleWhen: null,
      );
}

// ---------------------------------------------------------------
// Password field widget
// ---------------------------------------------------------------
class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool isRequired;
  const _PasswordField(
      {required this.controller,
      required this.label,
      required this.isRequired});
  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _visible = false;
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: !_visible,
      decoration: InputDecoration(
        labelText: widget.label + (widget.isRequired ? ' *' : ''),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: GridColors.primary, width: 1.5)),
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(_visible ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _visible = !_visible),
        ),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
      validator: widget.isRequired
          ? (v) => (v == null || v.trim().isEmpty)
              ? '${widget.label} é obrigatório'
              : null
          : null,
    );
  }
}

// ---------------------------------------------------------------
// MultiSelect dialog
// ---------------------------------------------------------------
class _MultiSelectDialog extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> options;
  final String valueField;
  final String displayField;
  final List<dynamic> initialSelected;
  const _MultiSelectDialog(
      {required this.title,
      required this.options,
      required this.valueField,
      required this.displayField,
      required this.initialSelected});
  @override
  State<_MultiSelectDialog> createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<_MultiSelectDialog> {
  late List<dynamic> _selected;
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
                .where((o) =>
                    o[widget.displayField]
                        ?.toString()
                        .toLowerCase()
                        .contains(q) ??
                    false)
                .toList();
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool _isSel(dynamic val) =>
      _selected.any((s) => s.toString() == val?.toString());
  void _toggle(dynamic val) {
    setState(() {
      if (_isSel(val)) {
        _selected.removeWhere((s) => s.toString() == val?.toString());
      } else {
        _selected.add(val);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 520, maxWidth: 420),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: GridColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(children: [
              const Icon(Icons.checklist, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(widget.title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white))),
              Text('${_selected.length} selecionado(s)',
                  style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Buscar...',
                prefixIcon: const Icon(Icons.search, color: GridColors.primary),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: GridColors.primary, width: 1.5)),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
              child: ListView.builder(
            itemCount: _filtered.length,
            itemBuilder: (ctx, i) {
              final opt = _filtered[i];
              final val = opt[widget.valueField];
              final label =
                  opt[widget.displayField]?.toString() ?? val.toString();
              return CheckboxListTile(
                title: Text(label, style: const TextStyle(fontSize: 14)),
                value: _isSel(val),
                activeColor: GridColors.primary,
                checkColor: Colors.white,
                onChanged: (_) => _toggle(val),
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
              );
            },
          )),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCELAR')),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, _selected),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GridColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const Text('CONFIRMAR'),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
