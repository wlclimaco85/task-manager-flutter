import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import './chatMenssageScreen.dart';
import '../../services/chat_caller.dart';
import '../../constants/custom_colors.dart';

class WebChatListScreen extends StatefulWidget {
  final String userName;

  const WebChatListScreen({super.key, required this.userName});

  @override
  _WebChatListScreenState createState() => _WebChatListScreenState();
}

class Chat {
  final String chatId; // Adicionando o ID do chat
  final String sector;
  final String lastMessage;
  final DateTime timestamp;
  final String status; // Novo campo para status

  Chat({
    required this.chatId,
    required this.sector,
    required this.lastMessage,
    required this.timestamp,
    required this.status,
  });
}

class _WebChatListScreenState extends State<WebChatListScreen> {
  List<Chat> _chats = [];
  bool _isLoading = false;
  Chat? _selectedChat; // chat aberto no painel direito

  final List<String> _availableSectors = [
    'Financeiro',
    'Departamento Pessoal',
    'Fiscal',
  ];

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final data = await ChatCaller().fetchChats(context);
      setState(() {
        _chats = data
            .map(
              (msg) => Chat(
                chatId: msg.chatId ?? '0', // Use o ID do chat do modelo
                sector: msg.sector ?? 'Setor Desconhecido',
                lastMessage: msg.text ?? 'Sem mensagem',
                timestamp:
                    DateTime.tryParse(msg.uploadDate ?? '') ?? DateTime.now(),
                status: 'Ativo', // Defina o status apropriado aqui
              ),
            )
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar chats: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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

  void _showSectorSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecionar Setor'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _availableSectors.length,
              itemBuilder: (BuildContext context, int index) {
                final sector = _availableSectors[index];
                return ListTile(
                  title: Text(sector),
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
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('Visualizar Chat'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedChat = chat;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Finalizar Chat'),
                onTap: () {
                  Navigator.pop(context);
                  _finalizeChat(chat);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Excluir Chat'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteChat(chat);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancelar'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _finalizeChat(Chat chat) {
    // Implementar lógica para finalizar o chat
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar Chat'),
        content: Text('Deseja finalizar o chat com ${chat.sector}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              // Lógica para finalizar o chat
              setState(() {
                // Atualizar status do chat para "Finalizado"
                _chats = _chats.map((c) {
                  if (c.sector == chat.sector) {
                    return Chat(
                      chatId: c.chatId,
                      sector: c.sector,
                      lastMessage: c.lastMessage,
                      timestamp: c.timestamp,
                      status: 'Finalizado',
                    );
                  }
                  return c;
                }).toList();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat finalizado com sucesso')),
              );
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _deleteChat(Chat chat) {
    // Implementar lógica para excluir o chat
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Chat'),
        content: Text('Deseja excluir o chat com ${chat.sector}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              // Lógica para excluir o chat
              setState(() {
                _chats.removeWhere((c) => c.sector == chat.sector);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat excluído com sucesso')),
              );
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Ativo':
        return Colors.green;
      case 'Finalizado':
        return Colors.blue;
      case 'Pendente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Painel esquerdo: lista de chats
        Container(
          width: 320,
          decoration: BoxDecoration(
            color: GridColors.card,
            border: Border(
              right: BorderSide(color: GridColors.inputBorder, width: 1),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: GridColors.primary,
                child: Row(
                  children: [
                    const Icon(Icons.chat, color: GridColors.textPrimary, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Meus Chats',
                        style: TextStyle(
                          color: GridColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_comment, color: GridColors.textPrimary, size: 20),
                      tooltip: 'Novo Chat',
                      onPressed: _showSectorSelectionDialog,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              // Lista
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: GridColors.primary))
                    : _chats.isEmpty
                        ? Center(
                            child: Text(
                              'Nenhum chat iniciado',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _chats.length,
                            separatorBuilder: (_, __) => Divider(height: 1, color: GridColors.divider),
                            itemBuilder: (context, index) {
                              final chat = _chats[index];
                              final isSelected = _selectedChat?.chatId == chat.chatId;
                              return InkWell(
                                onTap: () => setState(() {
                                  _selectedChat = chat;
                                }),
                                onLongPress: () => _showChatActions(context, chat),
                                child: Container(
                                  color: isSelected ? GridColors.primary.withOpacity(0.1) : null,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: GridColors.primary,
                                        radius: 20,
                                        child: Text(
                                          chat.sector.isNotEmpty ? chat.sector[0] : '?',
                                          style: const TextStyle(color: GridColors.textPrimary, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              chat.sector,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: isSelected ? GridColors.primary : GridColors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              chat.lastMessage,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(chat.status).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: _getStatusColor(chat.status), width: 1),
                                              ),
                                              child: Text(
                                                chat.status,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: _getStatusColor(chat.status),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            DateFormat('HH:mm').format(chat.timestamp),
                                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.more_vert, size: 18),
                                            onPressed: () => _showChatActions(context, chat),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
        // Painel direito: conversa
        Expanded(
          child: _selectedChat == null
              ? Container(
                  color: GridColors.filterBackground,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Selecione um chat ou inicie uma nova conversa',
                          style: TextStyle(color: Colors.grey[500], fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: GridColors.primary),
                          icon: const Icon(Icons.add_comment, color: GridColors.textPrimary),
                          label: const Text('Novo Chat', style: TextStyle(color: GridColors.textPrimary)),
                          onPressed: _showSectorSelectionDialog,
                        ),
                      ],
                    ),
                  ),
                )
              : WebChatMessageScreen(
                  key: ValueKey(_selectedChat!.chatId),
                  sector: _selectedChat!.sector,
                  userName: widget.userName,
                  chatId: _selectedChat!.chatId,
                ),
        ),
      ],
    );
  }
}
