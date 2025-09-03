import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class ChatMessageScreen extends StatefulWidget {
  const ChatMessageScreen({super.key});

  @override
  _ChatMessageScreenState createState() => _ChatMessageScreenState();
}

class _ChatMessageScreenState extends State<ChatMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  late WebSocketChannel _channel;
  String _authToken = ''; // Adicione seu token JWT aqui se necessário
  String? _selectedSector; // Setor selecionado
  String _currentUser = "Usuário Logado"; // Substitua pelo usuário logado

  // Lista de setores (exemplo)
  final List<String> _sectors = [
    'Financeiro',
    'Suporte Técnico',
    'Vendas',
    'Outro'
  ];

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
    _loadInitialMessages();
  }

  void _connectWebSocket() {
    try {
      _channel = IOWebSocketChannel.connect(
        'ws://192.168.114.1:8088/boletobancos/ws-chat',
      );

      _channel.stream.listen(
        (message) {
          final messageData = json.decode(message);
          setState(() {
            _messages.add(ChatMessage.fromJson(messageData));
          });
        },
        onError: (error) {
          print('WebSocket error: $error');
          // Reconexão automática após 3 segundos
          Future.delayed(Duration(seconds: 3), _connectWebSocket);
        },
        onDone: () {
          print('WebSocket closed');
          // Reconexão se a conexão for fechada
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
        Uri.parse('http://192.168.114.1:8088/boletobancos/api/chat/messages'),
        headers: {'Authorization': 'Bearer $_authToken'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> messageList = json.decode(response.body);
        setState(() {
          _messages.addAll(
            messageList.map((json) => ChatMessage.fromJson(json)).toList(),
          );
        });
      }
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  Future<void> _sendMessage() async {
    final String content = _messageController.text;

    if (content.isEmpty) return;

    // Envia a mensagem com o setor selecionado e o usuário logado
    _channel.sink.add(json.encode({
      'sender': _currentUser,
      'content': content,
      'sector': _selectedSector, // Envia o setor selecionado
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

        if (fileBytes == null) {
          if (file.path != null) {
            File ioFile = File(file.path!);
            fileBytes = await ioFile.readAsBytes();
          } else {
            throw Exception('Não foi possível ler o arquivo');
          }
        }

        // Prepara a requisição de upload
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('http://your-server-address/api/files/upload'),
        );

        request.files.add(http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ));

        if (_authToken.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $_authToken';
        }

        var response = await request.send();
        var responseData = await response.stream.toBytes();
        var responseString = String.fromCharCodes(responseData);
        var jsonResponse = json.decode(responseString);

        if (response.statusCode == 200) {
          _channel.sink.add(json.encode({
            'sender': _currentUser,
            'content': _messageController.text,
            'fileId': jsonResponse['fileId'],
            'fileName': fileName,
            'sector': _selectedSector,
          }));

          _messageController.clear();
        } else {
          print('Upload failed: ${jsonResponse['message']}');
        }
      }
    } catch (e) {
      print('Error uploading file: $e');
    }
  }

  void _openTicket() {
    // Lógica para abrir um chamado
    // Pode ser um diálogo ou navegação para outra tela
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Abrir Chamado'),
        content:
            Text('Funcionalidade de abrir chamado será implementada aqui.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _channel.sink.close();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat com Suporte'),
      ),
      body: Column(
        children: [
          // Dropdown para selecionar o setor
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<String>(
              value: _selectedSector,
              hint: Text('Selecione o setor'),
              items: _sectors.map((String sector) {
                return DropdownMenuItem<String>(
                  value: sector,
                  child: Text(sector),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedSector = newValue;
                });
              },
            ),
          ),
          const Divider(),
          // Área de exibição de mensagens
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(_messages[index]);
              },
            ),
          ),
          // Área de entrada de mensagens
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Botão para anexar arquivo
                IconButton(
                  icon: Icon(Icons.attach_file),
                  onPressed: _uploadAndSendFile,
                ),
                // Campo de texto
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Digite sua mensagem',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                // Botão para enviar mensagem
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
                // Botão para abrir chamado
                IconButton(
                  icon: Icon(Icons.support_agent),
                  onPressed: _openTicket,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    // Verifica se a mensagem é do usuário atual
    bool isMe = message.sender == _currentUser;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) CircleAvatar(child: Text(message.sender[0])),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMe ? Colors.blue[100] : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMe) // Mostra o nome do sender apenas se não for eu
                  Text(
                    message.sender,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                if (!isMe) SizedBox(height: 4),
                Text(message.content),
                if (message.fileName != null) ...[
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: () =>
                        _downloadFile(message.fileId!, message.fileName!),
                    child: Text(
                      message.fileName!,
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isMe) CircleAvatar(child: Text(message.sender[0])),
        ],
      ),
    );
  }

  Future<void> _downloadFile(int fileId, String fileName) async {
    // Implementar download do arquivo
  }
}

class ChatMessage {
  final String sender;
  final String content;
  final int? fileId;
  final String? fileName;
  final String? sector;

  ChatMessage({
    required this.sender,
    required this.content,
    this.fileId,
    this.fileName,
    this.sector,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      sender: json['sender'],
      content: json['content'],
      fileId: json['fileId'],
      fileName: json['fileName'],
      sector: json['sector'],
    );
  }
}
