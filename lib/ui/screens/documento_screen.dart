import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_manager_flutter/data/models/documento_model.dart';
import 'package:task_manager_flutter/data/services/documentoService.dart';
// Make sure to import your UserBannerAppBar
import 'package:task_manager_flutter/ui/widgets/user_banners.dart'; // Adjust path as needed

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

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
  final int _usuarioId = 1; // ID do usuário logado (deve vir da autenticação)
  bool _isLoading = false; // To control refresh indicator state

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month);
    _loadDatesWithDocuments();
  }

  Future<void> _loadDatesWithDocuments() async {
    setState(() {
      _isLoading = true;
    });
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
    } finally {
      setState(() {
        _isLoading = false;
      });
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
      // Replaced standard AppBar with UserBannerAppBar
      appBar: UserBannerAppBar(
        screenTitle: 'Calendário Financeiro',
        onRefresh: _loadDatesWithDocuments, // Connects refresh button
        isLoading: true, // Controls refresh indicator state
        showFilterButton: false,
        // onFilterToggle: () {
        //   Add filter functionality here if needed later
        // },
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

  Widget _buildMonthNavigation() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: _previousMonth),
          Text(
            DateFormat('MMMM de yyyy', 'pt_BR').format(_currentMonth),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(icon: const Icon(Icons.arrow_forward), onPressed: _nextMonth),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          const Text('Legenda: '),
          Container(
            padding: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: Colors.red[100],
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Text('Dias com docs novos', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Text(
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

    // Corrigido: O domingo é 7 no DateTime, mas queremos que seja 0 para o grid
    final int firstWeekday = firstDayOfMonth.weekday;
    final int startingDay =
        firstWeekday % 7; // Isso faz Dom=0, Seg=1, ..., Sab=6

    List<String> weekdays = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab'];

    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Cabeçalho com os dias da semana
          Row(
            children: weekdays.map((day) {
              return Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Text(
                      day,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          // Grid dos dias
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.2,
            ),
            itemCount: 42, // 6 semanas * 7 dias (máximo que pode precisar)
            itemBuilder: (context, index) {
              // Calcular qual dia este índice representa
              final dayOffset = index - startingDay;
              final currentDay = DateTime(
                _currentMonth.year,
                _currentMonth.month,
                1 + dayOffset,
              );

              // Verificar se este dia pertence ao mês atual
              final bool isCurrentMonth =
                  currentDay.month == _currentMonth.month;

              if (!isCurrentMonth ||
                  dayOffset < 0 ||
                  dayOffset >= daysInMonth) {
                // Dia vazio (de outro mês)
                return Container(
                  margin: const EdgeInsets.all(2),
                  child: const Center(child: Text('')),
                );
              }

              final int dayNumber = currentDay.day;

              return GestureDetector(
                onTap: () => _loadDayDocuments(currentDay),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: _getDayColor(currentDay),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedDay != null &&
                              _isSameDay(_selectedDay!, currentDay)
                          ? Colors.blue
                          : Colors.grey[300]!,
                      width: _selectedDay != null &&
                              _isSameDay(_selectedDay!, currentDay)
                          ? 2
                          : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$dayNumber',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDailyDocuments() {
    if (_selectedDay == null) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'Selecione um dia para ver os documentos',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    if (_selectedDayDocuments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Documentos do dia ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Nenhum documento encontrado para este dia',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Documentos do dia ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _selectedDayDocuments.length,
            itemBuilder: (context, index) {
              final doc = _selectedDayDocuments[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 5),
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
                                  padding: const EdgeInsets.symmetric(
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      if (!doc.lido)
                        IconButton(
                          icon: const Icon(
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
}
