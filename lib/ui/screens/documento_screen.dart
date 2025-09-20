import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_manager_flutter/data/models/documento_model.dart';
import 'package:task_manager_flutter/data/services/documentoService.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _currentMonth = DateTime.now();
  final DocumentoService _documentoService = DocumentoService();
  List<DateTime> _datesWithNewDocs = [];
  List<DateTime> _datesWithReadDocs = [];
  List<Documento> _selectedDayDocuments = [];
  DateTime? _selectedDay;
  int _usuarioId = 1; // ID do usuário logado (deve vir da autenticação)

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month);
    _loadDatesWithDocuments();
  }

  Future<void> _loadDatesWithDocuments() async {
    try {
      final newDates = await _documentoService.getDatasComDocumentosNovos(
        _currentMonth.month,
        _currentMonth.year,
        _usuarioId,
      );

      final readDates = await _documentoService.getDatasComDocumentosLidos(
        _currentMonth.month,
        _currentMonth.year,
        _usuarioId,
      );

      setState(() {
        _datesWithNewDocs = newDates;
        _datesWithReadDocs = readDates;
      });
    } catch (e) {
      print('Erro ao carregar datas: $e');
    }
  }

  Future<void> _loadDayDocuments(DateTime day) async {
    try {
      final documentos = await _documentoService.getDocumentosPorData(day);

      // Verificar quais documentos estão marcados como lidos
      for (var doc in documentos) {
        final isRead = await _documentoService.verificarSeLido(
          doc.id,
          _usuarioId,
        );
        doc.lido = isRead;
      }

      setState(() {
        _selectedDay = day;
        _selectedDayDocuments = documentos;
      });
    } catch (e) {
      print('Erro ao carregar documentos: $e');
    }
  }

  Future<void> _marcarDocumentoComoLido(int documentoId) async {
    try {
      await _documentoService.marcarComoLido(documentoId, _usuarioId);

      // Atualizar a lista de documentos
      setState(() {
        _selectedDayDocuments = _selectedDayDocuments.map((doc) {
          if (doc.id == documentoId) {
            return Documento(
              id: doc.id,
              dataDocumento: doc.dataDocumento,
              descricao: doc.descricao,
              valor: doc.valor,
              status: doc.status,
              lido: true,
            );
          }
          return doc;
        }).toList();
      });

      // Recarregar as datas para atualizar as cores no calendário
      _loadDatesWithDocuments();
    } catch (e) {
      print('Erro ao marcar documento como lido: $e');
    }
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      _loadDatesWithDocuments();
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      _loadDatesWithDocuments();
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Color _getDayColor(DateTime date) {
    if (_datesWithNewDocs.any((d) => _isSameDay(d, date))) {
      return Colors.red[100]!;
    } else if (_datesWithReadDocs.any((d) => _isSameDay(d, date))) {
      return Colors.grey[200]!;
    }
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendário Financeiro'),
        actions: [
          IconButton(icon: Icon(Icons.home), onPressed: () {}),
          IconButton(icon: Icon(Icons.menu), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          _buildMonthNavigation(),
          _buildLegend(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [_buildCalendarGrid(), _buildDailyDocuments()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Os métodos _buildMonthNavigation, _buildLegend, _buildCalendarGrid
  // permanecem iguais ao código anterior...

  Widget _buildDailyDocuments() {
    if (_selectedDay == null || _selectedDayDocuments.isEmpty) {
      return Container();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Documentos do dia ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _selectedDayDocuments.length,
            itemBuilder: (context, index) {
              final doc = _selectedDayDocuments[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 5),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text(doc.descricao),
                            if (!doc.lido)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    'Novo',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green[800],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        'R\$${doc.valor.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      if (!doc.lido)
                        IconButton(
                          icon: Icon(
                            Icons.check_circle_outline,
                            color: Colors.blue,
                          ),
                          onPressed: () => _marcarDocumentoComoLido(doc.id),
                          tooltip: 'Marcar como lido',
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  // Adicione estes métodos à classe _CalendarScreenState

  Widget _buildMonthNavigation() {
    return Container(
      padding: EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: Icon(Icons.arrow_back), onPressed: _previousMonth),
          Text(
            DateFormat('MMMM de yyyy', 'pt_BR').format(_currentMonth),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(icon: Icon(Icons.arrow_forward), onPressed: _nextMonth),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Text('Legenda: '),
          Container(
            padding: EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: Colors.red[100],
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text('Dias com docs novos', style: TextStyle(fontSize: 12)),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              'Dias com docs já lidos',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final int daysInMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;
    final DateTime firstDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    );
    final int firstWeekday = firstDayOfMonth.weekday == 7
        ? 0
        : firstDayOfMonth.weekday;

    List<String> weekdays = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab'];

    List<Widget> dayWidgets = [];

    // Add weekday headers
    for (String day in weekdays) {
      dayWidgets.add(
        Expanded(
          child: Center(
            child: Text(day, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      );
    }

    // Add empty cells for days before the 1st
    for (int i = 0; i < firstWeekday; i++) {
      dayWidgets.add(Expanded(child: Container()));
    }

    // Add days of the month
    for (int i = 1; i <= daysInMonth; i++) {
      DateTime dayDate = DateTime(_currentMonth.year, _currentMonth.month, i);
      dayWidgets.add(
        Expanded(
          child: GestureDetector(
            onTap: () => _loadDayDocuments(dayDate),
            child: Container(
              margin: EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: _getDayColor(dayDate),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Center(
                child: Text(
                  '$i',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Fill remaining cells to complete the last row
    while (dayWidgets.length % 7 != 0) {
      dayWidgets.add(Expanded(child: Container()));
    }

    return Container(
      padding: EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Weekday headers
          Row(children: dayWidgets.sublist(0, 7)),
          // Days grid
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
            ),
            itemCount: dayWidgets.length - 7,
            itemBuilder: (context, index) {
              return dayWidgets[index + 7];
            },
          ),
        ],
      ),
    );
  }
}
