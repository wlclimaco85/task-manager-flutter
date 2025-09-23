import 'dart:convert';
import 'dart:io';

import 'package:data_table_2/data_table_2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart'; // Para mobile/desktop
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:file_saver/file_saver.dart';

// Cores centralizadas para todo o componente
class GridColors {
  // 🔹 Cores principais do cliente
  static const Color primary = Color(0xFF93070A); // vermelho vinho
  static const Color primaryDark = Color(0xFF6A0507); // tom mais escuro
  static const Color primaryLight = Color(0xFFB84042); // tom mais claro

  static const Color secondary = Color(0xFF005826); // verde fundo
  static const Color secondaryLight = Color(0xFF2E7D32); // verde mais claro
  static const Color secondaryDark = Color(0xFF003D1A); // verde mais escuro

  // 🔹 Textos
  static const Color textPrimary = Color(0xFFFFFFFF); // branco
  static const Color textSecondary = Color(0xFF000000); // preto
  static const Color link = Color(0xFFFF0000); // vermelho

  // 🔹 Inputs
  static const Color inputBackground = Color(0xFFFFFFFF);
  static const Color inputBorder = Color(0xFF93070A);

  // 🔹 Botões
  static const Color buttonBackground = Color(0xFF93070A);
  static const Color buttonText = Color(0xFFFFFFFF);

  // 🔹 Fundo / cartões
  static const Color background = Color(0xFF005826); // cor secundária
  static const Color card = Color(0xFFFFFFFF);

  // 🔹 Estados do sistema (mantidos mas adaptados)
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFFFA000);
  static const Color success = Color(0xFF2E7D32);
  static const Color info = Color(0xFF1976D2);

  // 🔹 Outros
  static const Color divider = Color(0xFFBDBDBD);
  static const Color filterBackground = Color(0xFFEFEFEF);
  static const Color hover = Color(0x1A000000);
  static const Color selectedRow = Color(0xFFE3F2FD);
  static const Color dialogBackground = Color(0xFFFFFFFF);
  static const Color shadow = Color(0x26000000);
}

// Enum para tipos de campo
enum FieldType { text, number, email, date, multiline, dropdown, boolean, file }

// Configuração de arquivo
class FileConfig {
  final List<String> allowedExtensions;
  final bool allowMultiple;
  final int maxFileSize; // em bytes
  final String fileFieldName; // nome do campo para upload

  const FileConfig({
    this.allowedExtensions = const ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    this.allowMultiple = false,
    this.maxFileSize = 5 * 1024 * 1024, // 5MB
    this.fileFieldName = 'file',
  });
}

// Configuração avançada de campo
class FieldConfig {
  final String label;
  final String fieldName;
  final bool isFilterable;
  final bool isInForm;
  final int flex;
  final int maxLines;
  final IconData? icon;
  final bool isSortable;
  final FieldType fieldType;
  final List<Map<String, dynamic>>? dropdownOptions;
  final Future<List<Map<String, dynamic>>> Function()? dropdownFutureBuilder;
  final String dropdownValueField;
  final String dropdownDisplayField;
  final bool isRequired;
  final String? Function(String?)? validator;
  final String? displayFieldName;
  final bool isVisibleByDefault;
  final bool isFixed;
  final bool enabled; // NOVO: campo para habilitar/desabilitar
  final dynamic defaultValue; // NOVO: valor padrão para o campo
  final FileConfig? fileConfig; // NOVO: configuração para arquivos
  final dynamic
  dropdownSelectedValue; // NOVO: valor selecionado padrão para dropdown

  const FieldConfig({
    required this.label,
    required this.fieldName,
    this.isFilterable = true,
    this.isInForm = true,
    this.flex = 1,
    this.maxLines = 1,
    this.icon,
    this.isSortable = true,
    this.fieldType = FieldType.text,
    this.dropdownOptions,
    this.dropdownFutureBuilder,
    this.dropdownValueField = 'value',
    this.dropdownDisplayField = 'label',
    this.isRequired = false,
    this.validator,
    this.displayFieldName,
    this.isVisibleByDefault = true,
    this.isFixed = false,
    this.enabled = true, // NOVO: padrão é habilitado
    this.defaultValue, // NOVO: valor padrão
    this.fileConfig, // NOVO: configuração de arquivo
    this.dropdownSelectedValue, // NOVO: valor selecionado padrão para dropdown
  });
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

