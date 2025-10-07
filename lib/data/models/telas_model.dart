import 'package:task_manager_flutter/data/customization/generic_grid_card.dart';
import 'package:flutter/material.dart';

class TelaConfig {
  final int id;
  final String nome;
  final String descricao;
  final String titulo;
  final String fetchEndpoint;
  final String createEndpoint;
  final String updateEndpoint;
  final String deleteEndpoint;
  final String idFieldName;
  final String? dateFieldName;
  final String? storageKey;
  final bool enableSearch;
  final bool enableDebugMode;
  final bool useUserBannerAppBar;
  final List<TelaField> fields;

  TelaConfig({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.titulo,
    required this.fetchEndpoint,
    required this.createEndpoint,
    required this.updateEndpoint,
    required this.deleteEndpoint,
    this.idFieldName = 'id',
    this.dateFieldName,
    this.storageKey,
    this.enableSearch = true,
    this.enableDebugMode = false,
    this.useUserBannerAppBar = false,
    required this.fields,
  });

  factory TelaConfig.fromJson(Map<String, dynamic> json) {
    return TelaConfig(
      id: json['id'] ?? 0,
      nome: json['nome'] ?? '',
      descricao: json['descricao'] ?? '',
      titulo: json['titulo'] ?? '',
      fetchEndpoint: json['fetchEndpoint'] ?? '',
      createEndpoint: json['createEndpoint'] ?? '',
      updateEndpoint: json['updateEndpoint'] ?? '',
      deleteEndpoint: json['deleteEndpoint'] ?? '',
      idFieldName: json['idFieldName'] ?? 'id',
      dateFieldName: json['dateFieldName'],
      storageKey: json['storageKey'],
      enableSearch: json['enableSearch'] ?? true,
      enableDebugMode: json['enableDebugMode'] ?? false,
      useUserBannerAppBar: json['useUserBannerAppBar'] ?? false,
      fields: (json['fields'] as List? ?? [])
          .map((field) => TelaField.fromJson(field))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'titulo': titulo,
      'fetchEndpoint': fetchEndpoint,
      'createEndpoint': createEndpoint,
      'updateEndpoint': updateEndpoint,
      'deleteEndpoint': deleteEndpoint,
      'idFieldName': idFieldName,
      'dateFieldName': dateFieldName,
      'storageKey': storageKey,
      'enableSearch': enableSearch,
      'enableDebugMode': enableDebugMode,
      'useUserBannerAppBar': useUserBannerAppBar,
      'fields': fields.map((field) => field.toJson()).toList(),
    };
  }
}

class TelaField {
  final int id;
  final String label;
  final String fieldName;
  final String? displayFieldName;
  final FieldType fieldType;
  final bool isFilterable;
  final bool isInForm;
  final bool isVisibleByDefault;
  final bool isFixed;
  final bool isRequired;
  final bool enabled;
  final bool showInCard;
  final int flex;
  final int maxLines;
  final String? iconName;
  final bool isSortable;
  final String dropdownValueField;
  final String dropdownDisplayField;
  final String? dropdownEndpoint;
  final String dateFormat;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool showInInsert;
  final bool showInUpdate;
  final bool showInGrid;
  final int fieldOrder;
  final String formSection;
  final dynamic defaultValue;
  final dynamic dropdownSelectedValue;
  final List<String> allowedExtensions;
  final bool allowMultipleFiles;
  final int maxFileSize;
  final String fileFieldName;
  final List<FieldDropdownOption> dropdownOptions;

