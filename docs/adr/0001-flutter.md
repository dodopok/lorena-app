# ADR 0001 — Flutter para o cliente

- Estado: Aceita
- Data: 2026-08-24

## Contexto

O produto começa no iPhone, exige uma interface fortemente personalizada e pode ganhar Android no futuro. Há uma única base de código e desenvolvedor inicial.

## Decisão

Usar Flutter/Dart para o aplicativo, mantendo integrações iOS em plugins/código nativo quando necessário.

## Consequências

- Uma base pode atender iOS e Android futuramente.
- Design consistente e customizado é simples de manter.
- Share Extension, Sign in with Apple e algumas APIs exigem configuração nativa.
- Testes em iPhone físico continuam indispensáveis.

## Alternativas

- SwiftUI: ótima experiência exclusivamente Apple, mas reduz portabilidade.
- React Native: boa alternativa se a equipe já dominar React/TypeScript.
- PWA: integração e experiência mobile insuficientes para este produto.

