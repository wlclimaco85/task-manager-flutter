import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/customization/generic_grid_card.dart';
import 'package:task_manager_flutter/data/services/chamado_caller.dart';

class HistoricoChamadoDialog {
  static Future<void> show(BuildContext context, int chamadoId) async {
    final colors = CustomColors();
    bool isLoading = true;
    List<Map<String, dynamic>> historico = [];
    String? erro;

    try {
      historico = await ChamadoCaller().getHistoricoChamado(chamadoId);
    } catch (e) {
      erro = 'Erro ao buscar histórico: $e';
    }

    isLoading = false;

    showGeneralDialog(
      context: context,
      barrierLabel: "Histórico do Chamado",
      barrierDismissible: true,
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (_, anim, __, child) {
        final offset =
            Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
        );

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: offset,
              child: AlertDialog(
                backgroundColor: GridColors.dialogBackground.withOpacity(0.97),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                titlePadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                contentPadding: const EdgeInsets.all(16),
                title: Row(
                  children: [
                    const Icon(Icons.timeline_rounded,
                        color: GridColors.primary, size: 26),
                    const SizedBox(width: 10),
                    Text(
                      "Histórico do Chamado #$chamadoId",
                      style: const TextStyle(
                        color: GridColors.secondaryDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : erro != null
                          ? Center(
                              child: Text(
                                erro,
                                style: const TextStyle(color: GridColors.error),
                              ),
                            )
                          : historico.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Nenhum evento registrado',
                                    style: TextStyle(
                                      color: GridColors.secondaryDark,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: historico.length,
                                  itemBuilder: (ctx, i) {
                                    final item = historico[i];
                                    final usuarioOrigem =
                                        item['usuarioOrigem'] ?? '---';
                                    final usuarioDestino =
                                        item['usuarioDestino'];
                                    final acao =
                                        (item['acao'] ?? 'Ação desconhecida')
                                            .toString()
                                            .toUpperCase();
                                    final observacao = item['observacao'] ?? '';
                                    final dataStr = item['dataEvento'];
                                    String dataFormatada = '';

                                    if (dataStr != null &&
                                        dataStr.toString().isNotEmpty) {
                                      try {
                                        final dt = DateTime.parse(dataStr);
                                        dataFormatada =
                                            DateFormat('dd/MM/yyyy HH:mm')
                                                .format(dt);
                                      } catch (_) {
                                        dataFormatada = dataStr.toString();
                                      }
                                    }

                                    return TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0, end: 1),
                                      duration: Duration(
                                          milliseconds: 200 + (i * 80)),
                                      curve: Curves.easeOutBack,
                                      builder: (context, scale, child) {
                                        return Transform.scale(
                                          scale: scale,
                                          alignment: Alignment.centerLeft,
                                          child: _timelineItem(
                                            context,
                                            colors,
                                            dataFormatada,
                                            usuarioOrigem,
                                            usuarioDestino,
                                            observacao,
                                            acao,
                                            i == historico.length - 1,
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                ),
                actions: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Fechar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.getCancelButtonColor(),
                      foregroundColor: colors.getButtonTextColor(),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _timelineItem(
    BuildContext context,
    CustomColors colors,
    String data,
    String usuarioOrigem,
    String? usuarioDestino,
    String observacao,
    String acao,
    bool isLast,
  ) {
    return Stack(
      children: [
        // Linha vertical da timeline
        Positioned(
          left: 24,
          top: 0,
          bottom: isLast ? 12 : 0,
          child: Container(
            width: 2,
            color: GridColors.primary.withOpacity(0.4),
          ),
        ),

        // Conteúdo principal
        Padding(
          padding: const EdgeInsets.only(left: 56, right: 8, bottom: 16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  GridColors.primary.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ação
                Text(
                  acao,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: GridColors.primary,
                  ),
                ),

                const SizedBox(height: 4),

                // Data
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 14, color: Colors.black54),
                    const SizedBox(width: 6),
                    Text(
                      data,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Usuário origem e destino
                Text(
                  usuarioDestino != null
                      ? "De $usuarioOrigem → Para $usuarioDestino"
                      : "Por $usuarioOrigem",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: GridColors.secondaryDark,
                  ),
                ),

                if (observacao.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    observacao,
                    style: const TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Colors.black87,
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),

        // Ícone da timeline
        const Positioned(
          left: 16,
          top: 12,
          child: CircleAvatar(
            radius: 10,
            backgroundColor: GridColors.primary,
            child: Icon(Icons.history_edu, color: Colors.white, size: 12),
          ),
        ),
      ],
    );
  }
}
