import { onCall, HttpsError } from 'firebase-functions/v2/https';

import {
  LinkExtractionError,
  extractLinkMetadata as runExtraction,
} from './extractor';

const WINDOW_MS = 60_000;
const MAX_CALLS_PER_USER = 20;
const MAX_IN_FLIGHT_PER_USER = 2;
const counters = new Map<string, { startedAt: number; calls: number; inFlight: number }>();

export const extractLinkMetadataCallable = onCall(
  {
    region: 'us-central1',
    timeoutSeconds: 20,
    memory: '256MiB',
    enforceAppCheck: false,
  },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Autenticação necessária.');
    const rawUrl = request.data && typeof request.data.url === 'string'
      ? request.data.url.trim()
      : '';
    if (!rawUrl || rawUrl.length > 4096) {
      throw new HttpsError('invalid-argument', 'URL ausente ou grande demais.');
    }
    const state = takeQuota(uid);
    try {
      return await runExtraction(rawUrl);
    } catch (error) {
      if (error instanceof LinkExtractionError) {
        throw new HttpsError(error.code, error.message);
      }
      throw new HttpsError('unavailable', 'Não foi possível consultar este link.');
    } finally {
      state.inFlight -= 1;
    }
  },
);

// Keep the deployed name aligned with the endpoint consumed by the app.
export const extractLinkMetadata = extractLinkMetadataCallable;

function takeQuota(uid: string) {
  const now = Date.now();
  const previous = counters.get(uid);
  const state = !previous || now - previous.startedAt >= WINDOW_MS
    ? { startedAt: now, calls: 0, inFlight: 0 }
    : previous;
  if (state.calls >= MAX_CALLS_PER_USER) {
    throw new HttpsError('resource-exhausted', 'Limite temporário de consultas atingido.');
  }
  if (state.inFlight >= MAX_IN_FLIGHT_PER_USER) {
    throw new HttpsError('resource-exhausted', 'Aguarde a consulta atual terminar.');
  }
  state.calls += 1;
  state.inFlight += 1;
  counters.set(uid, state);
  return state;
}
