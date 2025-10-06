import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/customization/generic_grid_card.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/services/tela_caller.dart';

import '../models/telas_model.dart';
// ==============================================
// MOBILE GRID SCREEN - MATERIAL DESIGN 3 COMPLETO
// ==============================================

// screens/dynamic_grid_screen.dart
class DynamicGridScreen<T> extends StatefulWidget {
  final String telaNome;
  final FromJson<T> fromJson;
  final ToJson<T> toJson;
  final SecurityCheck hasPermission;
  final String? storageKey;
  final OnItemTap<T>? onItemTap;
  final Widget Function(T item)? detailScreenBuilder;
  final Map<String, dynamic>? extraParams;
  final VoidCallback? onUserBannerTapped;
  final VoidCallback? onBannerRefresh;
  final Map<String, dynamic>? additionalFormData;
  final Map<String, dynamic> Function(T? item)? dynamicAdditionalFormData;

  const DynamicGridScreen({
    super.key,
    required this.telaNome,
    required this.fromJson,
    required this.toJson,
    required this.hasPermission,
    this.storageKey,
    this.onItemTap,
    this.detailScreenBuilder,
    this.extraParams,
    this.onUserBannerTapped,
    this.onBannerRefresh,
    this.additionalFormData,
    this.dynamicAdditionalFormData,
  });

  @override
  State<DynamicGridScreen<T>> createState() => _DynamicGridScreenState<T>();
}

class _DynamicGridScreenState<T> extends State<DynamicGridScreen<T>> {
  late Future<TelaConfig> _telaFuture;
  final TelaService _telaService = TelaService(
    networkCaller: NetworkCaller(),
    prefs: SharedPreferences.getInstance() as SharedPreferences,
  );

  @override
  void initState() {
    super.initState();
    _telaFuture = _loadTelaConfig();
  }

  Future<TelaConfig> _loadTelaConfig() async {
    // Tenta carregar do cache primeiro
    final cachedTela = await _telaService.getTelaFromCache(widget.telaNome);
    if (cachedTela != null) {
      return cachedTela;
    }

    // Se não encontrou no cache, busca da API
    final tela = await _telaService.getTelaByNome(widget.telaNome);
    if (tela != null) {
      await _telaService.saveTelaToCache(widget.telaNome, tela);
      return tela;
    }

    throw Exception('Tela ${widget.telaNome} não encontrada');
  }

  List<FieldConfig> _convertToFieldConfigs(List<TelaField> fields,
      {bool forInsert = true, bool forUpdate = false}) {
    return fields.where((field) {
      if (forInsert && !field.showInInsert) return false;
      if (forUpdate && !field.showInUpdate) return false;
      return field.isInForm;
    }).map((field) {
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
        fieldType: field.fieldType,
        dropdownOptions: field.dropdownOptionsMap,
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
        fileConfig: field.fieldType == FieldType.file ? field.fileConfig : null,
        dropdownSelectedValue: field.dropdownSelectedValue,
        showInCard: field.showInCard,
        firstDate: field.firstDate,
        lastDate: field.lastDate,
        dateFormat: field.dateFormat,
      );
    }).toList();
  }

  Future<List<Map<String, dynamic>>> Function()? _createDropdownFutureBuilder(
      String endpoint) {
    return () async {
      try {
        final response = await NetworkCaller().getRequest(endpoint);
        if (response.isSuccess && response.body != null) {
          final data = response.body!['data'] ?? response.body!;
          return (data as List).cast<Map<String, dynamic>>();
        }
        return [];
      } catch (e) {
        print('Erro ao carregar dropdown: $e');
        return [];
      }
    };
  }

  String? Function(String?)? _createValidator(TelaField field) {
    if (!field.isRequired) return null;

    return (value) {
      if (value == null || value.isEmpty) {
        return '${field.label} é obrigatório';
      }

      // Validações específicas por tipo
      switch (field.fieldType) {
        case FieldType.email:
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return 'Email inválido';
          }
          break;
        case FieldType.cpf:
          if (!_validateCPF(value)) {
            return 'CPF inválido';
          }
          break;
        case FieldType.cnpj:
          if (!_validateCNPJ(value)) {
            return 'CNPJ inválido';
          }
          break;
        case FieldType.phone:
          if (!RegExp(r'^\(\d{2}\)\s\d{4,5}-\d{4}$').hasMatch(value)) {
            return 'Telefone inválido';
          }
          break;
        default:
          break;
      }

      return null;
    };
  }

  bool _validateCPF(String cpf) {
    // Implementação da validação de CPF
    return true;
  }

  bool _validateCNPJ(String cnpj) {
    // Implementação da validação de CNPJ
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TelaConfig>(
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar tela: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _telaFuture = _loadTelaConfig();
                    }),
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: Text('Tela não encontrada')),
          );
        }

        final telaConfig = snapshot.data!;

        return GenericMobileGridScreen<T>(
          title: telaConfig.titulo,
          fetchEndpoint: telaConfig.fetchEndpoint,
          createEndpoint: telaConfig.createEndpoint,
          updateEndpoint: telaConfig.updateEndpoint,
          deleteEndpoint: telaConfig.deleteEndpoint,
          fromJson: widget.fromJson,
          toJson: widget.toJson,
          hasPermission: widget.hasPermission,
          fieldConfigs: _convertToFieldConfigs(telaConfig.fields),
          idFieldName: telaConfig.idFieldName,
          dateFieldName: telaConfig.dateFieldName,
          storageKey: widget.storageKey ??
              telaConfig.storageKey ??
              'dynamic_grid_${telaConfig.nome}',
          onItemTap: widget.onItemTap,
          detailScreenBuilder: widget.detailScreenBuilder,
          extraParams: widget.extraParams,
          enableSearch: telaConfig.enableSearch,
          enableDebugMode: telaConfig.enableDebugMode,
          useUserBannerAppBar: telaConfig.useUserBannerAppBar,
          onUserBannerTapped: widget.onUserBannerTapped,
          onBannerRefresh: widget.onBannerRefresh,
          additionalFormData: widget.additionalFormData,
          dynamicAdditionalFormData: widget.dynamicAdditionalFormData,
        );
      },
    );
  }
}
