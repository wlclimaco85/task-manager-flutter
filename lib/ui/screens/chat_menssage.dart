import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/cotacao_model.dart';
import 'package:task_manager_flutter/data/services/cotacao_caller.dart';
import 'package:task_manager_flutter/ui/widgets/user_banners.dart';
import 'package:task_manager_flutter/ui/screens/update_profile.dart';
import 'package:task_manager_flutter/data/models/dollar_model.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class ChatMessageScreen extends StatefulWidget {
  const ChatMessageScreen({super.key});

  @override
  _ChatMessageScreenState createState() => _ChatMessageScreenState();
}

class _ChatMessageScreenState extends State<ChatMessageScreen> {
  final TextEditingController _senderController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  late WebSocketChannel _channel;
  String _authToken = ''; // Adicione seu token JWT aqui se necessário
  List<Cotacao> cotacoes = [];
  List<Dollar> dollarCotacoes = [];
  bool isLoading = true;

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
    final String sender = _senderController.text;
    final String content = _messageController.text;

    if (sender.isEmpty || content.isEmpty) return;

    // Se não há arquivo selecionado, envia apenas a mensagem de texto
    _channel.sink.add(json.encode({
      'sender': sender,
      'content': content,
    }));

    _messageController.clear();
  }

  Future<void> _uploadAndSendFile() async {
    try {
      // Seleciona o arquivo
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        Uint8List? fileBytes = file.bytes;
        String fileName = file.name;

        if (fileBytes == null) {
          // Se não temos os bytes, tenta ler do path
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

        // Adiciona o arquivo
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ));

        // Adiciona headers de autenticação se necessário
        if (_authToken.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $_authToken';
        }

        // Envia o arquivo
        var response = await request.send();
        var responseData = await response.stream.toBytes();
        var responseString = String.fromCharCodes(responseData);
        var jsonResponse = json.decode(responseString);

        if (response.statusCode == 200) {
          // Se o upload foi bem-sucedido, envia a mensagem com o arquivo
          _channel.sink.add(json.encode({
            'sender': _senderController.text,
            'content': _messageController.text,
            'fileId': jsonResponse['fileId'],
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

  @override
  void dispose() {
    _channel.sink.close();
    _senderController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void refresh() {
    _fetchCotacoes();
    _fetchCotacoesDollares();
  }

  void _fetchCotacoes() {
    setState(() {
      isLoading = true;
    });
    CotacaoCaller().fetchCotacoes().then((data) {
      setState(() {
        cotacoes = data;
        isLoading = false;
      });
    });
  }

  void _fetchCotacoesDollares() {
    setState(() {
      isLoading = true;
    });
    CotacaoCaller().fetchCotacoesDollar().then((data) {
      setState(() {
        dollarCotacoes = data;
        isLoading = false;
      });
    });
  }

  Widget _buildTable(String title, List<TableRow> rows,
      {String? footer, String? source}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // CABEÇALHO AZUL DA TABELA
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                color: CustomColors().getDarkBlue(),
                child: Text(
                  title, // Texto variável pelo parâmetro
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // TABELA
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: CustomColors().getDarkGreenBorder(),
                    width: 1,
                  ),
                ),
                child: Table(
                  border: TableBorder.all(
                    color: CustomColors().getDarkGreenBorder(),
                    width: 1,
                  ),
                  columnWidths: const {
                    0: FlexColumnWidth(),
                    1: FlexColumnWidth(),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(
                        color: CustomColors().getHeaderTable(),
                      ),
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "Data",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "Valor (R\$)",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ...rows,
                  ],
                ),
              ),
              // FOOTER E FONTE
              if (footer != null) ...[
                const SizedBox(height: 8),
                Text(
                  footer,
                  style: TextStyle(
                    fontSize: 12,
                    color: CustomColors().getTextColorDesc(),
                  ),
                ),
              ],
              if (source != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "Fonte: $source",
                      style: TextStyle(
                        fontSize: 12,
                        color: CustomColors().getTextColorDesc(),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  List<TableRow> _buildCotacoesRows(List<Cotacao> cotacoes) {
    return [
      TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Data',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: CustomColors().getTextColor()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Valor (R\$)',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: CustomColors().getTextColor()),
            ),
          ),
        ],
      ),
      ...cotacoes.map((cotacao) {
        return TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '${cotacao.dtCotacao?.day}/${cotacao.dtCotacao?.month}/${cotacao.dtCotacao?.year}',
                style: TextStyle(color: CustomColors().getTextColor()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'R\$ ${cotacao.valor?.toStringAsFixed(2)}',
                style: TextStyle(color: CustomColors().getTextColor()),
              ),
            ),
          ],
        );
      }),
    ];
  }

  List<TableRow> _buildDollarRows(List<Dollar> cotacoes) {
    return [
      TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Data',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: CustomColors().getTextColor()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Valor (R\$)',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: CustomColors().getTextColor()),
            ),
          ),
        ],
      ),
      ...cotacoes.map((cotacao) {
        return TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '${cotacao.date?.day}/${cotacao.date?.month}/${cotacao.date?.year}',
                style: TextStyle(color: CustomColors().getTextColor()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'R\$ ${cotacao.rate?.toStringAsFixed(2)}',
                style: TextStyle(color: CustomColors().getTextColor()),
              ),
            ),
          ],
        );
      }),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat com Upload de Arquivos'),
      ),
      body: Column(
        children: [
          // Área de entrada de mensagens
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _senderController,
                  decoration: const InputDecoration(
                    labelText: 'Seu nome',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    labelText: 'Sua mensagem',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _sendMessage,
                        child: const Text('Enviar Mensagem'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _uploadAndSendFile,
                        child: const Text('Enviar Arquivo'),
                      ),
                    ),
                  ],
                ),
              ],
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
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.sender,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(message.content),
            if (message.fileName != null) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _downloadFile(message.fileId!, message.fileName!),
                child: Text(
                  message.fileName!,
                  style: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _downloadFile(int fileId, String fileName) async {
    try {
      final response = await http.get(
        Uri.parse('http://your-server-address/api/files/$fileId'),
        headers: {'Authorization': 'Bearer $_authToken'},
      );

      if (response.statusCode == 200) {
        // Para arquivos reais, você usaria um gerenciador de downloads
        // Aqui estamos apenas mostrando um snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download do arquivo $fileName iniciado'),
          ),
        );
      }
    } catch (e) {
      print('Error downloading file: $e');
    }
  }
}

class ChatMessage {
  final String sender;
  final String content;
  final int? fileId;
  final String? fileName;

  ChatMessage({
    required this.sender,
    required this.content,
    this.fileId,
    this.fileName,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      sender: json['sender'],
      content: json['content'],
      fileId: json['fileId'],
      fileName: json['fileName'],
    );
  }
}
