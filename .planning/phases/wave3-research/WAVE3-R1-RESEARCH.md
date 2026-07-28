# Wave 3 Research — W3R1: Backend Agendamento Recorrente NFe

**Pesquisa Formal**: RFC 5545 iCalendar, PostgreSQL strategy, SEFAZ integration, versioning, JPA patterns  
**Projeto**: AppAcademia Backend (Spring Boot)  
**Story Points**: 12 SP  
**Timeline**: 2026-07-28 T+300h (6h pesquisa)  
**Status**: RESEARCH COMPLETO — PRONTO P3 EXECUÇÃO

---

## 1. RFC 5545 iCalendar — Recurrence Rule Parsing

### Contexto
RFC 5545 define o padrão aberto para calendários digitais (iCalendar/ICS). Recurrence Rules (RRULE) codificam padrões de repetição como strings: `FREQ=MONTHLY;BYDAY=2FR;UNTIL=20261231`.

### Análise Biblioteca ical4j

**Dependência Maven**:
```xml
<dependency>
    <groupId>org.mnode.ical4j</groupId>
    <artifactId>ical4j</artifactId>
    <version>3.2.13</version>
</dependency>
```

**Exemplo Parsing RRULE**:
```java
import net.fortuna.ical4j.model.property.RRule;
import net.fortuna.ical4j.model.Recur;

// Input: "FREQ=MONTHLY;BYDAY=2FR;UNTIL=20261231"
String rruleString = "FREQ=MONTHLY;BYDAY=2FR;UNTIL=20261231";
RRule rRule = new RRule(rruleString);
Recur recurrence = rRule.getRecur();

// Extrair componentes
System.out.println("Frequência: " + recurrence.getFrequency()); // MONTHLY
System.out.println("BYDAY: " + recurrence.getDayList());        // [2FR]
System.out.println("UNTIL: " + recurrence.getUntil());          // 2026-12-31
```

### Frequências Suportadas

| FREQ | Suporte ical4j | Caso Uso AppAcademia | Exemplo |
|------|---|---|---|
| **YEARLY** | ✅ | Anual (ex: declaração IR) | FREQ=YEARLY;BYMONTH=4;BYMONTHDAY=15 |
| **MONTHLY** | ✅ | Mensal (ex: folha pagamento) | FREQ=MONTHLY;BYMONTHDAY=5,20 |
| **WEEKLY** | ✅ | Semanal (ex: reunião terça) | FREQ=WEEKLY;BYDAY=TU,TH |
| **DAILY** | ✅ | Diário (ex: sincronização) | FREQ=DAILY;INTERVAL=2 |

### Validação e Risco

- **ical4j versão 3.2.13**: Stable, mantida, suporta RFC 5545 completo.
- **Risco de parsing**: RRULE inválido lança `IllegalArgumentException`. Deve-se validar antes de persistir.
- **Recomendação**: Criar `@Validated RRuleValidator` em Spring para validar input antes de salvar.

---

## 2. PostgreSQL — Estratégia de Armazenamento Recorrência

### Opção A: Armazenar RRULE Raw (String)

**Estratégia**: Persistir RRULE como TEXT na tabela `agendamento_nfe`.

**Schema**:
```sql
CREATE TABLE agendamento_nfe (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nfe_id UUID NOT NULL REFERENCES nfe(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenant(id),
    rrule TEXT NOT NULL, -- "FREQ=MONTHLY;BYDAY=2FR"
    proxima_data TIMESTAMP NOT NULL,
    status VARCHAR(20) DEFAULT 'ATIVO', -- ATIVO, PAUSADO, FINALIZADO
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID NOT NULL,
    updated_by UUID NOT NULL
);

CREATE INDEX idx_agendamento_nfe_tenant_proxima ON agendamento_nfe(tenant_id, proxima_data);
CREATE INDEX idx_agendamento_nfe_status ON agendamento_nfe(status);
```

**Vantagens**:
- Simples, sem denormalização.
- RRULE é imutável histórico.
- Fácil buscar "próxima execução próxima de X data".

