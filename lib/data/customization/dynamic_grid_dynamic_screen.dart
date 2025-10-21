// lib/data/customization/dynamic_grid_dynamic_screen.dart
// ------------------------------------------------------------
// DynamicGridDynamicScreen
// - Carrega TelaConfig (cache + API)
// - Converte TelaField (modelo) -> FieldConfig (UI)
// - Mapeia actions (TelaAction) -> ServerAction e passa para o grid
// - Passa asyncHasPermission (AuthService) para liberar botões
// - Inclui console flutuante e logs AppLogger
// - Corrigido erro _Map<String, String?> is not Iterable<dynamic>
// ------------------------------------------------------------

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/customization/generic_grid_card_1_1.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/services/tela_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart';
import '../models/telas_model.dart';
import '../services/auth_service.dart';

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
    AppLogger.i.info('🚀 Carregando tela: ${widget.telaNome}');
    try {
      final tela = await _telaService.getTelaFromCache(widget.telaNome);

      if (tela?.actions != null) {
        AppLogger.i.info(
            '🧩 Ações carregadas: ${tela?.actions!.map((a) => a.label).join(', ')}');
      }

      if (tela != null) {
        AppLogger.i.info(
            '✅ Tela carregada: ${tela.nome} (Campos=${tela.fields.length}, Actions=${tela.actions.length})');
        return tela;
      } else {
        AppLogger.i.error('❌ Nenhuma tela retornada.');
        throw Exception('Tela ${widget.telaNome} não encontrada');
      }
    } catch (e, stack) {
      AppLogger.i.error('💥 Erro em _loadTelaConfig(): $e\n$stack');
      rethrow;
    }
  }

  List<FieldConfig> _convertToFieldConfigs(List<TelaField> fields,
      {bool forInsert = true, bool forUpdate = false}) {
    AppLogger.i.info('🧱 Convertendo ${fields.length} campos...');
    return fields.where((field) {
      if (forInsert && !field.showInInsert) return false;
      if (forUpdate && !field.showInUpdate) return false;
      return field.isInForm;
    }).map((field) {
      AppLogger.i.debug('⚙️ Campo: ${field.label} (${field.fieldType})');

      List<Map<String, dynamic>>? dropdownOptions;
      if (field.dropdownOptions.isNotEmpty) {
        final unique = <String, Map<String, dynamic>>{};
        for (final option in field.dropdownOptions) {
          final value = option.optionValue?.toString() ?? '';
          if (value.isNotEmpty && !unique.containsKey(value)) {
            unique[value] = {
              'value': option.optionValue,
              'label':
                  option.optionLabel ?? option.optionValue?.toString() ?? '',
            };
          }
        }
        dropdownOptions = unique.values.toList();
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
        fileConfig: field.fieldType == TelaFieldType.file
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

  // ✅ Corrigido: trata qualquer formato (map, list, etc)
  Future<List<Map<String, dynamic>>> Function()? _createDropdownFutureBuilder(
      String endpoint) {
    return () async {
      AppLogger.i.debug('🌐 Carregando dropdown de $endpoint');
      try {
        final response = await NetworkCaller().getRequest(endpoint);
        AppLogger.i.debug('📡 Resposta dropdown: ${response.statusCode}');

        if (response.isSuccess && response.body != null) {
          final body = response.body!;
          final list = _extractAnyList(body['data'] ?? body['dados'] ?? body);

          AppLogger.i.debug('🧩 Dropdown retornou ${list.length} itens');

          return list.map<Map<String, dynamic>>((it) {
            final map = Map<String, dynamic>.from(it);
            final value = map['value'] ?? map['id'];
            final label =
                map['label'] ?? map['name'] ?? value?.toString() ?? 'Sem label';
            return {'value': value, 'label': label};
          }).toList();
        }

        return [];
      } catch (e, st) {
        AppLogger.i.error('❌ Erro ao carregar dropdown: $e\n$st');
        return [];
      }
    };
  }

  // ✅ Conversão robusta para lista segura
  List<Map<String, dynamic>> _extractAnyList(dynamic body) {
    if (body == null) return [];

    try {
      if (body is List) {
        return body
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }

      if (body is Map) {
        // Se for Map simples, retorna como lista de 1
        if (!body.containsKey('data') &&
            !body.containsKey('dados') &&
            !body.containsKey('items') &&
            !body.containsKey('content')) {
          return [Map<String, dynamic>.from(body)];
        }

        final inner =
            body['data'] ?? body['dados'] ?? body['items'] ?? body['content'];

        if (inner is List) {
          return inner
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }

        if (inner is Map) {
          return [Map<String, dynamic>.from(inner)];
        }
      }

      if (body is String) {
        final decoded = jsonDecode(body);
        return _extractAnyList(decoded);
      }

      return [];
    } catch (e) {
      AppLogger.i.error('💥 Erro em _extractAnyList: $e');
      return [];
    }
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
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (s.hasError) {
              AppLogger.i.error('💥 FutureBuilder erro: ${s.error}');
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
              AppLogger.i.warn('⚠️ Nenhum dado retornado pelo Future.');
              return const Scaffold(
                  body: Center(child: Text('Tela não encontrada')));
            }

            final tela = s.data!;
            AppLogger.i.info(
                '✅ Renderizando "${tela.nome}" fetch=${tela.fetchEndpoint} '
                'create=${tela.createEndpoint} update=${tela.updateEndpoint} delete=${tela.deleteEndpoint} '
                'campos=${tela.fields.length} actions=${tela.actions.length}');

            final serverActions = tela.actions.map((a) {
              return ServerAction(
                label: a.label,
                icon: _iconFromName(a.icon),
                method: a.method,
                endpoint: ApiLinks.baseUrl + a.endpoint,
                confirmMessage: a.confirmMessage,
                requiredPermission: a.requiredPermission,
              );
            }).toList();

            return GenericMobileGridScreen(
              title: tela.titulo,
              fetchEndpoint: ApiLinks.baseUrl + tela.fetchEndpoint,
              createEndpoint: ApiLinks.baseUrl + tela.createEndpoint,
              updateEndpoint: ApiLinks.baseUrl + tela.updateEndpoint,
              deleteEndpoint: ApiLinks.baseUrl + tela.deleteEndpoint,
              hasPermission: widget.hasPermission,
              asyncHasPermission:
                  AuthService().hasPermission, // libera botões dinamicamente
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
              serverActions: serverActions,
            );
          },
        ),

        // 🧠 Console flutuante
        const AppLoggerOverlay(),
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
