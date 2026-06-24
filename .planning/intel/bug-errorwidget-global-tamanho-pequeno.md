# Bug: ErrorWidget global não respeita tamanho do widget que falhou

## Status

NADA IMPLEMENTADO. Esta sessão foi só consulta de design/UX com o especialista
`ui-ux-pro-max` (produziu especificação, não código). Nenhum arquivo foi alterado.

## Onde está o problema

- `C:\App_Academia\task_manager_flutter\lib\main.dart`
  - Linhas 49-52: `ErrorWidget.builder` é configurado GLOBALMENTE. Isso afeta
    QUALQUER widget que falhe no build em QUALQUER lugar da árvore — não só
    falha de boot do app.
  - Linhas 161-214: classe `_BootErrorScreen` (StatelessWidget), é o widget de
    fallback retornado pelo builder. Foi desenhada pensando SOMENTE em falha
    de boot/tela cheia:
    - Instancia `MaterialApp` próprio (linha 166).
    - `Scaffold` próprio com `backgroundColor: GridColors.background` (linha 168).
    - `Center` > `ConstrainedBox(maxWidth: 420)` (linhas 170-172).
    - `Icon(Icons.error_outline, size: 56, color: GridColors.error)` (linhas 178-179).
    - Título + texto explicativo sobre "dados antigos guardados".
    - `ElevatedButton.icon` "Limpar dados e recarregar" (linhas 195-205), que
      chama `limparDadosLocaisERecarregar()` de `lib/utils/boot_recovery.dart`
      — apaga dados locais do dispositivo/navegador.

## Por que quebra visualmente

Como o builder é global e `_BootErrorScreen` sempre tenta ocupar espaço com
`MaterialApp` + `Scaffold` + `ConstrainedBox(420px)`, quando um widget PEQUENO
falha no meio da árvore (ex.: ícone dentro de card de lista, dentro de
popup/dialog), o Flutter força esse widget grande dentro do espaço pequeno
disponível. Resultado: overflow (faixas amarelo/preto) e fundo
vermelho/rosa do Scaffold sem conteúdo útil visível.

## Reports de usuário (produção)

1. Popup de upload de arquivo GED aparecendo com "fundo rosa feio".
2. Outra tela com "barra vermelha cortada sem contexto".

## O que já foi decidido na consulta de design (ui-ux-pro-max)

Especificação produzida (NÃO codada ainda):
- Usar `LayoutBuilder` para detectar o espaço disponível e decidir entre modo
  COMPACTO vs COMPLETO.
- Em modo compacto: ícone adaptativo (menor), SEM `MaterialApp`/`Scaffold`
  próprios (evita quebrar o `Theme`/`Navigator` do app já em execução —
  problema adicional ao visual, pois um `MaterialApp` aninhado dentro de uma
  árvore já viva pode causar comportamento inesperado de navegação/contexto).
- Botão "Limpar dados e recarregar" deve aparecer SOMENTE no modo
  fullscreen/boot — em modo compacto não faz sentido oferecer essa ação
  destrutiva para uma falha local pequena (ex.: um ícone de card).
- Reaproveitar os tokens de cor já existentes: `GridColors.error`,
  `GridColors.primary`, `GridColors.background` (não inventar paleta nova).

## Próximos passos (para quem pegar esta tarefa)

1. Implementar `_BootErrorScreen` (ou criar widget substituto) com
   `LayoutBuilder` decidindo compacto vs completo.
2. Em modo compacto, NÃO instanciar `MaterialApp`/`Scaffold` — usar apenas
   widgets simples (`Container`/`Center`/`Icon`/`Text`) que se encaixam no
   espaço do pai sem overflow e sem criar novo contexto de Theme/Navigator.
3. Restringir o botão "Limpar dados e recarregar" ao modo fullscreen/boot.
4. Validar com os dois cenários reportados (popup de upload GED e a tela com
   "barra vermelha cortada") antes de considerar resolvido.
5. Replicar a correção em `task_manager_flutter_merged_final` (paridade
   obrigatória conforme `C:\App_Academia\CLAUDE.md`, exceto branding/cores
   — neste caso a lógica de `LayoutBuilder` deve ser replicada, mas os
   tokens `GridColors.*` usados já são compartilhados, não é arquivo de
   tema exclusivo).
6. Testar em mobile, Windows e Web (o builder é global e afeta todas as
   plataformas).

## Arquivos relevantes

- `C:\App_Academia\task_manager_flutter\lib\main.dart` (linhas 49-52 e 161-214)
- `C:\App_Academia\task_manager_flutter\lib\utils\boot_recovery.dart`
  (função `limparDadosLocaisERecarregar()`)
- Tokens de cor: `GridColors.error`, `GridColors.primary`,
  `GridColors.background` (arquivo de tema, não replicar para
  merged_final conforme regra de branding do CLAUDE.md)
