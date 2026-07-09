import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../models/auth_utility.dart';
import '../../../models/chat_model.dart';
import '../../../utils/api_links.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/tenant_context.dart';
import '../../../widgets/chat/chat_support_ui.dart';
import '../../services/ai_assistant_service.dart';
import '../../services/chat_caller.dart';
import 'ticket_form_bottom_sheet.dart';

class ChatMessageScreen extends StatefulWidget {
  final String sector;
  final String userName;
  final String chatId;

  const ChatMessageScreen({
    super.key,
    required this.sector,
    required this.userName,
    required this.chatId,
  });

  @override
  State<ChatMessageScreen> createState() => _ChatMessageScreenState();
}

class _ChatMessageScreenState extends State<ChatMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  WebSocketChannel? _channel;
  bool _isLoading = false;
  bool _wsConnected = false;
  int _retryCount = 0;
  static const int _maxRetries = 10;
  bool _initDone = false;

  // Fix card #430: widget.chatId chega como '0' (placeholder) quando o chat
  // e novo; o backend so atribui o id real na primeira mensagem, que volta
  // pelo proprio WebSocket. _effectiveChatId comeca igual a widget.chatId e
  // e atualizado assim que uma mensagem com chatId real chega — e ele (nao
  // widget.chatId) que deve ser usado em toda chamada que precise do id
  // (enviar mensagem, upload, finalizar chat).
  late String _effectiveChatId = widget.chatId;

  String get _loggedUserName =>
      AuthUtility.userInfo?.login?.nome ?? widget.userName;
  String get _loggedUserEmail =>
      AuthUtility.userInfo?.login?.email ?? widget.userName;

  @override
  void initState() {
    super.initState();
    _loadInitialMessages().then((_) {
      _initDone = true;
      _connectWebSocket();
    });
  }

  bool _isDuplicate(ChatMessage msg) {
    return msg.chatId != null && _messages.any((m) =>
      m.content == msg.content && m.sender == msg.sender && m.timestamp == msg.timestamp);
  }

  void _adoptRealChatIdIfNeeded(ChatMessage msg) {
    final realId = msg.chatId;
    if (realId != null &&
        realId.isNotEmpty &&
        realId != '0' &&
        realId != _effectiveChatId) {
      setState(() => _effectiveChatId = realId);
    }
  }

  void _connectWebSocket() {
    if (!mounted || _retryCount >= _maxRetries) return;
    try {
      _channel?.sink.close();
      _channel = IOWebSocketChannel.connect(
        TenantContext.applyToUrl(
            ApiLinks.chatStart(_loggedUserEmail, widget.sector)),
      );
      _retryCount = 0;
      setState(() => _wsConnected = true);

      _channel!.stream.listen(
        (message) {
          try {
            final decoded = json.decode(message) as Map<String, dynamic>;
            final msg = ChatMessage.fromJson(decoded);
            _adoptRealChatIdIfNeeded(msg);
            if (!_isDuplicate(msg)) {
              setState(() => _messages.add(msg));
            }
            _scrollToBottom();
          } catch (_) {}
        },
        onError: (error) {
          setState(() => _wsConnected = false);
          _scheduleReconnect();
        },
        onDone: () {
          setState(() => _wsConnected = false);
          _scheduleReconnect();
        },
      );
    } catch (_) {
      setState(() => _wsConnected = false);
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _retryCount++;
    if (!mounted || _retryCount >= _maxRetries) return;
    final delay = Duration(seconds: (_retryCount > 5 ? 30 : 3 * (1 << (_retryCount - 1))).clamp(3, 30));
    Future.delayed(delay, () { if (mounted) _connectWebSocket(); });
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
      'chatId': _effectiveChatId,
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
        'chatId': _effectiveChatId,
        if (TenantContext.empresaId != null)
          'empId': TenantContext.empresaId.toString(),
        if (TenantContext.parceiroId != null)
          'parceiroId': TenantContext.parceiroId.toString(),
        // Fix card #429: FileController.uploadFile exige estes 5 campos
        // (fileName/fileType/diretorio/empresa/parceiro), nenhum era enviado
        // pelo chat -> 400. diretorio:{"id":0} e o mesmo default usado pelo
        // GED (ged_arquivos_screen.dart) quando nenhum diretorio e escolhido.
        'fileName': file.name,
        'fileType': (file.extension ?? '').toLowerCase(),
        'diretorio': '{"id":0}',
        'empresa': '{"id":${TenantContext.empresaId ?? 0}}',
        'parceiro': '{"id":${TenantContext.parceiroId ?? 0}}',
        'modulo': 'chat',
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
        'chatId': _effectiveChatId,
        if (TenantContext.empresaId != null) 'empId': TenantContext.empresaId,
      }));
    } catch (e) {
      _showSnack('Erro no upload: $e', error: true);
    }
  }

  /// Historico da conversa formatado como texto, para pre-preencher a
  /// descricao do chamado (card #432).
  String _buildHistoricoChat() {
    return _messages
        .where((m) => (m.content.isNotEmpty ? m.content : (m.text ?? ''))
            .trim()
            .isNotEmpty)
        .map((m) =>
            '${m.sender}: ${m.content.isNotEmpty ? m.content : (m.text ?? '')}')
        .join('\n');
  }

  /// Imagens anexadas na conversa (mensagens tipo 'file' com extensao de
  /// imagem), para reanexar automaticamente ao chamado (card #432).
  List<Map<String, dynamic>> _buildImagensChat() {
    const extensoesImagem = ['jpg', 'jpeg', 'png'];
    return _messages
        .where((m) =>
            m.type == 'file' &&
            m.fileId != null &&
            extensoesImagem.contains(
                (m.fileName ?? '').split('.').last.toLowerCase()))
        .map((m) => {'fileId': m.fileId, 'fileName': m.fileName})
        .toList();
  }

  Future<void> _createTicket() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        builder: (_, controller) => DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: SingleChildScrollView(
            controller: controller,
            child: TicketFormBottomSheet(
              sectorDescricao: widget.sector,
              initialDescricao: _buildHistoricoChat(),
              anexosChat: _buildImagensChat(),
            ),
          ),
        ),
      ),
    );

    if (result == null || _channel == null || !mounted) return;
    try {
      final id = (result as dynamic).id;
      _channel!.sink.add(json.encode({
        'sender': _loggedUserName,
        'senderName': _loggedUserName,
        'senderEmail': _loggedUserEmail,
        'content': 'Chamado aberto com sucesso (ID $id)',
        'sector': widget.sector,
        'type': 'ticket',
        'ticketId': id,
        'timestamp': DateTime.now().toIso8601String(),
        'chatId': _effectiveChatId,
        if (TenantContext.empresaId != null) 'empId': TenantContext.empresaId,
      }));
    } catch (_) {}
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
        chatId: _effectiveChatId,
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

  Future<void> _openOrDownload(int fileId, String fileName,
      {String? fileUrl}) async {
    if (fileUrl != null && fileUrl.isNotEmpty) {
      final uri = Uri.parse(fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    await _downloadFile(fileId, fileName);
  }

  Future<void> _downloadFile(int fileId, String fileName) async {
    try {
      final response = await http.get(
        Uri.parse(
            TenantContext.applyToUrl(ApiLinks.downloadFile(fileId.toString()))),
        headers: TenantContext.headers,
      );
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        final uri = Uri.file(file.path);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        _showSnack('Arquivo salvo em: ${file.path}');
      } else {
        _showSnack('Falha ao baixar (${response.statusCode})', error: true);
      }
    } catch (e) {
      _showSnack('Erro ao baixar: $e', error: true);
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

  Future<void> _finalizarChat() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finalizar atendimento'),
        content: const Text(
          'Deseja encerrar este atendimento? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: GridColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    if (_effectiveChatId.isEmpty || _effectiveChatId == '0') {
      _showSnack('Envie ao menos uma mensagem antes de finalizar.', error: true);
      return;
    }

    try {
      final url = TenantContext.applyToUrl(
          ApiLinks.chatFinalizarConversa(_effectiveChatId));
      final response = await http.put(
        Uri.parse(url),
        headers: TenantContext.headers,
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 204) {
        _showSnack('Atendimento finalizado com sucesso.');
        Navigator.of(context).pop();
      } else {
        _showSnack(
          'Não foi possível finalizar o atendimento (${response.statusCode}).',
          error: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Erro ao finalizar atendimento: $e', error: true);
    }
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
    return Scaffold(
      backgroundColor: ChatSupportPalette.page,
      body: Column(
        children: [
          ChatConversationHeader(
            sector: widget.sector,
            userName: _loggedUserEmail,
            compact: true,
            onBack: () => Navigator.pop(context),
            onFinalize: _finalizarChat,
          ),
          if (_isLoading)
            const LinearProgressIndicator(color: GridColors.primary),
          Expanded(
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
                      return ChatMessageBubble(
                        message: message,
                        isMe: _isMine(message),
                        displayName: _displayName(message),
                        time: _formatTime(
                            message.timestamp ?? message.uploadDate),
                        onOpenFile: message.fileId == null
                            ? null
                            : () => _openOrDownload(
                                  message.fileId!,
                                  message.fileName ?? 'arquivo',
                                  fileUrl: message.fileUrl,
                                ),
                      );
                    },
                  ),
          ),
          ChatComposer(
            controller: _messageController,
            onAttach: _uploadAndSendFile,
            onTicket: _createTicket,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}
