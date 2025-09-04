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
  final String sector;
  final String lastMessage;
  final DateTime timestamp;

  Chat({
    required this.sector,
    required this.lastMessage,
    required this.timestamp,
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
                  sector: msg.sector ?? 'Setor Desconhecido',
                  lastMessage: msg.text ?? 'Sem mensagem',
                  timestamp:
                      DateTime.tryParse(msg.uploadDate ?? '') ?? DateTime.now(),
                ))
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar produtos: $e')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meus Chats'),
      ),
      body: _chats.isEmpty
          ? Center(
              child: Text('Nenhum chat iniciado'),
            )
          : ListView.builder(
              itemCount: _chats.length,
              itemBuilder: (context, index) {
                final chat = _chats[index];
                return ListTile(
                  title: Text(chat.sector),
                  subtitle: Text(chat.lastMessage),
                  trailing: Text(
                    DateFormat('HH:mm').format(chat.timestamp),
                    style: TextStyle(color: Colors.grey),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatMessageScreen(
                          sector: chat.sector,
                          userName: widget.userName,
                        ),
                      ),
                    );
                  },
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
