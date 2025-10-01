import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'dart:typed_data';
import 'package:task_manager_flutter/data/models/chat_model.dart';
import 'package:task_manager_flutter/data/services/chat_caller.dart';

class ChatMessageScreen extends StatefulWidget {
  final String sector;
  final String userName;
  final String chatId; // Adicionando o ID do chat

  const ChatMessageScreen({
    super.key,
    required this.sector,
    required this.userName,
    required this.chatId,
  });

  @override
  _ChatMessageScreenState createState() => _ChatMessageScreenState();
}

class _ChatMessageScreenState extends State<ChatMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  List<ChatMessage> _messages = [];
  late WebSocketChannel _channel;
  String _authToken = '${AuthUtility.userInfo?.token}';
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
    _loadInitialMessages();
  }

  void _connectWebSocket() {
    try {
      _channel = IOWebSocketChannel.connect(
        ApiLinks.chatStart('Washington', widget.sector),
      );

      _channel.stream.listen(
        (message) {
          final messageData = json.decode(message);
          setState(() {
            _messages.add(ChatMessage.fromJson(messageData));
            _scrollToBottom();
          });
        },
        onError: (error) {
          print('WebSocket error: $error');
          Future.delayed(Duration(seconds: 3), _connectWebSocket);
        },
        onDone: () {
          print('WebSocket closed');
          _connectWebSocket();
        },
      );
    } catch (e) {
      print('Connection error: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _loadInitialMessages() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final data = await ChatCaller().fetchChatsById(context, widget.chatId);
      setState(() {
        _messages = data
            .map((msg) => ChatMessage(
                  sender: msg.sender ?? '',
                  content: msg.text ?? '',
                  type: 'text', // Ajuste conforme necessário
                  timestamp: msg.uploadDate,
                  empId: msg.empId,
                  codApp: msg.codApp,
                  codUsuOrig: msg.codUsuOrig,
                  codUsuDest: msg.codUsuDest,
                  sector: msg.sector,
                  chatId: msg.chatId,
                  uploadDate: msg.uploadDate,
                  text: msg.text,
                  // fileId e fileName serão null a menos que a mensagem seja do tipo arquivo
                ))
            .toList();
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
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

  Future<void> _finalizeChat(Chat chat) async {
    try {
      final response = await http.put(
        Uri.parse(ApiLinks.chatStartfetch(chat.chatId)),
        headers: {'Authorization': 'Bearer $_authToken'},
        body: json.encode({'status': 'Finalizado'}),
      );
      if (response.statusCode == 200) {
        setState(() {
          // Atualizar localmente o status do chat
          // _chats = _chats.map((c) {
          //   if (c.chatId == chat.chatId) {
          //     return Chat(
          //       chatId: c.chatId,
          //       sector: c.sector,
          //       lastMessage: c.lastMessage,
          //       timestamp: c.timestamp,
          //       status: 'Finalizado',
          //     );
          //   }
          //   return c;
          // }).toList();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chat finalizado com sucesso')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao finalizar o chat')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao finalizar o chat: $e')),
      );
    }
  }

  Future<void> _deleteChat(Chat chat) async {
    try {
      final response = await http.delete(
        Uri.parse(
            'http://192.168.114.1:8088/boletobancos/api/chat/${chat.chatId}'),
        headers: {'Authorization': 'Bearer $_authToken'},
      );
      if (response.statusCode == 200) {
        setState(() {
          //_chats.removeWhere((c) => c.chatId == chat.chatId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chat excluído com sucesso')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao excluir o chat')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir o chat: $e')),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Ativo':
        return Colors.green;
      case 'Finalizado':
        return Colors.red; // Alterado para vermelho
      case 'Pendente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _sendMessage() async {
    final String content = _messageController.text;
    if (content.isEmpty) return;

    _channel.sink.add(json.encode({
      'sender': widget.userName,
      'content': content,
      'sector': widget.sector,
      'type': 'text',
      'timestamp': DateTime.now().toIso8601String(),
    }));

    _messageController.clear();
  }

  Future<void> _uploadAndSendFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        Uint8List? fileBytes = file.bytes;
        String fileName = file.name;

        if (fileBytes == null && file.path != null) {
          File ioFile = File(file.path!);
          fileBytes = await ioFile.readAsBytes();
        }

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('http://192.168.114.1:8088/boletobancos/api/files/upload'),
        );

        request.files.add(http.MultipartFile.fromBytes(
          'file',
          fileBytes!,
          filename: fileName,
        ));

        request.fields['user'] = widget.userName;
        request.fields['sector'] = widget.sector;

        if (_authToken.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $_authToken';
        }

        var response = await request.send();

        if (response.statusCode == 200) {
          String responseBody = await response.stream.bytesToString();
          Map<String, dynamic> jsonResponse = json.decode(responseBody);

          // Converta dynamic para int? de forma segura
          int? fileId;
          if (jsonResponse['fileId'] != null) {
            if (jsonResponse['fileId'] is int) {
              fileId = jsonResponse['fileId'];
            } else if (jsonResponse['fileId'] is String) {
              fileId = int.tryParse(jsonResponse['fileId']);
            }
          }

          if (fileId != null) {
            _channel.sink.add(json.encode({
              'sender': widget.userName,
              'content': 'Arquivo anexado: $fileName',
              'sector': widget.sector,
              'type': 'file',
              'fileName': fileName,
              'fileId': fileId, // Agora é um int
              'timestamp': DateTime.now().toIso8601String(),
            }));
          } else {
            print(
                'ID do arquivo não encontrado ou inválido na resposta do servidor');
          }
        } else {
          print('Upload failed with status: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error uploading file: $e');
    }
  }

  void _createTicket() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Abrir Chamado'),
        content: Text('Deseja abrir um chamado para este assunto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              _channel.sink.add(json.encode({
                'sender': widget.userName,
                'content': 'Solicitação de abertura de chamado',
                'sector': widget.sector,
                'type': 'ticket',
                'timestamp': DateTime.now().toIso8601String(),
              }));
              Navigator.pop(context);
            },
            child: Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _channel.sink.close();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chat - ${widget.sector}'),
            Text(
              widget.userName,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {
              // Adicionar menu de opções
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(_messages[index]);
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: Border(top: BorderSide(color: Colors.grey)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.attach_file),
                  onPressed: _uploadAndSendFile,
                ),
                IconButton(
                  icon: Icon(Icons.support_agent),
                  onPressed: _createTicket,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Digite sua mensagem...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    bool isMe = message.sender == widget.userName;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe)
            CircleAvatar(
              backgroundColor: Colors.grey,
              child: Text(
                message.sender.isNotEmpty ? message.sender[0] : '?',
                style: TextStyle(color: Colors.white),
              ),
            ),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isMe ? Color(0xFFDCF8C6) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 1,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      message.sender,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                  if (message.type == 'text')
                    Text(
                      message.content,
                      style: const TextStyle(fontSize: 16),
                    ),
                  if (message.type == 'file')
                    InkWell(
                      onTap: () =>
                          _downloadFile(message.fileId!, message.fileName!),
                      child: Row(
                        children: [
                          const Icon(Icons.attach_file, size: 16),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              message.fileName!,
                              style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (message.type == 'ticket')
                    const Text(
                      '📋 Solicitação de chamado criada',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style:
                            const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe)
            CircleAvatar(
              backgroundColor: Colors.green,
              child: Text(
                message.sender[0],
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    final time = DateTime.parse(timestamp);
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _downloadFile(int fileId, String fileName) async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.114.1:8088/boletobancos/api/files/$fileId'),
        headers: {'Authorization': 'Bearer $_authToken'},
      );

      if (response.statusCode == 200) {
        // Salvar o arquivo localmente
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Arquivo salvo em: ${file.path}'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha ao baixar o arquivo'),
          ),
        );
      }
    } catch (e) {
      print('Error downloading file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao baixar o arquivo: $e'),
        ),
      );
    }
  }
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