**Desvantagens**:
- Parsing RRULE ocorre em memória app (CPU/latência).
- Sem índices diretos em componentes RRULE.
- Atualizar campo `proxima_data` requer cálculo em app.

### Opção B: Armazenar Próximas Ocorrências (Tabela Junction)

**Estratégia**: Gerar e persistir próximas 365 ocorrências em tabela `agendamento_nfe_ocorrencia`.

**Schema**:
```sql
CREATE TABLE agendamento_nfe (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nfe_id UUID NOT NULL REFERENCES nfe(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenant(id),
    rrule TEXT NOT NULL, -- histórico original
    status VARCHAR(20) DEFAULT 'ATIVO',
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID NOT NULL,
    updated_by UUID NOT NULL
);

CREATE TABLE agendamento_nfe_ocorrencia (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agendamento_id UUID NOT NULL REFERENCES agendamento_nfe(id) ON DELETE CASCADE,
    data_execucao TIMESTAMP NOT NULL,
    status_exec VARCHAR(20) DEFAULT 'PENDENTE', -- PENDENTE, PROCESSANDO, CONCLUIDO, ERRO, FALHA_IRREVERSIVEL
    protocolo_sefaz VARCHAR(50),
    resultado_json JSONB,
    tentativa_numero INT DEFAULT 0,
    proxima_tentativa TIMESTAMP,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX idx_agendamento_ocorr_unico ON agendamento_nfe_ocorrencia(agendamento_id, data_execucao);
CREATE INDEX idx_agendamento_ocorr_proxima ON agendamento_nfe_ocorrencia(data_execucao, status_exec) WHERE status_exec != 'CONCLUIDO';
CREATE INDEX idx_agendamento_ocorr_tenant ON agendamento_nfe_ocorrencia(agendamento_id);
```

**Processo Geração**:
```java
// Ao criar agendamento
public void criarAgendamentoComOcorrencias(Agendamento agendamento) {
    // 1. Persistir agendamento
    agendamentoRepository.save(agendamento);
    
    // 2. Gerar próximas 365 ocorrências via ical4j
    LocalDateTime inicio = LocalDateTime.now();
    LocalDateTime fim = inicio.plusDays(365);
    
    Recur recur = new RRule(agendamento.getRRule()).getRecur();
    Set<LocalDateTime> ocorrencias = gerarOcorrencias(recur, inicio, fim);
    
    // 3. Persistir ocorrências
    for (LocalDateTime data : ocorrencias) {
        AgendamentoOcorrencia ocorr = new AgendamentoOcorrencia(agendamento.getId(), data);
        ocorrenciaRepository.save(ocorr);
    }
}
```

**Vantagens**:
- Queries diretas em `data_execucao` (índices eficientes).
- Histórico detalhado de cada execução (tentativas, erros, protocolo SEFAZ).
- Job scheduler (quartz, spring-task) pode buscar OCORRÊNCIAs não executadas facilmente.
- Rastreabilidade completa: quem tentou, quando, resultado, próxima tentativa.

**Desvantagens**:
- Maior armazenamento (365 registros por agendamento ativo).
- Necessário regenerar ocorrências anualmente (ou weekly).
- Complexidade ligeiramente maior (join com ocorrencia).

### Recomendação
**Usar Opção B (Tabela Junction)**.  
Motivos:
1. Task scheduler (Quartz) roda melhor com dados denormalizados.
2. Histórico granular = auditoria + debugging.
3. Retry logic fica limpo: UPDATE ocorrencia SET status_exec='PROCESSANDO' WHERE id=X.
4. Escalável: 1M ocorrências indexadas é rápido em PostgreSQL.

---

## 3. Integração SEFAZ — Fluxo Recorrência Automática

### Arquitetura Fluxo

