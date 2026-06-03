import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/auth_utility.dart';
import '../models/telas_model.dart';
import '../services/auth_service.dart';
import '../services/network_caller.dart';
import '../services/tela_caller.dart';
import '../utils/api_links.dart';
import '../utils/app_logger.dart';
import '../widgets/generic_detail_form_screen.dart';
import 'generic_grid/grid_models.dart';
import 'generic_grid/grid_page.dart';

typedef SecurityCheck = bool Function(String permission);
typedef OnItemTap = void Function(
  Map<String, dynamic> item,
  BuildContext context,
);

class DynamicGridDynamicScreen extends StatefulWidget {
  final String telaNome;
  final SecurityCheck hasPermission;
  final String? storageKey;
  final OnItemTap? onItemTap;
  final Widget Function(Map<String, dynamic> item)? detailScreenBuilder;
  final Map<String, dynamic>? extraParams;
  final VoidCallback? onUserBannerTapped;
  final VoidCallback? onBannerRefresh;
  final Map<String, dynamic>? additionalFormData;
  final Map<String, dynamic> Function(Map<String, dynamic>? item)?
      dynamicAdditionalFormData;
  final List<FieldConfig>? fieldOverrides;
  final List<CustomAction> Function()? customActions;
  final String? fetchEndpointOverride;
  final String? createEndpointOverride;
  final String? updateEndpointOverride;
  final String? deleteEndpointOverride;
  final bool showAppBar;

  const DynamicGridDynamicScreen({
    super.key,
    required this.telaNome,
    required this.hasPermission,
    this.storageKey,
    this.onItemTap,
    this.detailScreenBuilder,
    this.extraParams,
    this.onUserBannerTapped,
    this.onBannerRefresh,
    this.additionalFormData,
    this.dynamicAdditionalFormData,
    this.fieldOverrides,
    this.customActions,
    this.fetchEndpointOverride,
    this.createEndpointOverride,
    this.updateEndpointOverride,
    this.deleteEndpointOverride,
    this.showAppBar = true,
  });

  @override
  State<DynamicGridDynamicScreen> createState() =>
      _DynamicGridDynamicScreenState();
}

class _DynamicGridDynamicScreenState extends State<DynamicGridDynamicScreen> {
  late Future<TelaConfig> _telaFuture;
  late TelaService _telaService;

  @override
  void initState() {
    super.initState();
    _telaService = TelaService(networkCaller: NetworkCaller());
    _telaFuture = _loadTelaConfig();
  }

  Future<TelaConfig> _loadTelaConfig() async {
    L.i('[DynamicMobileGrid] carregando tela: ${widget.telaNome}');
    try {
      final userInfo = AuthUtility.userInfo;
      final empId = userInfo?.login?.empresa?.id;
      final clienteId = userInfo?.data?.login?.empresa?.id ??
          userInfo?.data?.login?.parceiro?.id;

      final tela = await _telaService.getTelaFromCache(
        widget.telaNome,
        empId: empId,
        clienteId: clienteId,
      );
      if (tela != null) return tela;
      if (empId != null || clienteId != null) {
        try {
          final telaSemTenant =
              await _telaService.getTelaByNome(widget.telaNome);
          if (telaSemTenant != null) return telaSemTenant;
        } catch (e) {
          L.w('[DynamicMobileGrid] API de telas bloqueada para '
              '${widget.telaNome}; usando fallback local. $e');
        }
      }
      final fallback = _localTelaConfig(widget.telaNome);
      if (fallback != null) return fallback;
      throw Exception('Tela ${widget.telaNome} nao encontrada.');
    } catch (e, st) {
      final fallback = _localTelaConfig(widget.telaNome);
      if (fallback != null) {
        L.w('[DynamicMobileGrid] usando fallback local para '
            '${widget.telaNome} apos erro: $e');
        return fallback;
      }
      L.e('[DynamicMobileGrid] erro ao carregar tela: $e\n$st');
      rethrow;
    }
  }

