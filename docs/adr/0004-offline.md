# ADR 0004 — Firestore offline no MVP

- Estado: Aceita
- Data: 2026-08-24

## Contexto

Registros devem funcionar sem internet, mas criar um mecanismo próprio Drift ↔ nuvem aumentaria muito o escopo inicial.

## Decisão

Usar a persistência móvel do Firestore como armazenamento offline dos dados próprios. Um SQLite/Drift operacional guarda fila de fotos, rascunhos e cache da Agenda, sem se tornar uma segunda fonte de verdade para todos os módulos. Mutações da Agenda exigem conexão no MVP.

## Consequências

- Implementação inicial menor.
- Escritas locais sincronizam automaticamente.
- Cache não garante que todo o histórico remoto esteja disponível offline.
- Consultas complexas/anos de dados podem motivar Drift como fonte primária no futuro.
- Google Agenda e uploads requerem cache/fila operacional própria e não herdam a fila do Firestore.

## Gatilhos para revisar

- Necessidade de relatórios históricos offline completos.
- Conflitos frequentes em múltiplos dispositivos.
- Consultas relacionais inviáveis no Firestore.
- Custo ou latência incompatíveis com o uso real.
