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
}