  TelaConfig? _localTelaConfig(String nome) {
    final key = nome.toLowerCase();
    if (key == 'chamado' || key == 'chamados') {
      return TelaConfig(
        id: -1001,
        nome: 'chamado',
        titulo: 'Solicitacoes',
        fetchEndpoint: '/api/chamados',
        createEndpoint: '/api/chamados',
        updateEndpoint: '/api/chamados/:id',
        deleteEndpoint: '/api/chamados/:id',
        fields: [
          TelaField(label: 'ID', fieldName: 'id', isInForm: false),
          TelaField(label: 'Titulo', fieldName: 'titulo', fieldOrder: 1),
          TelaField(
            label: 'Descricao',
            fieldName: 'descricao',
            fieldType: TelaFieldType.multiline,
            maxLines: 4,
            fieldOrder: 2,
          ),
          TelaField(label: 'Status', fieldName: 'status', fieldOrder: 3),
          TelaField(label: 'Setor', fieldName: 'setor.nome', fieldOrder: 4),
          TelaField(
            label: 'Prioridade',
            fieldName: 'prioridade',
            fieldOrder: 5,
          ),
          TelaField(
            label: 'Criado em',
            fieldName: 'dhCreatedAt',
            isInForm: false,
            fieldType: TelaFieldType.date,
            fieldOrder: 6,
          ),
        ],
        actions: const [],
      );
    }
    if (key == 'comunicado' || key == 'comunicados') {
      return TelaConfig(
        id: -1002,
        nome: 'comunicado',
        titulo: 'Comunicado',
        fetchEndpoint: '/api/comunicado',
        createEndpoint: '/api/comunicado',
        updateEndpoint: '/api/comunicado/:id',
        deleteEndpoint: '/api/comunicado/:id',
        fields: [
          TelaField(label: 'ID', fieldName: 'id', isInForm: false),
          TelaField(label: 'Titulo', fieldName: 'titulo', fieldOrder: 1),
          TelaField(
            label: 'Descricao',
            fieldName: 'descricao',
            fieldType: TelaFieldType.multiline,
            maxLines: 4,
            fieldOrder: 2,
          ),
          TelaField(label: 'Status', fieldName: 'status', fieldOrder: 3),
          TelaField(
            label: 'Data',
            fieldName: 'data',
            fieldType: TelaFieldType.date,
            fieldOrder: 4,
          ),
        ],
        actions: const [],
      );
    }
    if (key == 'alvara' || key == 'alvaras') {
      return _basicTelaConfig(
        id: -1003,
        nome: 'alvara',
        titulo: 'Alvaras',
        endpoint: '/api/alvara',
        fields: [
          TelaField(label: 'ID', fieldName: 'id', isInForm: false),
          TelaField(
            label: 'Descricao',
            fieldName: 'descricao',
            fieldOrder: 1,
            isRequired: true,
          ),
          TelaField(label: 'Numero', fieldName: 'numero', fieldOrder: 2),
          TelaField(
            label: 'Tipo',
            fieldName: 'tipoAlvara',
            fieldOrder: 3,
          ),
          TelaField(
            label: 'Vencimento',
            fieldName: 'dataVencimento',
            fieldType: TelaFieldType.date,
            fieldOrder: 4,
          ),
          TelaField(label: 'Status', fieldName: 'status', fieldOrder: 5),
          TelaField(
            label: 'Observacao',
            fieldName: 'observacao',
            fieldType: TelaFieldType.multiline,
            maxLines: 4,
            fieldOrder: 6,
          ),
        ],
      );
    }
    if (key == 'conta_pagar') {
      return _financeTelaConfig(
        id: -1004,
        nome: 'conta_pagar',
        titulo: 'Contas a Pagar',
        endpoint: '/api/conta_pagar',
        pessoaLabel: 'Fornecedor',
      );
    }
    if (key == 'conta_receber') {
      return _financeTelaConfig(
        id: -1005,
        nome: 'conta_receber',
        titulo: 'Contas a Receber',
        endpoint: '/api/conta_receber',
        pessoaLabel: 'Cliente',
      );
    }
    if (key == 'parceiro' || key == 'parceiros') {
      return _basicTelaConfig(
        id: -1006,
        nome: 'parceiro',
        titulo: 'Parceiros',
        endpoint: '/api/parceiro',
        fields: [
          TelaField(label: 'ID', fieldName: 'id', isInForm: false),
          TelaField(label: 'Nome', fieldName: 'nome', fieldOrder: 1),
          TelaField(label: 'Documento', fieldName: 'cpfCnpj', fieldOrder: 2),
          TelaField(
            label: 'Email',
            fieldName: 'email',
            fieldType: TelaFieldType.email,
            fieldOrder: 3,
          ),
          TelaField(
            label: 'Telefone',
            fieldName: 'telefone',
            fieldType: TelaFieldType.phone,
            fieldOrder: 4,
          ),
          TelaField(label: 'Status', fieldName: 'status', fieldOrder: 5),
        ],
      );
    }
    if (key == 'produto' || key == 'produtos') {
      return _basicTelaConfig(
        id: -1007,
        nome: 'produto',
        titulo: 'Produtos',
        endpoint: '/api/produtos',
        fields: [
          TelaField(label: 'ID', fieldName: 'id', isInForm: false),
          TelaField(label: 'Nome', fieldName: 'nome', fieldOrder: 1),
          TelaField(label: 'Codigo', fieldName: 'codigo', fieldOrder: 2),
          TelaField(
            label: 'Preco',
            fieldName: 'preco',
            fieldType: TelaFieldType.currency,
            fieldOrder: 3,
          ),
          TelaField(label: 'Status', fieldName: 'status', fieldOrder: 4),
        ],
      );
    }
    if (key == 'conta_bancaria' || key == 'contas_bancaria') {
      return _basicTelaConfig(
        id: -1008,
        nome: 'conta_bancaria',
        titulo: 'Contas Bancarias',
        endpoint: '/api/contas-bancaria',
        fields: [
          TelaField(label: 'ID', fieldName: 'id', isInForm: false),
          TelaField(label: 'Banco', fieldName: 'banco', fieldOrder: 1),
          TelaField(label: 'Agencia', fieldName: 'agencia', fieldOrder: 2),
          TelaField(label: 'Conta', fieldName: 'conta', fieldOrder: 3),
          TelaField(
            label: 'Saldo',
            fieldName: 'saldo',
            fieldType: TelaFieldType.currency,
            fieldOrder: 4,
          ),
        ],
      );
    }
    if (key == 'funcionario' || key == 'funcionarios') {
      return _basicTelaConfig(
        id: -1009,
        nome: 'funcionario',
        titulo: 'Funcionarios',
        endpoint: '/api/funcionario',
        fields: [
          TelaField(label: 'ID', fieldName: 'id', isInForm: false),
          TelaField(label: 'Nome', fieldName: 'nome', fieldOrder: 1),
          TelaField(label: 'CPF', fieldName: 'cpf', fieldOrder: 2),
          TelaField(
            label: 'Email',
            fieldName: 'email',
            fieldType: TelaFieldType.email,
            fieldOrder: 3,
          ),
          TelaField(label: 'Cargo', fieldName: 'cargo', fieldOrder: 4),
          TelaField(label: 'Status', fieldName: 'status', fieldOrder: 5),
        ],
      );
    }
    return null;
  }