  TelaField({
    required this.id,
    required this.label,
    required this.fieldName,
    this.displayFieldName,
    required this.fieldType,
    this.isFilterable = true,
    this.isInForm = true,
    this.isVisibleByDefault = true,
    this.isFixed = false,
    this.isRequired = false,
    this.enabled = true,
    this.showInCard = true,
    this.flex = 1,
    this.maxLines = 1,
    this.iconName,
    this.isSortable = true,
    this.dropdownValueField = 'value',
    this.dropdownDisplayField = 'label',
    this.dropdownEndpoint,
    this.dateFormat = 'dd/MM/yyyy',
    this.firstDate,
    this.lastDate,
    this.showInInsert = true,
    this.showInUpdate = true,
    this.showInGrid = true,
    this.fieldOrder = 0,
    this.formSection = 'Geral',
    this.defaultValue,
    this.dropdownSelectedValue,
    this.allowedExtensions = const [],
    this.allowMultipleFiles = false,
    this.maxFileSize = 5242880,
    this.fileFieldName = 'file',
    this.dropdownOptions = const [],
  });

  factory TelaField.fromJson(Map<String, dynamic> json) {
    // Converte string de data para DateTime
    DateTime? parseDate(String? dateString) {
      if (dateString == null) return null;
      try {
        return DateTime.parse(dateString);
      } catch (e) {
        return null;
      }
    }

    return TelaField(
      id: json['id'] ?? 0,
      label: json['label'] ?? '',
      fieldName: json['fieldName'] ?? '',
      displayFieldName: json['displayFieldName'],
      fieldType: _parseFieldType(json['fieldType']),
      isFilterable: json['isFilterable'] ?? true,
      isInForm: json['isInForm'] ?? true,
      isVisibleByDefault: json['isVisibleByDefault'] ?? true,
      isFixed: json['isFixed'] ?? false,
      isRequired: json['isRequired'] ?? false,
      enabled: json['enabled'] ?? true,
      showInCard: json['showInCard'] ?? true,
      flex: json['flex'] ?? 1,
      maxLines: json['maxLines'] ?? 1,
      iconName: json['iconName'],
      isSortable: json['isSortable'] ?? true,
      dropdownValueField: json['dropdownValueField'] ?? 'value',
      dropdownDisplayField: json['dropdownDisplayField'] ?? 'label',
      dropdownEndpoint: json['dropdownEndpoint'],
      dateFormat: json['dateFormat'] ?? 'dd/MM/yyyy',
      firstDate: parseDate(json['firstDate']),
      lastDate: parseDate(json['lastDate']),
      showInInsert: json['showInInsert'] ?? true,
      showInUpdate: json['showInUpdate'] ?? true,
      showInGrid: json['showInGrid'] ?? true,
      fieldOrder: json['fieldOrder'] ?? 0,
      formSection: json['formSection'] ?? 'Geral',
      defaultValue: json['defaultValue'],
      dropdownSelectedValue: json['dropdownSelectedValue'],
      allowedExtensions: json['allowedExtensions'] != null
          ? (json['allowedExtensions'] is String
              ? (json['allowedExtensions'] as String)
                  .split(',')
                  .map((e) => e.trim())
                  .toList()
              : (json['allowedExtensions'] as List).cast<String>())
          : [],
      allowMultipleFiles: json['allowMultipleFiles'] ?? false,
      maxFileSize: json['maxFileSize'] ?? 5242880,
      fileFieldName: json['fileFieldName'] ?? 'file',
      dropdownOptions: (json['dropdownOptions'] as List? ?? [])
          .map((option) => FieldDropdownOption.fromJson(option))
          .toList(),
    );
  }

  static FieldType _parseFieldType(String? type) {
    if (type == null) return FieldType.text;

    switch (type.toLowerCase()) {
      case 'number':
        return FieldType.number;
      case 'email':
        return FieldType.email;
      case 'date':
        return FieldType.date;
      case 'multiline':
        return FieldType.multiline;
      case 'dropdown':
        return FieldType.dropdown;
      case 'boolean':
        return FieldType.boolean;
      case 'file':
        return FieldType.file;
      case 'password':
        return FieldType.password;
      case 'phone':
        return FieldType.phone;
      case 'cpf':
        return FieldType.cpf;
      case 'cnpj':
        return FieldType.cnpj;
      case 'currency':
        return FieldType.currency;
      case 'percentage':
        return FieldType.percentage;
      case 'url':
        return FieldType.url;
      default:
        return FieldType.text;
    }
  }

