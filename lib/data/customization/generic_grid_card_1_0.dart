import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/customization/generic_grid_card.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/services/tela_caller.dart';

import '../models/telas_model.dart';

class DynamicGridDynamicScreen<T> extends StatefulWidget {
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

  const DynamicGridDynamicScreen({
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
  State<DynamicGridDynamicScreen<T>> createState() =>
      _DynamicGridDynamicScreenState<T>();
}

class _DynamicGridDynamicScreenState<T>
    extends State<DynamicGridDynamicScreen<T>> {
  late Future<TelaConfig> _telaFuture;
  late TelaService _telaService;

  @override
  void initState() {
    super.initState();
    _telaService = TelaService(networkCaller: NetworkCaller());
    _telaFuture = _loadTelaConfig();
  }

  Future<TelaConfig> _loadTelaConfig() async {
    print('🔄 Carregando configuração da tela: ${widget.telaNome}');

    // Tenta do cache (que já tem fallback para API)
    final tela = await _telaService.getTelaFromCache(widget.telaNome);

    if (tela != null) {
      print('✅ Configuração carregada com sucesso');
      return tela;
    }

    throw Exception(
        'Tela ${widget.telaNome} não encontrada no cache nem na API');
  }

  List<FieldConfig> _convertToFieldConfigs(List<TelaField> fields,
      {bool forInsert = true, bool forUpdate = false}) {
    return fields.where((field) {
      if (forInsert && !field.showInInsert) return false;
      if (forUpdate && !field.showInUpdate) return false;
      return field.isInForm;
    }).map((field) {
      // **CORREÇÃO: Garantir que dropdownOptions seja único e válido**
      List<Map<String, dynamic>>? dropdownOptions;
      if (field.dropdownOptions.isNotEmpty) {
        // Remove duplicatas baseado no valor
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

        // Debug para verificar as opções
        print(
            'Dropdown ${field.fieldName}: ${dropdownOptions.length} opções únicas');
      }

      // **CORREÇÃO: Tratar dropdownSelectedValue para evitar valores inválidos**
      dynamic selectedValue = field.dropdownSelectedValue;
      if (selectedValue != null && dropdownOptions != null) {
        final valueExists = dropdownOptions.any((option) =>
            option['value']?.toString() == selectedValue?.toString());
        if (!valueExists) {
          print(
              '⚠️ Valor selecionado $selectedValue não existe nas opções para ${field.fieldName}');
          selectedValue = null;
        }
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
        fieldType: field.fieldType,
        dropdownOptions: dropdownOptions, // Usa a lista tratada
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
        dropdownSelectedValue: selectedValue, // Usa o valor tratado
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
          if (data is List) {
            final List<Map<String, dynamic>> items =
                data.cast<Map<String, dynamic>>();

            // **CORREÇÃO: Remove itens duplicados e garante valores únicos**
            final uniqueItems = <String, Map<String, dynamic>>{};
            for (final item in items) {
              final value =
                  item['value']?.toString() ?? item['id']?.toString() ?? '';
              if (value.isNotEmpty && !uniqueItems.containsKey(value)) {
                uniqueItems[value] = {
                  'value': item['value'] ?? item['id'],
                  'label': item['label'] ??
                      item['name'] ??
                      item['value']?.toString() ??
                      'Sem label',
                };
              }
            }

            print(
                '✅ Dropdown carregado: ${uniqueItems.length} itens únicos de $endpoint');
            return uniqueItems.values.toList();
          }
        }
        print('⚠️ Dropdown vazio ou erro na resposta de $endpoint');
        return [];
      } catch (e) {
        print('❌ Erro ao carregar dropdown de $endpoint: $e');
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
    // Implementação simplificada - substitua pela validação real
    final cleaned = cpf.replaceAll(RegExp(r'[^\d]'), '');
    return cleaned.length == 11;
  }

  bool _validateCNPJ(String cnpj) {
    // Implementação simplificada - substitua pela validação real
    final cleaned = cnpj.replaceAll(RegExp(r'[^\d]'), '');
    return cleaned.length == 14;
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

        // **CORREÇÃO: Debug para verificar os campos com dropdown**
        _debugDropdownFields(telaConfig.fields);

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

  // **NOVO MÉTODO: Debug para campos dropdown**
  void _debugDropdownFields(List<TelaField> fields) {
    for (final field in fields) {
      if (field.dropdownOptions.isNotEmpty || field.dropdownEndpoint != null) {
        print('🔍 Dropdown Field: ${field.fieldName}');
        print('   - Tipo: ${field.fieldType}');
        print('   - Opções locais: ${field.dropdownOptions.length}');
        print('   - Endpoint: ${field.dropdownEndpoint}');
        print('   - Valor selecionado: ${field.dropdownSelectedValue}');

        if (field.dropdownOptions.isNotEmpty) {
          final values =
              field.dropdownOptions.map((o) => o.optionValue).toList();
          print('   - Valores disponíveis: $values');

          // Verifica duplicatas
          final valueSet = <dynamic>{};
          final duplicates = <dynamic>[];
          for (final value in values) {
            if (!valueSet.add(value)) {
              duplicates.add(value);
            }
          }
          if (duplicates.isNotEmpty) {
            print('   ⚠️ VALORES DUPLICADOS: $duplicates');
          }
        }
      }
    }
  }
}
