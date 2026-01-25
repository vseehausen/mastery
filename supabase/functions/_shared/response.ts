// Response utilities for edge functions

import { corsHeaders } from './cors.ts';

export function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
}

export function errorResponse(message: string, status = 400, details?: unknown): Response {
  return jsonResponse({ error: status >= 500 ? 'Internal Error' : 'Bad Request', message, details }, status);
}

export function unauthorizedResponse(message = 'Unauthorized'): Response {
  return errorResponse(message, 401);
}

export function notFoundResponse(message = 'Not found'): Response {
  return errorResponse(message, 404);
}

export function conflictResponse(message: string, details?: unknown): Response {
  return errorResponse(message, 409, details);
}
