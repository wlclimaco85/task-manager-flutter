// lib/screens/contabil/calendario_screen.dart
import 'package:flutter/material.dart';

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({Key? key}) : super(key: key);

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  String _filtroTipo = 'Todos';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Calendário Tributário',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButton<String>(
              value: _filtroTipo,
              items: ['Todos', 'Federal', 'Estadual', 'Municipal']
                  .map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _filtroTipo = newValue;
                  });
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildCalendarTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarTable() {
    final diasSemana = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'];
    final diasMes = List.generate(42, (index) => index + 1);

    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      children: [
        // Cabeçalho com dias da semana
        TableRow(
          children: diasSemana
              .map((dia) => Container(
                    color: Colors.blue.shade100,
                    padding: const EdgeInsets.all(8.0),
                    child: Text(dia,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ))
              .toList(),
        ),
        // Linhas do calendário (6 semanas)
        for (int i = 0; i < 6; i++)
          TableRow(
            children: List.generate(7, (dayIndex) {
              final diaNumero = i * 7 + dayIndex + 1;
              return Container(
                height: 60,
                padding: const EdgeInsets.all(4.0),
                child: Text(
                  diaNumero <= 31 ? '$diaNumero' : '',
                  textAlign: TextAlign.center,
                ),
              );
            }),
          ),
      ],
    );
  }
}
