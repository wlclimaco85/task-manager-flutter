import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/customization/generic_grid_card.dart';
import 'package:task_manager_flutter/data/models/chamado_model.dart';
import 'package:task_manager_flutter/data/services/login_caller.dart';
import 'package:task_manager_flutter/data/services/chamado_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/utils/utils.dart';

// ✅ TELA PRINCIPAL
class ChamadoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const ChamadoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GenericMobileGridScreen<Chamado>(
        title: "Gerenciamento de Chamados",
        fetchEndpoint: ApiLinks.allChamados,
        createEndpoint: ApiLinks.createChamado,
        updateEndpoint: ApiLinks.updateChamado(":id"),
        deleteEndpoint: ApiLinks.deleteChamado(":id"),
        fromJson: (json) => Chamado.fromJson(Map<String, dynamic>.from(json)),
        toJson: (obj) => obj.toJson(),
        hasPermission: hasPermission,
        fieldConfigs: Chamado.fieldConfigs,
        idFieldName: 'id',
        enableSearch: true,
        useUserBannerAppBar: true,
        storageKey: 'chamados_grid',
        paginationConfig: const PaginationConfig(
          defaultRowsPerPage: 10,
          availableRowsPerPage: [10, 25, 50],
        ),

        // Dados adicionais de formulário (create/update)
        dynamicAdditionalFormData: (item) {
          if (item == null) {
            // CREATE
            return {
              'usuarioAberturaId': pegarUsuarioLogado(),
            };
          } else {
            // UPDATE
            return {
              'usuarioAberturaId': pegarUsuarioLogado(),
            };
          }
        },

        // ✅ Botões extras no rodapé vermelho do card (verde, só ícone + tooltip)
        customActions: () => [
          CustomAction<Chamado>(
            icon: Icons.play_circle_fill_rounded,
            label: 'Pegar Chamado',
            onPressed: (context, chamado) => _pegarChamado(context, chamado),
          ),
          CustomAction<Chamado>(
            icon: Icons.swap_horiz_rounded,
            label: 'Transferir Chamado',
            onPressed: (context, chamado) =>
                _transferirChamado(context, chamado),
          ),
          CustomAction<Chamado>(
            icon: Icons.assignment_ind_rounded,
            label: 'Atribuir Chamado',
            onPressed: (context, chamado) =>
                AtribuirChamadoDialog.show(context, chamado),
          ),
          CustomAction<Chamado>(
            icon: Icons.check_circle_rounded,
            label: 'Fechar Chamado',
            onPressed: (context, chamado) => _fecharChamado(context, chamado),
          ),
          CustomAction<Chamado>(
            icon: Icons.history_rounded,
            label: 'Ver Histórico',
            onPressed: (context, chamado) =>
                HistoricoChamadoDialog.show(context, chamado.id ?? 0),
          ),
        ],
      ),
    );
  }

  // ===========================
  // 🔹 PEGAR CHAMADO
  // ===========================
  static void _pegarChamado(BuildContext context, Chamado chamado) {
    final colors = CustomColors();
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pegar Chamado'),
        content: Text('Confirma assumir o chamado #${chamado.id}?'),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: colors.getCancelButtonColor(),
              foregroundColor: colors.getButtonTextColor(),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.getConfirmButtonColor(),
              foregroundColor: colors.getButtonTextColor(),
            ),
            onPressed: () async {
              Navigator.pop(context);
              final success = await ChamadoCaller().pegarChamado(chamado.id!);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(success
                    ? 'Chamado #${chamado.id} assumido com sucesso!'
                    : 'Falha ao assumir o chamado #${chamado.id}'),
                backgroundColor: success
                    ? colors.getShowSnackBarSuccess()
                    : colors.getShowSnackBarError(),
              ));
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  // ===========================
  // 🔹 TRANSFERIR CHAMADO
  // ===========================
  static void _transferirChamado(BuildContext context, Chamado chamado) async {
    final colors = CustomColors();
    final _formKey = GlobalKey<FormState>();
    int? _usuarioId;
    bool _isLoading = true;
    List<Map<String, dynamic>> _usuarios = [];

    try {
      _usuarios = await LoginCaller().fetchUsuariosEmpresa(chamado.empresa?.id);
    } catch (_) {}
    _isLoading = false;

    showGeneralDialog(
      context: context,
      barrierLabel: "Transferir Chamado",
      barrierDismissible: true,
      barrierColor: Colors.black38,
      transitionDuration: const Duration(milliseconds: 220),
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
                backgroundColor: GridColors.dialogBackground.withOpacity(0.95),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: const Text(
                  'Transferir Chamado',
                  style: TextStyle(
                    color: GridColors.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: _isLoading
                    ? const SizedBox(
                        height: 64,
                        child: Center(child: CircularProgressIndicator()))
                    : Form(
                        key: _formKey,
                        child: DropdownButtonFormField<int>(
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Transferir para',
                            prefixIcon: const Icon(Icons.swap_horiz_rounded,
                                color: GridColors.inputBorder),
                            filled: true,
                            fillColor: GridColors.inputBackground,
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: colors.getBorderInput(), width: 1.2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: colors.getBorderInput(), width: 1.5),
                            ),
                          ),
                          items: _usuarios
                              .map((u) => DropdownMenuItem<int>(
                                    value: u['value'],
                                    child: Text(u['label'],
                                        overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (v) => _usuarioId = v,
                          validator: (v) =>
                              v == null ? 'Selecione o usuário' : null,
                        ),
                      ),
                actions: [
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: colors.getCancelButtonColor(),
                      foregroundColor: colors.getButtonTextColor(),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.getConfirmButtonColor(),
                      foregroundColor: colors.getButtonTextColor(),
                    ),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        Navigator.pop(context);
                        final success = await ChamadoCaller()
                            .transferirChamado(chamado.id!, _usuarioId!);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(success
                              ? 'Chamado #${chamado.id} transferido para o usuário $_usuarioId'
                              : 'Falha ao transferir o chamado #${chamado.id}'),
                          backgroundColor: success
                              ? colors.getShowSnackBarSuccess()
                              : colors.getShowSnackBarError(),
                        ));
                      }
                    },
                    child: const Text('Confirmar'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ===========================
  // 🔹 FECHAR CHAMADO
  // ===========================
  static void _fecharChamado(BuildContext context, Chamado chamado) {
    final colors = CustomColors();
    final _formKey = GlobalKey<FormState>();
    final motivoCtrl = TextEditingController();

    showGeneralDialog(
      context: context,
      barrierLabel: "Fechar Chamado",
      barrierDismissible: true,
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 220),
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
                backgroundColor: GridColors.dialogBackground.withOpacity(0.95),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: const Text(
                  'Fechar Chamado',
                  style: TextStyle(
                    color: GridColors.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: motivoCtrl,
                    decoration: InputDecoration(
                      labelText: 'Motivo do Fechamento',
                      prefixIcon: const Icon(Icons.description_outlined,
                          color: GridColors.inputBorder),
                      filled: true,
                      fillColor: GridColors.inputBackground,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: colors.getBorderInput(), width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: colors.getBorderInput(), width: 1.5),
                      ),
                    ),
                    maxLines: 3,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Informe o motivo'
                        : null,
                  ),
                ),
                actions: [
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: colors.getCancelButtonColor(),
                      foregroundColor: colors.getButtonTextColor(),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.getConfirmButtonColor(),
                      foregroundColor: colors.getButtonTextColor(),
                    ),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        Navigator.pop(context);
                        final success = await ChamadoCaller()
                            .fecharChamado(chamado.id!, motivoCtrl.text.trim());
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(success
                              ? 'Chamado #${chamado.id} fechado com sucesso!'
                              : 'Falha ao fechar o chamado #${chamado.id}'),
                          backgroundColor: success
                              ? colors.getShowSnackBarSuccess()
                              : colors.getShowSnackBarError(),
                        ));
                      }
                    },
                    child: const Text('Confirmar'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// =======================================================
// POPUP: ATRIBUIR CHAMADO (com lista de logins da empresa)
// =======================================================
class AtribuirChamadoDialog {
  static Future<Object?> show(BuildContext context, Chamado chamado) async {
    final colors = CustomColors();
    final _formKey = GlobalKey<FormState>();
    int? _usuarioId;
    bool _isLoading = true;
    List<Map<String, dynamic>> _usuarios = [];

    // Carrega usuários da empresa
    try {
      _usuarios = await LoginCaller().fetchUsuariosEmpresa(chamado.empresa?.id);
    } catch (e) {
      debugPrint('Erro ao carregar usuários: $e');
    }
    _isLoading = false;

    return showGeneralDialog(
      context: context,
      barrierLabel: "Atribuir Chamado",
      barrierDismissible: true,
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 240),
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
                backgroundColor: GridColors.dialogBackground.withOpacity(0.95),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: const Text(
                  "Atribuir Chamado",
                  style: TextStyle(
                    color: GridColors.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                content: _isLoading
                    ? const SizedBox(
                        height: 64,
                        child: Center(child: CircularProgressIndicator()))
                    : Form(
                        key: _formKey,
                        child: DropdownButtonFormField<int>(
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Usuário Responsável',
                            prefixIcon: const Icon(Icons.person_add_alt_1,
                                color: GridColors.inputBorder),
                            filled: true,
                            fillColor: GridColors.inputBackground,
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: colors.getBorderInput(),
                                width: 1.2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: colors.getBorderInput(),
                                width: 1.5,
                              ),
                            ),
                          ),
                          items: _usuarios
                              .map((u) => DropdownMenuItem<int>(
                                    value: u['value'],
                                    child: Text(
                                      u['label'],
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                          onChanged: (v) => _usuarioId = v,
                          validator: (v) =>
                              v == null ? 'Selecione o usuário' : null,
                        ),
                      ),
                actions: [
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: colors.getCancelButtonColor(),
                      foregroundColor: colors.getButtonTextColor(),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancelar"),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.getConfirmButtonColor(),
                      foregroundColor: colors.getButtonTextColor(),
                    ),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        Navigator.pop(context);
                        final success = await ChamadoCaller()
                            .atribuirChamado(chamado.id!, _usuarioId!);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(success
                              ? "Chamado #${chamado.id} atribuído ao usuário $_usuarioId"
                              : "Falha ao atribuir o chamado #${chamado.id}"),
                          backgroundColor: success
                              ? colors.getShowSnackBarSuccess()
                              : colors.getShowSnackBarError(),
                        ));
                      }
                    },
                    child: const Text("Confirmar"),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// =======================================================
// POPUP: HISTÓRICO DO CHAMADO (dados reais do backend)
// =======================================================
class HistoricoChamadoDialog {
  static Future<Object?> show(BuildContext context, int chamadoId) async {
    final colors = CustomColors();
    bool _isLoading = true;
    List<Map<String, dynamic>> _historico = [];
    String? _erro;

    try {
      _historico = await ChamadoCaller().getHistoricoChamado(chamadoId);
    } catch (e) {
      _erro = 'Erro ao buscar histórico: $e';
    }

    _isLoading = false;

    return showGeneralDialog(
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
                    borderRadius: BorderRadius.circular(16)),
                title: Row(
                  children: [
                    const Icon(Icons.history_rounded,
                        color: GridColors.secondary),
                    const SizedBox(width: 8),
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
                  height: MediaQuery.of(context).size.height * 0.55,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _erro != null
                          ? Center(
                              child: Text(
                                _erro!,
                                style: const TextStyle(color: GridColors.error),
                              ),
                            )
                          : _historico.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Nenhum registro encontrado',
                                    style: TextStyle(
                                      color: GridColors.secondaryDark,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: _historico.length,
                                  separatorBuilder: (_, __) => const Divider(),
                                  itemBuilder: (ctx, i) {
                                    final item = _historico[i];
                                    final usuario =
                                        item['usuario']?['nome'] ?? '---';
                                    final dataHora =
                                        item['dataHora'] ?? item['data'] ?? '';
                                    final status = item['status'] ?? '';
                                    final obs = item['observacao'] ?? '';

                                    return ListTile(
                                      leading: const Icon(Icons.timeline,
                                          color: GridColors.primary),
                                      title: Text(
                                        status.isEmpty
                                            ? 'Alteração registrada'
                                            : status,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (obs.isNotEmpty)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 4),
                                              child: Text(
                                                obs,
                                                style: const TextStyle(
                                                  fontStyle: FontStyle.italic,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Por $usuario em $dataHora',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
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
}
