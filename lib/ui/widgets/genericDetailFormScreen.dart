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
  final Map<String, dynamic>? extraParams;

  const GenericDetailFormScreen({
    super.key,
    required this.item,
    required this.tabConfigs,
    required this.title,
    required this.onSave,
    required this.onBack,
    required this.hasPermission,
    this.extraParams,
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
  final Map<String, List<Map<String, dynamic>>> _dropdownOptionsCache = {};

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
        fetchEndpoint: "${tab.endpoint}?parcId=${_formData['id']}",
        createEndpoint: "${tab.endpoint}",
        updateEndpoint: "${tab.endpoint}",
        deleteEndpoint: "${tab.endpoint}?parcId${_formData['id']}",
        fromJson: tab.fromJson ?? (json) => json,
        toJson: tab.toJson != null
            ? (item) => tab.toJson!(item)
            : (item) => item as Map<String, dynamic>,
        hasPermission: widget.hasPermission,
        fieldConfigs: tab.gridFieldConfigs ?? [],
        extraParams: {
          'parceiro': {'id': _formData['id']},
          'empresa': {
            'id': _formData["empresa"] != null
                ? _formData["empresa"]["id"]
                : null,
            'codApp': 1,
          },
        },
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
    final currentValue = _dropdownValues[field.fieldName] ?? '';

    if (field.dropdownFutureBuilder != null) {
      // Para dropdowns com carregamento assíncrono
      return FutureBuilder<List<Map<String, dynamic>>>(
        future: field.dropdownFutureBuilder!(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildDropdownLoading(field);
          } else if (snapshot.hasError) {
            return _buildDropdownError(field, snapshot.error.toString());
          } else {
            final options = snapshot.data ?? [];
            _dropdownOptionsCache[field.fieldName] = options;
            return _buildDropdownWidget(field, options, currentValue);
          }
        },
      );
    } else {
      // Para dropdowns com opções estáticas
      final options = field.dropdownOptions ?? [];
      return _buildDropdownWidget(field, options, currentValue);
    }
  }

  Widget _buildDropdownLoading(FieldConfig field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: field.label,
          prefixIcon: Icon(field.icon),
          border: const OutlineInputBorder(),
        ),
        child: const Row(
          children: [
            Text("Carregando opções...", style: TextStyle(color: Colors.grey)),
            SizedBox(width: 10),
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownError(FieldConfig field, String error) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: field.label,
          prefixIcon: Icon(field.icon),
          border: const OutlineInputBorder(),
          errorText: "Erro ao carregar opções",
        ),
        child: Text("Erro: $error", style: const TextStyle(color: Colors.red)),
      ),
    );
  }

  Widget _buildDropdownWidget(
    FieldConfig field,
    List<Map<String, dynamic>> options,
    String currentValue,
  ) {
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
            items: _buildDropdownItems(field, options),
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
            hint: Text('Selecione ${field.label}'),
          ),
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildDropdownItems(
    FieldConfig field,
    List<Map<String, dynamic>> options,
  ) {
    final items = <DropdownMenuItem<String>>[];

    // Adicionar item vazio apenas se não houver valor selecionado
    if (_dropdownValues[field.fieldName] == null ||
        _dropdownValues[field.fieldName]!.toString().isEmpty) {
      items.add(
        DropdownMenuItem<String>(
          value: '',
          child: Text(
            'Selecione ${field.label}',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Adicionar opções
    for (final option in options) {
      final optionValue = option[field.dropdownValueField]?.toString() ?? '';
      final optionLabel =
          option[field.dropdownDisplayField]?.toString() ?? optionValue;

      items.add(
        DropdownMenuItem<String>(value: optionValue, child: Text(optionLabel)),
      );
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
