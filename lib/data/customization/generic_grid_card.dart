import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/services/upload_file_caller.dart';
import 'package:task_manager_flutter/ui/widgets/user_banners.dart';
// ==============================================
// MOBILE GRID SCREEN - MATERIAL DESIGN 3 COMPLETO
// ==============================================

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

// Enum para tipos de campo
enum FieldType {
  text,
  number,
  email,
  date,
  multiline,
  dropdown,
  boolean,
  file,
  password,
  phone,
  cpf,
  cnpj,
  currency,
  percentage,
  url,
}

// Configuração de arquivo
class FileConfig {
  final List<String> allowedExtensions;
  final bool allowMultiple;
  final int maxFileSize;
  final String fileFieldName;

  const FileConfig({
    this.allowedExtensions = const ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    this.allowMultiple = false,
    this.maxFileSize = 5 * 1024 * 1024,
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
  final bool enabled;
  final dynamic defaultValue;
  final FileConfig? fileConfig;
  final dynamic dropdownSelectedValue;
  final Map<String, dynamic>? fieldSpecificConfig;
  final bool showInCard;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String dateFormat;

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
    this.enabled = true,
    this.defaultValue,
    this.fileConfig,
    this.dropdownSelectedValue,
    this.fieldSpecificConfig,
    this.showInCard = true,
    this.firstDate,
    this.lastDate,
    this.dateFormat = 'dd/MM/yyyy',
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

class GenericMobileGridScreen<T> extends StatefulWidget {
  final String title;
  final String fetchEndpoint;
  final String createEndpoint;
  final String updateEndpoint;
  final String deleteEndpoint;
  final T Function(Map<String, dynamic> json) fromJson;
  final Map<String, dynamic> Function(T item) toJson;
  final bool Function(String permission) hasPermission;
  final List<FieldConfig> fieldConfigs;
  final String idFieldName;
  final String? dateFieldName;
  final PaginationConfig paginationConfig;
  final void Function(T item, BuildContext context)? onItemTap;
  final List<CustomAction<T>> Function()? customActions;
  final bool enableSearch;
  final Map<String, dynamic>? initialFilters;
  final String storageKey;
  final Widget Function(T item)? detailScreenBuilder;
  final Map<String, dynamic>? extraParams;
  final bool enableDebugMode;
  final bool useUserBannerAppBar;
  final VoidCallback? onUserBannerTapped;
  final VoidCallback? onBannerRefresh;
  // NOVA PROPRIEDADE SIMPLES
  final Map<String, dynamic>? additionalFormData;
  final Map<String, dynamic> Function(T? item)? dynamicAdditionalFormData;

  const GenericMobileGridScreen({
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
    this.dateFieldName,
    this.paginationConfig = const PaginationConfig(),
    this.onItemTap,
    this.customActions,
    this.enableSearch = true,
    this.initialFilters,
    this.storageKey = 'generic_mobile_grid_settings',
    this.detailScreenBuilder,
    this.extraParams,
    this.enableDebugMode = false,
    this.useUserBannerAppBar = false,
    this.onUserBannerTapped,
    this.onBannerRefresh,
    this.additionalFormData, // NOVO PARÂMETRO
    this.dynamicAdditionalFormData, // NOVO: Para dados dinâmicos
  });

  @override
  State<GenericMobileGridScreen<T>> createState() =>
      _GenericMobileGridScreenState<T>();
}

class _GenericMobileGridScreenState<T>
    extends State<GenericMobileGridScreen<T>> {
  List<T> items = [];
  List<T> filtered = [];
  Set<String> selectedRows = {};
  bool isLoading = false;
  bool _isUpdating = false;
  bool _isDeleting = false;
  bool filtrosAbertos = false;
  final Map<String, List<PlatformFile>> _fileCache =
      {}; // NOVO: Cache para arquivos

  int _currentPage = 0;
  int _totalItems = 0;
  final int _itemsPerPage = 20;
  bool _hasMoreItems = true;
  final ScrollController _scrollController = ScrollController();

  final Map<String, TextEditingController> _filterControllers = {};
  final TextEditingController _searchController = TextEditingController();
  final Map<String, List<Map<String, dynamic>>> _dropdownCache = {};

  final Map<String, bool> _fieldVisibility = {};
  List<CustomAction<T>> _customActions = [];

  bool _isSelectionMode = false;
  final Map<String, bool> _cardSelection = {};
  T? _itemParaEditar;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    for (final config in widget.fieldConfigs) {
      _fieldVisibility[config.fieldName] = config.isVisibleByDefault;
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

    _loadFieldPreferences().then((_) {
      _loadItems();
    });

    if (widget.customActions != null) {
      _customActions = widget.customActions!();
    }

    if (widget.enableDebugMode) {
      _customActions.add(
        CustomAction<T>(
          icon: Icons.bug_report,
          label: 'Ver Todos Campos',
          onPressed: _showAllFieldsDebug,
        ),
      );
    }

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final controller in _filterControllers.values) {
      controller.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFieldPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${widget.storageKey}_${widget.title}';

      for (final config in widget.fieldConfigs) {
        final savedValue = prefs.getBool('$key${config.fieldName}');
        if (savedValue != null) {
          _fieldVisibility[config.fieldName] = savedValue;
        }
      }
    } catch (e) {
      print('Erro ao carregar preferências: $e');
    }
  }

  Future<void> _saveFieldPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${widget.storageKey}_${widget.title}';

      for (final config in widget.fieldConfigs) {
        await prefs.setBool(
          '$key${config.fieldName}',
          _fieldVisibility[config.fieldName] ?? config.isVisibleByDefault,
        );
      }
    } catch (e) {
      print('Erro ao salvar preferências: $e');
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        _hasMoreItems &&
        !isLoading) {
      _loadMoreItems();
    }
  }