```
┌─────────────────┐
│  Quartz Job     │
│  (executar a    │
│   cada hora)    │
└────────┬────────┘
         │
         v
┌──────────────────────────────────────┐
│ AgendamentoScheduler                 │
│ - Busca ocorrências PENDENTE com     │
│   data_execucao <= now()             │
│ - Lock pessimista (SELECT FOR UPDATE)│
└────────┬─────────────────────────────┘
         │
         v
┌──────────────────────────────────────┐
│ DistribuirParaSeqFila                │
│ - Separa por TENANT                  │
│ - Enfileira em RabbitMQ /Kafka       │
│ - Status = PROCESSANDO               │
└────────┬─────────────────────────────┘
         │
         v
┌──────────────────────────────────────┐
│ SendNfeSefazWorker (async consumer)  │
│ - Recupera NFe + dados recorrência   │
│ - Monta XML, assina, envia SEFAZ     │
│ - Captura protocolo, status          │
└────────┬─────────────────────────────┘
         │
         v
┌──────────────────────────────────────┐
│ RegistrarResultado                   │
│ - UPDATE ocorrencia                  │
│   SET status='CONCLUIDO',            │
│       protocolo_sefaz=X,             │
│       resultado_json={...}           │
│ - Se erro: retry logic               │
└──────────────────────────────────────┘
```

### Retry Logic (Exponential Backoff)

```java
public void processarOcorrenciaComRetry(AgendamentoOcorrencia ocorr) {
    int tentativa = ocorr.getTentativaNumero();
    
    try {
        // 1. Validar NFe ainda existe e é válida
        Nfe nfe = nfeRepository.findById(ocorr.getAgendamento().getNfeId())
            .orElseThrow(NfeNaoEncontradaException::new);
        
        if (nfe.getStatus() == NfeStatus.CANCELADA) {
            ocorr.setStatusExec("FALHA_IRREVERSIVEL");
            ocorr.setResultadoJson(Map.of("erro", "NFe foi cancelada"));
            ocorrenciaRepository.save(ocorr);
            return;
        }
        
        // 2. Enviar SEFAZ
        ResultadoNfeSefaz resultado = nfeSefazService.enviarNfe(nfe, /* dados recorrência */);
        
        // 3. Registrar sucesso
        ocorr.setStatusExec("CONCLUIDO");
        ocorr.setProtocoloSefaz(resultado.getProtocolo());
        ocorr.setResultadoJson(resultado.toJson());
        ocorrenciaRepository.save(ocorr);
        
    } catch (SefazTemporaryException e) {
        // Erro temporário (timeout, serviço indisponível)
        if (tentativa < 5) {
            long delay = Math.min(300000, 1000 * (long) Math.pow(2, tentativa)); // backoff
            ocorr.setTentativaNumero(tentativa + 1);
            ocorr.setProximaTentativa(LocalDateTime.now().plusSeconds(delay / 1000));
            ocorrenciaRepository.save(ocorr);
        } else {
            ocorr.setStatusExec("FALHA_IRREVERSIVEL");
            ocorr.setResultadoJson(Map.of("erro", "Max retry attempts reached"));
            ocorrenciaRepository.save(ocorr);
            // Alertar usuário
            notificacaoService.alertarMaxRetry(ocorr);
        }
    } catch (SefazPermanentException e) {
        // Erro permanente (XML inválido, assinatura ruim)
        ocorr.setStatusExec("FALHA_IRREVERSIVEL");
        ocorr.setResultadoJson(Map.of("erro", e.getMessage()));
        ocorrenciaRepository.save(ocorr);
        notificacaoService.alertarErroFatal(ocorr);
    }
}
```

### Timing e Configurabilidade

```properties
# application.properties
agendamento.scheduler.cron=0 0 * * * ?  # a cada hora
agendamento.scheduler.timezone=America/Sao_Paulo
agendamento.retry.max_attempts=5
agendamento.retry.initial_delay_ms=1000
agendamento.retry.backoff_multiplier=2
agendamento.lock.timeout_seconds=300  # pessimistic lock
```

---

## 4. Versionamento NFe — Contexto SEFAZ

### Versões Suportadas Atualmente

| Versão | Status SEFAZ | PJ | PF | Notas |
|--------|---|---|---|---|
| **4.0** | ✅ Ativa | ✅ | ✅ | Versão 2009-2017, descontinuada |
| **5.0** | ✅ Ativa (recomendada) | ✅ | ✅ | Versão 2024+, obrigatória pós 2026 |

### Impacto em Assinatura XML

