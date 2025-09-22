import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/widgets/field_factory.dart';

// Cores centralizadas para todo o componente
class GridColors {
  static const Color primary = Color(0xFF93070A);
  static const Color primaryDark = Color(0xFF6A0507);
  static const Color primaryLight = Color(0xFFB84042);
  static const Color secondary = Color(0xFF005826);
  static const Color secondaryLight = Color(0xFF2E7D32);
  static const Color secondaryDark = Color(0xFF003D1A);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF000000);
  static const Color link = Color(0xFFFF0000);
  static const Color inputBackground = Color(0xFFFFFFFF);
  static const Color inputBorder = Color(0xFF93070A);
  static const Color buttonBackground = Color(0xFF93070A);
  static const Color buttonText = Color(0xFFFFFFFF);
  static const Color background = Color(0xFF005826);
  static const Color card = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFFFA000);
  static const Color success = Color(0xFF2E7D32);
  static const Color info = Color(0xFF1976D2);
  static const Color divider = Color(0xFFBDBDBD);
  static const Color filterBackground = Color(0xFFEFEFEF);
  static const Color hover = Color(0x1A000000);
  static const Color selectedRow = Color(0xFFE3F2FD);
  static const Color dialogBackground = Color(0xFFFFFFFF);
  static const Color shadow = Color(0x26000000);
}

// Configuração de exportação
class ExportConfig {
  final bool enableCsvExport;
  final bool enablePdfExport;
  final String filenamePrefix;

  const ExportConfig({
    this.enableCsvExport = true,
    this.enablePdfExport = true,
    this.filenamePrefix = 'export',
  });
}

// Configuração de paginação
class PaginationConfig {
  final int defaultRowsPerPage;
  final List<int> availableRowsPerPage;
  final bool showItemsPerPageSelector;

  const PaginationConfig({
    this.defaultRowsPerPage = 25,
    this.availableRowsPerPage = const [10, 25, 50, 100],
    this.showItemsPerPageSelector = true,
  });
}

// Configuração de ação personalizada
class CustomAction<T> {
  final IconData icon;
  final String label;
  final void Function(BuildContext context, T item) onPressed;
  final bool Function(T item)? isVisible;

  const CustomAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isVisible,
  });
}

typedef FromJson<T> = T Function(Map<String, dynamic> json);
typedef ToJson<T> = Map<String, dynamic> Function(T item);
typedef SecurityCheck = bool Function(String permission);
typedef OnItemTap<T> = void Function(T item, BuildContext context);
typedef CustomActionBuilder<T> = List<CustomAction<T>> Function();

class GenericGridScreen<T> extends StatefulWidget {
  final String title;
  final String fetchEndpoint;
  final String createEndpoint;
  final String updateEndpoint;
  final String deleteEndpoint;
  final FromJson<T> fromJson;
  final ToJson<T> toJson;
  final SecurityCheck hasPermission;
  final Map<String, bool> buttonPermissions;
  final List<FieldConfig> fieldConfigs;
  final String idFieldName;
  final String dateFieldName;
  final ExportConfig exportConfig;
  final PaginationConfig paginationConfig;
  final OnItemTap<T>? onItemTap;
  final CustomActionBuilder<T>? customActions;
  final bool enableSearch;
  final bool enableColumnReorder;
  final bool enableColumnResize;
  final Map<String, dynamic>? initialFilters;
  final String storageKey;
  final Widget Function(T item)? detailScreenBuilder;
  final Map<String, dynamic>? extraParams;

  const GenericGridScreen({
    super.key,
    required this.title,
    required this.fetchEndpoint,
    required this.createEndpoint,
    required this.updateEndpoint,
    required this.deleteEndpoint,
    required this.fromJson,
    required this.toJson,
    required this.hasPermission,
    required this.fieldConfigs,
    this.idFieldName = 'id',
    this.dateFieldName = 'createdAt',
    this.buttonPermissions = const {
      'create': true,
      'edit': true,
      'delete': true,
      'deleteMultiple': true,
      'export': true,
    },
    this.exportConfig = const ExportConfig(),
    this.paginationConfig = const PaginationConfig(),
    this.onItemTap,
    this.customActions,
    this.enableSearch = true,
    this.enableColumnReorder = false,
    this.enableColumnResize = false,
    this.initialFilters,
    this.storageKey = 'generic_grid_settings',
    this.detailScreenBuilder,
    this.extraParams,
  });

