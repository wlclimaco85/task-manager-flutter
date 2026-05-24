// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';
import 'package:intl/intl.dart';
import '../../../services/network_caller.dart';
import '../../../utils/api_links.dart';
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

class WindowsCalendarScreen extends StatefulWidget {
  const WindowsCalendarScreen({super.key});

  @override
  State<WindowsCalendarScreen> createState() => _WindowsCalendarScreenState();
}

class _WindowsCalendarScreenState extends State<WindowsCalendarScreen> {
  // ── Colors ──────────────────────────────────────────────────────────────
  static const Color _red = GridColors.primary;
  static const Color _redLight = Color(0xFFFFEBEE);
  static const Color _green = GridColors.secondary;
  static const Color _greenLight = Color(0xFFE8F5E9);
  static const Color _orange = Color(0xFFE65100);
  static const Color _purple = Color(0xFF6A1B9A);
  static const Color _purpleLight = Color(0xFFF3E5F5);
  static const Color _grey = Color(0xFFF5F5F5);
  static const Color _greyBorder = Color(0xFFE0E0E0);
  static const Color _dark = Color(0xFF212121);

  // ── State ────────────────────────────────────────────────────────────────
  DateTime _currentMonth = DateTime.now();
  DateTime? _selectedDay;
  String _viewMode = 'day';
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
    final parcId = TenantContext.parceiroId;
    final buf = StringBuffer(base);
    buf.write('?');
    params.forEach((k, v) => buf.write('$k=$v&'));
    if (empId != null) buf.write('empId=$empId&');
    if (parcId != null) buf.write('parceiroId=$parcId&');
    return buf.toString();
  }

  /// Parseia a resposta da API financeira com suporte a múltiplos formatos.
  /// O backend pode retornar:
  ///   { "data": { "dados": [...] } }        (Spring Page wrapper)
  ///   { "data": [...] }                      (lista direta dentro de "data")
  ///   [ ... ]                                 (lista raiz)
  ///   { "content": [...] }                    (Spring Page alternativo)
  ///   { "items": [...] }  ou { "results": [...] }
  List<Map<String, dynamic>> _parseItems(dynamic body) {
    try {
      dynamic cursor = body;
      // Tenta extrair 'data' se existir
      if (cursor is Map && cursor.containsKey('data')) {
        cursor = cursor['data'];
      }
      // Se 'data' é um Map, procura listas internas
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
      // Se cursor já é uma lista direta
      if (cursor is List) {
        return cursor
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> _loadMonthMarkers(DateTime month) async {
    setState(() => _loadingMonth = true);
    final monthStr = _monthParam(month);
    final urlP = _buildUrl(
        ApiLinks.allContasPagar, {'mesAno': monthStr, 'tamanho': '1000'});
    final urlR = _buildUrl(
        ApiLinks.allContasReceber, {'mesAno': monthStr, 'tamanho': '1000'});

    final resP = await NetworkCaller().getRequest(urlP);
    final resR = await NetworkCaller().getRequest(urlR);

    final pagarList =
        resP.isSuccess ? _parseItems(resP.body) : <Map<String, dynamic>>[];
    final receberList =
        resR.isSuccess ? _parseItems(resR.body) : <Map<String, dynamic>>[];

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
      final dateStr =
          (item['dataVencimento'] as String?)?.substring(0, 10) ?? '';
      if (dateStr.isEmpty) continue;
      final date = DateTime.tryParse(dateStr);
      if (date == null) continue;
      final isBaixa = item['status'] == 'BAIXADA';
      final tributo = item['documentoFiscal'] == true;
      addMarker(
        dateStr,
        pagar: !isBaixa,
        pago: isBaixa,
        tributo: tributo,
      );
    }

    for (final item in receberList) {
      final dateStr =
          (item['dataVencimento'] as String?)?.substring(0, 10) ?? '';
      if (dateStr.isEmpty) continue;
      final date = DateTime.tryParse(dateStr);
      if (date == null) continue;
      final isBaixa = item['status'] == 'BAIXADA';
      final tributo = item['documentoFiscal'] == true;
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

    final resP = await NetworkCaller().getRequest(urlP);
    final resR = await NetworkCaller().getRequest(urlR);

    if (!mounted) return;
    setState(() {
      _contasPagar = resP.isSuccess ? _parseItems(resP.body) : [];
      _contasReceber = resR.isSuccess ? _parseItems(resR.body) : [];
      _loadingDay = false;
    });
  }

  Future<_MonthSummary> _loadMonthSummary(int year, int month) async {
    final monthStr = '$year-${month.toString().padLeft(2, '0')}';
    final urlP = _buildUrl(
        ApiLinks.allContasPagar, {'mesAno': monthStr, 'tamanho': '1000'});
    final urlR = _buildUrl(
        ApiLinks.allContasReceber, {'mesAno': monthStr, 'tamanho': '1000'});

    final resP = await NetworkCaller().getRequest(urlP);
    final resR = await NetworkCaller().getRequest(urlR);

    final pagarList =
        resP.isSuccess ? _parseItems(resP.body) : <Map<String, dynamic>>[];
    final receberList =
        resR.isSuccess ? _parseItems(resR.body) : <Map<String, dynamic>>[];

    double totalPagar = 0, totalPago = 0, totalReceber = 0, totalRecebido = 0;

    for (final item in pagarList) {
      final v = (item['valor'] as num?)?.toDouble() ?? 0;
      if (item['status'] == 'BAIXADA') {
        totalPago += v;
      } else if (item['status'] != 'CANCELADA') {
        totalPagar += v;
      }
    }
    for (final item in receberList) {
      final v = (item['valor'] as num?)?.toDouble() ?? 0;
      if (item['status'] == 'BAIXADA') {
        totalRecebido += v;
      } else if (item['status'] != 'CANCELADA') {
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
      backgroundColor: _grey,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _viewMode == 'day' ? _buildDayView() : _buildMonthView(),
          ),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: _red,
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
            onTap: () => setState(() => _viewMode = 'day'),
          ),
          const SizedBox(width: 6),
          _buildToggleBtn(
            icon: Icons.calendar_view_month,
            label: 'Mês',
            active: _viewMode == 'month',
            onTap: () => setState(() => _viewMode = 'month'),
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
            Icon(icon, size: 16, color: active ? _red : Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: active ? _red : Colors.white,
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

  Widget _buildMonthNav() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: _green),
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
            color: _dark,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: _green),
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
                      color: _green,
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

    return GridView.count(
      crossAxisCount: 7,
      childAspectRatio: 0.85,
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      children: cells,
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
    Color textColor = _dark;

    if (isSelected) {
      bgColor = _red;
      textColor = Colors.white;
    } else if (isPast &&
        (markers.hasPago || markers.hasRecebido || markers.hasTributo)) {
      bgColor = _grey;
    } else if (!isPast && markers.hasPagar) {
      bgColor = _redLight;
    } else if (!isPast && markers.hasReceber) {
      bgColor = _greenLight;
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
            color: isToday ? _green : _greyBorder,
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
                if (markers.hasPagar) _miniIcon(Icons.arrow_upward, _red, 11),
                if (markers.hasReceber)
                  _miniIcon(Icons.arrow_downward, _green, 11),
                if (markers.hasPago) _miniIcon(Icons.check, Colors.grey, 11),
                if (markers.hasRecebido)
                  _miniIcon(Icons.check_circle, _green, 11),
                if (markers.hasTributo)
                  Container(
                    decoration: BoxDecoration(
                      color: _purpleLight,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: _purple, width: 1),
                    ),
                    padding: const EdgeInsets.all(1),
                    child: const Icon(Icons.receipt_long,
                        color: _purple, size: 13),
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
        _legendItem(Icons.arrow_upward, _red, 'A Pagar'),
        _legendItem(Icons.arrow_downward, _green, 'A Receber'),
        _legendItem(Icons.check, Colors.grey, 'Pago'),
        _legendItem(Icons.check_circle, _green, 'Recebido'),
        _legendItem(Icons.receipt_long, _purple, 'Doc. Fiscal'),
      ],
    );
  }

  Widget _legendItem(IconData icon, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 11, color: _dark)),
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

    final totalPagar = _contasPagar.fold<double>(
        0, (s, i) => s + ((i['valor'] as num?)?.toDouble() ?? 0));
    final totalReceber = _contasReceber.fold<double>(
        0, (s, i) => s + ((i['valor'] as num?)?.toDouble() ?? 0));
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
              color: _red,
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
                ? const Center(child: CircularProgressIndicator(color: _red))
                : ListView(
                    padding: const EdgeInsets.all(10),
                    children: [
                      _buildSectionHeader(
                        icon: Icons.arrow_upward,
                        color: _red,
                        label: 'A Pagar',
                        total: totalPagar,
                        totalColor: _red,
                      ),
                      ..._contasPagar
                          .map((item) => _buildContaItem(item, isPagar: true)),
                      if (_contasPagar.isEmpty)
                        _emptySection('Nenhuma conta a pagar'),
                      const SizedBox(height: 12),
                      _buildSectionHeader(
                        icon: Icons.arrow_downward,
                        color: _green,
                        label: 'A Receber',
                        total: totalReceber,
                        totalColor: _green,
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
    final valor = (item['valor'] as num?)?.toDouble() ?? 0;
    final status = item['status'] as String? ?? 'ABERTA';
    final descricao = item['descricao'] as String? ?? '';
    final tributo = item['documentoFiscal'] == true;
    final parceiro = (item['parceiro'] as Map?)?.cast<String, dynamic>();
    final parceiroNome = parceiro?['nome'] as String? ?? '';

    final today = DateTime.now();
    final vencStr = (item['dataVencimento'] as String?)?.substring(0, 10) ?? '';
    final vencDate = DateTime.tryParse(vencStr);
    final isVencida = status == 'ABERTA' &&
        vencDate != null &&
        vencDate.isBefore(DateTime(today.year, today.month, today.day));

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'BAIXADA':
        statusColor = _green;
        statusLabel = isPagar ? 'PAGO' : 'RECEBIDO';
        break;
      case 'CANCELADA':
        statusColor = Colors.grey;
        statusLabel = 'CANCELADA';
        break;
      default:
        statusColor = _orange;
        statusLabel = 'ABERTA';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: tributo ? _purple : _greyBorder,
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
                  border: Border.all(color: _purple),
                ),
                child: const Icon(Icons.receipt_long, color: _purple, size: 14),
              ),
              const SizedBox(width: 6),
            ] else ...[
              Icon(
                status == 'BAIXADA' ? Icons.check : Icons.arrow_upward,
                color: status == 'BAIXADA'
                    ? Colors.grey
                    : (isPagar ? _red : _green),
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
                    color: isPagar ? _red : _green,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isVencida) _chip('VENCIDA', _red, Colors.white),
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
        color: _grey,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _greyBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryCell('-${_currencyFmt.format(pagar)}', 'A Pagar', _red),
          _summaryCell('+${_currencyFmt.format(receber)}', 'A Receber', _green),
          _summaryCell(
            '${saldo >= 0 ? '+' : ''}${_currencyFmt.format(saldo)}',
            'Saldo',
            saldo >= 0 ? _green : _red,
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
                icon: const Icon(Icons.chevron_left, color: _green),
                onPressed: () => setState(
                    () => _currentMonth = DateTime(_currentMonth.year - 1, 1)),
              ),
              Text(
                '$year',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18, color: _dark),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: _green),
                onPressed: () => setState(
                    () => _currentMonth = DateTime(_currentMonth.year + 1, 1)),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loadingMonth
              ? const Center(child: CircularProgressIndicator(color: _red))
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
                  fontWeight: FontWeight.bold, fontSize: 13, color: _dark),
            ),
            const SizedBox(height: 6),
            // Action buttons
            Row(
              children: [
                _monthActionBtn(
                  icon: Icons.arrow_upward,
                  color: _red,
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
                  color: _green,
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
                style: const TextStyle(fontSize: 10, color: _red),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Receber: ${_currencyFmt.format(summary.totalReceber)}',
                style: const TextStyle(fontSize: 10, color: _green),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Saldo: ${_currencyFmt.format(summary.saldoReceber - summary.saldoPagar.abs())}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: saldo >= 0 ? _green : _red,
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
  static const Color _red = GridColors.primary;
  static const Color _green = GridColors.secondary;
  static const Color _orange = Color(0xFFE65100);
  static const Color _grey = Color(0xFFF5F5F5);
  static const Color _greyBorder = Color(0xFFE0E0E0);
  static const Color _purple = Color(0xFF6A1B9A);
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
    final res = await NetworkCaller().getRequest(widget.url);
    if (!mounted) return;
    List<Map<String, dynamic>> items = [];
    if (res.isSuccess) {
      try {
        final data = res.body!['data'];
        final dados = data['dados'] as List? ?? [];
        items = List<Map<String, dynamic>>.from(dados);
      } catch (_) {}
    }
    setState(() {
      _abertas = items
          .where((i) => i['status'] != 'BAIXADA' && i['status'] != 'CANCELADA')
          .toList();
      _baixadas = items.where((i) => i['status'] == 'BAIXADA').toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalAberto = _abertas.fold<double>(
        0, (s, i) => s + ((i['valor'] as num?)?.toDouble() ?? 0));
    final totalBaixado = _baixadas.fold<double>(
        0, (s, i) => s + ((i['valor'] as num?)?.toDouble() ?? 0));
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
                color: widget.isPagar ? _red : _green,
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
                  ? const Center(child: CircularProgressIndicator(color: _red))
                  : ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        _sectionTitle('Em Aberto', _orange),
                        ..._abertas.map((i) => _dialogItem(i)),
                        if (_abertas.isEmpty)
                          _emptyMsg('Nenhum item em aberto'),
                        const SizedBox(height: 12),
                        _sectionTitle(
                          widget.isPagar ? 'Pagas' : 'Recebidas',
                          _green,
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
                color: _grey,
                border: Border(top: BorderSide(color: _greyBorder)),
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
                            color: widget.isPagar ? _red : _orange),
                      ),
                      Text(
                        widget.currencyFmt.format(totalAberto),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: widget.isPagar ? _red : _orange,
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
                        style: const TextStyle(fontSize: 12, color: _green),
                      ),
                      Text(
                        widget.currencyFmt.format(totalBaixado),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: _green,
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
                          color: saldo >= 0 ? _green : _red,
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
    final valor = (item['valor'] as num?)?.toDouble() ?? 0;
    final descricao = item['descricao'] as String? ?? '';
    final tributo = item['documentoFiscal'] == true;
    final parceiro = (item['parceiro'] as Map?)?.cast<String, dynamic>();
    final parceiroNome = parceiro?['nome'] as String? ?? '';
    final vencStr = (item['dataVencimento'] as String?)?.substring(0, 10) ?? '';
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
          color: tributo ? _purple : _greyBorder,
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
                  border: Border.all(color: _purple),
                ),
                child: const Icon(Icons.receipt_long, color: _purple, size: 14),
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
            color: widget.isPagar ? _red : _green,
          ),
        ),
      ),
    );
  }

  Widget _emptyMsg(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        msg,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
    );
  }
}
