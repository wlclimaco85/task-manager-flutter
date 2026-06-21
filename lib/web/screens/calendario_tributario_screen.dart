import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';

import '../../models/auth_utility.dart';
import '../../utils/api_links.dart';
import '../../utils/grid_colors.dart';
import '../../utils/tenant_context.dart';

class CalendarioTributarioScreen extends StatefulWidget {
  const CalendarioTributarioScreen({super.key});

  @override
  State<CalendarioTributarioScreen> createState() =>
      _CalendarioTributarioScreenState();
}

class _CalendarioTributarioScreenState
    extends State<CalendarioTributarioScreen> {
  bool _carregando = true;
  DateTime _focoMes = DateTime.now();
  DateTime? _diaSelecionado;
  Map<DateTime, List<Map<String, dynamic>>> _eventos = {};

  @override
  void initState() {
    super.initState();
    _diaSelecionado = DateTime.now();
    _carregar();
  }

  DateTime _normalizarDia(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _carregar() async {
    try {
      final url = TenantContext.applyToUrl(
          '${ApiLinks.baseUrl}/api/dashboard/calendario-tributario?mes=${_focoMes.month}&ano=${_focoMes.year}');
      final token = AuthUtility.userInfo?.token;
      final resp = await http.get(Uri.parse(url), headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      });
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final lista = List<Map<String, dynamic>>.from(body['data'] ?? body['content'] ?? []);
        final Map<DateTime, List<Map<String, dynamic>>> mapa = {};
        for (final item in lista) {
          final vencStr = item['dataVencimento']?.toString();
          if (vencStr == null) continue;
          try {
            final d = _normalizarDia(DateTime.parse(vencStr));
            mapa.putIfAbsent(d, () => []).add(item);
          } catch (_) {}
        }
        setState(() {
          _eventos = mapa;
          _carregando = false;
        });
      } else {
        setState(() => _carregando = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregando = false);
    }
  }

  List<Map<String, dynamic>> _eventosNoDia(DateTime dia) =>
      _eventos[_normalizarDia(dia)] ?? [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendário Tributário'),
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TableCalendar<Map<String, dynamic>>(
                  firstDay: DateTime(2020),
                  lastDay: DateTime(2030, 12, 31),
                  focusedDay: _focoMes,
                  selectedDayPredicate: (d) =>
                      isSameDay(d, _diaSelecionado),
                  eventLoader: _eventosNoDia,
                  onDaySelected: (selected, focado) {
                    setState(() {
                      _diaSelecionado = selected;
                      _focoMes = focado;
                    });
                  },
                  onPageChanged: (focado) {
                    _focoMes = focado;
                    setState(() => _carregando = true);
                    _carregar();
                  },
                  calendarStyle: CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color: GridColors.primary,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: GridColors.primary.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                        color: GridColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _buildListaEventos(),
                ),
              ],
            ),
    );
  }

  Widget _buildListaEventos() {
    if (_diaSelecionado == null) return const SizedBox();
    final lista = _eventosNoDia(_diaSelecionado!);
    if (lista.isEmpty) {
      return const Center(
          child: Text('Nenhuma obrigação neste dia',
              style: TextStyle(color: Colors.grey)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: lista.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final item = lista[i];
        final desc = item['descricao']?.toString() ?? 'Obrigação';
        final valor = item['valor']?.toString() ?? '0';
        final status = item['status'] as int? ?? 0;
        final cor = status == 0 ? Colors.orange : Colors.green;
        return Card(
          child: ListTile(
            leading: Icon(Icons.event_note, color: cor),
            title: Text(desc),
            trailing: Text('R\$ $valor',
                style: TextStyle(fontWeight: FontWeight.bold, color: cor)),
          ),
        );
      },
    );
  }
}