  @override
  State<GenericGridScreen<T>> createState() => _GenericGridScreenState<T>();
}

class _GenericGridScreenState<T> extends State<GenericGridScreen<T>> {
  List<T> items = [];
  List<T> filtered = [];
  Set<String> selectedRows = {};
  int rowsPerPage = 25;
  bool filtrosAbertos = false;
  bool isLoading = false;
  bool _isUpdating = false;
  bool _isDeleting = false;
  bool _isExporting = false;

  int _currentPage = 0;
  int _totalItems = 0;

  final Map<String, TextEditingController> _filterControllers = {};
  final TextEditingController _searchController = TextEditingController();
  final Map<String, List<Map<String, dynamic>>> _dropdownCache = {};
  int? sortColumnIndex;
  bool sortAscending = true;

  final Map<String, bool> _columnVisibility = {};
  List<CustomAction<T>> _customActions = [];

  final Map<String, List<PlatformFile>> _fileCache = {};

  @override
  void initState() {
    super.initState();
    rowsPerPage = widget.paginationConfig.defaultRowsPerPage;

    for (final config in widget.fieldConfigs) {
      _columnVisibility[config.fieldName] = config.isVisibleByDefault;
    }

    for (final config in widget.fieldConfigs.where((c) => c.isFilterable)) {
      _filterControllers[config.fieldName] = TextEditingController();
    }

    if (widget.initialFilters != null) {
      widget.initialFilters!.forEach((key, value) {
        if (_filterControllers.containsKey(key)) {
          _filterControllers[key]!.text = value.toString();
        }
      });
    }

    _loadColumnPreferences().then((_) {
      _loadItems(_currentPage, rowsPerPage);
    });

    if (widget.customActions != null) {
      _customActions = widget.customActions!();
    }
  }

  Future<void> _loadColumnPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${widget.storageKey}_${widget.title}';