  // Controles de paginação
  int _currentPage = 0;
  int _totalItems = 0;

  final Map<String, TextEditingController> _filterControllers = {};
  final TextEditingController _searchController = TextEditingController();
  final Map<String, List<Map<String, dynamic>>> _dropdownCache = {};
  int? sortColumnIndex;
  bool sortAscending = true;

  // Para controle de colunas visíveis
  final Map<String, bool> _columnVisibility = {};

  // Para ações personalizadas
  List<CustomAction<T>> _customActions = [];

  // NOVO: Para controle de arquivos
  final Map<String, List<PlatformFile>> _fileCache = {};
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    rowsPerPage = widget.paginationConfig.defaultRowsPerPage;

    // Inicializar visibilidade com valores padrão primeiro
    for (final config in widget.fieldConfigs) {
      _columnVisibility[config.fieldName] = config.isVisibleByDefault;
    }

    // Inicializar controladores de filtro para campos filtráveis
    for (final config in widget.fieldConfigs.where((c) => c.isFilterable)) {
      _filterControllers[config.fieldName] = TextEditingController();
    }

    // Aplicar filtros iniciais se fornecidos
    if (widget.initialFilters != null) {
      widget.initialFilters!.forEach((key, value) {
        if (_filterControllers.containsKey(key)) {
          _filterControllers[key]!.text = value.toString();
        }
      });
    }

    // Carregar preferências e depois carregar dados
    _loadColumnPreferences().then((_) {
      _loadItems(_currentPage, rowsPerPage);
    });

