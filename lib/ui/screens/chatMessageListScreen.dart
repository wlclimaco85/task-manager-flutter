import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_manager_flutter/ui/screens/chatMenssageScreen.dart';
import 'package:task_manager_flutter/data/services/chat_caller.dart';

class ChatListScreen extends StatefulWidget {
  final String userName;

  const ChatListScreen({super.key, required this.userName});

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
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

class _ChatListScreenState extends State<ChatListScreen> {
  List<Chat> _chats = [];
  bool _isLoading = false;
  final List<String> _availableSectors = [
    'Financeiro',
    'Departamento Pessoal',
    'Fiscal'
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
            .map((msg) => Chat(
                  chatId: msg.chatId ?? '0', // Use o ID do chat do modelo
                  sector: msg.sector ?? 'Setor Desconhecido',
                  lastMessage: msg.text ?? 'Sem mensagem',
                  timestamp:
                      DateTime.tryParse(msg.uploadDate ?? '') ?? DateTime.now(),
                  status: 'Ativo', // Defina o status apropriado aqui
                ))
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar chats: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startNewChat(String sector) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatMessageScreen(
          sector: sector,
          userName: widget.userName,
          chatId: '0', // Novo chat, ID inicial 0
        ),
      ),
    );
  }

  void _showSectorSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Selecionar Setor'),
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
                leading: Icon(Icons.visibility),
                title: Text('Visualizar Chat'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatMessageScreen(
                        sector: chat.sector,
                        userName: widget.userName,
                        chatId: chat.chatId, // Passando o ID do chat existente
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text('Finalizar Chat'),
                onTap: () {
                  Navigator.pop(context);
                  _finalizeChat(chat);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Excluir Chat'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteChat(chat);
                },
              ),
              ListTile(
                leading: Icon(Icons.cancel),
                title: Text('Cancelar'),
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
        title: Text('Finalizar Chat'),
        content: Text('Deseja finalizar o chat com ${chat.sector}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
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
                SnackBar(content: Text('Chat finalizado com sucesso')),
              );
            },
            child: Text('Confirmar'),
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
        title: Text('Excluir Chat'),
        content: Text('Deseja excluir o chat com ${chat.sector}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              // Lógica para excluir o chat
              setState(() {
                _chats.removeWhere((c) => c.sector == chat.sector);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Chat excluído com sucesso')),
              );
            },
            child: Text('Excluir'),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Meus Chats'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _chats.isEmpty
              ? Center(
                  child: Text('Nenhum chat iniciado'),
                )
              : ListView.separated(
                  itemCount: _chats.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Colors.grey[300],
                  ),
                  itemBuilder: (context, index) {
                    final chat = _chats[index];
                    return Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1.0,
                          ),
                        ),
                      ),
                      child: ListTile(
                        title: Text(chat.sector),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chat.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(chat.status)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _getStatusColor(chat.status),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    chat.status,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getStatusColor(chat.status),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat('HH:mm').format(chat.timestamp),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.more_vert),
                              onPressed: () => _showChatActions(context, chat),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatMessageScreen(
                                sector: chat.sector,
                                userName: widget.userName,
                                chatId: chat
                                    .chatId, // Passando o ID do chat existente
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showSectorSelectionDialog,
        child: Icon(Icons.chat),
        tooltip: 'Novo Chat',
      ),
    );
  }
}
