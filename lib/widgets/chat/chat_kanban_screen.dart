import 'package:flutter/material.dart';
import '../../models/chat_model.dart';
import '../../services/chat_caller.dart';
import '../../utils/grid_colors.dart';
import 'chat_support_ui.dart';

class ChatKanbanScreen extends StatefulWidget {
  const ChatKanbanScreen({super.key});

  @override
  State<ChatKanbanScreen> createState() => _ChatKanbanScreenState();
}

class _ChatKanbanScreenState extends State<ChatKanbanScreen> {
  final ChatCaller _caller = ChatCaller();
  List<ChatKanbanItem> _items = [];
  bool _loading = true;

  static const _colunas = ['ABERTO', 'EM_ANDAMENTO', 'RESOLVIDO', 'FECHADO'];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    final items = await _caller.fetchChatsKanban();
    if (mounted) setState(() { _items = items; _loading = false; });
  }

  List<ChatKanbanItem> _itensDaColuna(String coluna) {
    return _items.where((i) => i.status.toUpperCase() == coluna).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChatSupportPalette.page,
      appBar: AppBar(
        title: const Text('Kanban de Chats'),
        backgroundColor: GridColors.card,
        surfaceTintColor: GridColors.card,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregar,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? ChatEmptyState(
                  title: 'Nenhum chat encontrado',
                  message: 'Os chats aparecerao aqui organizados por status.',
                )
              : _buildBoard(),
    );
  }

  Widget _buildBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        if (isWide) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _colunas.map((c) => _ColunaCard(c, _itensDaColuna(c))).toList(),
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: _colunas.map((c) => _ColunaCard(c, _itensDaColuna(c))).toList(),
          ),
        );
      },
    );
  }
}

class _ColunaCard extends StatelessWidget {
  final String titulo;
  final List<ChatKanbanItem> itens;

  const _ColunaCard(this.titulo, this.itens);

  Color get _corCabecalho {
    switch (titulo) {
      case 'ABERTO':
        return GridColors.warning;
      case 'EM_ANDAMENTO':
        return GridColors.primary;
      case 'RESOLVIDO':
        return GridColors.info;
      case 'FECHADO':
        return GridColors.success;
      default:
        return GridColors.divider;
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 320),
      child: Card(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _corCabecalho.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: _corCabecalho,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    titulo,
                    style: TextStyle(
                      color: _corCabecalho,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _corCabecalho.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${itens.length}',
                      style: TextStyle(
                        color: _corCabecalho,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (itens.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Nenhum item', style: TextStyle(color: GridColors.textMuted)),
              )
            else
              ...itens.map((item) => _ItemCard(item: item)),
          ],
        ),
      ),
    );

    final isWide = MediaQuery.of(context).size.width > 700;
    if (isWide) {
      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: SizedBox(
          width: 280,
          child: card,
        ),
      );
    }
    return card;
  }
}

class _ItemCard extends StatelessWidget {
  final ChatKanbanItem item;

  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: GridColors.divider.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.cliente ?? 'Cliente',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: GridColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (item.ultimaMensagem != null && item.ultimaMensagem!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.ultimaMensagem!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.55),
                      fontSize: 11,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (item.setor != null)
                      Text(
                        item.setor!,
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.4),
                          fontSize: 10,
                        ),
                      ),
                    const Spacer(),
                    if (item.naoLidos > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: GridColors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${item.naoLidos}',
                          style: const TextStyle(
                            color: GridColors.error,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
