import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/customization/generic_grid_card_1_1.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/services/tela_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart'; // ⬅️ adiciona o console flutuante

import '../models/telas_model.dart';

typedef SecurityCheck = bool Function(String permission);
typedef OnItemTap = void Function(
    Map<String, dynamic> item, BuildContext context);

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

  const DynamicGridDynamicScreen({
    Key? key,
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
  }) : super(key: key);

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
    print(
        '🚀 [DynamicGridDynamicScreen] Iniciando carregamento da tela: ${widget.telaNome}');
    try {
      final tela = await _telaService.getTelaFromCache(widget.telaNome);

      if (tela != null) {
        print('✅ [DynamicGridDynamicScreen] Tela carregada com sucesso.');
        print('🧩 Campos: ${tela.fields.length}');
        return tela;
      } else {
        print('❌ [DynamicGridDynamicScreen] Nenhuma tela retornada (null).');
        throw Exception('Tela ${widget.telaNome} não encontrada');
      }
    } catch (e, stack) {
      print('💥 [DynamicGridDynamicScreen] Erro em _loadTelaConfig(): $e');
      print('📄 StackTrace: $stack');
      rethrow;
    }
  }

  List<FieldConfig> _convertToFieldConfigs(List<TelaField> fields,
      {bool forInsert = true, bool forUpdate = false}) {
    print(
        '🧱 [DynamicGridDynamicScreen] Convertendo ${fields.length} campos...');
    return fields.where((field) {
      if (forInsert && !field.showInInsert) return false;
      if (forUpdate && !field.showInUpdate) return false;
      return field.isInForm;
    }).map((field) {
      print('⚙️ Campo: ${field.label} (${field.fieldType})');

      List<Map<String, dynamic>>? dropdownOptions;
      if (field.dropdownOptions.isNotEmpty) {
        final uniqueOptions = <String, Map<String, dynamic>>{};
        for (final option in field.dropdownOptions) {
          final value = option.optionValue?.toString() ?? '';
          if (value.isNotEmpty && !uniqueOptions.containsKey(value)) {
            uniqueOptions[value] = {
              'value': option.optionValue,
              'label':
                  option.optionLabel ?? option.optionValue?.toString() ?? '',
            };
          }
        }
        dropdownOptions = uniqueOptions.values.toList();
      }

      dynamic selectedValue = field.dropdownSelectedValue;
      if (selectedValue != null && dropdownOptions != null) {
        final exists = dropdownOptions.any(
          (o) => o['value']?.toString() == selectedValue.toString(),
        );
        if (!exists) selectedValue = null;
      }

      return FieldConfig(
        label: field.label,
        fieldName: field.fieldName,
        displayFieldName: field.displayFieldName,
        isFilterable: field.isFilterable,
        isInForm: field.isInForm,
        flex: field.flex,
        maxLines: field.maxLines,
        icon: field.iconData,
        isSortable: field.isSortable,
        fieldType: FieldType.values[field.fieldType.index],
        dropdownOptions: dropdownOptions,
        dropdownFutureBuilder: field.dropdownEndpoint != null
            ? _createDropdownFutureBuilder(field.dropdownEndpoint!)
            : null,
        dropdownValueField: field.dropdownValueField,
        dropdownDisplayField: field.dropdownDisplayField,
        isRequired: field.isRequired,
        validator: _createValidator(field),
        isVisibleByDefault: field.isVisibleByDefault,
        isFixed: field.isFixed,
        enabled: field.enabled,
        defaultValue: field.defaultValue,
        fileConfig: field.fieldType == FieldType.file
            ? FileConfig(
                allowedExtensions: field.allowedExtensions,
                allowMultiple: field.allowMultipleFiles,
                maxFileSize: field.maxFileSize,
                fileFieldName: field.fileFieldName,
              )
            : null,
        dropdownSelectedValue: selectedValue,
        showInCard: field.showInCard,
        firstDate: field.firstDate,
        lastDate: field.lastDate,
        dateFormat: field.dateFormat,
      );
    }).toList();
  }

  // 🔧 Corrigido: suporta List e Map para evitar erro _Map<String, dynamic> is not List
  Future<List<Map<String, dynamic>>> Function()? _createDropdownFutureBuilder(
      String endpoint) {
    return () async {
      print('🌐 [DynamicGridDynamicScreen] Carregando dropdown de $endpoint');
      try {
        final response = await NetworkCaller().getRequest(endpoint);
        print('📡 [Dropdown] Status: ${response.statusCode}');
        print('📦 [Dropdown] Body: ${response.body}');

        if (response.isSuccess && response.body != null) {
          final body = response.body!;
          final data = body['data'] ?? body;

          if (data is List) {
            print('✅ Dropdown data é uma LISTA (${data.length})');
            return data.map<Map<String, dynamic>>((it) {
              return {
                'value': it['value'] ?? it['id'],
                'label': it['label'] ??
                    it['name'] ??
                    it['value']?.toString() ??
                    'Sem label',
              };
            }).toList();
          }

          if (data is Map<String, dynamic>) {
            print('✅ Dropdown data é um MAP, convertendo para lista');
            return [
              {
                'value': data['value'] ?? data['id'],
                'label': data['label'] ??
                    data['name'] ??
                    data['value']?.toString() ??
                    'Sem label',
              }
            ];
          }

          print('⚠️ Tipo inesperado em dropdown: ${data.runtimeType}');
        }
        return [];
      } catch (e, stack) {
        print('❌ [Dropdown] Erro ao carregar: $e');
        print('📄 Stack: $stack');
        return [];
      }
    };
  }

  String? Function(String?)? _createValidator(TelaField field) {
    if (!field.isRequired) return null;
    return (value) {
      if (value == null || value.isEmpty) return '${field.label} é obrigatório';
      return null;
    };
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<TelaConfig>(
          future: _telaFuture,
          builder: (context, s) {
            if (s.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }
            if (s.hasError) {
              print(
                  '💥 [DynamicGridDynamicScreen] Erro FutureBuilder: ${s.error}');
              return Scaffold(
                appBar: AppBar(title: const Text('Erro')),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Erro ao carregar tela: ${s.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            setState(() => _telaFuture = _loadTelaConfig()),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (!s.hasData) {
              print(
                  '⚠️ [DynamicGridDynamicScreen] Nenhum dado retornado pelo Future.');
              return const Scaffold(
                  body: Center(child: Text('Tela não encontrada')));
            }

            final tela = s.data!;
            print(
                '✅ [DynamicGridDynamicScreen] Renderizando tela "${tela.nome}"');
            print('   ↳ fetchEndpoint: ${tela.fetchEndpoint}');
            print('   ↳ createEndpoint: ${tela.createEndpoint}');
            print('   ↳ updateEndpoint: ${tela.updateEndpoint}');
            print('   ↳ deleteEndpoint: ${tela.deleteEndpoint}');
            print('   ↳ Campos: ${tela.fields.length}');

            return GenericMobileGridScreen(
              title: tela.titulo,
              fetchEndpoint: ApiLinks.baseUrl + tela.fetchEndpoint,
              createEndpoint: ApiLinks.baseUrl + tela.createEndpoint,
              updateEndpoint: ApiLinks.baseUrl + tela.updateEndpoint,
              deleteEndpoint: ApiLinks.baseUrl + tela.deleteEndpoint,
              hasPermission: widget.hasPermission,
              fieldConfigs: _convertToFieldConfigs(tela.fields),
              idFieldName: tela.idFieldName,
              dateFieldName: tela.dateFieldName,
              storageKey: widget.storageKey ??
                  tela.storageKey ??
                  'dynamic_grid_${tela.nome}',
              onItemTap: widget.onItemTap,
              detailScreenBuilder: widget.detailScreenBuilder,
              extraParams: widget.extraParams,
              enableSearch: tela.enableSearch,
              enableDebugMode: tela.enableDebugMode,
              useUserBannerAppBar: tela.useUserBannerAppBar,
              onUserBannerTapped: widget.onUserBannerTapped,
              onBannerRefresh: widget.onBannerRefresh,
              additionalFormData: widget.additionalFormData,
              dynamicAdditionalFormData: widget.dynamicAdditionalFormData,
            );
          },
        ),

        // 🧠 Console flutuante de debug com botão copiar
        const FloatingConsoleOverlay(),
      ],
    );
  }
}