- Ambas versões usam XMLDSig (RFC 3275).
- Certificado digital (A1/A3) é igual.
- Diferença: estrutura XML e ordem de campos.
- **ical4j NÃO afeta XML NFe**: recorrência é lógica de aplicação, não XML.

### Recomendação
Assumir **NFe v5.0** para P3-P4. Validar com PO se há clientes ainda em v4.0 que precisam backcompat.

---

## 5. JPA/Hibernate — Entity Design

### Entity Agendamento

```java
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "agendamento_nfe", indexes = {
    @Index(name = "idx_agendamento_nfe_tenant_proxima", 
           columnList = "tenant_id,proxima_data"),
    @Index(name = "idx_agendamento_nfe_status", columnList = "status")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AgendamentoNfe {
    
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "nfe_id", nullable = false)
    private Nfe nfe;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "tenant_id", nullable = false)
    private Tenant tenant;
    
    @Column(name = "rrule", nullable = false, columnDefinition = "TEXT")
    private String rrule; // "FREQ=MONTHLY;BYDAY=2FR"
    
    @Column(name = "proxima_data", nullable = false)
    private LocalDateTime proximaData;
    
    @Column(name = "status", length = 20)
    @Enumerated(EnumType.STRING)
    private AgendamentoStatus status; // ATIVO, PAUSADO, FINALIZADO
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by", nullable = false)
    private Usuario criadoPor;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "updated_by", nullable = false)
    private Usuario atualizadoPor;
    
    @CreationTimestamp
    @Column(name = "criado_em", nullable = false, updatable = false)
    private LocalDateTime criadoEm;
    
    @UpdateTimestamp
    @Column(name = "atualizado_em", nullable = false)
    private LocalDateTime atualizadoEm;
    
    @OneToMany(mappedBy = "agendamento", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<AgendamentoOcorrencia> ocorrencias = new ArrayList<>();
}

public enum AgendamentoStatus {
    ATIVO,
    PAUSADO,
    FINALIZADO
}
```

### Entity Ocorrência

```java
@Entity
@Table(name = "agendamento_nfe_ocorrencia", indexes = {
    @Index(name = "idx_agendamento_ocorr_proxima", 
           columnList = "data_execucao,status_exec", 
           where = "status_exec != 'CONCLUIDO'"),
    @Index(name = "idx_agendamento_ocorr_agendamento", 
           columnList = "agendamento_id")
})
@UniqueConstraint(columnNames = {"agendamento_id", "data_execucao"}, 
                  name = "uk_agendamento_ocorr_unico")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AgendamentoOcorrencia {
    
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "agendamento_id", nullable = false)
    private AgendamentoNfe agendamento;
    
    @Column(name = "data_execucao", nullable = false)
    private LocalDateTime dataExecucao;
    
    @Column(name = "status_exec", length = 20)
    @Enumerated(EnumType.STRING)
    private OcorrenciaStatus statusExec; // PENDENTE, PROCESSANDO, CONCLUIDO, ERRO, FALHA_IRREVERSIVEL
    
    @Column(name = "protocolo_sefaz", length = 50)
    private String protocoloSefaz;
    
    @Column(name = "resultado_json", columnDefinition = "JSONB")
    @Type(JsonType.class)
    private Map<String, Object> resultadoJson;
    
    @Column(name = "tentativa_numero")
    private Integer tentativaNumero = 0;
    
    @Column(name = "proxima_tentativa")
    private LocalDateTime proximaTentativa;
    
    @CreationTimestamp
    @Column(name = "criado_em", nullable = false, updatable = false)
    private LocalDateTime criadoEm;
    
    @UpdateTimestamp
    @Column(name = "atualizado_em", nullable = false)
    private LocalDateTime atualizadoEm;
}

public enum OcorrenciaStatus {
    PENDENTE,
    PROCESSANDO,
    CONCLUIDO,
    ERRO,
    FALHA_IRREVERSIVEL
}
```

### Repository Pattern

