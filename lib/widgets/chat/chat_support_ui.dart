import 'package:flutter/material.dart';
import '../../models/chat_model.dart';
import '../../utils/grid_colors.dart';

class ChatSupportPalette {
  ChatSupportPalette._();

  static const Color surface = GridColors.card;
  static const Color page = Color(0xFFEAF5EE); // verde institucional suave (GridColors.secondarySoft)
  static const Color subtle = Color(0xFFD4EAD8);
  static const Color outbound = Color(0xFFCDE8D2); // minha mensagem — verde mais vivo
  static const Color inbound = Color(0xFFF9FAFB); // mensagem recebida — off-white
}

class ChatStatusPill extends StatelessWidget {
  final String status;

  const ChatStatusPill({super.key, required this.status});

  Color get _color {
    switch (status) {
      case 'Ativo':
        return GridColors.success;
      case 'Finalizado':
        return GridColors.info;
      case 'Pendente':
        return GridColors.warning;
      default:
        return GridColors.divider;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class ChatListTileCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final String status;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onMore;

  const ChatListTileCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.status,
    required this.selected,
    required this.onTap,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final initial = title.trim().isEmpty ? '?' : title.trim()[0].toUpperCase();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Material(
        color: selected
            ? GridColors.primary.withValues(alpha: 0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? GridColors.primary.withValues(alpha: 0.45)
                    : GridColors.divider.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: GridColors.secondary.withValues(alpha: 0.12),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: GridColors.secondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: GridColors.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            time,
                            style: TextStyle(
                              color: Colors.black.withValues(alpha: 0.48),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle.isEmpty ? 'Sem mensagens ainda' : subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ChatStatusPill(status: status),
                          const Spacer(),
                          SizedBox.square(
                            dimension: 28,
                            child: IconButton(
                              tooltip: 'Mais opcoes',
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.more_horiz, size: 18),
                              color: Colors.grey,
                              onPressed: onMore,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChatEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onStart;

  const ChatEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: GridColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.support_agent,
                color: GridColors.primary,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: GridColors.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.6),
                height: 1.35,
              ),
            ),
            if (onStart != null) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: GridColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: onStart,
                icon: const Icon(Icons.add_comment_outlined, size: 18),
                label: const Text('Novo atendimento'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ChatConversationHeader extends StatelessWidget {
  final String sector;
  final String userName;
  final bool compact;
  final VoidCallback? onBack;
  final VoidCallback? onFinalize;
  final VoidCallback? onTransfer;
  // Card #474 (Fase 3 fila de atendimento): inclui participante adicional.
  final VoidCallback? onAddParticipant;

  const ChatConversationHeader({
    super.key,
    required this.sector,
    required this.userName,
    this.compact = false,
    this.onBack,
    this.onFinalize,
    this.onTransfer,
    this.onAddParticipant,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 18,
        vertical: compact ? 10 : 14,
      ),
      decoration: const BoxDecoration(
        color: GridColors.card,
        border: Border(bottom: BorderSide(color: GridColors.divider)),
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            IconButton(
              tooltip: 'Voltar',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
            ),
            const SizedBox(width: 4),
          ],
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: GridColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.support_agent, color: GridColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sector,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: GridColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.56),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const ChatStatusPill(status: 'Ativo'),
          if (onTransfer != null) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Transferir chat',
              onPressed: onTransfer,
              icon: const Icon(Icons.swap_horiz),
              color: GridColors.secondary,
            ),
          ],
          if (onAddParticipant != null) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Incluir participante',
              onPressed: onAddParticipant,
              icon: const Icon(Icons.person_add_alt),
              color: GridColors.secondary,
            ),
          ],
          if (onFinalize != null) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Finalizar atendimento',
              onPressed: onFinalize,
              icon: const Icon(Icons.stop_circle_outlined),
              color: GridColors.error,
            ),
          ],
        ],
      ),
    );
  }
}

class ChatComposer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAttach;
  final VoidCallback onTicket;
  final VoidCallback onSend;
  final VoidCallback? onCorrect;
  final VoidCallback? onSummarize;

  const ChatComposer({
    super.key,
    required this.controller,
    required this.onAttach,
    required this.onTicket,
    required this.onSend,
    this.onCorrect,
    this.onSummarize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: const BoxDecoration(
        color: GridColors.card,
        border: Border(top: BorderSide(color: GridColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              tooltip: 'Anexar arquivo',
              icon: const Icon(Icons.attach_file),
              color: GridColors.secondary,
              onPressed: onAttach,
            ),
            IconButton(
              tooltip: 'Abrir chamado',
              icon: const Icon(Icons.assignment_outlined),
              color: GridColors.primary,
              onPressed: onTicket,
            ),
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Digite sua mensagem...',
                  filled: true,
                  fillColor: ChatSupportPalette.page,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: GridColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: GridColors.divider.withValues(alpha: 0.8),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: GridColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox.square(
              dimension: 44,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: GridColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: onSend,
                child: const Icon(Icons.send_rounded, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final String displayName;
  final String time;
  final VoidCallback? onOpenFile;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.displayName,
    required this.time,
    this.onOpenFile,
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width > 900
        ? 520.0
        : MediaQuery.of(context).size.width * 0.74;
    final bubbleColor =
        isMe ? ChatSupportPalette.outbound : ChatSupportPalette.inbound;
    final borderColor = isMe
        ? GridColors.secondary.withValues(alpha: 0.24)
        : GridColors.divider.withValues(alpha: 0.55);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _Avatar(name: displayName, mine: false),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              isMe ? GridColors.secondary : GridColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _MessageContent(message: message, onOpenFile: onOpenFile),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          time,
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.45),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            _Avatar(name: displayName, mine: true),
          ],
        ],
      ),
    );
  }
}

class _MessageContent extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onOpenFile;

  const _MessageContent({required this.message, this.onOpenFile});

  @override
  Widget build(BuildContext context) {
    final text =
        message.content.isNotEmpty ? message.content : (message.text ?? '');
    if (message.type == 'file') {
      return InkWell(
        onTap: onOpenFile,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.attach_file, color: GridColors.primary, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                message.fileName ?? 'Arquivo anexado',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: GridColors.primary,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (message.type == 'ticket') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.assignment_turned_in_outlined,
              size: 18, color: GridColors.secondary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text.isEmpty ? 'Chamado aberto com sucesso' : text,
              style: const TextStyle(
                color: GridColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: const TextStyle(
        color: GridColors.textSecondary,
        fontSize: 15,
        height: 1.32,
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final bool mine;

  const _Avatar({required this.name, required this.mine});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: 16,
      backgroundColor: mine
          ? GridColors.secondary
          : GridColors.primary.withValues(alpha: 0.12),
      child: Text(
        initial,
        style: TextStyle(
          color: mine ? Colors.white : GridColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