  Future<void> _loadItems({bool reset = true}) async {
    if (reset) {
      setState(() {
        _currentPage = 0;
        _hasMoreItems = true;
        isLoading = true;
      });
    } else {
      setState(() => isLoading = true);
    }

    try {
      final url = _buildUrl(reset ? 0 : _currentPage);
      final NetworkResponse response = await NetworkCaller().getRequest(url);

      if (response.statusCode == 200 && response.body != null) {
        final responseData = response.body!['data'];
        final List<dynamic> data = responseData is Map
            ? responseData['dados'] ?? []
            : responseData ?? [];

        final processedData = data.map((json) {
          final itemMap = json is Map ? Map<String, dynamic>.from(json) : {};

          for (final config in widget.fieldConfigs.where(
            (c) => c.fieldType == FieldType.file,
          )) {
            final fileField = config.fieldName.split('.')[0];
            if (!itemMap.containsKey(fileField)) {
              itemMap[fileField] = {'id': 0, 'nome': ''};
            }
          }

          return itemMap;
        }).toList();

        setState(() {
          if (reset) {
            items = processedData.map((json) {
              Map<String, dynamic> jsonMap = Map<String, dynamic>.from(json);
              return widget.fromJson(jsonMap);
            }).toList();
            filtered = List.from(items);
            _totalItems = responseData is Map
                ? responseData['totalElements'] ?? 0
                : data.length;
          } else {
            items.addAll(processedData.map((json) {
              Map<String, dynamic> jsonMap = Map<String, dynamic>.from(json);
              return widget.fromJson(jsonMap);
            }).toList());
            filtered = List.from(items);
          }

          _totalItems = responseData is Map
              ? responseData['totalElements'] ??
                  responseData['total'] ??
                  data.length
              : data.length;
          _hasMoreItems = items.length < _totalItems;
          _currentPage++;
        });
      }
    } catch (e) {
      _showSnackBar('Erro ao carregar dados: $e', isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadMoreItems() async {
    if (!_hasMoreItems || isLoading) return;

    await _loadItems(reset: false);
  }

  String _buildUrl(int page) {
    String url = '${widget.fetchEndpoint}?page=$page&size=$_itemsPerPage';

    if (_searchController.text.isNotEmpty) {
      url += '&search=${Uri.encodeComponent(_searchController.text)}';
    }

    for (final config in widget.fieldConfigs.where((c) => c.isFilterable)) {
      final filterValue = _filterControllers[config.fieldName]?.text;
      if (filterValue != null && filterValue.isNotEmpty) {
        url += '&${config.fieldName}=${Uri.encodeComponent(filterValue)}';
      }
    }

    if (widget.extraParams != null) {
      widget.extraParams!.forEach((key, value) {
        url += '&$key=${Uri.encodeComponent(value.toString())}';
      });
    }

    return url;
  }

  void _applyFilters() {
    _loadItems(reset: true);
  }

  void _clearFilters() {
    for (final controller in _filterControllers.values) {
      controller.clear();
    }
    _searchController.clear();
    _applyFilters();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _cardSelection.clear();
        selectedRows.clear();
      }
    });
  }

  void _toggleCardSelection(String id, bool selected) {
    setState(() {
      if (selected) {
        _cardSelection[id] = true;
        selectedRows.add(id);
      } else {
        _cardSelection.remove(id);
        selectedRows.remove(id);
      }
    });
  }

  void _selectAllCards() {
    setState(() {
      for (final item in filtered) {
        final itemMap = widget.toJson(item);
        final id = _getNestedValue(itemMap, widget.idFieldName).toString();
        _cardSelection[id] = true;
        selectedRows.add(id);
      }
    });
  }

  void _deselectAllCards() {
    setState(() {
      _cardSelection.clear();
      selectedRows.clear();
    });
  }

  void _openForm({T? item}) {
    _itemParaEditar = item;
    showDialog(
      context: context,
      builder: (context) => _buildFormDialog(item),
    );
  }