```java
public interface AgendamentoNfeRepository extends JpaRepository<AgendamentoNfe, UUID> {
    List<AgendamentoNfe> findByTenantIdAndStatus(UUID tenantId, AgendamentoStatus status);
    List<AgendamentoNfe> findByNfeId(UUID nfeId);
}

public interface AgendamentoOcorrenciaRepository extends JpaRepository<AgendamentoOcorrencia, UUID> {
    // Buscar próximas ocorrências a executar (pessimistic lock)
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("""
        SELECT o FROM AgendamentoOcorrencia o
        WHERE o.statusExec = 'PENDENTE'
        AND o.dataExecucao <= CURRENT_TIMESTAMP
        ORDER BY o.dataExecucao ASC
        LIMIT ?1
    """)
    List<AgendamentoOcorrencia> findProximasParaExecutar(int limite);
    
    // Buscar ocorrências com retry pendente
    @Query("""
        SELECT o FROM AgendamentoOcorrencia o
        WHERE o.statusExec = 'ERRO'
        AND o.proximaTentativa <= CURRENT_TIMESTAMP
        ORDER BY o.proximaTentativa ASC
    """)
    List<AgendamentoOcorrencia> findComRetryPendente();
}
```

---

## 6. Endpoints REST — Proposta

### Criar Agendamento

```
POST /api/agendamentos-nfe
Content-Type: application/json

{
  "nfeId": "uuid-da-nfe",
  "rrule": "FREQ=MONTHLY;BYDAY=2FR;UNTIL=20261231",
  "iniciarEm": "2026-08-01T10:00:00"
}

Resposta 201:
{
  "id": "uuid-do-agendamento",
  "nfeId": "uuid-da-nfe",
  "rrule": "FREQ=MONTHLY;BYDAY=2FR;UNTIL=20261231",
  "proximaData": "2026-08-08T10:00:00",
  "status": "ATIVO",
  "criadoEm": "2026-07-28T10:00:00"
}
```

### Pausar/Retomar Agendamento

```
PATCH /api/agendamentos-nfe/{id}/status
Content-Type: application/json

{
  "novoStatus": "PAUSADO"
}
```

### Listar Próximas Execuções

```
GET /api/agendamentos-nfe/{id}/ocorrencias?limite=10&status=PENDENTE

Resposta 200:
{
  "total": 25,
  "ocorrencias": [
    {
      "id": "uuid-ocorr-1",
      "dataExecucao": "2026-08-08T10:00:00",
      "statusExec": "PENDENTE",
      "tentativaNumero": 0
    },
    ...
  ]
}
```

### Reexecutar Ocorrência

```
POST /api/agendamentos-nfe/ocorrencias/{id}/reexecutar
Content-Type: application/json

{}

Resposta 200:
{
  "id": "uuid-ocorr-1",
  "statusExec": "PROCESSANDO",
  "tentativaNumero": 1
}
```

---

## 7. Próximos Passos — P3 Execução

### Task Breakdown (Estimativa 30h críticas)

| Task | Subtarefas | SP | Horas |
|------|-----------|----|----|
| **T1: Entities + Migrations** | JPA entities, Flyway migrations, índices | 3 | 6h |
| **T2: Repositories + Services** | CRUD, Query methods, repository tests | 3 | 6h |
| **T3: Quartz Scheduler** | Job config, AgendamentoScheduler, lock logic | 2 | 4h |
| **T4: SEFAZ Integration** | Retry logic, webhook SEFAZ, async worker | 3 | 8h |
| **T5: REST Endpoints** | CRUD, status, reexecução, validação | 2 | 4h |
| **T6: Tests + E2E** | Unit tests, integration tests, happy path | 2 | 2h |

**Total**: 15 SP, 30h críticas.

---

## 📋 Conclusão Research W3R1

✅ RFC 5545 validado — ical4j 3.2.13 pronto.  
✅ PostgreSQL Opção B recomendada (tabela junction, escalável, auditável).  
✅ SEFAZ retry logic + exponential backoff definido.  
✅ Versionamento NFe v5.0 (assumir, validar com PO).  
✅ JPA entities, repositories, endpoints — schema pronto codificação.  

**SEM BLOQUEADORES. PRONTO P3 EXECUÇÃO.**
