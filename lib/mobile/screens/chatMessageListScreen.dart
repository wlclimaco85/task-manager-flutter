import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/chamado_model.dart';
import '../../../utils/grid_colors.dart';
import '../../../widgets/chat/chat_support_ui.dart';
import '../../../widgets/user_banners.dart';
import '../../services/chat_caller.dart';
import '../screens/chatMenssageScreen.dart';

class ChatListScreen extends StatefulWidget {
  final String userName;

  const ChatListScreen({super.key, required this.userName});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
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

class _ChatListScreenState extends State<ChatListScreen> {
  final List<Chat> _chats = [];
  final List<Map<String, dynamic>> _setores = [];
  bool _isLoading = false;

  static const List<String> _fallbackSectors = [
    'Financeiro',
    'Departamento Pessoal',
    'Fiscal',
  ];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([_loadSetores(), _loadChats()]);
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
    } catch (e) {
      _showSnack('Erro ao carregar setores: $e', error: true);
    }
  }

  Future<void> _loadChats() async {
    try {
      final data = await ChatCaller().fetchChats(context);
      final chats = data
          .map(
            (msg) => Chat(
              chatId: msg.chatId ?? '0',
              sector: msg.sector ?? 'Setor desconhecido',
              lastMessage: msg.text ?? msg.content,
              timestamp:
                  DateTime.tryParse(msg.uploadDate ?? msg.timestamp ?? '') ??
                      DateTime.now(),
              status: 'Ativo',
            ),
          )
          .toList();

      if (!mounted) return;
      setState(() {
        _chats
          ..clear()
          ..addAll(chats);
      });
    } catch (e) {
      _showSnack('Erro ao carregar chats: $e', error: true);
    }
  }

  List<String> get _sectorLabels {
    final labels = _setores
        .map((item) =>
            (item['label'] ?? item['descricao'] ?? item['nome'] ?? '')
                .toString())
        .where((label) => label.trim().isNotEmpty)
        .toList();
    return labels.isEmpty ? _fallbackSectors : labels;
  }

  void _startNewChat(String sector) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatMessageScreen(
          sector: sector,
          userName: widget.userName,
          chatId: '0',
        ),
      ),
    );
  }

  Future<void> _showSectorSelectionDialog() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 8, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Novo atendimento',
                        style: TextStyle(
                          color: GridColors.textSecondary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fechar',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Flexible(
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
            ],
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
                  _openChat(chat);
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

  void _openChat(Chat chat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatMessageScreen(
          sector: chat.sector,
          userName: widget.userName,
          chatId: chat.chatId,
        ),
      ),
    );
  }

  void _finalizeChat(Chat chat) {
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
  }

  void _deleteChat(Chat chat) {
    setState(() => _chats.removeWhere((item) => item.chatId == chat.chatId));
    _showSnack('Chat excluido com sucesso');
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
    return Scaffold(
      backgroundColor: ChatSupportPalette.page,
      appBar: UserBannerAppBar(
        screenTitle: 'Atendimento',
        onRefresh: _bootstrap,
        isLoading: _isLoading,
        showFilterButton: false,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: GridColors.primary))
          : _chats.isEmpty
              ? ChatEmptyState(
                  title: 'Nenhum chat iniciado',
                  message:
                      'Abra um atendimento para falar com o setor responsavel.',
                  onStart: _showSectorSelectionDialog,
                )
              : RefreshIndicator(
                  color: GridColors.primary,
                  onRefresh: _bootstrap,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(6, 10, 6, 88),
                    itemCount: _chats.length,
                    itemBuilder: (context, index) {
                      final chat = _chats[index];
                      return ChatListTileCard(
                        title: chat.sector,
                        subtitle: chat.lastMessage,
                        time: DateFormat('HH:mm').format(chat.timestamp),
                        status: chat.status,
                        selected: false,
                        onTap: () => _openChat(chat),
                        onMore: () => _showChatActions(context, chat),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showSectorSelectionDialog,
        tooltip: 'Novo atendimento',
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_comment_outlined),
      ),
    );
  }
}