      for (final config in widget.fieldConfigs) {
        final savedValue = prefs.getBool('$key${config.fieldName}');
        if (savedValue != null) {
          _columnVisibility[config.fieldName] = savedValue;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao carregar preferências: $e');
      }
    }
  }

  Future<void> _saveColumnPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${widget.storageKey}_${widget.title}';

      for (final config in widget.fieldConfigs) {
        await prefs.setBool(
          '$key${config.fieldName}',
          _columnVisibility[config.fieldName] ?? config.isVisibleByDefault,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao salvar preferências: $e');
      }
    }
  }

  String construirUrl(String baseUrl, int pagina, int tamanhoPagina) {
    String url = baseUrl;
    bool jaTemParametros = url.contains('?');

    url += jaTemParametros ? '&' : '?';
    url += 'pagina=$pagina&tamanho=$tamanhoPagina';

    return url;
  }

  Future<void> _loadItems(int pagina, int tamanhoPagina) async {
    setState(() => isLoading = true);

    try {
      String endpoint = construirUrl(
        widget.fetchEndpoint,
        pagina,
        tamanhoPagina,
      );
      String url = endpoint;

      if (sortColumnIndex != null &&
          sortColumnIndex! < widget.fieldConfigs.length &&
          widget.fieldConfigs[sortColumnIndex!].isSortable) {
        final config = widget.fieldConfigs[sortColumnIndex!];
        final direction = sortAscending ? 'ASC' : 'DESC';
        url += '&ordenarPor=${config.fieldName}&direcao=$direction';
      }

      for (final config in widget.fieldConfigs.where((c) => c.isFilterable)) {
        final filterValue = _filterControllers[config.fieldName]?.text;
        if (filterValue != null && filterValue.isNotEmpty) {
          url += '&${config.fieldName}=${Uri.encodeComponent(filterValue)}';
        }
      }

      if (_searchController.text.isNotEmpty) {
        url += '&busca=${Uri.encodeComponent(_searchController.text)}';
      }

      final NetworkResponse response = await NetworkCaller().getRequest(url);

      if (response.statusCode == 200 && response.body != null) {
        final responseData = response.body!['data'];
        final List<dynamic> data = responseData is Map
            ? responseData['dados'] ?? []
            : responseData ?? [];

        setState(() {
          items = data.map((json) => widget.fromJson(json)).toList();
          filtered = List.from(items);
          _totalItems = responseData is Map
              ? responseData['totalElements'] ?? 0
              : data.length;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha ao carregar dados: ${response.statusCode}'),
            backgroundColor: GridColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar dados: $e'),
          backgroundColor: GridColors.error,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _currentPage = 0;
    });
    _loadItems(_currentPage, rowsPerPage);
  }

  void _sort<U>(
    Comparable<U> Function(T c) getField,
    int columnIndex,
    bool asc,
  ) {
    setState(() {
      sortColumnIndex = columnIndex;
      sortAscending = asc;
    });
    _loadItems(_currentPage, rowsPerPage);
  }

  void _openForm({T? item}) {
    final controllers = <String, TextEditingController>{};
    final itemMap = item != null ? widget.toJson(item) : {};

    for (final config in widget.fieldConfigs.where((c) => c.isInForm)) {
      if (item == null && config.fieldName == widget.idFieldName) {
        continue;
      }

      String initialValue = '';
      if (item != null) {
        final value = _getNestedValue(itemMap, config.fieldName);
        if (value is Map) {
          initialValue = value[config.dropdownValueField]?.toString() ?? '';
        } else {
          initialValue = value?.toString() ?? '';
        }
      } else if (config.defaultValue != null) {
        initialValue = config.defaultValue.toString();
      }

      controllers[config.fieldName] = TextEditingController(text: initialValue);
    }

    showDialog(
      context: context,
      builder: (ctx) => _buildForm(ctx, item, controllers),
    );
  }

  Widget _buildForm(
    BuildContext context,
    T? item,
    Map<String, TextEditingController> controllers,
  ) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: GridColors.dialogBackground,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: GridColors.shadow,
              blurRadius: 10.0,
              offset: Offset(0.0, 10.0),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: GridColors.divider, width: 0.5),
                  ),
                ),
                child: Text(
                  item == null ? "Novo Item" : "Editar Item",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: GridColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              ...widget.fieldConfigs
                  .where((config) {
                    if (item == null &&
                        config.fieldName == widget.idFieldName) {
                      return false;
                    }
                    return config.isInForm;
                  })
                  .map((config) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: FieldFactory.buildField(
                        config: config,
                        controller: controllers[config.fieldName]!,
                        context: context,
                        fileCache: _fileCache,
                        dropdownCache: _dropdownCache,
                        item: item,
                      ),
                    );
                  }),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: GridColors.textSecondary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: const Text("CANCELAR"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isUpdating
                        ? null
                        : () => _saveItem(item, controllers, context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GridColors.primary,
                      foregroundColor: GridColors.card,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isUpdating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text("SALVAR"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveItem(
    T? item,
    Map<String, TextEditingController> controllers,
    BuildContext context,
  ) async {
    for (final config in widget.fieldConfigs.where(
      (c) => c.isInForm && c.isRequired,
    )) {
      if (controllers[config.fieldName]?.text.isEmpty == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${config.label} é obrigatório'),
            backgroundColor: GridColors.error,
          ),
        );
        return;
      }

      if (config.validator != null) {
        final error = config.validator!(controllers[config.fieldName]?.text);
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: GridColors.error),
          );
          return;
        }
      }
    }

    setState(() => _isUpdating = true);

    final formData = <String, dynamic>{};

    for (final config in widget.fieldConfigs.where(
      (c) => c.fieldType == FieldType.file,
    )) {
      final files = _fileCache[config.fieldName];
      if (files != null && files.isNotEmpty) {
        formData[config.fieldName] = files;
      }
    }

    for (final config in widget.fieldConfigs.where(
      (c) => c.isInForm && c.fieldType != FieldType.file,
    )) {
      if (item == null && config.fieldName == widget.idFieldName) {
        continue;
      }

      final value = controllers[config.fieldName]!.text;
      formData[config.fieldName] = value;
    }

    if (item != null) {
      final itemMap = widget.toJson(item);
      formData[widget.idFieldName] = _getNestedValue(
        itemMap,
        widget.idFieldName,
      );
    }

    final success = item == null
        ? await _createItem(formData)
        : await _updateItem(formData);

    if (success) {
      for (final config in widget.fieldConfigs.where(
        (c) => c.fieldType == FieldType.file,
      )) {
        _fileCache.remove(config.fieldName);
      }
      Navigator.pop(context);
      _loadItems(_currentPage, rowsPerPage);
    }

    setState(() => _isUpdating = false);
  }

  Future<bool> _createItem(Map<String, dynamic> formData) async {
    if (!widget.hasPermission('create') ||
        !widget.buttonPermissions['create']!) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sem permissão para criar')));
      return false;
    }

    final Map<String, dynamic> enrichedFormData = Map.from(formData);

    if (widget.extraParams != null) {
      enrichedFormData.addAll(widget.extraParams!);
    }

    final filesToUpload = <String, List<PlatformFile>>{};
    final keysToRemove = <String>[];

    for (final key in enrichedFormData.keys) {
      final value = enrichedFormData[key];
      if (value is List<PlatformFile>) {
        filesToUpload[key] = value;
        keysToRemove.add(key);
      }
    }

    for (final key in keysToRemove) {
      enrichedFormData.remove(key);
    }

    enrichedFormData.updateAll((key, value) {
      if (value is String && value.isNotEmpty) {
        try {
          final parsedDate = DateFormat("dd/MM/yyyy").parseStrict(value);
          return DateFormat("yyyy-MM-dd").format(parsedDate);
        } catch (e) {
          return value;
        }
      }
      return value;
    });

    final response = await NetworkCaller().postRequest(
      widget.createEndpoint,
      enrichedFormData,
    );

    if (response.isSuccess) {
      if (filesToUpload.isNotEmpty) {
        await _uploadFiles(response.body?['id']?.toString(), filesToUpload);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item criado com sucesso'),
          backgroundColor: GridColors.success,
        ),
      );
      return true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Falha ao criar item: ${response.statusCode}'),
          backgroundColor: GridColors.error,
        ),
      );
      return false;
    }
  }

  Future<void> _uploadFiles(
    String? itemId,
    Map<String, List<PlatformFile>> filesToUpload,
  ) async {
    final String _authToken = '${AuthUtility.userInfo.token}';
    if (itemId == null || filesToUpload.isEmpty) return;

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiLinks.fecthAUpload),
      );
      request.fields['itemId'] = itemId;

      for (final entry in filesToUpload.entries) {
        final String fieldName = entry.key;
        final List<PlatformFile> files = entry.value;

        for (final platformFile in files) {
          Uint8List fileBytes;

          if (platformFile.bytes != null) {
            fileBytes = platformFile.bytes!;
          } else if (platformFile.path != null) {
            File ioFile = File(platformFile.path!);
            fileBytes = await ioFile.readAsBytes();
          } else {
            continue;
          }

          request.files.add(
            http.MultipartFile.fromBytes(
              fieldName,
              fileBytes,
              filename: platformFile.name,
            ),
          );
        }
      }

      if (_authToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        print('Upload realizado com sucesso: $responseBody');
      } else {
        final errorBody = await response.stream.bytesToString();
        print('Erro no upload (${response.statusCode}): $errorBody');
      }
    } catch (e) {
      print('Exceção durante o upload: $e');
    }
  }

  Map<String, dynamic> normalizeFormData(Map<String, dynamic> formData) {
    final updated = Map<String, dynamic>.from(formData);

    if (updated.containsKey("status")) {
      final status = updated["status"];
      if (status is String) {
        if (status.toLowerCase() == "ativo") {
          updated["status"] = 0;
        } else if (status.toLowerCase() == "inativo") {
          updated["status"] = 1;
        } else {
          updated["status"] = 0;
        }
      } else if (status == null) {
        updated["status"] = 0;
      }
    } else {
      updated["status"] = 0;
    }

    return updated;
  }

  Future<bool> _updateItem(Map<String, dynamic> formData) async {
    if (!widget.hasPermission('edit') || !widget.buttonPermissions['edit']!) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sem permissão para editar')),
      );
      return false;
    }
    final adjustedFormData = normalizeFormData(formData);

    final response = await NetworkCaller().postRequest(
      widget.updateEndpoint.replaceAll(
        ':id',
        adjustedFormData[widget.idFieldName].toString(),
      ),
      adjustedFormData,
    );

    if (response.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item atualizado com sucesso'),
          backgroundColor: GridColors.success,
        ),
      );
      return true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Falha ao atualizar item: ${response.statusCode}'),
          backgroundColor: GridColors.error,
        ),
      );
      return false;
    }
  }

  Future<void> _deleteItem(String id) async {
    if (!widget.hasPermission('delete') ||
        !widget.buttonPermissions['delete']!) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sem permissão para excluir')),
      );
      return;
    }

    setState(() => _isDeleting = true);
    final response = await NetworkCaller().getRequest(
      widget.deleteEndpoint.replaceAll(':id', id),
    );
    setState(() => _isDeleting = false);

    if (response.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item excluído com sucesso'),
          backgroundColor: GridColors.success,
        ),
      );
      _loadItems(_currentPage, rowsPerPage);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Falha ao excluir item: ${response.statusCode}'),
          backgroundColor: GridColors.error,
        ),
      );
    }
  }

  void _deleteSelected() {
    if (!widget.hasPermission('deleteMultiple') ||
        !widget.buttonPermissions['deleteMultiple']!) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sem permissão para excluir múltiplos itens'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Deseja excluir ${selectedRows.length} item(s) selecionado(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              for (final id in selectedRows) {
                await _deleteItem(id);
              }
              setState(() => selectedRows.clear());
            },
            style: ElevatedButton.styleFrom(backgroundColor: GridColors.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  // MÉTODOS QUE ESTAVAM FALTANDO:

  Future<void> _exportToCsv() async {
    if (!widget.hasPermission('export') ||
        !widget.buttonPermissions['export']!) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sem permissão para exportar')),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      final csvData = StringBuffer();

      final visibleFields = widget.fieldConfigs.where(
        (config) => _columnVisibility[config.fieldName] == true,
      );
      csvData.write(visibleFields.map((config) => config.label).join(','));
      csvData.write(',Data\n');

      for (final item in filtered) {
        final itemMap = widget.toJson(item);
        final row = visibleFields
            .map((config) {
              final value =
                  _getNestedValue(
                    itemMap,
                    config.displayFieldName ?? config.fieldName,
                  )?.toString() ??
                  '';
              return value.contains(',') ? '"$value"' : value;
            })
            .join(',');

        final dateValue = _getNestedValue(itemMap, widget.dateFieldName);
        String date = 'N/A';
        if (dateValue != null) {
          try {
            final dateString = dateValue.toString();
            final dateTime = DateTime.parse(dateString).toLocal();
            date = DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
          } catch (e) {
            date = 'Data inválida';
          }
        }

        csvData.write('$row,$date\n');
      }

      if (kDebugMode) {
        print(csvData.toString());
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dados exportados com sucesso'),
          backgroundColor: GridColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Falha ao exportar: $e'),
          backgroundColor: GridColors.error,
        ),
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Widget _buildLoadingOverlay() {
    if (_isUpdating || _isDeleting || _isExporting) {
      return Container(
        color: Colors.black54,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildFilters() {
    return Container(
      decoration: BoxDecoration(
        color: GridColors.filterBackground,
        border: Border.all(color: GridColors.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (widget.enableSearch)
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Busca Global",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _applyFilters();
                  },
                ),
              ),
              onChanged: (_) => _applyFilters(),
            ),
          if (widget.enableSearch) const SizedBox(height: 16),
          const Text(
            "Filtros Avançados",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final config in widget.fieldConfigs.where(
                (c) => c.isFilterable,
              ))
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _filterControllers[config.fieldName],
                    decoration: InputDecoration(
                      labelText: "Filtrar ${config.label}",
                      prefixIcon: Icon(config.icon ?? Icons.search),
                      isDense: true,
                    ),
                    onChanged: (_) => _applyFilters(),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColumnSettingsMenu() {
    return PopupMenuButton(
      icon: const Icon(Icons.settings),
      tooltip: 'Configurar colunas',
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'settings',
          child: Text('Configurar colunas visíveis'),
        ),
      ],
      onSelected: (value) {
        if (value == 'settings') {
          _showColumnSettingsDialog();
        }
      },
    );
  }

  void _showColumnSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Colunas visíveis'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: widget.fieldConfigs.map((config) {
                  return CheckboxListTile(
                    title: Text(config.label),
                    value:
                        _columnVisibility[config.fieldName] ??
                        config.isVisibleByDefault,
                    onChanged: config.isFixed
                        ? null
                        : (value) {
                            setState(() {
                              _columnVisibility[config.fieldName] =
                                  value ?? false;
                            });
                          },
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  _saveColumnPreferences();
                  setState(() {});
                  Navigator.pop(ctx);
                  _applyFilters();
                },
                child: const Text('Aplicar'),
              ),
            ],
          );
        },
      ),
    );
  }

  List<DataColumn> _buildColumns() {
    final columns = <DataColumn>[];

    for (final config in widget.fieldConfigs.where(
      (c) => _columnVisibility[c.fieldName] == true,
    )) {
      columns.add(
        DataColumn(
          label: Text(config.label),
          onSort: config.isSortable
              ? (columnIndex, ascending) {
                  _sort<dynamic>(
                    (c) {
                      final value = _getNestedValue(
                        widget.toJson(c),
                        config.displayFieldName ?? config.fieldName,
                      );
                      return value is Comparable ? value : value.toString();
                    },
                    widget.fieldConfigs.indexOf(config),
                    ascending,
                  );
                }
              : null,
        ),
      );
    }

    columns.add(const DataColumn(label: Text("Ações")));

    return columns;
  }

  List<DataCell> _buildCells(T item, int index) {
    final itemMap = widget.toJson(item);
    final cells = <DataCell>[];

    for (final config in widget.fieldConfigs.where(
      (c) => _columnVisibility[c.fieldName] == true,
    )) {
      cells.add(
        DataCell(
          Text(
            _getNestedValue(
                  itemMap,
                  config.displayFieldName ?? config.fieldName,
                )?.toString() ??
                '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: widget.onItemTap != null
              ? () => widget.onItemTap!(item, context)
              : null,
        ),
      );
    }

    cells.add(
      DataCell(
        Row(
          children: [
            if (widget.detailScreenBuilder != null &&
                widget.hasPermission('view'))
              IconButton(
                icon: const Icon(Icons.visibility, size: 20),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => widget.detailScreenBuilder!(item),
                    ),
                  );
                },
              ),
            if (widget.hasPermission('edit') &&
                widget.buttonPermissions['edit']!)
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _openForm(item: item),
              ),
            if (widget.hasPermission('delete') &&
                widget.buttonPermissions['delete']!)
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                onPressed: () => _deleteItem(
                  _getNestedValue(itemMap, widget.idFieldName).toString(),
                ),
              ),
            ..._customActions
                .where((action) => action.isVisible?.call(item) ?? true)
                .map(
                  (action) => IconButton(
                    icon: Icon(action.icon, size: 20),
                    onPressed: () => action.onPressed(context, item),
                    tooltip: action.label,
                  ),
                ),
          ],
        ),
      ),
    );

    return cells;
  }

  dynamic _getNestedValue(dynamic map, String fieldName) {
    if (map == null) return null;

    if (!fieldName.contains('.')) {
      return map is Map ? map[fieldName] : null;
    }

    final parts = fieldName.split('.');
    dynamic value = map;

    for (final part in parts) {
      if (value == null) return null;

      if (value is Map<dynamic, dynamic>) {
        value = Map<String, dynamic>.from(value)[part];
      } else if (value is Map<String, dynamic>) {
        value = value[part];
      } else if (value is List) {
        final index = int.tryParse(part);
        if (index != null && index >= 0 && index < value.length) {
          value = value[index];
        } else {
          return null;
        }
      } else {
        try {
          value = value[part];
        } catch (e) {
          return null;
        }
      }
    }

    return value;
  }

  @override
  Widget build(BuildContext context) {
    final fixedColumnsCount = widget.fieldConfigs
        .where((c) => _columnVisibility[c.fieldName] == true && c.isFixed)
        .length;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            backgroundColor: GridColors.primary,
            foregroundColor: GridColors.card,
            actions: [
              _buildColumnSettingsMenu(),
              if (widget.exportConfig.enableCsvExport &&
                  widget.hasPermission('export') &&
                  widget.buttonPermissions['export']!)
                IconButton(
                  icon: _isExporting
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        )
                      : const Icon(Icons.download),
                  onPressed: _isExporting ? null : _exportToCsv,
                  tooltip: "Exportar CSV",
                ),
            ],
          ),
          body: isLoading && items.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              if (widget.hasPermission('create') &&
                                  widget.buttonPermissions['create']!)
                                ElevatedButton.icon(
                                  onPressed: () => _openForm(),
                                  icon: const Icon(Icons.add),
                                  label: const Text("Novo"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: GridColors.primary,
                                    foregroundColor: GridColors.card,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              if (widget.hasPermission('deleteMultiple') &&
                                  widget.buttonPermissions['deleteMultiple']!)
                                ElevatedButton.icon(
                                  onPressed: selectedRows.isNotEmpty
                                      ? _deleteSelected
                                      : null,
                                  icon: const Icon(Icons.delete),
                                  label: const Text("Deletar Selecionados"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: GridColors.error,
                                    foregroundColor: GridColors.card,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () =>
                                _loadItems(_currentPage, rowsPerPage),
                            icon: const Icon(Icons.refresh),
                            tooltip: "Recarregar",
                          ),
                          ElevatedButton.icon(
                            onPressed: () => setState(
                              () => filtrosAbertos = !filtrosAbertos,
                            ),
                            icon: Icon(
                              filtrosAbertos
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                            ),
                            label: Text(
                              filtrosAbertos
                                  ? "Ocultar Filtros"
                                  : "Mostrar Filtros",
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GridColors.buttonBackground,
                              foregroundColor: GridColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (filtrosAbertos) _buildFilters(),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        child: PaginatedDataTable2(
                          columnSpacing: 12,
                          horizontalMargin: 12,
                          minWidth: 800,
                          sortColumnIndex: sortColumnIndex,
                          sortAscending: sortAscending,
                          columns: _buildColumns(),
                          source: _GenericDataSource<T>(
                            items: filtered,
                            selectedRows: selectedRows,
                            cellBuilder: _buildCells,
                            onSelect: (index, selected) {
                              setState(() {
                                final itemMap = widget.toJson(filtered[index]);
                                final id = _getNestedValue(
                                  itemMap,
                                  widget.idFieldName,
                                ).toString();
                                selected
                                    ? selectedRows.add(id)
                                    : selectedRows.remove(id);
                              });
                            },
                          ),
                          rowsPerPage: rowsPerPage,
                          availableRowsPerPage:
                              widget.paginationConfig.availableRowsPerPage,
                          onRowsPerPageChanged:
                              widget.paginationConfig.showItemsPerPageSelector
                              ? (value) {
                                  setState(() {
                                    rowsPerPage =
                                        value ??
                                        widget
                                            .paginationConfig
                                            .defaultRowsPerPage;
                                    _currentPage = 0;
                                  });
                                  _loadItems(_currentPage, rowsPerPage);
                                }
                              : null,
                          onPageChanged: (pageIndex) {
                            setState(() => _currentPage = pageIndex);
                            _loadItems(_currentPage, rowsPerPage);
                          },
                          fixedLeftColumns: fixedColumnsCount,
                          empty: Center(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              child: const Text(
                                "Nenhum item encontrado",
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        _buildLoadingOverlay(),
      ],
    );
  }
}

class _GenericDataSource<T> extends DataTableSource {
  final List<T> items;
  final Set<String> selectedRows;
  final List<DataCell> Function(T item, int index) cellBuilder;
  final void Function(int index, bool selected) onSelect;

  _GenericDataSource({
    required this.items,
    required this.selectedRows,
    required this.cellBuilder,
    required this.onSelect,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= items.length) return null;
    final item = items[index];
    final isSelected = selectedRows.contains(index.toString());

    return DataRow(
      selected: isSelected,
      onSelectChanged: (selected) => onSelect(index, selected ?? false),
      cells: cellBuilder(item, index),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => items.length;

  @override
  int get selectedRowCount => selectedRows.length;
}
