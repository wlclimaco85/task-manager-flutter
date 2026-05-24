// ignore_for_file: library_private_types_in_public_api
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../utils/api_links.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/tenant_context.dart';

// ─── Internal data models ────────────────────────────────────────────────────

class _DayMarkers {
  final bool hasPagar;
  final bool hasReceber;
  final bool hasPago;
  final bool hasRecebido;
  final bool hasTributo;
  const _DayMarkers({
    this.hasPagar = false,
    this.hasReceber = false,
    this.hasPago = false,
    this.hasRecebido = false,
    this.hasTributo = false,
  });
}

class _MonthSummary {
  final double totalPagar;
  final double totalPago;
  final double totalReceber;
  final double totalRecebido;
  final double saldoPagar;
  final double saldoReceber;
  const _MonthSummary({
    this.totalPagar = 0,
    this.totalPago = 0,
    this.totalReceber = 0,
    this.totalRecebido = 0,
    this.saldoPagar = 0,
    this.saldoReceber = 0,
  });
}

// ─── Main widget ─────────────────────────────────────────────────────────────

List<Map<String, dynamic>> _parseFinancialItems(dynamic body) {
  try {
    dynamic cursor = body;
    if (cursor is Map && cursor.containsKey('data')) {
      cursor = cursor['data'];
    }
    if (cursor is Map) {
      for (final key in const ['dados', 'content', 'items', 'results']) {
        final value = cursor[key];
        if (value is List) {
          return value
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      }
    }
    if (cursor is List) {
      return cursor
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
  } catch (_) {}
  return [];
}

String _stringValue(Map<String, dynamic> item, List<String> keys) {
  for (final key in keys) {
    final value = item[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty && text != 'null') return text;
  }
  return '';
}

String _dateKey(Map<String, dynamic> item) {
  final value = _stringValue(item, const [
    'dataVencimento',
    'data_vencimento',
    'vencimento',
    'dtVencimento',
    'dt_vencimento',
  ]);
  if (value.length >= 10) return value.substring(0, 10);
  return value;
}

double _moneyValue(Map<String, dynamic> item, String key) {
  final value = item[key];
  if (value is num) return value.toDouble();
  if (value is String) {
    final normalized = value.contains(',')
        ? value.replaceAll('.', '').replaceAll(',', '.')
        : value;
    return double.tryParse(normalized) ?? 0;
  }
  return 0;
}

String _statusValue(Map<String, dynamic> item) =>
    _stringValue(item, const ['status', 'situacao']).toUpperCase();

bool _isBaixada(Map<String, dynamic> item) => _statusValue(item) == 'BAIXADA';

bool _isCancelada(Map<String, dynamic> item) =>
    _statusValue(item) == 'CANCELADA';

bool _hasDocumentoFiscal(Map<String, dynamic> item) {
  final value = item['documentoFiscal'] ?? item['documento_fiscal'];
  return value == true || value.toString().toLowerCase() == 'true';
}

Future<dynamic> _fetchFinancialJson(String url) async {
  try {
    final response =
        await http.get(Uri.parse(url), headers: TenantContext.headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
  } catch (_) {}
  return null;
}

class WindowsCalendarScreen extends StatefulWidget {
  const WindowsCalendarScreen({super.key});

  @override
  State<WindowsCalendarScreen> createState() => _WindowsCalendarScreenState();
}

class _WindowsCalendarScreenState extends State<WindowsCalendarScreen> {
  // ── Colors ──────────────────────────────────────────────────────────────
  // (local constants kept for non‑GridColors equivalents)
  static const Color _purpleLight = Color(0xFFF3E5F5);

  // ── State ────────────────────────────────────────────────────────────────
  DateTime _currentMonth = DateTime.now();
  DateTime? _selectedDay;
  String _viewMode = 'month';
  bool _loadingDay = false;
  bool _loadingMonth = false;

  List<Map<String, dynamic>> _contasPagar = [];
  List<Map<String, dynamic>> _contasReceber = [];

  final Map<int, _MonthSummary> _monthSummaries = {};
  Map<String, _DayMarkers> _dayMarkers = {};

  // ── Formatters ───────────────────────────────────────────────────────────
  final _currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  // ── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadMonthMarkers(_currentMonth);
  }

  // ── API helpers ──────────────────────────────────────────────────────────

  String _dayParam(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
  String _monthParam(DateTime d) => DateFormat('yyyy-MM').format(d);

  String _buildUrl(String base, Map<String, String> params) {
    final empId = TenantContext.empresaId;
    final buf = StringBuffer(base);
    buf.write('?');
    params.forEach((k, v) => buf.write('$k=$v&'));
    if (empId != null) buf.write('empId=$empId&');
    return buf.toString();
  }

  Future<dynamic> _getFinancialJson(String url) async {
    return _fetchFinancialJson(url);
  }

  List<Map<String, dynamic>> _parseItems(dynamic body) {
    return _parseFinancialItems(body);
  }

  Future<void> _loadMonthMarkers(DateTime month) async {
    setState(() => _loadingMonth = true);
    final monthStr = _monthParam(month);
    final urlP = _buildUrl(
        ApiLinks.allContasPagar, {'mesAno': monthStr, 'tamanho': '1000'});
    final urlR = _buildUrl(
        ApiLinks.allContasReceber, {'mesAno': monthStr, 'tamanho': '1000'});

    final bodyP = await _getFinancialJson(urlP);
    final bodyR = await _getFinancialJson(urlR);

    final pagarList = _parseItems(bodyP);
    final receberList = _parseItems(bodyR);

    final newMarkers = <String, _DayMarkers>{};

    void addMarker(String key,
        {bool pagar = false,
        bool receber = false,
        bool pago = false,
        bool recebido = false,
        bool tributo = false}) {
      final old = newMarkers[key] ?? const _DayMarkers();
      newMarkers[key] = _DayMarkers(
        hasPagar: old.hasPagar || pagar,
        hasReceber: old.hasReceber || receber,
        hasPago: old.hasPago || pago,
        hasRecebido: old.hasRecebido || recebido,
        hasTributo: old.hasTributo || tributo,
      );
    }

    for (final item in pagarList) {
      final dateStr = _dateKey(item);
      if (dateStr.isEmpty) continue;
      final date = DateTime.tryParse(dateStr);
      if (date == null) continue;
      final isBaixa = _isBaixada(item);
      final tributo = _hasDocumentoFiscal(item);
      addMarker(
        dateStr,
        pagar: !isBaixa,
        pago: isBaixa,
        tributo: tributo,
      );
    }

    for (final item in receberList) {
      final dateStr = _dateKey(item);
      if (dateStr.isEmpty) continue;
      final date = DateTime.tryParse(dateStr);
      if (date == null) continue;
      final isBaixa = _isBaixada(item);
      final tributo = _hasDocumentoFiscal(item);
      addMarker(
        dateStr,
        receber: !isBaixa,
        recebido: isBaixa,
        tributo: tributo,
      );
    }

    if (!mounted) return;
    setState(() {
      _dayMarkers = newMarkers;
      _loadingMonth = false;
    });
  }

  Future<void> _loadDayData(DateTime day) async {
    setState(() {
      _loadingDay = true;
      _contasPagar = [];
      _contasReceber = [];
    });
    final dayStr = _dayParam(day);
    final urlP = _buildUrl(
        ApiLinks.allContasPagar, {'dataVencimento': dayStr, 'tamanho': '100'});
    final urlR = _buildUrl(ApiLinks.allContasReceber,
        {'dataVencimento': dayStr, 'tamanho': '100'});

    final bodyP = await _getFinancialJson(urlP);
    final bodyR = await _getFinancialJson(urlR);

    if (!mounted) return;
    setState(() {
      _contasPagar = _parseItems(bodyP);
      _contasReceber = _parseItems(bodyR);
      _loadingDay = false;
    });
  }

  Future<_MonthSummary> _loadMonthSummary(int year, int month) async {
    final monthStr = '$year-${month.toString().padLeft(2, '0')}';
    final urlP = _buildUrl(
        ApiLinks.allContasPagar, {'mesAno': monthStr, 'tamanho': '1000'});
    final urlR = _buildUrl(
        ApiLinks.allContasReceber, {'mesAno': monthStr, 'tamanho': '1000'});

    final bodyP = await _getFinancialJson(urlP);
    final bodyR = await _getFinancialJson(urlR);

    final pagarList = _parseItems(bodyP);
    final receberList = _parseItems(bodyR);

    double totalPagar = 0, totalPago = 0, totalReceber = 0, totalRecebido = 0;

    for (final item in pagarList) {
      final v = _moneyValue(item, 'valor');
      if (_isBaixada(item)) {
        totalPago += v;
      } else if (!_isCancelada(item)) {
        totalPagar += v;
      }
    }
    for (final item in receberList) {
      final v = _moneyValue(item, 'valor');
      if (_isBaixada(item)) {
        totalRecebido += v;
      } else if (!_isCancelada(item)) {
        totalReceber += v;
      }
    }

    return _MonthSummary(
      totalPagar: totalPagar,
      totalPago: totalPago,
      totalReceber: totalReceber,
      totalRecebido: totalRecebido,
      saldoPagar: totalPago - totalPagar,
      saldoReceber: totalRecebido - totalReceber,
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.divider,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _viewMode == 'day'
                ? _buildSingleDayView()
                : _viewMode == 'year'
                    ? _buildMonthView()
                    : _buildDayView(),
          ),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: GridColors.error,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Left: title
          const Icon(Icons.calendar_month, color: Colors.white, size: 22),
          const SizedBox(width: 8),
          const Text(
            'Calendário Financeiro',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          // Center: toggle buttons
          _buildToggleBtn(
            icon: Icons.calendar_view_day,
            label: 'Dia',
            active: _viewMode == 'day',
            onTap: () {
              final day = _selectedDay ?? DateTime.now();
              setState(() {
                _viewMode = 'day';
                _selectedDay = day;
                _currentMonth = DateTime(day.year, day.month);
              });
              _loadMonthMarkers(_currentMonth);
              _loadDayData(day);
            },
          ),
          const SizedBox(width: 6),
          _buildToggleBtn(
            icon: Icons.calendar_view_month,
            label: 'Mês',
            active: _viewMode == 'month',
            onTap: () => setState(() => _viewMode = 'month'),
          ),
          const SizedBox(width: 6),
          _buildToggleBtn(
            icon: Icons.calendar_month,
            label: 'Ano',
            active: _viewMode == 'year',
            onTap: () {
              setState(() => _viewMode = 'year');
              _autoCarregarResumoAno(_currentMonth.year);
            },
          ),
          const Spacer(),
          // Right: Hoje button
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.white24,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () {
              final today = DateTime.now();
              setState(() {
                _selectedDay = today;
                _currentMonth = DateTime(today.year, today.month);
              });
              _loadMonthMarkers(_currentMonth);
              _loadDayData(today);
            },
            child: const Text('Hoje',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleBtn({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white54),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: active ? GridColors.error : Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: active ? GridColors.error : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Day view ─────────────────────────────────────────────────────────────
  Widget _buildDayView() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Card(
            margin: const EdgeInsets.all(12),
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _buildMonthNav(),
                  const SizedBox(height: 8),
                  _buildWeekdayHeaders(),
                  const SizedBox(height: 4),
                  Expanded(child: _buildCalendarGrid()),
                  const Divider(height: 16),
                  _buildLegend(),
                ],
              ),
            ),
          ),
        ),
        if (_selectedDay != null)
          SizedBox(
            width: 360,
            child: _buildDaySidePanel(),
          ),
      ],
    );
  }

  Widget _buildSingleDayView() {
    if (_selectedDay == null) {
      return const SizedBox.shrink();
    }
    return Center(
      child: SizedBox(
        width: 460,
        child: _buildDaySidePanel(),
      ),
    );
  }

  Widget _buildMonthNav() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: GridColors.success),
          tooltip: 'Mês anterior',
          onPressed: () {
            final prev = DateTime(_currentMonth.year, _currentMonth.month - 1);
            setState(() => _currentMonth = prev);
            _loadMonthMarkers(prev);
          },
        ),
        Text(
          DateFormat('MMMM yyyy', 'pt_BR').format(_currentMonth),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: GridColors.textSecondary,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: GridColors.success),
          tooltip: 'Próximo mês',
          onPressed: () {
            final next = DateTime(_currentMonth.year, _currentMonth.month + 1);
            setState(() => _currentMonth = next);
            _loadMonthMarkers(next);
          },
        ),
      ],
    );
  }

  Widget _buildWeekdayHeaders() {
    const days = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    return Row(
      children: days
          .map((d) => Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: const TextStyle(
                      color: GridColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth =
        DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final startWeekday = firstDay.weekday % 7; // 0=Sun
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);

    final filledCells = startWeekday + daysInMonth;
    final rowCount = (filledCells / 7).ceil();
    final totalCells = rowCount * 7;
    final cells = <Widget>[];

    // Empty leading cells
    for (int i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final dateStr = _dayParam(date);
      final markers = _dayMarkers[dateStr] ?? const _DayMarkers();
      final isToday = date == todayNorm;
      final isSelected =
          _selectedDay != null && _dayParam(_selectedDay!) == dateStr;
      final isPast = date.isBefore(todayNorm);

      cells.add(_buildDayCell(
        day: day,
        date: date,
        markers: markers,
        isToday: isToday,
        isSelected: isSelected,
        isPast: isPast,
      ));
    }

    while (cells.length < totalCells) {
      cells.add(const SizedBox());
    }

    return Column(
      children: List.generate(rowCount, (row) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: row == rowCount - 1 ? 0 : 2),
            child: Row(
              children: List.generate(7, (col) {
                final index = row * 7 + col;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: col == 6 ? 0 : 2),
                    child: cells[index],
                  ),
                );
              }),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDayCell({
    required int day,
    required DateTime date,
    required _DayMarkers markers,
    required bool isToday,
    required bool isSelected,
    required bool isPast,
  }) {
    Color? bgColor;
    Color textColor = GridColors.textSecondary;

    if (isSelected) {
      bgColor = GridColors.error;
      textColor = Colors.white;
    } else if (markers.hasPagar) {
      bgColor = GridColors.primaryLight;
    } else if (markers.hasReceber) {
      bgColor = GridColors.secondaryLight;
    } else if (isPast &&
        (markers.hasPago || markers.hasRecebido || markers.hasTributo)) {
      bgColor = GridColors.divider;
    }

    return GestureDetector(
      onTap: () {
        setState(() => _selectedDay = date);
        _loadDayData(date);
      },
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isToday ? GridColors.success : GridColors.divider,
            width: isToday ? 2 : 0.5,
          ),
        ),
        padding: const EdgeInsets.all(3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Wrap(
              spacing: 1,
              runSpacing: 1,
              children: [
                if (markers.hasPagar) _miniIcon(Icons.arrow_upward, GridColors.error, 11),
                if (markers.hasReceber)
                  _miniIcon(Icons.arrow_downward, GridColors.success, 11),
                if (markers.hasPago) _miniIcon(Icons.check, Colors.grey, 11),
                if (markers.hasRecebido)
                  _miniIcon(Icons.check_circle, GridColors.success, 11),
                if (markers.hasTributo)
                  Container(
                    decoration: BoxDecoration(
                      color: _purpleLight,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: GridColors.info, width: 1),
                    ),
                    padding: const EdgeInsets.all(1),
                    child: const Icon(Icons.receipt_long,
                        color: GridColors.info, size: 13),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniIcon(IconData icon, Color color, double size) {
    return Icon(icon, color: color, size: size);
  }

  // ── Legend ───────────────────────────────────────────────────────────────
  Widget _buildLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        _legendItem(Icons.arrow_upward, GridColors.error, 'A Pagar'),
        _legendItem(Icons.arrow_downward, GridColors.success, 'A Receber'),
        _legendItem(Icons.check, Colors.grey, 'Pago'),
        _legendItem(Icons.check_circle, GridColors.success, 'Recebido'),
        _legendItem(Icons.receipt_long, GridColors.info, 'Doc. Fiscal'),
      ],
    );
  }

  Widget _legendItem(IconData icon, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 11, color: GridColors.textSecondary)),
      ],
    );
  }

  // ── Day side panel ───────────────────────────────────────────────────────
  Widget _buildDaySidePanel() {
    final day = _selectedDay!;
    final weekdays = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    final wdLabel = weekdays[day.weekday % 7];
    final dateLabel =
        '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}/${day.year} ($wdLabel)';

    final totalPagar =
        _contasPagar.fold<double>(0, (s, i) => s + _moneyValue(i, 'valor'));
    final totalReceber =
        _contasReceber.fold<double>(0, (s, i) => s + _moneyValue(i, 'valor'));
    final saldo = totalReceber - totalPagar;

    return Card(
      margin: const EdgeInsets.fromLTRB(0, 12, 12, 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          // Panel header
          Container(
            decoration: const BoxDecoration(
              color: GridColors.error,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.event, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    dateLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
                  tooltip: 'Limpar seleção',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() => _selectedDay = null),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _loadingDay
                ? const Center(child: CircularProgressIndicator(color: GridColors.error))
                : ListView(
                    padding: const EdgeInsets.all(10),
                    children: [
                      _buildSectionHeader(
                        icon: Icons.arrow_upward,
                        color: GridColors.error,
                        label: 'A Pagar',
                        total: totalPagar,
                        totalColor: GridColors.error,
                      ),
                      ..._contasPagar
                          .map((item) => _buildContaItem(item, isPagar: true)),
                      if (_contasPagar.isEmpty)
                        _emptySection('Nenhuma conta a pagar'),
                      const SizedBox(height: 12),
                      _buildSectionHeader(
                        icon: Icons.arrow_downward,
                        color: GridColors.success,
                        label: 'A Receber',
                        total: totalReceber,
                        totalColor: GridColors.success,
                      ),
                      ..._contasReceber
                          .map((item) => _buildContaItem(item, isPagar: false)),
                      if (_contasReceber.isEmpty)
                        _emptySection('Nenhuma conta a receber'),
                      const SizedBox(height: 12),
                      _buildDaySummaryRow(totalPagar, totalReceber, saldo),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required Color color,
    required String label,
    required double total,
    required Color totalColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 13)),
          const Spacer(),
          Text(
            _currencyFmt.format(total),
            style: TextStyle(
                fontWeight: FontWeight.bold, color: totalColor, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildContaItem(Map<String, dynamic> item, {required bool isPagar}) {
    final valor = _moneyValue(item, 'valor');
    final status = _statusValue(item).isEmpty ? 'ABERTA' : _statusValue(item);
    final descricao = item['descricao'] as String? ?? '';
    final tributo = _hasDocumentoFiscal(item);
    final parceiro = (item['parceiro'] as Map?)?.cast<String, dynamic>();
    final parceiroNome = parceiro?['nome'] as String? ?? '';

    final today = DateTime.now();
    final vencStr = _dateKey(item);
    final vencDate = DateTime.tryParse(vencStr);
    final isVencida = status == 'ABERTA' &&
        vencDate != null &&
        vencDate.isBefore(DateTime(today.year, today.month, today.day));

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'BAIXADA':
        statusColor = GridColors.success;
        statusLabel = isPagar ? 'PAGO' : 'RECEBIDO';
        break;
      case 'CANCELADA':
        statusColor = Colors.grey;
        statusLabel = 'CANCELADA';
        break;
      default:
        statusColor = GridColors.warning;
        statusLabel = 'ABERTA';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: tributo ? GridColors.info : GridColors.divider,
          width: tributo ? 1.5 : 0.5,
        ),
      ),
      color: tributo ? _purpleLight.withValues(alpha: 0.3) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fiscal icon
            if (tributo) ...[
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: _purpleLight,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: GridColors.info),
                ),
                child: const Icon(Icons.receipt_long, color: GridColors.info, size: 14),
              ),
              const SizedBox(width: 6),
            ] else ...[
              Icon(
                status == 'BAIXADA' ? Icons.check : Icons.arrow_upward,
                color: status == 'BAIXADA'
                    ? Colors.grey
                    : (isPagar ? GridColors.error : GridColors.success),
                size: 16,
              ),
              const SizedBox(width: 6),
            ],
            // Description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    descricao,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  if (parceiroNome.isNotEmpty)
                    Text(parceiroNome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Right side: value + chips
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _currencyFmt.format(valor),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isPagar ? GridColors.error : GridColors.success,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isVencida) _chip('VENCIDA', GridColors.error, Colors.white),
                    const SizedBox(width: 3),
                    _chip(statusLabel, statusColor, Colors.white),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style:
              TextStyle(color: fg, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Widget _emptySection(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(msg,
          style: const TextStyle(color: Colors.grey, fontSize: 11),
          textAlign: TextAlign.center),
    );
  }

  Widget _buildDaySummaryRow(double pagar, double receber, double saldo) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: GridColors.divider,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GridColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryCell('-${_currencyFmt.format(pagar)}', 'A Pagar', GridColors.error),
          _summaryCell('+${_currencyFmt.format(receber)}', 'A Receber', GridColors.success),
          _summaryCell(
            '${saldo >= 0 ? '+' : ''}${_currencyFmt.format(saldo)}',
            'Saldo',
            saldo >= 0 ? GridColors.success : GridColors.error,
          ),
        ],
      ),
    );
  }

  Widget _summaryCell(String value, String label, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 12)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  // ── Month view ───────────────────────────────────────────────────────────
  Widget _buildMonthView() {
    final year = _currentMonth.year;
    return Column(
      children: [
        // Year navigation
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: GridColors.success),
                tooltip: 'Ano anterior',
                onPressed: () {
                  final novoAno = _currentMonth.year - 1;
                  setState(() {
                    _currentMonth = DateTime(novoAno, 1);
                    _monthSummaries.clear();
                  });
                  _autoCarregarResumoAno(novoAno);
                },
              ),
              Text(
                '$year',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18, color: GridColors.textSecondary),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: GridColors.success),
                tooltip: 'Próximo ano',
                onPressed: () {
                  final novoAno = _currentMonth.year + 1;
                  setState(() {
                    _currentMonth = DateTime(novoAno, 1);
                    _monthSummaries.clear();
                  });
                  _autoCarregarResumoAno(novoAno);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _loadingMonth
              ? const Center(child: CircularProgressIndicator(color: GridColors.error))
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.6,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: 12,
                  itemBuilder: (ctx, idx) => _buildMonthCard(year, idx + 1),
                ),
        ),
      ],
    );
  }

  Widget _buildMonthCard(int year, int month) {
    final monthNames = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    final summary = _monthSummaries[month];
    final saldo = summary != null
        ? (summary.totalRecebido + summary.saldoReceber) -
            (summary.totalPago + summary.saldoPagar.abs())
        : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month name + year
            Text(
              '${monthNames[month - 1]} $year',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13, color: GridColors.textSecondary),
            ),
            const SizedBox(height: 6),
            // Action buttons
            Row(
              children: [
                _monthActionBtn(
                  icon: Icons.arrow_upward,
                  color: GridColors.error,
                  tooltip: 'Contas a Pagar',
                  onTap: () => _showMonthPopup(
                    context,
                    year: year,
                    month: month,
                    isPagar: true,
                    monthName: monthNames[month - 1],
                  ),
                ),
                const SizedBox(width: 6),
                _monthActionBtn(
                  icon: Icons.arrow_downward,
                  color: GridColors.success,
                  tooltip: 'Contas a Receber',
                  onTap: () => _showMonthPopup(
                    context,
                    year: year,
                    month: month,
                    isPagar: false,
                    monthName: monthNames[month - 1],
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Summary text
            if (summary != null) ...[
              Text(
                'Pagar: ${_currencyFmt.format(summary.totalPagar)}',
                style: const TextStyle(fontSize: 10, color: GridColors.error),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Receber: ${_currencyFmt.format(summary.totalReceber)}',
                style: const TextStyle(fontSize: 10, color: GridColors.success),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Saldo: ${_currencyFmt.format(summary.saldoReceber - summary.saldoPagar.abs())}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: saldo >= 0 ? GridColors.success : GridColors.error,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ] else
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => _loadAndCacheMonthSummary(year, month),
                child: const Text('Carregar', style: TextStyle(fontSize: 10)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _monthActionBtn({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }

  Future<void> _loadAndCacheMonthSummary(int year, int month) async {
    final summary = await _loadMonthSummary(year, month);
    if (!mounted) return;
    setState(() => _monthSummaries[month] = summary);
  }

  /// Carrega automaticamente todos os 12 meses do ano ao entrar na view de Ano.
  /// Dispara em paralelo sem bloquear a UI (sem await).
  void _autoCarregarResumoAno(int year) {
    for (int m = 1; m <= 12; m++) {
      if (!_monthSummaries.containsKey(m)) {
        _loadAndCacheMonthSummary(year, m);
      }
    }
  }

  Future<void> _showMonthPopup(
    BuildContext context, {
    required int year,
    required int month,
    required bool isPagar,
    required String monthName,
  }) async {
    final monthStr = '$year-${month.toString().padLeft(2, '0')}';
    final url = isPagar
        ? _buildUrl(
            ApiLinks.allContasPagar, {'mesAno': monthStr, 'tamanho': '1000'})
        : _buildUrl(
            ApiLinks.allContasReceber, {'mesAno': monthStr, 'tamanho': '1000'});

    showDialog(
      context: context,
      builder: (_) => _MonthDetailDialog(
        title:
            '${isPagar ? 'Contas a Pagar' : 'Contas a Receber'} — $monthName $year',
        url: url,
        isPagar: isPagar,
        currencyFmt: _currencyFmt,
      ),
    );
  }
}

// ─── Month detail dialog ─────────────────────────────────────────────────────

class _MonthDetailDialog extends StatefulWidget {
  final String title;
  final String url;
  final bool isPagar;
  final NumberFormat currencyFmt;

  const _MonthDetailDialog({
    required this.title,
    required this.url,
    required this.isPagar,
    required this.currencyFmt,
  });

  @override
  State<_MonthDetailDialog> createState() => _MonthDetailDialogState();
}

class _MonthDetailDialogState extends State<_MonthDetailDialog> {
  // (local constants kept for non‑GridColors equivalents)
  static const Color _purpleLight = Color(0xFFF3E5F5);

  bool _loading = true;
  List<Map<String, dynamic>> _abertas = [];
  List<Map<String, dynamic>> _baixadas = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final body = await _fetchFinancialJson(widget.url);
    if (!mounted) return;
    final items = _parseFinancialItems(body);
    setState(() {
      _abertas =
          items.where((i) => !_isBaixada(i) && !_isCancelada(i)).toList();
      _baixadas = items.where(_isBaixada).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalAberto =
        _abertas.fold<double>(0, (s, i) => s + _moneyValue(i, 'valor'));
    final totalBaixado =
        _baixadas.fold<double>(0, (s, i) => s + _moneyValue(i, 'valor'));
    final saldo = widget.isPagar
        ? totalBaixado - totalAberto
        : totalBaixado - totalAberto;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
        child: Column(
          children: [
            // Dialog header
            Container(
              decoration: BoxDecoration(
                color: widget.isPagar ? GridColors.error : GridColors.success,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    widget.isPagar ? Icons.arrow_upward : Icons.arrow_downward,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 18),
                    tooltip: 'Fechar',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: GridColors.error))
                  : ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        _sectionTitle('Em Aberto', GridColors.warning),
                        ..._abertas.map((i) => _dialogItem(i)),
                        if (_abertas.isEmpty)
                          _emptyMsg('Nenhum item em aberto'),
                        const SizedBox(height: 12),
                        _sectionTitle(
                          widget.isPagar ? 'Pagas' : 'Recebidas',
                          GridColors.success,
                        ),
                        ..._baixadas.map((i) => _dialogItem(i)),
                        if (_baixadas.isEmpty) _emptyMsg('Nenhum item'),
                      ],
                    ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: GridColors.divider,
                border: Border(top: BorderSide(color: GridColors.divider)),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total em aberto:',
                        style: TextStyle(
                            fontSize: 12,
                            color: widget.isPagar ? GridColors.error : GridColors.warning),
                      ),
                      Text(
                        widget.currencyFmt.format(totalAberto),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: widget.isPagar ? GridColors.error : GridColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.isPagar ? 'Total pago:' : 'Total recebido:',
                        style: const TextStyle(fontSize: 12, color: GridColors.success),
                      ),
                      Text(
                        widget.currencyFmt.format(totalBaixado),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: GridColors.success,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Saldo:',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.currencyFmt.format(saldo),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: saldo >= 0 ? GridColors.success : GridColors.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        label,
        style:
            TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
      ),
    );
  }

  Widget _dialogItem(Map<String, dynamic> item) {
    final valor = _moneyValue(item, 'valor');
    final descricao = item['descricao'] as String? ?? '';
    final tributo = _hasDocumentoFiscal(item);
    final parceiro = (item['parceiro'] as Map?)?.cast<String, dynamic>();
    final parceiroNome = parceiro?['nome'] as String? ?? '';
    final vencStr = _dateKey(item);
    final dia = vencStr.length >= 10 ? vencStr.substring(8, 10) : '';
    final mes = vencStr.length >= 7 ? vencStr.substring(5, 7) : '';
    final dataLabel = dia.isNotEmpty && mes.isNotEmpty ? '$dia/$mes' : '';

    final subtitleParts = <String>[];
    if (dataLabel.isNotEmpty) subtitleParts.add(dataLabel);
    if (parceiroNome.isNotEmpty) subtitleParts.add(parceiroNome);
    final subtitleText = subtitleParts.join(' · ');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: tributo ? GridColors.info : GridColors.divider,
          width: tributo ? 1.5 : 0.5,
        ),
      ),
      color: tributo ? _purpleLight.withValues(alpha: 0.25) : Colors.white,
      child: ListTile(
        dense: true,
        leading: tributo
            ? Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _purpleLight,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: GridColors.info),
                ),
                child: const Icon(Icons.receipt_long, color: GridColors.info, size: 14),
              )
            : null,
        title: Text(descricao,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12)),
        subtitle: subtitleText.isNotEmpty
            ? Text(subtitleText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10))
            : null,
        trailing: Text(
          widget.currencyFmt.format(valor),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: widget.isPagar ? GridColors.error : GridColors.success,
          ),
        ),
      ),
    );
  }

  Widget _emptyMsg(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(msg,
          style: const TextStyle(color: Colors.grey, fontSize: 11),
          textAlign: TextAlign.center),
    );
  }
}

// ─── Web alias ───────────────────────────────────────────────────────────────
typedef WebCalendarScreen = WindowsCalendarScreen;