    // Inicializar ações personalizadas
    if (widget.customActions != null) {
      _customActions = widget.customActions!();
    }
  }

  // Carregar preferências de coluna
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

  // Salvar preferências de coluna
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

  String buildUrl(String baseUrl, Map<String, dynamic> params) {
    String url = baseUrl;

    // Verifica se a URL já contém parâmetros
    bool hasExistingParams = url.contains('?');

    // Adiciona os parâmetros à URL
    if (params.isNotEmpty) {
      url += hasExistingParams ? '&' : '?';

      // Converte os parâmetros para query string
      url += params.entries
          .map(
            (entry) =>
                '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value.toString())}',
          )
          .join('&');
    }

    return url;
  }

  Future<void> _downloadFile(int fileId, String fileName) async {
    try {
      final String authToken = '${AuthUtility.userInfo.token}';

      final response = await http.get(
        Uri.parse(
          'http://192.168.114.1:8088/boletobancos/api/files/download/$fileId',
        ),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      if (response.statusCode == 200) {
        await FileSaver.instance.saveFile(
          fileName,
          response.bodyBytes,
          fileName.split('.').last, // file extension
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download realizado com sucesso'),
            backgroundColor: GridColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha no download: ${response.statusCode}'),
            backgroundColor: GridColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro no download: $e'),
          backgroundColor: GridColors.error,
        ),
      );
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

      // Adicionar parâmetros de ordenação
      if (sortColumnIndex != null &&
          sortColumnIndex! < widget.fieldConfigs.length &&
          widget.fieldConfigs[sortColumnIndex!].isSortable) {
        final config = widget.fieldConfigs[sortColumnIndex!];
        final direction = sortAscending ? 'ASC' : 'DESC';
        url += '&ordenarPor=${config.fieldName}&direcao=$direction';
      }

      // Adicionar filtros - CORREÇÃO DO BUG: usar _filterControllers
      for (final config in widget.fieldConfigs.where((c) => c.isFilterable)) {
        final filterValue = _filterControllers[config.fieldName]?.text;
        if (filterValue != null && filterValue.isNotEmpty) {
          url += '&${config.fieldName}=${Uri.encodeComponent(filterValue)}';
        }
      }

      // Adicionar busca global
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

      // NOVO: Inicializar com valor padrão se fornecido
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
                      child: _buildFormField(
                        config,
                        controllers[config.fieldName]!,
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

  // NOVO: Parâmetro item adicionado para verificar se é edição
  Widget _buildFormField(
    FieldConfig config,
    TextEditingController controller, {
    T? item,
  }) {
    // Aplicar valor selecionado padrão para dropdowns se for um novo item
    if (item == null &&
        config.fieldType == FieldType.dropdown &&
        config.dropdownSelectedValue != null &&
        controller.text.isEmpty) {
      controller.text = config.dropdownSelectedValue.toString();
    }

    final fieldWidget = _buildFieldByType(config, controller);

    // NOVO: Aplicar enabled/disabled state
    return AbsorbPointer(
      absorbing: !config.enabled,
      child: Opacity(opacity: config.enabled ? 1.0 : 0.6, child: fieldWidget),
    );
  }

  Widget _buildFieldByType(
    FieldConfig config,
    TextEditingController controller,
  ) {
    switch (config.fieldType) {
      case FieldType.multiline:
        return TextFormField(
          controller: controller,
          maxLines: config.maxLines,
          decoration: _buildInputDecoration(config),
          style: const TextStyle(fontSize: 16),
          validator: config.validator,
        );
      case FieldType.dropdown:
        return _buildDropdownField(config, controller);
      case FieldType.date:
        return TextFormField(
          controller: controller,
          decoration: _buildInputDecoration(config),
          style: const TextStyle(fontSize: 16),
          readOnly: true,
          onTap: () => _selectDate(context, controller),
          validator: config.validator,
        );
      case FieldType.file:
        return _buildFileField(config, controller);
      default:
        return TextFormField(
          controller: controller,
          maxLines: config.maxLines,
          decoration: _buildInputDecoration(config),
          style: const TextStyle(fontSize: 16),
          keyboardType: config.fieldType == FieldType.number
              ? TextInputType.number
              : TextInputType.text,
          validator: config.validator,
        );
    }
  }

  InputDecoration _buildInputDecoration(FieldConfig config) {
    return InputDecoration(
      labelText: config.label + (config.isRequired ? ' *' : ''),
      labelStyle: TextStyle(color: GridColors.textSecondary, fontSize: 14),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: GridColors.primary, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: GridColors.divider, width: 1.0),
        borderRadius: BorderRadius.circular(8),
      ),
      prefixIcon: config.icon != null
          ? Icon(config.icon, size: 20, color: GridColors.primary)
          : null,
    );
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  // NOVO: Implementação do campo de arquivo
  Widget _buildFileField(FieldConfig config, TextEditingController controller) {
    final fileConfig = config.fileConfig ?? const FileConfig();
    final currentFiles = _fileCache[config.fieldName] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (currentFiles.isNotEmpty)
          ...currentFiles.map(
            (file) => ListTile(
              leading: const Icon(Icons.attach_file),
              title: Text(file.name),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: GridColors.error),
                onPressed: () {
                  setState(() {
                    _fileCache[config.fieldName]?.remove(file);
                    controller.text = '';
                  });
                },
              ),
            ),
          ),
        ElevatedButton.icon(
          onPressed: () => _selectFiles(config, controller),
          icon: const Icon(Icons.attach_file),
          label: Text(
            currentFiles.isEmpty
                ? 'Selecionar Arquivo'
                : 'Adicionar Mais Arquivos',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: GridColors.primary,
            foregroundColor: GridColors.card,
          ),
        ),
        if (fileConfig.allowedExtensions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Extensões permitidas: ${fileConfig.allowedExtensions.join(', ')}',
              style: const TextStyle(
                fontSize: 12,
                color: GridColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }

  // NOVO: Método para selecionar arquivos
  Future<void> _selectFiles(
    FieldConfig config,
    TextEditingController controller,
  ) async {
    final fileConfig = config.fileConfig ?? const FileConfig();

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: fileConfig.allowedExtensions,
        allowMultiple: fileConfig.allowMultiple,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _fileCache[config.fieldName] = result.files;
          controller.text = result.files.map((f) => f.name).join(', ');
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao selecionar arquivo: $e'),
          backgroundColor: GridColors.error,
        ),
      );
    }
  }

  Widget _buildDropdownField(
    FieldConfig config,
    TextEditingController controller,
  ) {
    final cacheKey = '${config.fieldName}_dropdown';

    if (_dropdownCache.containsKey(cacheKey)) {
      return _buildDropdownContent(
        config: config,
        controller: controller,
        options: _dropdownCache[cacheKey]!,
      );
    } else if (config.dropdownFutureBuilder != null) {
      return FutureBuilder<List<Map<String, dynamic>>>(
        future: config.dropdownFutureBuilder!(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Erro ao carregar opções: ${snapshot.error}');
          } else {
            final options = snapshot.data ?? [];
            _dropdownCache[cacheKey] = options;
            return _buildDropdownContent(
              config: config,
              controller: controller,
              options: options,
            );
          }
        },
      );
    } else {
      return _buildDropdownContent(
        config: config,
        controller: controller,
        options: config.dropdownOptions ?? [],
      );
    }
  }

  Widget _buildDropdownContent({
    required FieldConfig config,
    required TextEditingController controller,
    required List<Map<String, dynamic>> options,
  }) {
    bool expectInteger = _isIntegerField(config);
    dynamic currentValue = _getCurrentValue(config, controller);

    final uniqueOptions = options
        .fold<Map<dynamic, Map<String, dynamic>>>({}, (map, item) {
          dynamic key = item[config.dropdownValueField];
          if (key != null && !map.containsKey(key)) {
            map[key] = item;
          }
          return map;
        })
        .values
        .toList();

    bool valueExists = uniqueOptions.any(
      (option) => option[config.dropdownValueField] == currentValue,
    );

    if (!valueExists && config.dropdownSelectedValue != null) {
      currentValue = config.dropdownSelectedValue;
    } else if (!valueExists) {
      currentValue = null;
    }

    return DropdownButtonFormField<dynamic>(
      initialValue: currentValue,
      decoration: _buildInputDecoration(config),
      isExpanded: true,
      menuMaxHeight: 300,
      itemHeight: 48,
      items: uniqueOptions.map<DropdownMenuItem<dynamic>>((option) {
        final optionValue = option[config.dropdownValueField];
        final optionLabel =
            option[config.dropdownDisplayField]?.toString() ?? '';
        return DropdownMenuItem<dynamic>(
          value: optionValue,
          child: Text(optionLabel, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (value) {
        controller.text = value?.toString() ?? '';
      },
      validator: (value) {
        if (config.validator != null) {
          return config.validator!(value?.toString());
        }
        return null;
      },
    );
  }

  dynamic _getCurrentValue(
    FieldConfig config,
    TextEditingController controller,
  ) {
    bool expectInteger = _isIntegerField(config);

    if (controller.text.isNotEmpty) {
      if (expectInteger) {
        return int.tryParse(controller.text);
      } else {
        return controller.text;
      }
    } else {
      return null;
    }
  }

  bool _isIntegerField(FieldConfig config) {
    return config.dropdownValueField == 'id' ||
        config.fieldName.toLowerCase().contains('id');
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

    void setNestedValue(
      Map<String, dynamic> map,
      List<String> parts,
      dynamic value,
    ) {
      if (parts.isEmpty) return;

      var current = map;
      for (int i = 0; i < parts.length - 1; i++) {
        final part = parts[i];
        if (!current.containsKey(part) ||
            current[part] is! Map<String, dynamic>) {
          current[part] = <String, dynamic>{};
        }
        current = current[part];
      }

      current[parts.last] = value;
    }

    setState(() => _isUpdating = true);

    final formData = <String, dynamic>{};

    // NOVO: Processar arquivos primeiro
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

      if (config.fieldName.contains('.')) {
        final parts = config.fieldName.split('.');
        setNestedValue(formData, parts, value);
      } else {
        formData[config.fieldName] = value;
      }
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
      // NOVO: Limpar cache de arquivos após salvar
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

    // NOVO: Processar upload de arquivos se houver
    // NOVO: Processar upload de arquivos se houver
    final filesToUpload = <String, List<PlatformFile>>{};
    final keysToRemove =
        <String>[]; // Lista para armazenar as chaves que serão removidas

    for (final key in enrichedFormData.keys) {
      final value = enrichedFormData[key];
      if (value is List<PlatformFile>) {
        filesToUpload[key] = value;
        keysToRemove.add(key); // Adiciona a chave à lista de remoção
      }
    }

    // Remove todas as chaves marcadas fora do loop de iteração
    for (final key in keysToRemove) {
      enrichedFormData.remove(key);
    }

    // 🔹 Detectar qualquer campo que esteja em formato dd/MM/yyyy e converter para yyyy-MM-dd
    enrichedFormData.updateAll((key, value) {
      if (value is String && value.isNotEmpty) {
        try {
          // Tenta fazer parse no formato brasileiro
          final parsedDate = DateFormat("dd/MM/yyyy").parseStrict(value);
          return DateFormat("yyyy-MM-dd").format(parsedDate);
        } catch (e) {
          // Se não for data válida em dd/MM/yyyy, mantém o valor original
          return value;
        }
      }
      return value;
    });
    int fileId = 0;
    if (filesToUpload.isNotEmpty) {
      fileId = await _uploadFiles("", filesToUpload);
      enrichedFormData["file"] = {"id": fileId};
    }

    print(enrichedFormData);

    final response = await NetworkCaller().postRequest(
      widget.createEndpoint,
      enrichedFormData,
    );

    if (response.isSuccess) {
      // NOVO: Fazer upload dos arquivos se a criação foi bem sucedida

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

  // NOVO: Método para upload de arquivos - VERSÃO CORRIGIDA
  Future<int> _uploadFiles(
    String? itemId,
    Map<String, List<PlatformFile>> filesToUpload,
  ) async {
    final String authToken = '${AuthUtility.userInfo.token}';
    if (itemId == null || filesToUpload.isEmpty) return 0;

    try {
      // Criar a requisição multipart
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.114.1:8088/boletobancos/api/files/upload'),
      );

      // Adicionar o ID do item como parâmetro
      request.fields['itemId'] = itemId;

      // Processar todos os arquivos do Map filesToUpload
      for (final entry in filesToUpload.entries) {
        final String fieldName =
            entry.key; // Nome do campo (ex: "file", "anexo")
        final List<PlatformFile> files = entry.value;

        for (final platformFile in files) {
          Uint8List fileBytes;

          // Obter os bytes do arquivo
          if (platformFile.bytes != null) {
            fileBytes = platformFile.bytes!;
          } else if (platformFile.path != null) {
            // Para arquivos com path (mobile/desktop)
            File ioFile = File(platformFile.path!);
            fileBytes = await ioFile.readAsBytes();
          } else {
            print('Arquivo sem bytes ou path: ${platformFile.name}');
            continue;
          }

          // Adicionar o arquivo à requisição
          request.files.add(
            http.MultipartFile.fromBytes(
              fieldName, // Nome do campo que o backend espera
              fileBytes,
              filename: platformFile.name,
            ),
          );
        }
      }

      // Adicionar headers de autenticação
      if (authToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }

      print('Enviando ${filesToUpload.length} arquivo(s) para o item $itemId');

      // Enviar a requisição
      final response = await request.send();

      // Verificar resposta
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        print('Upload realizado com sucesso: $responseBody');
        // Converter JSON para Map
        final decoded = jsonDecode(responseBody);

        // Retornar o fileId se existir
        return decoded['fileId'] ?? 0;
      } else {
        final errorBody = await response.stream.bytesToString();
        print('Erro no upload (${response.statusCode}): $errorBody');
      }
    } catch (e) {
      print('Exceção durante o upload: $e');
    }
    return 0;
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

      // Cabeçalhos
      final visibleFields = widget.fieldConfigs.where(
        (config) => _columnVisibility[config.fieldName] == true,
      );
      csvData.write(visibleFields.map((config) => config.label).join(','));
      csvData.write(',Data\n');

      // Dados
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

        // Adicionar data
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

  // Método para construir o menu de configuração de colunas
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

  // Diálogo para configuração de colunas
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
                  _applyFilters(); // Recarregar dados com as novas colunas
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

    // Adicionar colunas visíveis
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

    // Adicionar coluna de ações (sempre visível)
    columns.add(const DataColumn(label: Text("Ações")));

    return columns;
  }

  List<DataCell> _buildCells(T item, int index) {
    final itemMap = widget.toJson(item);
    final cells = <DataCell>[];

    for (final config in widget.fieldConfigs.where(
      (c) => _columnVisibility[c.fieldName] == true,
    )) {
      // TRATAMENTO ESPECIAL PARA CAMPOS DE ARQUIVO
      if (config.fieldType == FieldType.file) {
        final fileData = _getNestedValue(itemMap, config.fieldName);
        final fileName = _getNestedValue(
          itemMap,
          config.displayFieldName ?? 'fileName',
        )?.toString();
        final fileId = _getNestedValue(fileData, 'id');

        cells.add(
          DataCell(
            fileId != null && fileName != null && fileName.isNotEmpty
                ? InkWell(
                    onTap: () => _downloadFile(
                      fileId is int
                          ? fileId
                          : int.tryParse(fileId.toString()) ?? 0,
                      fileName,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.attach_file,
                          size: 16,
                          color: GridColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            fileName,
                            style: TextStyle(
                              color: GridColors.primary,
                              decoration: TextDecoration.underline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )
                : Text(
                    'Nenhum arquivo',
                    style: TextStyle(
                      color: GridColors.textSecondary.withOpacity(0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
          ),
        );
      } else {
        // Célula normal para outros tipos de campo
        final displayValue = _getNestedValue(
          itemMap,
          config.displayFieldName ?? config.fieldName,
        );

        cells.add(
          DataCell(
            Text(
              displayValue?.toString() ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: widget.onItemTap != null
                ? () => widget.onItemTap!(item, context)
                : null,
          ),
        );
      }
    }

    // ... resto do método (célula de ações) permanece igual
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

    // Se não tem ponto, é acesso direto
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
        // PARA OBJETOS DART: tenta métodos específicos sem reflexão
        value = _getObjectProperty(value, part);
        if (value == null) return null;
      }
    }

    return value;
  }

  // NOVO: Método para acessar propriedades de objetos Dart sem reflexão
  dynamic _getObjectProperty(dynamic object, String propertyName) {
    if (object == null) return null;

    // Tenta métodos comuns primeiro
    switch (propertyName) {
      case 'id':
        return object.id ?? object.ID ?? object.Id;
      case 'fileName':
      case 'filename':
      case 'name':
        return object.fileName ??
            object.filename ??
            object.name ??
            object.fileName;
      case 'fileType':
      case 'filetype':
      case 'type':
        return object.fileType ?? object.filetype ?? object.type;
      default:
        // Tenta converter para mapa via toJson() se existir
        try {
          if (object.toJson != null) {
            final jsonMap = object.toJson();
            if (jsonMap is Map && jsonMap.containsKey(propertyName)) {
              return jsonMap[propertyName];
            }
          }
        } catch (e) {
          // Ignora erro e retorna null
        }
        return null;
    }
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
                            setState(() {
                              _currentPage = pageIndex;
                            });
                            _loadItems(_currentPage, rowsPerPage);
                          },
                          fixedLeftColumns: widget.fieldConfigs
                              .where(
                                (c) =>
                                    _columnVisibility[c.fieldName] == true &&
                                    c.isFixed,
                              )
                              .length,
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
