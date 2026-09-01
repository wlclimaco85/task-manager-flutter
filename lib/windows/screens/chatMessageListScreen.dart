import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../models/chamado_model.dart';
import '../../../utils/api_links.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/tenant_context.dart';
import '../../../widgets/chat/chat_list_logic.dart';
import '../../../widgets/chat/chat_support_ui.dart';
import '../../services/chat_caller.dart';
import '../../../windows/screens/chatMenssageScreen.dart';

class WindowsChatListScreen extends StatefulWidget {
  final String userName;

  /// Fix (card #473): quando informado (ex.: navegação a partir da tela de
  /// detalhe do chamado), abre direto nesta conversa em vez da lista vazia,
  /// sem precisar passar pelo diálogo de seleção de setor.
  final String? initialChatId;
  final String? initialSector;

  const WindowsChatListScreen({
    super.key,
    required this.userName,
    this.initialChatId,
    this.initialSector,
  });

  @override
  State<WindowsChatListScreen> createState() => _WindowsChatListScreenState();
}

class Chat {
  final String chatId;
  final String sector;
  final String lastMessage;
  final DateTime timestamp;
  final String status;

  Chat({
    required this.chatId,
    required this.sector,
    required this.lastMessage,
    required this.timestamp,
    required this.status,
  });
}

class _WindowsChatListScreenState extends State<WindowsChatListScreen> {
  final List<Chat> _chats = [];
  final List<Map<String, dynamic>> _setores = [];
  bool _isLoading = false;
  Chat? _selectedChat;
  // Fix card #444: filtro Abertos/Finalizados (antes nao existia nenhum
  // filtro nem status real vindo do backend).
  bool _mostrarFinalizados = false;

  static const List<String> _fallbackSectors = [
    'Financeiro',
    'Departamento Pessoal',
    'Fiscal',
  ];