  Widget _buildFormDialog(T? item) {
    final Map<String, dynamic> itemData =
        item != null ? widget.toJson(item) : {};
    final Map<String, TextEditingController> formControllers = {};

    for (final config in widget.fieldConfigs.where((c) => c.isInForm)) {
      final initialValue =
          _getNestedValue(itemData, config.fieldName)?.toString() ?? '';
      formControllers[config.fieldName] =
          TextEditingController(text: initialValue);
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
            maxWidth: 500, maxHeight: MediaQuery.of(context).size.height * 0.8),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.edit,
                    color: Theme.of(context).colorScheme.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  item == null ? 'Adicionar Novo' : 'Editar Item',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: widget.fieldConfigs
                      .where((config) => config.isInForm)
                      .map((config) => _buildFormField(
                          config, formControllers[config.fieldName]!))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _saveForm(item, formControllers, context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: Text(item == null ? 'Adicionar' : 'Salvar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField(FieldConfig config, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            config.label + (config.isRequired ? ' *' : ''),
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          if (config.fieldType == FieldType.dropdown)
            _buildDropdownField(config, controller)
          else if (config.fieldType == FieldType.boolean)
            _buildBooleanField(config, controller)
          else if (config.fieldType == FieldType.multiline)
            _buildMultilineField(config, controller)
          else if (config.fieldType == FieldType.date) // NOVO: Campo de data
            _buildDateField(config, controller)
          else if (config.fieldType == FieldType.file) // NOVO: Campo de arquivo
            _buildFileField(config, controller)
          else
            _buildTextField(config, controller),
        ],
      ),
    );
  }

  Widget _buildFileField(FieldConfig config, TextEditingController controller) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentFiles = _fileCache[config.fieldName] ?? [];
    final fileConfig = config.fileConfig ?? const FileConfig();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Exibe arquivos selecionados
        if (currentFiles.isNotEmpty)
          ...currentFiles.map((file) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.attach_file),
                  title: Text(
                    file.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${(file.size / 1024).toStringAsFixed(1)} KB',
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: GridColors.error),
                    onPressed: () {
                      setState(() {
                        _fileCache[config.fieldName]?.remove(file);
                        if (_fileCache[config.fieldName]!.isEmpty) {
                          _fileCache.remove(config.fieldName);
                        }
                        controller.clear();
                      });
                    },
                  ),
                ),
              )),

        // Botão para selecionar arquivos
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

        // Informações sobre extensões permitidas
        if (fileConfig.allowedExtensions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Extensões permitidas: ${fileConfig.allowedExtensions.join(', ')}',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _selectFiles(
      FieldConfig config, TextEditingController controller) async {
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
      _showSnackBar('Erro ao selecionar arquivo: $e', isError: true);
    }
  }

  Widget _buildDateField(FieldConfig config, TextEditingController controller) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return TextFormField(
      controller: controller,
      readOnly: true,
      enabled: config.enabled, // CORREÇÃO: Propriedade enabled funcionando
      decoration: InputDecoration(
        hintText: 'Selecione a data',
        suffixIcon: Icon(
          Icons.calendar_today,
          color: config.enabled
              ? colorScheme.primary
              : colorScheme.onSurface.withOpacity(0.38),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: colorScheme.onSurface.withOpacity(0.38)),
        ),
        filled: !config.enabled,
        fillColor: !config.enabled
            ? colorScheme.onSurface.withOpacity(0.04)
            : Colors.transparent,
      ),
      style: TextStyle(
        color: config.enabled
            ? textTheme.bodyMedium?.color
            : colorScheme.onSurface.withOpacity(0.38),
      ),
      onTap: config.enabled ? () => _selectDate(config, controller) : null,
      validator: config.validator,
    );
  }

  Future<void> _selectDate(
      FieldConfig config, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _parseDate(controller.text) ?? DateTime.now(),
      firstDate: config.firstDate ?? DateTime(1900),
      lastDate: config.lastDate ?? DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: _buildDatePickerTheme(),
          child: child!,
        );
      },
      locale: const Locale('pt', 'BR'), // Português Brasil
    );

    if (picked != null) {
      final formattedDate = _formatDate(picked, config.dateFormat);
      controller.text = formattedDate;
    }
  }

  ThemeData _buildDatePickerTheme() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ThemeData(
      colorScheme: const ColorScheme.light(
        primary: GridColors.primary, // Sua cor primária
        onPrimary: GridColors.textPrimary, // Texto sobre a cor primária
        surface: GridColors.card, // Cor de fundo
        onSurface: GridColors.textSecondary, // Texto principal
        background: GridColors.background, // Cor de fundo alternativa
      ),
      dialogBackgroundColor: GridColors.dialogBackground,
      textTheme: textTheme.copyWith(
        bodyLarge: const TextStyle(
          color: GridColors.textSecondary,
          fontSize: 16,
        ),
        bodyMedium: const TextStyle(
          color: GridColors.textSecondary,
          fontSize: 14,
        ),
        labelLarge: const TextStyle(
          color: GridColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        titleMedium: TextStyle(
          color: GridColors.textSecondary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: GridColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: GridColors.primary, width: 2),
        ),
      ),
    );
  }

  DateTime? _parseDate(String dateString) {
    if (dateString.isEmpty) return null;

    try {
      // Tenta vários formatos de data comuns
      final formats = [
        'dd/MM/yyyy',
        'dd-MM-yyyy',
        'yyyy-MM-dd',
        'dd/MM/yy',
      ];

      for (final format in formats) {
        try {
          final inputFormat = DateFormat(format);
          return inputFormat.parse(dateString);
        } catch (e) {
          continue;
        }
      }

      // Se nenhum formato funcionar, tenta parse padrão
      return DateTime.tryParse(dateString);
    } catch (e) {
      return null;
    }
  }

  String _formatDate(DateTime date, String format) {
    try {
      final dateFormat = DateFormat(format);
      return dateFormat.format(date);
    } catch (e) {
      // Fallback para formato padrão
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  Widget _buildTextField(FieldConfig config, TextEditingController controller) {
    return TextField(
      controller: controller,
      enabled: config.enabled, // CORREÇÃO ADICIONADA
      decoration: InputDecoration(
        hintText: 'Digite ${config.label.toLowerCase()}',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary, width: 2),
        ),
      ),
      keyboardType: _getKeyboardType(config.fieldType),
      maxLines: config.maxLines,
    );
  }

  Widget _buildMultilineField(
      FieldConfig config, TextEditingController controller) {
    return TextField(
      enabled: config.enabled, // CORREÇÃO ADICIONADA
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Digite ${config.label.toLowerCase()}',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary, width: 2),
        ),
      ),
      maxLines: 4,
      minLines: 3,
    );
  }

  Widget _buildBooleanField(
      FieldConfig config, TextEditingController controller) {
    return Row(
      children: [
        Checkbox(
          value: controller.text.toLowerCase() == 'true',
          onChanged: (value) {
            controller.text = value.toString();
            setState(() {});
          },
        ),
        Text(config.label),
      ],
    );
  }

  Widget _buildDropdownField(
      FieldConfig config, TextEditingController controller) {
    Future<List<Map<String, dynamic>>> getOptions() async {
      if (config.dropdownFutureBuilder != null) {
        return await config.dropdownFutureBuilder!();
      } else {
        return config.dropdownOptions ?? [];
      }
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: getOptions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return Text('Erro: ${snapshot.error}');
        }

        final options = snapshot.data ?? [];

        final uniqueOptions = <dynamic, Map<String, dynamic>>{};
        for (final option in options) {
          try {
            final value = option[config.dropdownValueField];
            if (value != null && !uniqueOptions.containsKey(value)) {
              uniqueOptions[value] = option;
            }
          } catch (e) {
            continue;
          }
        }

        final uniqueOptionsList = uniqueOptions.values.toList();

        dynamic currentValue = _getCurrentValue(config, controller);

        // Adicione debug para verificar os valores
        print('dropdownSelectedValue: ${config.dropdownSelectedValue}');
        print('currentValue inicial: $currentValue');
        print('controller.text: ${controller.text}');

        if (controller.text.isEmpty && config.dropdownSelectedValue != null) {
          // Force o mesmo tipo que será usado nas opções
          currentValue = config.dropdownSelectedValue is int
              ? config.dropdownSelectedValue
              : int.tryParse(config.dropdownSelectedValue.toString());
        }

        bool valueExists = uniqueOptionsList.any((option) {
          try {
            final optionValue = option[config.dropdownValueField];
            final optionInt = int.tryParse(optionValue.toString());
            final currentInt = currentValue is int
                ? currentValue
                : int.tryParse(currentValue.toString());

            final exists = optionInt != null &&
                currentInt != null &&
                optionInt == currentInt;

            if (exists) {
              print('COMPARAÇÃO BEM SUCEDIDA:');
              print('  optionValue: $optionValue -> $optionInt (int)');
              print('  currentValue: $currentValue -> $currentInt (int)');
            }

            return exists;
          } catch (e) {
            return false;
          }
        });

        if (!valueExists) {
          currentValue = null;
        }
        return AbsorbPointer(
          absorbing:
              !config.enabled, // Desabilita quando config.enabled = false
          child: Opacity(
            opacity: config.enabled ? 1.0 : 0.6, // Visualmente desabilitado
            child: DropdownButtonFormField<dynamic>(
              value: currentValue,
              decoration: InputDecoration(
                labelText: config.label + (config.isRequired ? ' *' : ''),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.38)),
                ),
                filled: !config.enabled,
                fillColor: !config.enabled
                    ? Theme.of(context).colorScheme.onSurface.withOpacity(0.04)
                    : Colors.transparent,
              ),
              isExpanded: true,
              items: [
                if (!config.isRequired || currentValue == null)
                  const DropdownMenuItem<dynamic>(
                    value: null,
                    child: Text(
                      'Selecione uma opção',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ...uniqueOptionsList.map<DropdownMenuItem<dynamic>>((option) {
                  try {
                    final optionValue = option[config.dropdownValueField];
                    final optionLabel =
                        option[config.dropdownDisplayField]?.toString() ??
                            optionValue?.toString() ??
                            'Sem label';

                    return DropdownMenuItem<dynamic>(
                      value: optionValue is int
                          ? optionValue
                          : int.tryParse(optionValue.toString()),
                      child: Text(optionLabel),
                    );
                  } catch (e) {
                    return DropdownMenuItem<dynamic>(
                      value: UniqueKey().toString(),
                      child: const Text('Erro na opção'),
                    );
                  }
                }),
              ],
              onChanged: config.enabled
                  ? (dynamic newValue) {
                      setState(() {
                        if (newValue == null) {
                          controller.clear();
                        } else {
                          controller.text = newValue.toString();
                        }
                      });
                    }
                  : null, // Desabilita onChanged quando não enabled
              validator: (dynamic value) {
                if (config.isRequired &&
                    (value == null || value.toString().isEmpty)) {
                  return '${config.label} é obrigatório';
                }
                return config.validator?.call(value?.toString());
              },
            ),
          ),
        );
      },
    );
  }

  dynamic _getCurrentValue(
      FieldConfig config, TextEditingController controller) {
    bool expectInteger = _isIntegerField(config);

    if (controller.text.isNotEmpty) {
      if (expectInteger) {
        return int.tryParse(controller.text);
      } else {
        return controller.text;
      }
    } else if (config.dropdownSelectedValue != null) {
      return config.dropdownSelectedValue;
    } else {
      return null;
    }
  }

  bool _isIntegerField(FieldConfig config) {
    return config.dropdownValueField == 'id' ||
        config.fieldName.toLowerCase().contains('id');
  }

  TextInputType _getKeyboardType(FieldType fieldType) {
    switch (fieldType) {
      case FieldType.number:
        return TextInputType.number;
      case FieldType.email:
        return TextInputType.emailAddress;
      case FieldType.phone:
        return TextInputType.phone;
      case FieldType.multiline:
        return TextInputType.multiline;
      default:
        return TextInputType.text;
    }
  }

  String? _parseDates(String dateString) {
    try {
      // Tenta parsear no formato "MM/dd/yyyy"
      final parts = dateString.split('/');
      if (parts.length == 3) {
        final month = parts[1].padLeft(2, '0');
        final day = parts[0].padLeft(2, '0');
        final year = parts[2];

        // Retorna no formato ISO "yyyy-MM-dd"
        return '$year-$month-$day';
      }

      // Se não conseguir parsear, retorna null para usar o valor original
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveForm(
      T? item,
      Map<String, TextEditingController> controllers,
      BuildContext context) async {
    try {
      final Map<String, dynamic> formData = {};

      // ==============================================
      // NOVO: ADICIONAR DADOS EXTRAS AO FORM DATA
      // ==============================================
      if (widget.additionalFormData != null) {
        formData.addAll(widget.additionalFormData!);

        // DEBUG: Mostrar dados adicionais
        if (widget.enableDebugMode) {
          print('=== DADOS ADICIONAIS DO FORMULÁRIO ===');
          widget.additionalFormData!.forEach((key, value) {
            print('$key: $value (${value.runtimeType})');
          });
          print('=====================================');
        }
      }

      // Dados dinâmicos (create vs update)
      if (widget.dynamicAdditionalFormData != null) {
        final dynamicData = widget.dynamicAdditionalFormData!(item);
        formData.addAll(dynamicData);
      }

      // Adiciona ao formData
      if (formData.isNotEmpty) {
        formData.addAll(formData);

        // DEBUG: Mostrar dados adicionais
        if (widget.enableDebugMode) {
          print('=== DADOS ADICIONAIS DO FORMULÁRIO ===');
          print('Tipo: ${item == null ? "CREATE" : "UPDATE"}');
          formData.forEach((key, value) {
            print('$key: $value (${value.runtimeType})');
          });
          print('=====================================');
        }
      }

      // ADICIONE ESTA PARTE SIMPLES - Processa dropdowns com valor selecionado
      for (final config in widget.fieldConfigs) {
        if (config.fieldType == FieldType.dropdown &&
            config.dropdownSelectedValue != null) {
          final value = config.dropdownSelectedValue;
          // Usa o valor direto, sem verificar tipo
          _addToFormData(formData, config.fieldName, value);
        }
      }

      for (final config in widget.fieldConfigs
          .where((c) => c.isInForm && c.fieldType != FieldType.file)) {
        final controller = controllers[config.fieldName];
        if (controller != null && controller.text.isNotEmpty) {
          final fieldValue = controller.text;
          // FORMATAÇÃO ESPECIAL PARA DATAS
          if (config.fieldType == FieldType.date) {
            // Converte de "MM/dd/yyyy" para "yyyy-MM-dd"
            final dateValue = _parseDates(controller.text);
            if (dateValue != null) {
              formData[config.fieldName] = dateValue;
            } else {
              formData[config.fieldName] = controller.text;
            }
          } else {
            _addToFormData(formData, config.fieldName, fieldValue);
          }
        }
      }

      // Processa arquivos
      final filesToUpload = <String, List<PlatformFile>>{};
      for (final config
          in widget.fieldConfigs.where((c) => c.fieldType == FieldType.file)) {
        final files = _fileCache[config.fieldName];
        if (files != null && files.isNotEmpty) {
          filesToUpload[config.fieldName] = files;
        }
      }

      final endpoint = item == null
          ? widget.createEndpoint
          : widget.updateEndpoint.replaceFirst(':id', _getItemId(item));

      if (filesToUpload.isNotEmpty) {
        // CORREÇÃO: Para criação (item == null), usa um ID temporário ou vazio
        final itemId = item == null ? '0' : _getItemId(item);
        final fileId =
            await UploadFileCaller().uploadFiles(itemId, filesToUpload);
        if (fileId > 0) {
          formData['file'] = {'id': fileId};
        }
      }

      final NetworkResponse response = item == null
          ? await NetworkCaller().postRequest(endpoint, formData)
          : await NetworkCaller().putRequest(endpoint, formData);

      if (response.isSuccess) {
        Navigator.pop(context);
        // Limpa o cache de arquivos após sucesso
        for (final config in widget.fieldConfigs
            .where((c) => c.fieldType == FieldType.file)) {
          _fileCache.remove(config.fieldName);
        }
        _showSnackBar(item == null
            ? 'Item adicionado com sucesso!'
            : 'Item atualizado com sucesso!');
        _loadItems(reset: true);
      } else {
        _showSnackBar('Erro ao salvar: ${response}', isError: true);
      }
    } catch (e) {
      _showSnackBar('Erro: $e', isError: true);
    }
  }

  void _addToFormData(
      Map<String, dynamic> formData, String fieldName, dynamic value) {
    if (fieldName.contains('.')) {
      final parts = fieldName.split('.');
      _buildNestedStructure(formData, parts, value);
    } else {
      formData[fieldName] = value;
    }
  }

  void _buildNestedStructure(
      Map<String, dynamic> map, List<String> parts, dynamic value) {
    final currentPart = parts[0];

    if (parts.length == 1) {
      // Última parte - atribui o valor
      map[currentPart] = value;
    } else {
      // Precisa criar estrutura aninhada
      if (!map.containsKey(currentPart)) {
        map[currentPart] = <String, dynamic>{};
      }

      // Garante que é um Map
      var nextMap = map[currentPart];
      if (nextMap is! Map) {
        nextMap = <String, dynamic>{};
        map[currentPart] = nextMap;
      }

      // Converte para Map<String, dynamic> se necessário
      final nextMapString = (nextMap is Map<String, dynamic>)
          ? nextMap
          : Map<String, dynamic>.from(nextMap as Map);

      map[currentPart] = nextMapString;

      // Continua recursivamente
      _buildNestedStructure(nextMapString, parts.sublist(1), value);
    }
  }

  void _addNestedField(
      Map<String, dynamic> map, List<String> parts, dynamic value) {
    if (parts.isEmpty) return;

    final currentPart = parts[0];

    if (parts.length == 1) {
      // Última parte, adiciona o valor
      map[currentPart] = value;
    } else {
      // Ainda tem partes aninhadas
      if (!map.containsKey(currentPart) || map[currentPart] is! Map) {
        map[currentPart] = {};
      }

      // Chama recursivamente para o próximo nível
      _addNestedField(
          map[currentPart] as Map<String, dynamic>, parts.sublist(1), value);
    }
  }

  String _getItemId(T item) {
    final itemMap = widget.toJson(item);
    return _getNestedValue(itemMap, widget.idFieldName).toString();
  }

  Future<void> _deleteItem(String id) async {
    try {
      final response = await NetworkCaller().deleteRequest(
        widget.deleteEndpoint.replaceFirst(':id', id),
      );

      if (response.isSuccess) {
        _showSnackBar('Item excluído com sucesso!');
        _loadItems(reset: true);
      } else {
        _showSnackBar('Erro ao excluir: ${response}', isError: true);
      }
    } catch (e) {
      _showSnackBar('Erro: $e', isError: true);
    }
  }

  void _deleteSelected() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
            'Deseja excluir ${selectedRows.length} item(s) selecionado(s)?'),
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
              setState(() {
                selectedRows.clear();
                _cardSelection.clear();
                _isSelectionMode = false;
              });
              _loadItems(reset: true);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _showAllFieldsDebug(BuildContext context, T item) {
    final itemMap = widget.toJson(item);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(20),
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              Text(
                'DEBUG - Todos os Campos',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: itemMap.entries.map((entry) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Theme.of(context).colorScheme.outline),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 150,
                              child: Text(
                                entry.key,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                entry.value?.toString() ?? 'null',
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Fechar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFieldSettings() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Campos Visíveis'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: widget.fieldConfigs.map((config) {
                  return CheckboxListTile(
                    title: Text(config.label),
                    value: _fieldVisibility[config.fieldName] ??
                        config.isVisibleByDefault,
                    onChanged: config.isFixed
                        ? null
                        : (value) {
                            setState(() {
                              _fieldVisibility[config.fieldName] =
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
                  _saveFieldPreferences();
                  setState(() {});
                  Navigator.pop(ctx);
                },
                child: const Text('Aplicar'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==============================================
  // FILTROS RESTAURADOS - VERSÃO COMPLETA
  // ==============================================

  Widget _buildFilters() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.filter_alt, color: colorScheme.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Filtros e Busca',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close,
                      color: colorScheme.onSurface.withOpacity(0.6)),
                  onPressed: () => setState(() => filtrosAbertos = false),
                  tooltip: 'Fechar filtros',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Busca Global
            if (widget.enableSearch)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Busca Global',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Digite para buscar em todos os campos...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _applyFilters();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => _applyFilters(),
                  ),
                  const SizedBox(height: 20),
                ],
              ),

            // Filtros por Campo
            Text(
              'Filtros por Campo',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: widget.fieldConfigs
                  .where((c) => c.isFilterable)
                  .map((config) => SizedBox(
                        width: 250,
                        child: TextField(
                          controller: _filterControllers[config.fieldName],
                          decoration: InputDecoration(
                            labelText: config.label,
                            hintText:
                                'Filtrar por ${config.label.toLowerCase()}...',
                            prefixIcon: Icon(
                                config.icon ?? Icons.filter_list_alt,
                                size: 20),
                            suffixIcon: _filterControllers[config.fieldName]
                                        ?.text
                                        .isNotEmpty ==
                                    true
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () {
                                      _filterControllers[config.fieldName]
                                          ?.clear();
                                      _applyFilters();
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor:
                                colorScheme.surfaceVariant.withOpacity(0.3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onChanged: (_) => _applyFilters(),
                        ),
                      ))
                  .toList(),
            ),

            const SizedBox(height: 24),

            // Botões de Ação dos Filtros
            Container(
              padding: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.tonal(
                    onPressed: _clearFilters,
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.surfaceVariant,
                      foregroundColor: colorScheme.onSurfaceVariant,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.clear_all, size: 18),
                        SizedBox(width: 8),
                        Text('Limpar Todos'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _applyFilters,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 18),
                        SizedBox(width: 8),
                        Text('Aplicar Filtros'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================
  // BOTÃO DE REFRESH RESTAURADO
  // ==============================================

  Widget _buildRefreshButton() {
    return IconButton(
      icon: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            )
          : const Icon(Icons.refresh),
      onPressed: isLoading ? null : () => _loadItems(reset: true),
      tooltip: 'Recarregar dados',
    );
  }

  // ==============================================
  // HEADER COM TODAS AS AÇÕES RESTAURADAS
  // ==============================================

  AppBar _buildNormalAppBar() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppBar(
      title: Text(
        widget.title,
        style: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onPrimary,
        ),
      ),
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 3,
      shadowColor: colorScheme.shadow,
      surfaceTintColor: Colors.transparent,
      actions: [
        // Botão de Refresh
        _buildRefreshButton(),

        // Configuração de Campos
        IconButton(
          icon: const Icon(Icons.view_column),
          onPressed: _showFieldSettings,
          tooltip: 'Configurar campos visíveis',
        ),

        // Filtros
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () => setState(() => filtrosAbertos = !filtrosAbertos),
          tooltip: 'Mostrar/ocultar filtros',
        ),

        // Botão Adicionar (se tiver permissão)
        if (widget.hasPermission('create')) ...[
          const SizedBox(width: 8),
          _buildAddButton(),
        ],
      ],
    );
  }

  Widget _buildAddButton() {
    final colorScheme = Theme.of(context).colorScheme;
    return FloatingActionButton.small(
      onPressed: () => _openForm(),
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      elevation: 2,
      child: const Icon(Icons.add),
    );
  }

  FloatingActionButton _buildFloatingActionButton() {
    final colorScheme = Theme.of(context).colorScheme;
    return FloatingActionButton(
      onPressed: () => _openForm(),
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 4,
      child: const Icon(Icons.add),
    );
  }

  AppBar _buildSelectionAppBar() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppBar(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _toggleSelectionMode,
      ),
      title: Text(
        '${selectedRows.length} selecionado(s)',
        style: textTheme.bodyMedium?.copyWith(color: colorScheme.onPrimary),
      ),
      actions: [
        if (selectedRows.length == filtered.length)
          IconButton(
            icon: const Icon(Icons.deselect),
            onPressed: _deselectAllCards,
            tooltip: 'Desmarcar todos',
          )
        else
          IconButton(
            icon: const Icon(Icons.select_all),
            onPressed: _selectAllCards,
            tooltip: 'Selecionar todos',
          ),
        if (widget.hasPermission('delete') && selectedRows.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteSelected,
            tooltip: 'Excluir selecionados',
          ),
      ],
    );
  }

  // ==============================================
  // WIDGET PRINCIPAL COMPLETO
  // ==============================================

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: widget.useUserBannerAppBar
          ? PreferredSize(
              // preferredSize: const Size.fromHeight(94),
              preferredSize: Size.fromHeight(
                widget.useUserBannerAppBar == true ? 94 : kToolbarHeight,
              ),
              child: UserBannerAppBar(
                screenTitle: widget.title,
                onTapped: widget.onUserBannerTapped,
                onRefresh:
                    widget.onBannerRefresh ?? () => _loadItems(reset: true),
                isLoading: isLoading,
                // NOVOS PARÂMETROS:
                onFilterToggle: () =>
                    setState(() => filtrosAbertos = !filtrosAbertos),
                showFilterButton: widget.useUserBannerAppBar ?? true,
                // Adicione também se precisar:
                // onFieldSettings: _showFieldSettings,
              ),
            )
          : (_isSelectionMode ? _buildSelectionAppBar() : _buildNormalAppBar()),
      floatingActionButton:
          widget.hasPermission('create') ? _buildFloatingActionButton() : null,
      body: Column(
        children: [
          // Filtros (quando abertos)
          if (filtrosAbertos) _buildFilters(),

          // Header de Informações
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.3),
              border: Border(
                bottom: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
              ),
            ),
            /*       child: Row(
              children: [
                Text(
                  '${filtered.length} itens de $_totalItems encontrados',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const Spacer(),
                if (_isSelectionMode)
                  Text(
                    '${selectedRows.length} selecionados',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                // Botão de Refresh adicional no header
                if (!_isSelectionMode) ...[
                  const SizedBox(width: 16),
                  _buildRefreshButton(),
                ],
              ],
            ),*/
          ),

          // Lista de Itens
          Expanded(
            child: Stack(
              children: [
                RefreshIndicator.adaptive(
                  onRefresh: () => _loadItems(reset: true),
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: filtered.length + (isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == filtered.length) {
                        return _buildLoadingIndicator();
                      }
                      return _buildItemCard(filtered[index], index);
                    },
                  ),
                ),

                // Overlay de carregamento
                if (isLoading && filtered.isEmpty)
                  Container(
                    color: Colors.black.withOpacity(0.1),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_hasMoreItems) ...[
              CircularProgressIndicator.adaptive(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'Carregando mais itens...',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ] else ...[
              Icon(
                Icons.check_circle,
                color: colorScheme.primary.withOpacity(0.5),
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Todos os itens foram carregados',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ... (mantenha os métodos _buildItemCard, _buildVisibleFieldsForCard,
  // _buildStatusBadge, _buildCardActions, _showSnackBar, _getNestedValue,
  // _hasStatusField exatamente como estavam na versão anterior que eu forneci)

  // Restaurando métodos essenciais que podem estar faltando
  Widget _buildItemCard(T item, int index) {
    final itemMap = widget.toJson(item);
    final id = _getNestedValue(itemMap, widget.idFieldName).toString();
    final isSelected = _cardSelection[id] ?? false;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide(color: colorScheme.outline.withOpacity(0.2)),
      ),
      color: isSelected
          ? colorScheme.primary.withOpacity(0.08)
          : colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _isSelectionMode
            ? () => _toggleCardSelection(id, !isSelected)
            : () => widget.onItemTap?.call(item, context),
        onLongPress: () {
          if (!_isSelectionMode) {
            _toggleSelectionMode();
            _toggleCardSelection(id, true);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (_isSelectionMode)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (value) =>
                            _toggleCardSelection(id, value ?? false),
                        fillColor:
                            MaterialStateProperty.all(colorScheme.primary),
                      ),
                    ),
                  if (_fieldVisibility[widget.idFieldName] == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#$id',
                        style: textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (_hasStatusField(itemMap)) _buildStatusBadge(itemMap),
                ],
              ),
              const SizedBox(height: 12),
              ..._buildVisibleFieldsForCard(itemMap),
              const SizedBox(height: 12),
              if (!_isSelectionMode) _buildCardActions(item, itemMap),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildVisibleFieldsForCard(Map<String, dynamic> itemMap) {
    final visibleConfigs = widget.fieldConfigs
        .where((config) =>
            _fieldVisibility[config.fieldName] == true &&
            config.fieldName != widget.idFieldName &&
            config.showInCard)
        .toList();

    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return visibleConfigs.map((config) {
      if (config.fieldType == FieldType.file) {
        final fileData = _extractFileData(itemMap, config);
        final int fileId = fileData['id'] ?? 0;
        final String fileName = fileData['nome'] ?? fileData['fileName'] ?? '';

        if (fileId == 0 || fileName.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                config.label,
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 2),
              InkWell(
                onTap: () => _downloadFile(fileId, fileName),
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
              ),
            ],
          ),
        );
      } else {
        final displayValue = _getNestedValue(
                    itemMap, config.displayFieldName ?? config.fieldName)
                ?.toString() ??
            '';

        if (displayValue.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                config.label,
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                displayValue,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }
    }).toList();
  }

  Future<void> _downloadFile(int fileId, String fileName) async {
    final response = await UploadFileCaller().downloadFile(fileId, fileName);

    if (response == 200) {
      _showSnackBar('Download realizado com sucesso');
    } else {
      _showSnackBar('Falha no download: ${response}', isError: true);
    }
  }

  Map<String, dynamic> _extractFileData(
    Map<String, dynamic> itemMap,
    FieldConfig config,
  ) {
    try {
      final fileData =
          _getNestedValue(itemMap, config.fieldName.split('.')[0]) ?? {};

      if (fileData is Map) {
        return {
          'id': _getNestedValue(fileData, 'id') ?? 0,
          'nome': _getNestedValue(fileData, 'nome') ?? '',
          'fileName': _getNestedValue(fileData, 'fileName') ?? '',
          'fileType': _getNestedValue(fileData, 'fileType') ?? '',
        };
      }

      return {
        'id': _getObjectProperty(fileData, 'id') ?? 0,
        'nome': _getObjectProperty(fileData, 'nome') ??
            _getObjectProperty(fileData, 'fileName') ??
            '',
        'fileName': _getObjectProperty(fileData, 'fileName') ??
            _getObjectProperty(fileData, 'nome') ??
            '',
        'fileType': _getObjectProperty(fileData, 'fileType') ?? '',
      };
    } catch (e) {
      return {'id': 0, 'nome': '', 'fileName': '', 'fileType': ''};
    }
  }

  dynamic _getObjectProperty(dynamic object, String propertyName) {
    if (object == null) return null;

    switch (propertyName.toLowerCase()) {
      case 'id':
        return object.id ??
            object.ID ??
            object.Id ??
            object.fileId ??
            object.fileID ??
            0;
      case 'nome':
      case 'filename':
      case 'name':
        return object.nome ??
            object.fileName ??
            object.filename ??
            object.name ??
            '';
      case 'filetype':
      case 'type':
        return object.fileType ?? object.type ?? object.contentType ?? '';
      case 'tamanho':
      case 'size':
        return object.tamanho ?? object.size ?? object.fileSize ?? 0;
      default:
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

  Widget _buildStatusBadge(Map<String, dynamic> itemMap) {
    final status = _getNestedValue(itemMap, 'status')?.toString().toLowerCase();
    final colorScheme = Theme.of(context).colorScheme;

    Color badgeColor;
    String badgeText;

    switch (status) {
      case 'ativo':
      case 'true':
      case '1':
      case 'aberto':
        badgeColor = colorScheme.primary;
        badgeText = 'Ativo';
        break;
      case 'inativo':
      case 'false':
      case '0':
      case 'fechado':
        badgeColor = colorScheme.error;
        badgeText = 'Inativo';
        break;
      case 'pendente':
        badgeColor = colorScheme.secondary;
        badgeText = 'Pendente';
        break;
      default:
        badgeColor = colorScheme.outline;
        badgeText = status?.toUpperCase() ?? 'Status';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Text(
        badgeText,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildCardActions(T item, Map<String, dynamic> itemMap) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (widget.enableDebugMode)
          IconButton(
            icon: Icon(Icons.bug_report,
                size: 18, color: colorScheme.onSurface.withOpacity(0.6)),
            onPressed: () => _showAllFieldsDebug(context, item),
            tooltip: 'Ver todos os campos',
          ),
        if (widget.detailScreenBuilder != null && widget.hasPermission('view'))
          IconButton(
            icon: Icon(Icons.visibility_outlined,
                size: 18, color: colorScheme.onSurface.withOpacity(0.6)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => widget.detailScreenBuilder!(item),
                ),
              );
            },
            tooltip: 'Visualizar',
          ),
        if (widget.hasPermission('edit'))
          IconButton(
            icon: Icon(Icons.edit_outlined,
                size: 18, color: colorScheme.onSurface.withOpacity(0.6)),
            onPressed: () => _openForm(item: item),
            tooltip: 'Editar',
          ),
        if (widget.hasPermission('delete'))
          IconButton(
            icon:
                Icon(Icons.delete_outline, size: 18, color: colorScheme.error),
            onPressed: () => _deleteItem(
              _getNestedValue(itemMap, widget.idFieldName).toString(),
            ),
            tooltip: 'Excluir',
          ),
        ..._customActions
            .where((action) => action.isVisible?.call(item) ?? true)
            .map(
              (action) => IconButton(
                icon: Icon(action.icon,
                    size: 18, color: colorScheme.onSurface.withOpacity(0.6)),
                onPressed: () => action.onPressed(context, item),
                tooltip: action.label,
              ),
            ),
      ],
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    final colorScheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  dynamic _getNestedValue(dynamic map, String fieldName) {
    if (map == null) return null;
    if (!fieldName.contains('.')) {
      if (map is! Map) return null;
      return map[fieldName];
    }

    final parts = fieldName.split('.');
    dynamic value = map;

    for (final part in parts) {
      if (value == null) return null;
      if (value is Map) {
        value = value[part];
      } else {
        return null;
      }
    }

    return value;
  }

  bool _hasStatusField(Map<String, dynamic> itemMap) {
    return itemMap.containsKey('status') ||
        itemMap.containsKey('ativo') ||
        itemMap.containsKey('situacao');
  }
}

// Typedefs necessários
typedef FromJson<T> = T Function(Map<String, dynamic> json);
typedef ToJson<T> = Map<String, dynamic> Function(T item);
typedef SecurityCheck = bool Function(String permission);
typedef OnItemTap<T> = void Function(T item, BuildContext context);
typedef CustomActionBuilder<T> = List<CustomAction<T>> Function();
