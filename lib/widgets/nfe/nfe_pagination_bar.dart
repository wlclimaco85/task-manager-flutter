import 'package:flutter/material.dart';
import 'package:task_manager_flutter/core/design/design_tokens.dart';

/// Barra de paginação sticky para NfeListScreen
/// Renderiza: Página X de Y | [< | >]
class NfePaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool canPrevious;
  final bool canNext;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;

  const NfePaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.canPrevious,
    required this.canNext,
    this.onPreviousPage,
    this.onNextPage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingMd,
        vertical: DesignTokens.spacingSm,
      ),
      child: Semantics(
        label: 'Controle de paginação',
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Página X de Y
            Semantics(
              label: 'Página $currentPage de $totalPages',
              child: Text(
                'Página $currentPage de $totalPages',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),

            // Botões de navegação
            Semantics(
              button: true,
              enabled: true,
              label: 'Navegação de páginas',
              child: Row(
                children: [
                  // Botão: Página anterior
                  Tooltip(
                    message: 'Página anterior',
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: canPrevious ? onPreviousPage : null,
                      tooltip: 'Página anterior',
                    ),
                  ),

                  // Botão: Próxima página
                  Tooltip(
                    message: 'Próxima página',
                    child: IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: canNext ? onNextPage : null,
                      tooltip: 'Próxima página',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