  IconData? get iconData {
    if (iconName == null) return null;

    // Mapeamento de ícones Material Icons
    final iconMap = {
      'title': Icons.title,
      'description': Icons.description,
      'info': Icons.info,
      'priority_high': Icons.priority_high,
      'business': Icons.business,
      'close': Icons.close,
      'calendar_today': Icons.calendar_today,
      'event_available': Icons.event_available,
      'attach_file': Icons.attach_file,
      'person': Icons.person,
      'email': Icons.email,
      'phone': Icons.phone,
      'location_on': Icons.location_on,
      'money': Icons.money,
      'percentage': Icons.percent,
      'link': Icons.link,
      'lock': Icons.lock,
    };

    return iconMap[iconName];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'fieldName': fieldName,
      'displayFieldName': displayFieldName,
      'fieldType': fieldType.toString().split('.').last,
      'isFilterable': isFilterable,
      'isInForm': isInForm,
      'isVisibleByDefault': isVisibleByDefault,
      'isFixed': isFixed,
      'isRequired': isRequired,
      'enabled': enabled,
      'showInCard': showInCard,
      'flex': flex,
      'maxLines': maxLines,
      'iconName': iconName,
      'isSortable': isSortable,
      'dropdownValueField': dropdownValueField,
      'dropdownDisplayField': dropdownDisplayField,
      'dropdownEndpoint': dropdownEndpoint,
      'dateFormat': dateFormat,
      'firstDate': firstDate?.toIso8601String(),
      'lastDate': lastDate?.toIso8601String(),
      'showInInsert': showInInsert,
      'showInUpdate': showInUpdate,
      'showInGrid': showInGrid,
      'fieldOrder': fieldOrder,
      'formSection': formSection,
      'defaultValue': defaultValue,
      'dropdownSelectedValue': dropdownSelectedValue,
      'allowedExtensions': allowedExtensions,
      'allowMultipleFiles': allowMultipleFiles,
      'maxFileSize': maxFileSize,
      'fileFieldName': fileFieldName,
      'dropdownOptions':
          dropdownOptions.map((option) => option.toJson()).toList(),
    };
  }
}

class FieldDropdownOption {
  final int id;
  final String optionValue;
  final String optionLabel;
  final int optionOrder;

  FieldDropdownOption({
    required this.id,
    required this.optionValue,
    required this.optionLabel,
    required this.optionOrder,
  });

  factory FieldDropdownOption.fromJson(Map<String, dynamic> json) {
    return FieldDropdownOption(
      id: json['id'] ?? 0,
      optionValue: json['optionValue'] ?? '',
      optionLabel: json['optionLabel'] ?? '',
      optionOrder: json['optionOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'optionValue': optionValue,
      'optionLabel': optionLabel,
      'optionOrder': optionOrder,
    };
  }
}

class UserFieldPreference {
  final int id;
  final int userId;
  final int telaId;
  final String fieldName;
  final bool isVisible;
  final double? widthPreference;
  final int orderPreference;

  UserFieldPreference({
    required this.id,
    required this.userId,
    required this.telaId,
    required this.fieldName,
    required this.isVisible,
    this.widthPreference,
    this.orderPreference = 0,
  });

  factory UserFieldPreference.fromJson(Map<String, dynamic> json) {
    return UserFieldPreference(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      telaId: json['telaId'] ??
          (json['tela'] != null ? json['tela']['id'] ?? 0 : 0),
      fieldName: json['fieldName'] ?? '',
      isVisible: json['isVisible'] ?? true,
      widthPreference: json['widthPreference']?.toDouble(),
      orderPreference: json['orderPreference'] ?? 0,
    );
  }
}