  TelaConfig _basicTelaConfig({
    required int id,
    required String nome,
    required String titulo,
    required String endpoint,
    required List<TelaField> fields,
  }) {
    return TelaConfig(
      id: id,
      nome: nome,
      titulo: titulo,
      fetchEndpoint: endpoint,
      createEndpoint: endpoint,
      updateEndpoint: '$endpoint/:id',
      deleteEndpoint: '$endpoint/:id',
      fields: fields,
      actions: const [],
    );
  }

  TelaConfig _financeTelaConfig({
    required int id,
    required String nome,
    required String titulo,
    required String endpoint,
    required String pessoaLabel,
  }) {
    return _basicTelaConfig(
      id: id,
      nome: nome,
      titulo: titulo,
      endpoint: endpoint,
      fields: [
        TelaField(label: 'ID', fieldName: 'id', isInForm: false),
        TelaField(label: 'Descricao', fieldName: 'descricao', fieldOrder: 1),
        TelaField(
          label: pessoaLabel,
          fieldName: 'parceiro.id',
          displayFieldName: 'parceiro.nome',
          fieldType: TelaFieldType.dropdown,
          dropdownEndpoint: '/api/parceiro',
          dropdownValueField: 'id',
          dropdownDisplayField: 'nome',
          isRequired: false,
          fieldOrder: 2,
        ),
        TelaField(
          label: 'Vencimento',
          fieldName: 'dataVencimento',
          fieldType: TelaFieldType.date,
          fieldOrder: 3,
        ),
        TelaField(
          label: 'Valor',
          fieldName: 'valor',
          fieldType: TelaFieldType.currency,
          fieldOrder: 4,
        ),
        TelaField(label: 'Status', fieldName: 'status', fieldOrder: 5),
      ],
    );
  }

