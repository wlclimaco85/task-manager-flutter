import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';

class PontoScreen extends StatefulWidget {
  const PontoScreen({super.key});

  @override
  State<PontoScreen> createState() => _PontoScreenState();
}

class _PontoScreenState extends State<PontoScreen> {
  bool _isRegistering = false;
  DateTime now = DateTime.now();

  List<Map<String, dynamic>> marcacoes = [
    {"entrada": "08:14", "saida": "12:44"},
    {"entrada": "13:51", "saida": "18:17"},
  ];

  String get horasTrabalhadas => "8h 56min";
  String get intervalo => "1h 07min";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.background,
      appBar: AppBar(
        backgroundColor: GridColors.primary,
        title: const Text(
          'Registro de Ponto',
          style: TextStyle(
            color: GridColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildClockCard(),
            const SizedBox(height: 20),
            _buildMarcacoesCard(),
            const SizedBox(height: 20),
            _buildActionButtons(context),
            const SizedBox(height: 30),
            _buildHumorSection(),
          ],
        ),
      ),
    );
  }

  // === RELÓGIO E BOTÃO DE REGISTRAR
  Widget _buildClockCard() {
    return Card(
      color: GridColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            Text(
              DateFormat.Hms().format(now),
              style: const TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: GridColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat("EEEE, dd 'de' MMMM 'de' yyyy", 'pt_BR').format(now),
              style: const TextStyle(
                fontSize: 15,
                color: GridColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.success,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              onPressed: _isRegistering
                  ? null
                  : () {
                      setState(() => _isRegistering = true);
                      Future.delayed(const Duration(seconds: 2), () {
                        setState(() => _isRegistering = false);
                      });
                    },
              icon: const Icon(Icons.fingerprint, color: Colors.white),
              label: Text(
                _isRegistering ? "Registrando..." : "Registrar Ponto",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Mantenha o botão pressionado para registrar",
              style: TextStyle(fontSize: 13, color: GridColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // === MARCAÇÕES DO DIA
  Widget _buildMarcacoesCard() {
    return Card(
      color: GridColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.schedule, color: GridColors.primary),
                SizedBox(width: 8),
                Text(
                  "Marcações de Hoje",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: GridColors.textPrimary,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Column(
              children: marcacoes
                  .map(
                    (m) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTimeBadge(Icons.login, m['entrada'], true),
                          const Icon(Icons.swap_horiz,
                              color: GridColors.textSecondary),
                          _buildTimeBadge(Icons.logout, m['saida'], false),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            _buildInfoRow("Horas trabalhadas hoje", horasTrabalhadas),
            _buildInfoRow("Intervalos", intervalo),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeBadge(IconData icon, String time, bool start) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: start
            ? GridColors.success.withOpacity(0.15)
            : GridColors.error.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon,
              color: start ? GridColors.success : GridColors.error, size: 18),
          const SizedBox(width: 6),
          Text(
            time,
            style: TextStyle(
              color: start ? GridColors.success : GridColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: GridColors.textSecondary)),
          Text(value,
              style: const TextStyle(
                  color: GridColors.textPrimary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // === BOTÕES ADICIONAIS
  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.edit_calendar, color: Colors.white),
          label: const Text("Solicitar Ajuste de Ponto"),
          style: ElevatedButton.styleFrom(
            backgroundColor: GridColors.primary,
            minimumSize: const Size(double.infinity, 52),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
          label: const Text("Visualizar Batidas em PDF"),
          style: ElevatedButton.styleFrom(
            backgroundColor: GridColors.buttonBackground,
            minimumSize: const Size(double.infinity, 52),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.timelapse, color: Colors.white),
          label: const Text("Saldo do Banco de Horas"),
          style: ElevatedButton.styleFrom(
            backgroundColor: GridColors.success,
            minimumSize: const Size(double.infinity, 52),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  // === SEÇÃO DE HUMOR (opcional)
  Widget _buildHumorSection() {
    final icons = [
      Icons.sentiment_very_satisfied,
      Icons.sentiment_satisfied,
      Icons.sentiment_neutral,
      Icons.sentiment_dissatisfied,
      Icons.sentiment_very_dissatisfied,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Como está seu humor hoje?",
          style: TextStyle(
            color: GridColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: icons
              .map(
                (icon) => IconButton(
                  icon: Icon(icon, size: 34, color: GridColors.primary),
                  onPressed: () {},
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
