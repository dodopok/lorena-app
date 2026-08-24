# ADR 0003 — Identidade Apple e Google Agenda separado

- Estado: Aceita
- Data: 2026-08-24

## Contexto

A usuária precisa conectar o Google Agenda, mas os demais dados não dependem do Google. O app é inicialmente exclusivo para iPhone e pode passar por revisão Apple.

## Decisão

Usar Sign in with Apple/Firebase Auth como conta do app. Google Sign-In existe como autorização opcional e incremental apenas para Calendar API.

## Consequências

- Dados continuam acessíveis mesmo com Google revogado.
- Menor privilégio e responsabilidades mais claras.
- Onboarding possui duas conexões, embora a segunda seja opcional.
- Tokens Calendar ficam fora do Firestore e devem ser protegidos pelo Keychain/SDK.
- A eventual revisão da App Store fica alinhada à regra de login de terceiros.

