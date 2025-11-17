import 'dart:async';

import 'package:downloads_path_provider_28/downloads_path_provider_28.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/constants/custom_colors.dart';
import '../../data/controller/ponto_controller.dart';
import 'pdf_preview_dialog.dart';
import 'ponto_controller.dart';

class PontoScreen extends ConsumerStatefulWidget {
  /// parceiroId vindo da sessão/login (você já tem em cache)
  final int parceiroId;

  const PontoScreen({
    super.key,
    required this.parceiroId,
  });

  @override
  ConsumerState<PontoScreen> createState() => _PontoScreenState();
}

class _PontoScreenState extends ConsumerState<PontoScreen> {
  late DateTime now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    now = DateTime.now();

    // Atualiza o relógio a cada segundo
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _mostrarSnack(String msg) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pontoState = ref.watch(pontoControllerProvider(widget.parceiroId));
    final controller =
        ref.read(pontoControllerProvider(widget.parceiroId).notifier);

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
      body: RefreshIndicator(
        onRefresh: () => controller.carregarDiaAtual(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildClockCard(
                registering: pontoState.registering,
                onRegistrar: () async {
                  final ok = await controller.registrarPontoAutomatico();
                  if (ok) {
                    await _mostrarSnack('Ponto registrado com sucesso!');
                  } else {
                    await _mostrarSnack(
                      pontoState.error ?? 'Erro ao registrar ponto',
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
              _buildMarcacoesCard(
                marcacoes: controller.marcacoesAgrupadas,
                horasTrabalhadas: controller.horasTrabalhadasFormatada,
                intervalo: controller.intervaloFormatado,
                loading: pontoState.loading,
              ),
              const SizedBox(height: 20),
              _buildActionButtons(
                context,
                onPdf: () async {
                  final bytes = await controller.gerarRelatorioPdf();
                  if (bytes == null) {
                    await _mostrarSnack(
                        'Não foi possível gerar o PDF de batidas');
                    return;
                  }

                  if (!mounted) return;
                  showDialog(
                    context: context,
                    builder: (_) => PdfPreviewDialog(bytes: bytes),
                  );
                },
                onBancoHoras: () async {
                  final valor = await controller.carregarBancoHorasMesAtual();
                  if (valor == null) {
                    await _mostrarSnack(
                      pontoState.error ?? 'Erro ao carregar banco de horas',
                    );
                    return;
                  }

                  if (!mounted) return;
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Banco de Horas'),
                      content: Text(
                        'Saldo: ${valor.toStringAsFixed(2)} horas',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
              _buildHumorSection(),
            ],
          ),
        ),
      ),
    );
  }

  // === RELÓGIO E BOTÃO DE REGISTRAR
  Widget _buildClockCard({
    required bool registering,
    required VoidCallback onRegistrar,
  }) {
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
              onPressed: registering ? null : onRegistrar,
              icon: const Icon(Icons.fingerprint, color: Colors.white),
              label: Text(
                registering ? 'Registrando...' : 'Registrar Ponto',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Clique para registrar sua entrada/saída automaticamente',
              style: TextStyle(
                fontSize: 13,
                color: GridColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === MARCAÇÕES DO DIA
  Widget _buildMarcacoesCard({
    required List<Map<String, String>> marcacoes,
    required String horasTrabalhadas,
    required String intervalo,
    required bool loading,
  }) {
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
                  'Marcações de Hoje',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: GridColors.textPrimary,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            if (loading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (marcacoes.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Nenhuma marcação registrada hoje.',
                  style: TextStyle(color: GridColors.textSecondary),
                ),
              )
            else
              Column(
                children: marcacoes
                    .map(
                      (m) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildTimeBadge(
                              Icons.login,
                              m['entrada'] ?? '--:--',
                              true,
                            ),
                            const Icon(
                              Icons.swap_horiz,
                              color: GridColors.textSecondary,
                            ),
                            _buildTimeBadge(
                              Icons.logout,
                              m['saida'] ?? '--:--',
                              false,
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 16),
            _buildInfoRow('Horas trabalhadas hoje', horasTrabalhadas),
            _buildInfoRow('Intervalos', intervalo),
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
          Icon(
            icon,
            color: start ? GridColors.success : GridColors.error,
            size: 18,
          ),
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
          Text(
            label,
            style: const TextStyle(color: GridColors.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(
              color: GridColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // === BOTÕES ADICIONAIS
  Widget _buildActionButtons(
    BuildContext context, {
    required VoidCallback onPdf,
    required VoidCallback onBancoHoras,
  }) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () {
            // aqui você pode abrir uma tela para solicitar ajuste de ponto
          },
          icon: const Icon(Icons.edit_calendar, color: Colors.white),
          label: const Text('Solicitar Ajuste de Ponto'),
          style: ElevatedButton.styleFrom(
            backgroundColor: GridColors.primary,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: onPdf,
          icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
          label: const Text('Visualizar Batidas em PDF'),
          style: ElevatedButton.styleFrom(
            backgroundColor: GridColors.buttonBackground,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: onBancoHoras,
          icon: const Icon(Icons.timelapse, color: Colors.white),
          label: const Text('Saldo do Banco de Horas'),
          style: ElevatedButton.styleFrom(
            backgroundColor: GridColors.success,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  // === SEÇÃO DE HUMOR
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
          'Como está seu humor hoje?',
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
                  onPressed: () {
                    // aqui você pode enviar o humor pro backend se quiser
                  },
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