  List<FieldConfig> _convertToFieldConfigs(List<TelaField> fields) {
    final overrides = widget.fieldOverrides ?? const <FieldConfig>[];
    final suppressMap = <String, FieldConfig>{
      for (final o in overrides.where((o) => !o.isInForm))
        o.fieldName.toLowerCase(): o,
    };
    final replaceMap = <String, FieldConfig>{
      for (final o in overrides.where((o) => o.isInForm))
        o.fieldName.toLowerCase(): o,
    };
    final dropdownReplaceNames = overrides
        .where((o) =>
            o.isInForm &&
            (o.fieldType == FieldType.dropdown ||
                o.fieldType == FieldType.multiselect))
        .map((o) => o.fieldName.toLowerCase())
        .toSet();

    final allDropdownNames = <String>{...dropdownReplaceNames};
    for (final f in fields) {
      if (f.dropdownEndpoint != null && f.dropdownEndpoint!.isNotEmpty) {
        allDropdownNames.add(f.fieldName.toLowerCase());
      }
    }

    final converted = <FieldConfig>[];
    final insertedOverrides = <String>{};
    final backendFieldNames = <String>{};

    for (final f in fields) {
      final fn = f.fieldName;
      final fnLower = fn.toLowerCase();
      final fnNorm = fnLower.replaceAll('_', '');
      backendFieldNames.add(fnLower);

      final suppress = suppressMap[fnLower];
      if (suppress != null) {
        converted.add(suppress);
        final base = _extractBase(fnLower);
        if (base != null && replaceMap.containsKey(base)) {
          _addOverrideOnce(converted, insertedOverrides, replaceMap[base]!);
        }
        continue;
      }

      final exactReplace = replaceMap[fnLower] ??
          _firstOverrideWhere(
            replaceMap,
            (key) => key.replaceAll('_', '') == fnNorm,
          );
      if (exactReplace != null) {
        _addOverrideOnce(converted, insertedOverrides, exactReplace);
        continue;
      }

      final base = _extractBase(fnLower);
      if (base != null && dropdownReplaceNames.contains(base)) {
        _addOverrideOnce(converted, insertedOverrides, replaceMap[base]!);
        continue;
      }

      if (_isAutoDateField(fnLower)) {
        converted.add(FieldConfig(
          label: f.label,
          fieldName: fn,
          isInForm: false,
          isVisibleByDefault: false,
          showInCard: false,
        ));
        continue;
      }

      if (_isRawFkIdField(fnLower, allDropdownNames)) continue;

      converted.add(_toFieldConfig(f));
    }

    for (final override in overrides.where((o) => o.isInForm)) {
      final key = override.fieldName.toLowerCase();
      if (!backendFieldNames.contains(key) &&
          !insertedOverrides.contains(key)) {
        converted.add(override);
      }
    }

    return converted;
  }

