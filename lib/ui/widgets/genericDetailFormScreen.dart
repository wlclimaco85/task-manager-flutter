import 'package:flutter/material.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';
import 'package:task_manager_flutter/ui/widgets/tab_config.dart';

class GenericDetailFormScreen<T> extends StatefulWidget {
  final T item;
  final List<TabConfig> tabConfigs;
  final String title;
  final Future<void> Function(Map<String, dynamic> formData) onSave;
  final VoidCallback onBack;
  final SecurityCheck hasPermission;

  const GenericDetailFormScreen({
    super.key,
    required this.item,
    required this.tabConfigs,
    required this.title,
    required this.onSave,
    required this.onBack,
    required this.hasPermission,
  });

  @override
  State<GenericDetailFormScreen<T>> createState() =>
      _GenericDetailFormScreenState<T>();
}

class _GenericDetailFormScreenState<T> extends State<GenericDetailFormScreen<T>>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, dynamic> _formData = {};
  final Map<int, GlobalKey<FormState>> _formKeys = {};
  final Map<String, dynamic> _dropdownValues = {};
  final Map<String, bool> _checkboxValues = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.tabConfigs.length,
      vsync: this,
    );

    // Inicializar chaves para cada aba de formulário
    for (int i = 0; i < widget.tabConfigs.length; i++) {
      if (!widget.tabConfigs[i].isGrid) {
        _formKeys[i] = GlobalKey<FormState>();
      }
    }

    _convertItemToMap(widget.item);
    _initializeFieldValues();
  }

  void _convertItemToMap(T item) {
    if (item is Map) {
      _formData.addAll(item as Map<String, dynamic>);
    } else {
      try {
        final dynamicItem = item as dynamic;
        if (dynamicItem.toJson != null) {
          _formData.addAll(dynamicItem.toJson());
        } else {
          // Fallback: usar toString para propriedades simples
          _formData['id'] = dynamicItem.id?.toString();
          _formData['toString'] = dynamicItem.toString();
        }
      } catch (_) {
        // Último recurso: usar representação string
        _formData['toString'] = item.toString();
      }
    }
  }

  void _initializeFieldValues() {
    // Inicializar valores para dropdowns e checkboxes
    for (final tab in widget.tabConfigs) {
      if (!tab.isGrid && tab.fields != null) {
        for (final field in tab.fields!) {
          if (field.fieldType == FieldType.dropdown) {
            // Obter valor inicial para dropdown
            if (field.fieldName.contains('.')) {
              final parts = field.fieldName.split('.');
              if (_formData[parts[0]] is Map) {
                _dropdownValues[field.fieldName] =
                    _formData[parts[0]][parts[1]]?.toString() ?? '';
              }
            } else {
              _dropdownValues[field.fieldName] =
                  _formData[field.fieldName]?.toString() ?? '';
            }
          } else if (field.fieldType == FieldType.boolean) {
            // Obter valor inicial para checkbox
            if (field.fieldName.contains('.')) {
              final parts = field.fieldName.split('.');
              if (_formData[parts[0]] is Map) {
                _checkboxValues[field.fieldName] =
                    _formData[parts[0]][parts[1]]?.toString() == 'true' ||
                    _formData[parts[0]][parts[1]] == true;
              }
            } else {
              _checkboxValues[field.fieldName] =
                  _formData[field.fieldName]?.toString() == 'true' ||
                  _formData[field.fieldName] == true;
            }
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        bottom: widget.tabConfigs.length > 1
            ? TabBar(
                controller: _tabController,
                tabs: widget.tabConfigs
                    .map((tab) => Tab(icon: Icon(tab.icon), text: tab.title))
                    .toList(),
              )
            : null,
      ),
      body: widget.tabConfigs.length > 1
          ? TabBarView(
              controller: _tabController,
              children: List.generate(widget.tabConfigs.length, (index) {
                return _buildTabContent(widget.tabConfigs[index], index);
              }),
            )
          : _buildTabContent(widget.tabConfigs.first, 0),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final currentIndex = _tabController.index;
          final currentTab = widget.tabConfigs[currentIndex];

          if (!currentTab.isGrid) {
            if (_formKeys[currentIndex]?.currentState?.validate() ?? false) {
              await widget.onSave(_formData);
            }
          } else {
            // Se for uma grid, salva diretamente sem validação de formulário
            await widget.onSave(_formData);
          }
        },
        child: const Icon(Icons.save),
      ),
    );
  }

  Widget _buildTabContent(TabConfig tab, int index) {
    if (tab.isGrid) {
      return GenericGridScreen(
        title: tab.title,
        fetchEndpoint: "${tab.endpoint}/${_formData['id']}/listar",
        createEndpoint: "${tab.endpoint}/${_formData['id']}/criar",
        updateEndpoint: "${tab.endpoint}/${_formData['id']}/atualizar",
        deleteEndpoint: "${tab.endpoint}/${_formData['id']}/deletar",
        fromJson: tab.fromJson ?? (json) => json,
        toJson: tab.toJson != null
            ? (item) => tab.toJson!(item) as Map<String, dynamic>
            : (item) => item as Map<String, dynamic>,
        hasPermission: widget.hasPermission,
        fieldConfigs: tab.gridFieldConfigs ?? [],
      );
    } else {
      return Form(
        key: _formKeys[index],
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: tab.fields!.map((field) => _buildFormField(field)).toList(),
        ),
      );
    }
  }

  Widget _buildFormField(FieldConfig field) {
    switch (field.fieldType) {
      case FieldType.dropdown:
        return _buildDropdownField(field);
      case FieldType.boolean:
        return _buildCheckboxField(field);
      default:
        return _buildTextField(field);
    }
  }

  Widget _buildTextField(FieldConfig field) {
    String initialValue = '';

    if (field.fieldName.contains('.')) {
      final parts = field.fieldName.split('.');
      if (_formData[parts[0]] is Map) {
        initialValue = _formData[parts[0]][parts[1]]?.toString() ?? '';
      }
    } else {
      initialValue = _formData[field.fieldName]?.toString() ?? '';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: field.label,
          prefixIcon: Icon(field.icon),
          border: const OutlineInputBorder(),
        ),
        keyboardType: field.fieldType == FieldType.number
            ? TextInputType.number
            : TextInputType.text,
        maxLines: field.fieldType == FieldType.multiline ? field.maxLines : 1,
        validator: field.validator,
        onChanged: (val) {
          setState(() {
            if (field.fieldName.contains('.')) {
              final parts = field.fieldName.split('.');
              if (_formData[parts[0]] is! Map) {
                _formData[parts[0]] = {};
              }
              _formData[parts[0]][parts[1]] = val;
            } else {
              _formData[field.fieldName] = val;
            }
          });
        },
      ),
    );
  }

  Widget _buildDropdownField(FieldConfig field) {
    // Obter valor inicial
    final currentValue = _dropdownValues[field.fieldName] ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: field.label,
          prefixIcon: Icon(field.icon),
          border: const OutlineInputBorder(),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: currentValue.isNotEmpty ? currentValue : null,
            isExpanded: true,
            items: _buildDropdownItems(field),
            onChanged: (String? newValue) {
              setState(() {
                _dropdownValues[field.fieldName] = newValue ?? '';

                if (field.fieldName.contains('.')) {
                  final parts = field.fieldName.split('.');
                  if (_formData[parts[0]] is! Map) {
                    _formData[parts[0]] = {};
                  }
                  _formData[parts[0]][parts[1]] = newValue;
                } else {
                  _formData[field.fieldName] = newValue;
                }
              });
            },
          ),
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildDropdownItems(FieldConfig field) {
    final items = <DropdownMenuItem<String>>[];

    // Adicionar item vazio
    items.add(
      DropdownMenuItem<String>(
        value: '',
        child: Text('Selecione ${field.label}'),
      ),
    );

    // Adicionar opções estáticas
    if (field.dropdownOptions != null) {
      for (final option in field.dropdownOptions!) {
        items.add(
          DropdownMenuItem<String>(
            value: option[field.dropdownValueField]?.toString(),
            child: Text(option[field.dropdownDisplayField]?.toString() ?? ''),
          ),
        );
      }
    }

    return items;
  }

  Widget _buildCheckboxField(FieldConfig field) {
    final currentValue = _checkboxValues[field.fieldName] ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CheckboxListTile(
        title: Text(field.label),
        subtitle: field.isRequired ? const Text('Obrigatório') : null,
        value: currentValue,
        onChanged: (bool? newValue) {
          setState(() {
            _checkboxValues[field.fieldName] = newValue ?? false;

            if (field.fieldName.contains('.')) {
              final parts = field.fieldName.split('.');
              if (_formData[parts[0]] is! Map) {
                _formData[parts[0]] = {};
              }
              _formData[parts[0]][parts[1]] = newValue;
            } else {
              _formData[field.fieldName] = newValue;
            }
          });
        },
        secondary: Icon(field.icon),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}