  // Pedido explicito do usuario: a conversa/notificacao tem que "ficar
  // disponivel" pra todos os usuarios do setor -- o WebSocket so' entrega em
  // tempo real pra quem esta com uma conversa aberta (ver
  // ChatWebSocketHandler); quem esta parado na LISTA (sem nenhuma conversa
  // selecionada) nao tem nenhum socket ativo. Poll periodico e' a rede de
  // seguranca pra essa tela sempre refletir o backend, mesmo sem WS ou push.
  static const Duration _pollInterval = Duration(seconds: 15);
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (!_isLoading && _selectedChat == null) {
        _loadChats();
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([_loadSetores(), _loadChats()]);
      // Fix (card #473): se veio de navegação com uma conversa específica
      // (ex.: botão "Abrir Chat" na tela do chamado), seleciona direto --
      // não precisa existir na lista ainda (pode ser a primeira mensagem).
      if (widget.initialChatId != null && mounted) {
        setState(() {
          _selectedChat = _chats.firstWhere(
            (c) => c.chatId == widget.initialChatId,
            orElse: () => Chat(
              chatId: widget.initialChatId!,
              sector: widget.initialSector ?? 'Atendimento',
              lastMessage: '',
              timestamp: DateTime.now(),
              status: 'Ativo',
            ),
          );
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSetores() async {
    try {
      final itens = await Chamado.loadSetores();
      if (!mounted) return;
      setState(() {
        _setores
          ..clear()
          ..addAll(itens);
      });
    } catch (_) {}
  }

  Future<void> _loadChats() async {
    try {
      final data = await ChatCaller().fetchChats(context);
      final chats = buildChatListItemsFromMessages(data)
          .map(
            (item) => Chat(
              chatId: item.chatId,
              sector: item.sector,
              lastMessage: item.lastMessage,
              timestamp: item.timestamp,
              status: item.status,
            ),
          )
          .toList();

      if (!mounted) return;
      setState(() {
        _chats
          ..clear()
          ..addAll(chats);
        if (_selectedChat != null &&
            !_chats.any((chat) => chat.chatId == _selectedChat!.chatId)) {
          _selectedChat = null;
        }
      });
    } catch (e) {
      _showSnack('Erro ao carregar chats: $e', error: true);
    }
  }

  List<Chat> get _filteredChats => _chats
      .where((c) => (c.status == 'Finalizado') == _mostrarFinalizados)
      .toList();

  List<String> get _sectorLabels {
    return sectorLabelsFromCadastro(_setores, fallback: _fallbackSectors);
  }

  void _startNewChat(String sector) {
    setState(() {
      _selectedChat = Chat(
        chatId: '0',
        sector: sector,
        lastMessage: '',
        timestamp: DateTime.now(),
        status: 'Ativo',
      );
    });
  }

  Future<void> _showSectorSelectionDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: GridColors.card,
          title: const Text('Novo atendimento'),
          content: SizedBox(
            width: 420,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _sectorLabels.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final sector = _sectorLabels[index];
                return ListTile(
                  leading: const Icon(Icons.support_agent,
                      color: GridColors.primary),
                  title: Text(sector),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    _startNewChat(sector);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showChatActions(BuildContext context, Chat chat) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: const Text('Visualizar'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedChat = chat);
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle_outline,
                    color: GridColors.success),
                title: const Text('Finalizar'),
                onTap: () {
                  Navigator.pop(context);
                  _finalizeChat(chat);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: GridColors.error),
                title: const Text('Excluir'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteChat(chat);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _finalizeChat(Chat chat) async {
    if (chat.chatId.isEmpty || chat.chatId == '0') {
      _showSnack('Envie ao menos uma mensagem antes de finalizar.',
          error: true);
      return;
    }
    try {
      // Fix card #444: usava ApiLinks.chatFinalize (PUT /api/chat/{id} sem
      // corpo, id Integer de mensagem) -- mesmo bug ja corrigido no card
      // #430 dentro da tela de conversa, mas nao replicado aqui na lista.
      final url =
          TenantContext.applyToUrl(ApiLinks.chatFinalizarConversa(chat.chatId));
      final response =
          await http.put(Uri.parse(url), headers: TenantContext.headers);
      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          final index = _chats.indexWhere((item) => item.chatId == chat.chatId);
          if (index >= 0) {
            _chats[index] = Chat(
              chatId: chat.chatId,
              sector: chat.sector,
              lastMessage: chat.lastMessage,
              timestamp: chat.timestamp,
              status: 'Finalizado',
            );
          }
        });
        _showSnack('Chat finalizado com sucesso');
      } else {
        _showSnack('Erro ao finalizar (${response.statusCode})', error: true);
      }
    } catch (e) {
      _showSnack('Erro ao finalizar: $e', error: true);
    }
  }

  Future<void> _deleteChat(Chat chat) async {
    try {
      final url = TenantContext.applyToUrl(ApiLinks.chatDelete(chat.chatId));
      final response =
          await http.delete(Uri.parse(url), headers: TenantContext.headers);
      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          _chats.removeWhere((item) => item.chatId == chat.chatId);
          if (_selectedChat?.chatId == chat.chatId) _selectedChat = null;
        });
        _showSnack('Chat excluído com sucesso');
      } else {
        _showSnack('Erro ao excluir (${response.statusCode})', error: true);
      }
    } catch (e) {
      _showSnack('Erro ao excluir: $e', error: true);
    }
  }

