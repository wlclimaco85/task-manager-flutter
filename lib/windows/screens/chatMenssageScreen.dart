import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../models/auth_utility.dart';
import '../../../models/chat_model.dart';
import '../../../utils/api_links.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/tenant_context.dart';
import '../../../widgets/chat/chat_support_ui.dart';
import '../../services/ai_assistant_service.dart';
import '../../services/chat_caller.dart';

class WindowsChatMessageScreen extends StatefulWidget {
  final String sector;
  final String userName;
  final String chatId;

  const WindowsChatMessageScreen({
    super.key,
    required this.sector,
    required this.userName,
    required this.chatId,
  });

  @override
  State<WindowsChatMessageScreen> createState() =>
      _WindowsChatMessageScreenState();
}

class _WindowsChatMessageScreenState extends State<WindowsChatMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  WebSocketChannel? _channel;
  bool _isLoading = false;

  String get _loggedUserName =>
      AuthUtility.userInfo?.login?.nome ?? widget.userName;
  String get _loggedUserEmail =>
      AuthUtility.userInfo?.login?.email ?? widget.userName;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
    _loadInitialMessages();
  }

  void _connectWebSocket() {
    try {
      _channel?.sink.close();
      _channel = IOWebSocketChannel.connect(
        TenantContext.applyToUrl(
            ApiLinks.chatStart(_loggedUserEmail, widget.sector)),
      );

      _channel!.stream.listen(
        (message) {
          final decoded = json.decode(message) as Map<String, dynamic>;
          setState(() => _messages.add(ChatMessage.fromJson(decoded)));
          _scrollToBottom();
        },
        onError: (error) {
          L.d('WebSocket error: $error');
          Future.delayed(const Duration(seconds: 3), _connectWebSocket);
        },
        onDone: () {
          L.d('WebSocket closed');
          Future.delayed(const Duration(seconds: 3), _connectWebSocket);
        },
      );
    } catch (e) {
      L.d('Connection error: $e');
    }
  }

  Future<void> _loadInitialMessages() async {
    setState(() => _isLoading = true);
    try {
      final data = await ChatCaller().fetchChatsById(context, widget.chatId);
      setState(() {
        _messages
          ..clear()
          ..addAll(data.map(_normalizeMessage));
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      _showSnack('Erro ao carregar mensagens: $e', error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  ChatMessage _normalizeMessage(ChatMessage msg) {
    return ChatMessage(
      sender: msg.sender,
      content: msg.content.isNotEmpty ? msg.content : (msg.text ?? ''),
      type: msg.type.isNotEmpty ? msg.type : 'text',
      timestamp: msg.timestamp ?? msg.uploadDate,
      empId: msg.empId,
      codApp: msg.codApp,
      codUsuOrig: msg.codUsuOrig,
      codUsuDest: msg.codUsuDest,
      sector: msg.sector,
      chatId: msg.chatId,
      uploadDate: msg.uploadDate,
      text: msg.text,
      fileId: msg.fileId,
      fileName: msg.fileName,
      fileUrl: msg.fileUrl,
    );
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _channel == null) return;

    _channel!.sink.add(json.encode({
      'sender': _loggedUserName,
      'senderName': _loggedUserName,
      'senderEmail': _loggedUserEmail,
      'content': content,
      'sector': widget.sector,
      'type': 'text',
      'timestamp': DateTime.now().toIso8601String(),
      'chatId': widget.chatId,
      if (TenantContext.empresaId != null) 'empId': TenantContext.empresaId,
      if (TenantContext.aplicativoId != null)
        'codApp': TenantContext.aplicativoId,
    }));

    _messageController.clear();
  }

  Future<void> _uploadAndSendFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (result == null || _channel == null) return;

      final file = result.files.first;
      Uint8List? fileBytes = file.bytes;
      if (fileBytes == null && file.path != null) {
        fileBytes = await File(file.path!).readAsBytes();
      }
      if (fileBytes == null) {
        _showSnack('Nao foi possivel ler o arquivo selecionado', error: true);
        return;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(TenantContext.applyToUrl(ApiLinks.uploadFile)),
      );
      request.headers.addAll(TenantContext.headers);
      request.files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: file.name),
      );
      request.fields.addAll({
        'user': _loggedUserEmail,
        'userEmail': _loggedUserEmail,
        'userName': _loggedUserName,
        'sector': widget.sector,
        'chatId': widget.chatId,
        if (TenantContext.empresaId != null)
          'empId': TenantContext.empresaId.toString(),
        if (TenantContext.parceiroId != null)
          'parceiroId': TenantContext.parceiroId.toString(),
      });

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      if (response.statusCode != 200) {
        _showSnack('Falha no upload (${response.statusCode})', error: true);
        return;
      }

      final jsonResponse = json.decode(responseBody) as Map<String, dynamic>;
      final rawId = jsonResponse['fileId'] ?? jsonResponse['data']?['fileId'];
      final fileId =
          rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
      final fileUrl =
          (jsonResponse['fileUrl'] ?? jsonResponse['data']?['fileUrl'])
              ?.toString();
      if (fileId == null) {
        _showSnack('Upload concluido, mas o arquivo voltou sem identificador',
            error: true);
        return;
      }

      _channel!.sink.add(json.encode({
        'sender': _loggedUserName,
        'senderName': _loggedUserName,
        'senderEmail': _loggedUserEmail,
        'content': 'Arquivo: ${file.name}',
        'sector': widget.sector,
        'type': 'file',
        'fileName': file.name,
        'fileId': fileId,
        'fileUrl': fileUrl ?? ApiLinks.publicFileUrl(fileId),
        'timestamp': DateTime.now().toIso8601String(),
        'chatId': widget.chatId,
        if (TenantContext.empresaId != null) 'empId': TenantContext.empresaId,
      }));
    } catch (e) {
      _showSnack('Erro no upload: $e', error: true);
    }
  }

  void _createTicket() {
    if (_channel == null) return;
    _channel!.sink.add(json.encode({
      'sender': _loggedUserName,
      'senderName': _loggedUserName,
      'senderEmail': _loggedUserEmail,
      'content': 'Solicitacao de abertura de chamado',
      'sector': widget.sector,
      'type': 'ticket',
      'timestamp': DateTime.now().toIso8601String(),
      'chatId': widget.chatId,
      if (TenantContext.empresaId != null) 'empId': TenantContext.empresaId,
    }));
    _showSnack('Solicitacao de chamado enviada');
  }

  Future<void> _correctDraft() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    try {
      final result = await AiAssistantService().correctMessage(text: text);
      _messageController.text = result.correctedText;
      _messageController.selection = TextSelection.collapsed(
        offset: _messageController.text.length,
      );
    } catch (e) {
      _showSnack('Erro ao corrigir mensagem: $e', error: true);
    }
  }

  Future<void> _summarizeChat() async {
    try {
      final result = await AiAssistantService().summarizeChat(
        chatId: widget.chatId,
        messages: _messages
            .map((m) => m.content.isNotEmpty ? m.content : (m.text ?? ''))
            .where((m) => m.trim().isNotEmpty)
            .toList(),
      );
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Resumo do atendimento'),
          content: Text(
            '${result.summary}\n\nPrioridade: ${result.priority}\nSentimento: ${result.sentiment}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showSnack('Erro ao resumir atendimento: $e', error: true);
    }
  }

  Future<void> _downloadFile(int fileId, String fileName) async {
    try {
      final response = await http.get(
        Uri.parse(TenantContext.applyToUrl(ApiLinks.getFile(fileId))),
        headers: TenantContext.headers,
      );
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        _showSnack('Arquivo salvo em: ${file.path}');
      } else {
        _showSnack('Falha ao baixar o arquivo', error: true);
      }
    } catch (e) {
      _showSnack('Erro ao baixar o arquivo: $e', error: true);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  bool _isMine(ChatMessage message) {
    return message.sender == _loggedUserName ||
        message.sender == _loggedUserEmail ||
        message.codUsuOrig == TenantContext.userId;
  }

  String _displayName(ChatMessage message) {
    if (message.sender.trim().isNotEmpty) return message.sender.trim();
    return _isMine(message) ? _loggedUserName : widget.sector;
  }

  String _formatTime(String? timestamp) {
    final time = DateTime.tryParse(timestamp ?? '');
    if (time == null) return '';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
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
  void dispose() {
    _scrollController.dispose();
    _channel?.sink.close();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ChatConversationHeader(
          sector: widget.sector,
          userName: _loggedUserEmail,
        ),
        if (_isLoading)
          const LinearProgressIndicator(color: GridColors.primary),
        Expanded(
          child: ColoredBox(
            color: ChatSupportPalette.page,
            child: _messages.isEmpty && !_isLoading
                ? ChatEmptyState(
                    title: 'Conversa vazia',
                    message:
                        'Envie a primeira mensagem para iniciar o atendimento deste setor.',
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = _isMine(message);
                      return ChatMessageBubble(
                        message: message,
                        isMe: isMe,
                        displayName: _displayName(message),
                        time: _formatTime(
                            message.timestamp ?? message.uploadDate),
                        onOpenFile: message.fileId == null
                            ? null
                            : () => _downloadFile(
                                  message.fileId!,
                                  message.fileName ?? 'arquivo',
                                ),
                      );
                    },
                  ),
          ),
        ),
        ChatComposer(
          controller: _messageController,
          onAttach: _uploadAndSendFile,
          onTicket: _createTicket,
          onSend: _sendMessage,
          onCorrect: _correctDraft,
          onSummarize: _summarizeChat,
        ),
      ],
    );
  }
}
