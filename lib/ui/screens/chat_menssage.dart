import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'dart:typed_data';

class ChatMessageScreen extends StatefulWidget {
  final String sector;
  final String userName;

  const ChatMessageScreen({
    super.key,
    required this.sector,
    required this.userName,
  });

  @override
  _ChatMessageScreenState createState() => _ChatMessageScreenState();
}

class _ChatMessageScreenState extends State<ChatMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  late WebSocketChannel _channel;
  String _authToken = '${AuthUtility.userInfo.token}';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
    _loadInitialMessages();
  }

  void _connectWebSocket() {
    try {
      _channel = IOWebSocketChannel.connect(
        'ws://192.168.114.1:8088/boletobancos/ws-chat?user=${widget.userName}&sector=${widget.sector}',
      );

      _channel.stream.listen(
        (message) {
          final messageData = json.decode(message);
          setState(() {
            _messages.add(ChatMessage.fromJson(messageData));
            // Rolar para a última mensagem
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

  Future<void> _loadInitialMessages() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://192.168.114.1:8088/boletobancos/api/chat/messages?user=${widget.userName}&sector=${widget.sector}'),
        headers: {'Authorization': 'Bearer $_authToken'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> messageList = json.decode(response.body);
        setState(() {
          _messages.addAll(
            messageList.map((json) => ChatMessage.fromJson(json)).toList(),
          );
          // Rolar para a última mensagem após carregar as iniciais
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _scrollToBottom());
        });
      }
    } catch (e) {
      print('Error loading messages: $e');
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
          _channel.sink.add(json.encode({
            'sender': widget.userName,
            'content': 'Arquivo anexado',
            'sector': widget.sector,
            'type': 'file',
            'fileName': fileName,
            'fileId': await response.stream.bytesToString(),
            'timestamp': DateTime.now().toIso8601String(),
          }));
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
                message.sender[0],
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                  if (message.type == 'text')
                    Text(
                      message.content,
                      style: TextStyle(fontSize: 16),
                    ),
                  if (message.type == 'file')
                    InkWell(
                      onTap: () =>
                          _downloadFile(message.fileId!, message.fileName!),
                      child: Row(
                        children: [
                          Icon(Icons.attach_file, size: 16),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              message.fileName!,
                              style: TextStyle(
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
                    Text(
                      '📋 Solicitação de chamado criada',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(fontSize: 10, color: Colors.grey),
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
                style: TextStyle(color: Colors.white),
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
    // Implementar download do arquivo
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Download'),
        content: Text('Iniciando download de $fileName'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String sender;
  final String content;
  final String type;
  final int? fileId;
  final String? fileName;
  final String? timestamp;

  ChatMessage({
    required this.sender,
    required this.content,
    required this.type,
    this.fileId,
    this.fileName,
    this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      sender: json['sender'],
      content: json['content'],
      type: json['type'] ?? 'text',
      fileId: _parseFileId(json['fileId']),
      fileName: json['fileName'],
      timestamp: json['timestamp'],
    );
  }

  static int? _parseFileId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}