  FieldConfig _toFieldConfig(TelaField f) {
    final isAutoDropdown =
        f.dropdownEndpoint != null && f.dropdownEndpoint!.isNotEmpty;
    final isMulti = f.multiSelect || f.fieldType == TelaFieldType.multiselect;

    List<Map<String, dynamic>>? dropdownOptions;
    if (f.dropdownOptions.isNotEmpty) {
      dropdownOptions = f.dropdownOptions
          .map((opt) => {
                'value': opt.optionValue,
                'label': opt.optionLabel ?? opt.optionValue?.toString() ?? '',
              })
          .toList();
    }

    return FieldConfig(
      label: f.label,
      fieldName: f.fieldName,
      displayFieldName: f.displayFieldName,
      isFilterable: f.isFilterable,
      isInForm: f.isInForm,
      flex: f.flex,
      maxLines: f.maxLines,
      icon: f.iconData,
      isSortable: f.isSortable,
      fieldType: isMulti
          ? FieldType.multiselect
          : isAutoDropdown
              ? FieldType.dropdown
              : _telaType(f.fieldType, f.fieldName),
      dropdownOptions: dropdownOptions,
      dropdownFutureBuilder: isAutoDropdown
          ? _createDropdownFutureBuilder(f.dropdownEndpoint!)
          : null,
      dropdownValueField:
          f.dropdownValueField.isNotEmpty ? f.dropdownValueField : 'id',
      dropdownDisplayField:
          f.dropdownDisplayField.isNotEmpty ? f.dropdownDisplayField : 'nome',
      isRequired: f.isRequired,
      validator: _createValidator(f),
      isVisibleByDefault: f.isVisibleByDefault,
      isFixed: f.isFixed,
      enabled: isAutoDropdown || isMulti || f.fieldType == TelaFieldType.boolean
          ? true
          : f.enabled,
      defaultValue: f.defaultValue,
      fileConfig: f.fieldType == TelaFieldType.file
          ? FileConfig(
              allowedExtensions: f.allowedExtensions,
              allowMultiple: f.allowMultipleFiles,
              maxFileSize: f.maxFileSize,
              fileFieldName: f.fileFieldName,
            )
          : null,
      dropdownSelectedValue: f.defaultValue,
      showInCard: f.showInCard,
      firstDate: f.firstDate,
      lastDate: f.lastDate,
      dateFormat: f.dateFormat,
    );
  }

  Future<List<Map<String, dynamic>>> Function()? _createDropdownFutureBuilder(
    String endpoint,
  ) {
    return () async {
      L.d('[DynamicMobileGrid] carregando dropdown: $endpoint');
      try {
        final url = endpoint.startsWith('http')
            ? endpoint
            : ApiLinks.baseUrl + endpoint;
        final resp = await NetworkCaller().getRequest(url);
        if (resp.isSuccess && resp.body != null)
          return _extractAnyList(resp.body);
      } catch (e, st) {
        L.e('[DynamicMobileGrid] erro dropdown: $e\n$st');
      }
      return [];
    };
  }

