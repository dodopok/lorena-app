# ADR 0002 — Firebase para backend inicial

- Estado: Aceita
- Data: 2026-08-24

## Contexto

O app precisa de conta, sincronização offline, fotos, regras por usuário, backend pequeno e operação simples.

## Decisão

Usar Firebase Authentication, Cloud Firestore, Cloud Storage, Cloud Functions pontuais, App Check e Crashlytics sanitizado.

## Consequências

- Menor esforço operacional e boa integração Flutter/iOS.
- Firestore fornece persistência offline adequada ao volume inicial.
- Modelo NoSQL exige disciplina nos relatórios financeiros.
- Há lock-in e custos de Storage/Functions/backup a monitorar.
- Security Rules se tornam parte crítica da aplicação.

## Alternativas

- Supabase: melhor para SQL, porém exige estratégia offline adicional.
- CloudKit: bom para Apple, menos adequado a Flutter/Android e scraping.
- Backend próprio: flexível, mas desproporcional para uma usuária.

