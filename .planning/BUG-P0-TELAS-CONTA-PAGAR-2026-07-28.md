# BUG P0: HTTP 500 em GET /api/telas/conta_pagar — Erro SQL bytea

**Data Criação**: 2026-07-28  
**Status**: Pronto para Trello  
**Wave**: Wave 3 P2  
**Prioridade**: P0 — CRÍTICO  

---

## Título do Card (Trello)

```
BUG P0: HTTP 500 em GET /api/telas/conta_pagar — Erro SQL bytea
```

---

## Classificação (conforme CLAUDE.md)

| Campo | Valor |
|-------|-------|
| **Projeto Alvo** | Backend AppAcademia |
| **Plataforma Alvo** | Backend/API apenas |
| **Fora do Escopo** | V003 fora, appDaniel fora |
| **Story Points** | 2-3 SP |
| **Labels** | `bug` `p0-critical` `sql` `boletobancos` `telas` |

---

## Descrição Técnica

### Problema Identificado

GET `/api/telas/conta_pagar` retorna **HTTP 500** com erro SQL:

```
ERROR: function lower(bytea) does not exist
```

**Root Cause**: Coluna `descricao` em tabela `telas` está como tipo de dado `bytea` (binary) em vez de `TEXT`.

**Código Afetado**: `TelaServiceImpl.buildTelaSpecification():200`
```java
Specification<Tela> spec = (root, query, cb) -> {
    // ... outros filtros
    return cb.like(cb.lower(root.get("descricao")), "%" + descricao.toLowerCase() + "%");
    // ^^ LOWER() não existe para bytea no PostgreSQL
};
```

---

## Solução Implementada

### Migração Flyway V176

**Arquivo**: `src/main/resources/db/migration/V176__fix_telas_descricao_bytea.sql`

```sql
-- Fix: Convert bytea descricao to TEXT in telas table
ALTER TABLE telas ALTER COLUMN descricao TYPE TEXT USING encode(descricao, 'escape');

-- Ensure index exists (reindex if needed)
DROP INDEX IF EXISTS idx_telas_descricao;
CREATE INDEX idx_telas_descricao ON telas(descricao);
```

**Rationale**:
- `USING encode(descricao, 'escape')` converte dados binários para text sem perda
- Index mantém performance
- Sem downtime no PostgreSQL 9.4+

---

## Critérios de Aceitação (AC)

- ✅ Migração V176 aplicada com sucesso
- ✅ GET `/api/telas/conta_pagar` retorna HTTP 200 OK
- ✅ Resposta inclui lista correta de telas com `descricao` como string
- ✅ Sem corrupção/perda de dados durante conversão
- ✅ Validado via curl/Postman contra staging/local
- ✅ Índice criado e verified com EXPLAIN ANALYZE

---

## Tarefas para Implementação

1. [ ] Aplicar migração V176 ao banco de staging
2. [ ] Validar conversão de dados (SELECT COUNT(*) FROM telas)
3. [ ] Testar endpoint GET /api/telas/conta_pagar
4. [ ] Validar performance com EXPLAIN ANALYZE
5. [ ] Aprovação QA (sem regressão em outras telas)
6. [ ] Merge para main e deploy produção

---

## Referências

- **Sprint**: Wave 3 P2  
- **Epic**: Correções P0 — Telas/NFe  
- **Relacionados**: P2-501 (Cancelamento NFe), P2-502 (Manifestação UI)
- **Banco**: PostgreSQL (via Railway)

---

## Histórico

| Data | Ação | Responsável |
|------|------|-------------|
| 2026-07-28 | Card criado para Trello | Claude Code |
| 2026-07-28 | Aguardando PO para criar card Trello | — |

