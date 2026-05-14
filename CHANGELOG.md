# Changelog — task_manager_flutter (AppAcademia Cliente)

Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/).

---

## [Unreleased]

## [1.1.0] — 2026-05-13

### Fixed

- **Bug critico 404 em todas as requisicoes de CP/CR**: 12 constantes de URL em
  `lib/utils/api_links.dart` usavam o path incorreto `/api/contas-pagar` (plural,
  hifen) em vez de `/api/conta_pagar` (singular, underscore), causando erro 404 em
  toda listagem, baixa e desfazer de Contas a Pagar e Contas a Receber.
  - Constantes corrigidas: `allContasPagar`, `createContaPagar`, `updateContaPagar`,
    `deleteContaPagar`, `registrarBaixaContaPagar`, `desfazerContaPagar`,
    `allContasReceber`, `createContaReceber`, `updateContaReceber`,
    `deleteContaReceber`, `registrarBaixaContaReceber`, `desfazerContaReceber`.
- **Calendario financeiro nao exibia contas**: consequencia direta do bug 404 acima;
  apos correcao os dados do mes/ano passam a ser carregados corretamente.

### Added

- **Widget `SearchableDropdownField`** (`lib/widgets/searchable_dropdown.dart`):
  dropdown com dialogo de busca em tempo real. Parametros principais: `label`,
  `items`, `valueField`, `displayField`, `onChanged`, `nullable`, `nullLabel`,
  `hintText`, `validator`. Integra com `Form`/`FormState`. Criado neste projeto
  (ja existia no `merged_final`).

- **3 novas constantes de importacao CSV** em `lib/utils/api_links.dart`:
  - `importacaoContaPagar`  → `GET/POST /api/importacao/conta-pagar`
  - `importacaoContaReceber` → `GET/POST /api/importacao/conta-receber`
  - `importacaoPreview`      → `POST /api/importacao/preview`

- **7 novos campos de mapeamento CSV** em `_camposMapeamento` e nos controladores
  de `_ImportacaoSection` em `lib/web/screens/configuracoes_sistema_screen.dart`:
  | Campo            | Label                  | Sinonimos de auto-mapeamento                          |
  |------------------|------------------------|-------------------------------------------------------|
  | `colDataBaixa`   | Coluna Data Baixa      | data_baixa, dt_baixa, data_pagamento, data_recebimento |
  | `colValorBaixa`  | Coluna Valor Baixa     | valor_baixa, valor_pago, valor_recebido, valor_liquido |
  | `colValorMulta`  | Coluna Valor Multa     | valor_multa, multa, vl_multa                          |
  | `colValorJuros`  | Coluna Valor Juros     | valor_juros, juros, vl_juros, juro                    |
  | `colValorDesconto` | Coluna Valor Desconto | valor_desconto, desconto, vl_desconto                |
  | `colParceiroDev` | Coluna Parceiro/Dev    | parceiro, fornecedor, cliente, devedor, beneficiario  |
  | `colContaBancaria` | Coluna Conta Bancaria | conta, conta_bancaria, banco, conta_corrente          |

  Total de campos passou de 8 para 15, igualando o backend (`ImportacaoController`).

- **Feedback visual no resultado de importacao**:
  - Aviso ambar quando parceiros sao criados automaticamente (`novosParceiros > 0`).
  - Aviso laranja quando formas de pagamento sao criadas automaticamente
    (`novasFormasPagamento > 0`).
  - Chips de resumo para "Parceiros novos" e "Formas novas" no cabecalho do resultado.

### Changed

- `DropdownButtonFormField` substituido por `SearchableDropdownField` nos 3
  dropdowns de empresa nos formularios de importacao CSV (CP e CR) em
  `configuracoes_sistema_screen.dart`, melhorando usabilidade com listas longas.

---

## [1.0.0] — baseline anterior

- Estado anterior ao modulo de importacao CSV de CP/CR.

---

## Notas de divergencia com `task_manager_flutter_merged_final`

Este projeto (`task_manager_flutter`, cliente) e o `merged_final` (base/dono) estao
funcionalmente equivalentes apos esta versao 1.1.0. Os arquivos sincronizados foram:

- `lib/utils/api_links.dart` — identico nos dois projetos
- `lib/widgets/searchable_dropdown.dart` — identico nos dois projetos
- `lib/web/screens/configuracoes_sistema_screen.dart` — identico nos dois projetos