  void _showSnack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error ? GridColors.error : GridColors.success,
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ChatSupportPalette.page,
      child: Row(
        children: [
          SizedBox(
            width: 360,
            child: _buildSidebar(),
          ),
          const VerticalDivider(width: 1, color: GridColors.divider),
          Expanded(
            child: _selectedChat == null
                ? ChatEmptyState(
                    title: 'Atendimento',
                    message:
                        'Escolha uma conversa ou abra um novo atendimento por setor.',
                    onStart: _showSectorSelectionDialog,
                  )
                : WindowsChatMessageScreen(
                    key: ValueKey(
                        '${_selectedChat!.chatId}-${_selectedChat!.sector}'),
                    sector: _selectedChat!.sector,
                    userName: widget.userName,
                    chatId: _selectedChat!.chatId,
                    onMessagePersisted: _upsertChatFromMessage,
                    // Fix card #444: ao finalizar dentro da conversa, volta
                    // para a lista de atendimentos.
                    onFinalized: () {
                      setState(() => _selectedChat = null);
                      _loadChats();
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return DecoratedBox(
      decoration: const BoxDecoration(color: GridColors.card),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline,
                    color: GridColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Atendimento',
                        style: TextStyle(
                          color: GridColors.textSecondary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${_filteredChats.length} conversas',
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.55),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Atualizar',
                  onPressed: _isLoading ? null : _bootstrap,
                  icon: const Icon(Icons.refresh),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: GridColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: _showSectorSelectionDialog,
                  child: const Icon(Icons.add_comment_outlined, size: 18),
                ),
              ],
            ),
          ),
          // Fix card #444: filtro Abertos/Finalizados (antes toda conversa
          // aparecia junta, sem forma de ver/reabrir uma ja finalizada).
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: _FiltroChip(
                    label: 'Abertos',
                    selected: !_mostrarFinalizados,
                    onTap: () => setState(() => _mostrarFinalizados = false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FiltroChip(
                    label: 'Finalizados',
                    selected: _mostrarFinalizados,
                    onTap: () => setState(() => _mostrarFinalizados = true),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_isLoading)
            const LinearProgressIndicator(color: GridColors.primary),
          Expanded(
            child: _filteredChats.isEmpty && !_isLoading
                ? ChatEmptyState(
                    title: _mostrarFinalizados
                        ? 'Nenhum chat finalizado'
                        : 'Nenhum chat iniciado',
                    message: _mostrarFinalizados
                        ? 'Conversas finalizadas aparecem aqui.'
                        : 'Abra um atendimento para falar com o setor responsavel.',
                    onStart:
                        _mostrarFinalizados ? null : _showSectorSelectionDialog,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filteredChats.length,
                    itemBuilder: (context, index) {
                      final chat = _filteredChats[index];
                      final chamadoId = extrairChamadoIdDoChatId(chat.chatId);
                      return ChatListTileCard(
                        title: chamadoId != null
                            ? 'Chamado #$chamadoId · ${chat.sector}'
                            : chat.sector,
                        subtitle: chat.lastMessage,
                        time: DateFormat('HH:mm').format(chat.timestamp),
                        status: chat.status,
                        selected: _selectedChat?.chatId == chat.chatId,
                        onTap: () => setState(() => _selectedChat = chat),
                        onMore: () => _showChatActions(context, chat),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _upsertChatFromMessage(dynamic message) {
    final chatId = (message.chatId ?? '').toString();
    if (chatId.isEmpty || chatId == '0') return;
    final sector =
        (message.sector ?? _selectedChat?.sector ?? 'Atendimento').toString();
    final lastMessage = ((message.text ?? '').toString().isNotEmpty
            ? message.text
            : message.content)
        .toString();
    final timestamp = DateTime.tryParse(
            (message.uploadDate ?? message.timestamp ?? '').toString()) ??
        DateTime.now();
    final status = chatStatusLabel(message.status?.toString());
    setState(() {
      final chat = Chat(
        chatId: chatId,
        sector: sector,
        lastMessage: lastMessage,
        timestamp: timestamp,
        status: status,
      );
      final index = _chats.indexWhere((item) => item.chatId == chatId);
      if (index >= 0) {
        _chats[index] = chat;
      } else {
        _chats.insert(0, chat);
      }
      if (_selectedChat?.chatId == '0' || _selectedChat?.chatId == chatId) {
        _selectedChat = chat;
      }
    });
  }
}

/// Fix card #444: chip de filtro Abertos/Finalizados na lista de atendimento.
class _FiltroChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FiltroChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? GridColors.primary : GridColors.card,
          border: Border.all(
            color: selected ? GridColors.primary : GridColors.divider,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : GridColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