  List<Map<String, dynamic>> _extractAnyList(dynamic body) {
    try {
      if (body is List) {
        return body
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      if (body is Map) {
        final inner =
            body['data'] ?? body['dados'] ?? body['items'] ?? body['content'];
        if (inner is List) {
          return inner
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        if (inner is Map) return _extractAnyList(inner);
      }
      if (body is String) return _extractAnyList(jsonDecode(body));
    } catch (e) {
      L.e('[DynamicMobileGrid] erro ao extrair lista: $e');
    }
    return [];
  }

  String? Function(String?)? _createValidator(TelaField f) {
    if (!f.isRequired) return null;
    return (v) => (v == null || v.isEmpty) ? '${f.label} e obrigatorio' : null;
  }

  static void _addOverrideOnce(
    List<FieldConfig> converted,
    Set<String> inserted,
    FieldConfig override,
  ) {
    final key = override.fieldName.toLowerCase();
    if (inserted.add(key)) converted.add(override);
  }

  static FieldConfig? _firstOverrideWhere(
    Map<String, FieldConfig> overrides,
    bool Function(String key) test,
  ) {
    for (final entry in overrides.entries) {
      if (test(entry.key)) return entry.value;
    }
    return null;
  }

  static String? _extractBase(String fnLower) {
    if (fnLower.endsWith('_id') && fnLower.length > 3) {
      return fnLower.substring(0, fnLower.length - 3);
    }
    if (fnLower.startsWith('id_') && fnLower.length > 3) {
      return fnLower.substring(3);
    }
    if (fnLower.startsWith('cod_') && fnLower.length > 4) {
      return fnLower.substring(4);
    }
    if (fnLower.endsWith('id') &&
        fnLower.length > 2 &&
        !fnLower.contains('_')) {
      return fnLower.substring(0, fnLower.length - 2);
    }
    return null;
  }

  static bool _isAutoDateField(String fnLower) {
    return fnLower == 'dh_created_at' ||
        fnLower == 'dh_updated_at' ||
        fnLower == 'dhcreatedat' ||
        fnLower == 'dhupdatedat' ||
        fnLower == 'created_at' ||
        fnLower == 'updated_at';
  }

  static bool _isRawFkIdField(String fnLower, Set<String> allDropdownNames) {
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

    final base = _extractBase(fnLower);
    if (base == null || base.length < 2) return false;

    for (final name in allDropdownNames) {
      if (name == base ||
          name.contains(base) ||
          base.contains(name) ||
          name.replaceAll('_', '') == base.replaceAll('_', '')) {
        return true;
      }
    }
    return false;
  }

  FieldType _telaType(TelaFieldType type, String fieldName) {
    final name = fieldName.toLowerCase();
    if (name == 'senha' || name.endsWith('_senha') || name == 'password') {
      return FieldType.password;
    }
    if (name == 'email' || name.endsWith('_email')) return FieldType.email;
    if (name == 'cpf' || name.endsWith('_cpf')) return FieldType.cpf;
    if (name == 'cnpj' || name.endsWith('_cnpj')) return FieldType.cnpj;
    if (name == 'cpfcnpj' || name == 'cpf_cnpj' || name == 'documento') {
      return FieldType.cpf;
    }
    if (name == 'telefone' || name == 'celular' || name.endsWith('_telefone')) {
      return FieldType.phone;
    }
    if (type.index < FieldType.values.length)
      return FieldType.values[type.index];
    return FieldType.text;
  }

  String _endpoint(String? override, String backendEndpoint) {
    if (override != null && override.isNotEmpty) return override;
    return backendEndpoint.startsWith('http')
        ? backendEndpoint
        : ApiLinks.baseUrl + backendEndpoint;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<TelaConfig>(
          future: _telaFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Scaffold(
                appBar: AppBar(title: const Text('Erro')),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 56, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Erro ao carregar tela: ${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () =>
                              setState(() => _telaFuture = _loadTelaConfig()),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Scaffold(
                body: Center(child: Text('Nenhuma tela encontrada.')),
              );
            }

            final tela = snapshot.data!;
            final serverActions = tela.actions.map((a) {
              return ServerAction(
                label: a.label,
                icon: _iconFromName(a.icon),
                method: a.method,
                endpoint: _endpoint(null, a.endpoint),
                confirmMessage: a.confirmMessage,
                requiredPermission: a.requiredPermission,
              );
            }).toList();

            return GenericMobileGridScreen(
              title: tela.titulo,
              fetchEndpoint: _endpoint(
                widget.fetchEndpointOverride,
                tela.fetchEndpoint,
              ),
              createEndpoint: _endpoint(
                widget.createEndpointOverride,
                tela.createEndpoint,
              ),
              updateEndpoint: _endpoint(
                widget.updateEndpointOverride,
                tela.updateEndpoint,
              ),
              deleteEndpoint: _endpoint(
                widget.deleteEndpointOverride,
                tela.deleteEndpoint,
              ),
              hasPermission: widget.hasPermission,
              asyncHasPermission: AuthService().hasPermission,
              fieldConfigs: _convertToFieldConfigs(tela.fields),
              idFieldName: tela.idFieldName,
              dateFieldName: tela.dateFieldName,
              storageKey: widget.storageKey ?? 'dynamic_${tela.nome}',
              onItemTap: widget.onItemTap,
              detailScreenBuilder: widget.detailScreenBuilder ??
                  (tela.relatedGrids.isNotEmpty
                      ? (item) => GenericDetailFormScreen(
                            item: item,
                            telaNome: tela.nome,
                            hasPermission: widget.hasPermission,
                          )
                      : null),
              extraParams: widget.extraParams,
              enableSearch: tela.enableSearch,
              enableDebugMode: tela.enableDebugMode,
              useUserBannerAppBar: tela.useUserBannerAppBar,
              onUserBannerTapped: widget.onUserBannerTapped,
              onBannerRefresh: widget.onBannerRefresh,
              additionalFormData: widget.additionalFormData,
              dynamicAdditionalFormData: widget.dynamicAdditionalFormData,
              customActions: widget.customActions,
              serverActions: serverActions,
            );
          },
        ),
      ],
    );
  }

  IconData? _iconFromName(String? name) {
    if (name == null) return null;
    switch (name) {
      case 'add':
        return Icons.add;
      case 'edit':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      case 'visibility':
      case 'view':
        return Icons.visibility;
      case 'file':
        return Icons.attach_file;
      case 'email':
        return Icons.email;
      case 'phone':
        return Icons.phone;
      case 'calendar':
        return Icons.calendar_today;
      case 'check':
      case 'ok':
        return Icons.check_circle;
      default:
        return Icons.play_circle_outline;
    }
  }
}
