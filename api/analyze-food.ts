import { createHash } from 'node:crypto';

const MAX_IMAGE_BASE64_LENGTH = 4_000_000;
const MAX_OUTPUT_FOODS = 5;
const CACHE_TTL_MS = 10 * 60 * 1000;
const OPENAI_TIMEOUT_MS = 25_000;
const OPENAI_CHAT_COMPLETIONS_URL =
  'https://api.openai.com/v1/chat/completions';

type AnalysisFood = {
  name: string;
  confidence: 'high' | 'medium' | 'low';
  description: string;
  estimatedPortionText: string;
  estimatedGram: number;
};

type ImageDetail = 'low' | 'auto' | 'high';

type AnalysisBody = {
  foods: AnalysisFood[];
  warning: string;
  cached: boolean;
  model: string;
  detail: ImageDetail;
};

type CacheEntry = {
  expiresAt: number;
  body: Omit<AnalysisBody, 'cached'>;
};

const analysisCache: Map<string, CacheEntry> =
  (globalThis as any).__todayMealAnalysisCache ??
  ((globalThis as any).__todayMealAnalysisCache = new Map());

type DailyLimitEntry = {
  dateKey: string;
  count: number;
};

const dailyLimitCounts: Map<string, DailyLimitEntry> =
  (globalThis as any).__todayMealDailyLimitCounts ??
  ((globalThis as any).__todayMealDailyLimitCounts = new Map());

function setJsonHeaders(res: any, statusCode: number) {
  res.statusCode = statusCode;
  res.setHeader('Content-Type', 'application/json; charset=utf-8');
  // TODO: Restrict this to the deployed Flutter Web domain before production.
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, X-Client-Id');
}

function sendJson(res: any, statusCode: number, body: unknown) {
  setJsonHeaders(res, statusCode);
  res.end(JSON.stringify(body));
}

function sendError(
  res: any,
  statusCode: number,
  code: string,
  message: string,
  details?: string,
) {
  console.error(`[API_ERROR] code=${code}`);
  sendJson(res, statusCode, {
    error: {
      code,
      message,
      ...(details ? { details } : {}),
    },
  });
}

function hashText(value: string) {
  return createHash('sha256').update(value).digest('hex');
}

function shortHash(value: string) {
  return value.length > 12 ? value.slice(0, 12) : value;
}

function normalizeImageDetail(value: unknown): ImageDetail {
  if (value === 'auto' || value === 'high') {
    return value;
  }
  return 'low';
}

function normalizeImageHash(value: unknown, imageBase64: string) {
  const explicit = String(value ?? '').trim().toLowerCase();
  if (/^[a-f0-9]{32,128}$/.test(explicit)) {
    return explicit;
  }
  return hashText(imageBase64);
}

function getCachedAnalysis(cacheKey: string) {
  const entry = analysisCache.get(cacheKey);
  if (!entry) {
    return null;
  }
  if (entry.expiresAt <= Date.now()) {
    analysisCache.delete(cacheKey);
    return null;
  }
  return entry.body;
}

function setCachedAnalysis(
  cacheKey: string,
  body: Omit<AnalysisBody, 'cached'>,
) {
  // Vercel Serverless memory is short-lived and per-instance. This cache only
  // prevents repeated calls while the same warm instance is alive.
  // TODO: Move cross-instance caching to Vercel KV or a Supabase table.
  analysisCache.set(cacheKey, {
    expiresAt: Date.now() + CACHE_TTL_MS,
    body,
  });
}

function todayKey() {
  return new Date().toISOString().slice(0, 10);
}

function dailyLimit() {
  const parsed = Number(process.env.AI_DAILY_LIMIT_PER_CLIENT ?? '20');
  if (!Number.isFinite(parsed) || parsed <= 0) {
    return 20;
  }
  return Math.floor(parsed);
}

function headerValue(value: unknown) {
  if (Array.isArray(value)) {
    return String(value[0] ?? '');
  }
  return String(value ?? '');
}

function clientIdFromRequest(req: any) {
  const provided = headerValue(req.headers?.['x-client-id']).trim();
  if (provided) {
    return provided.slice(0, 120);
  }
  const forwardedFor = headerValue(req.headers?.['x-forwarded-for'])
    .split(',')[0]
    .trim();
  const fallback = forwardedFor || req.socket?.remoteAddress || 'anonymous';
  return `ip:${hashText(fallback).slice(0, 24)}`;
}

function consumeDailyLimit(clientId: string) {
  const dateKey = todayKey();
  const limit = dailyLimit();
  const entry = dailyLimitCounts.get(clientId);
  const next =
    entry && entry.dateKey === dateKey
      ? { dateKey, count: entry.count + 1 }
      : { dateKey, count: 1 };
  dailyLimitCounts.set(clientId, next);
  return {
    allowed: next.count <= limit,
    count: next.count,
    limit,
  };
}

function parseBody(body: unknown): any {
  if (typeof body === 'string') {
    return JSON.parse(body);
  }
  return body ?? {};
}

function normalizeConfidence(value: unknown): 'high' | 'medium' | 'low' {
  if (value === 'high' || value === 'medium' || value === 'low') {
    return value;
  }
  return 'low';
}

function normalizeAnalysisFoods(value: unknown) {
  if (!Array.isArray(value)) {
    return [];
  }
  return value
    .map((item): AnalysisFood => {
      const estimatedGram = Number(item?.estimatedGram);
      const normalizedGram =
        Number.isFinite(estimatedGram) && estimatedGram >= 20 && estimatedGram <= 2000
          ? Math.round(estimatedGram)
          : 100;
      return {
        name: String(item?.name ?? '').trim(),
        confidence: normalizeConfidence(item?.confidence),
        description:
          String(item?.description ?? '').trim().slice(0, 90) ||
          '사진 기반 음식 후보입니다.',
        estimatedPortionText:
          String(item?.estimatedPortionText ?? '').trim().slice(0, 30) ||
          '확인 필요',
        estimatedGram: normalizedGram,
      };
    })
    .filter((food) => food.name)
    .slice(0, MAX_OUTPUT_FOODS);
}

function buildPrompt() {
  return [
    'You are a Korean meal photo recognition assistant for a diet logging app.',
    'Analyze the meal image and return likely visible foods.',
    'Prioritize Korean food names when appropriate.',
    '',
    'Rules:',
    '1. Return up to 5 visible food candidates.',
    '2. If the image contains multiple dishes, return multiple candidates instead of choosing only one.',
    '3. Separate rice, soup/stew, side dishes, and main dishes when they are clearly visible.',
    '4. Do not invent foods that are not visually supported.',
    '5. Do not overclaim confidence. Use "high" only when the food is visually clear.',
    '6. Use "medium" or "low" when the food is partially visible, ambiguous, or could be confused with similar dishes.',
    '7. Do not generate calories, carbs, protein, or fat.',
    '8. Do not match against any food database. Do not return IDs.',
    '9. Only return name, confidence, description, estimatedPortionText, estimatedGram.',
    '10. Never include matchedFoodItemId, database IDs, calories, carbs, protein, or fat.',
    '11. If the image is not food or the food is impossible to identify, return an empty foods array.',
    '12. Return valid JSON only.',
    '',
    'Descriptions must be short Korean sentences.',
    '',
    'JSON schema:',
    '{"foods":[{"name":"공깃밥","confidence":"high","description":"흰 쌀밥으로 보입니다.","estimatedPortionText":"약 1인분","estimatedGram":210}]}',
  ].join('\n');
}

async function callOpenAi({
  imageBase64,
  mimeType,
  model,
  detail,
}: {
  imageBase64: string;
  mimeType: string;
  model: string;
  detail: ImageDetail;
}) {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    return {
      statusCode: 503,
      body: {
        error: {
          code: 'OPENAI_API_KEY_MISSING',
          message:
            'OPENAI_API_KEY가 서버 환경변수에 없습니다. Vercel Environment Variables에 추가해 주세요.',
          details: 'hasOpenAIKey=false',
        },
      },
    };
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), OPENAI_TIMEOUT_MS);

  try {
    console.log(`[API_OPENAI_REQUEST] model=${model} detail=${detail} promptFoods=0`);
    const response = await fetch(OPENAI_CHAT_COMPLETIONS_URL, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      signal: controller.signal,
      body: JSON.stringify({
        model,
        temperature: 0.1,
        max_tokens: 900,
        response_format: { type: 'json_object' },
        messages: [
          {
            role: 'system',
            content:
              'You return strict JSON only. Never estimate calories or macros. Never return database IDs.',
          },
          {
            role: 'user',
            content: [
              { type: 'text', text: buildPrompt() },
              {
                type: 'image_url',
                image_url: {
                  url: `data:${mimeType};base64,${imageBase64}`,
                  detail,
                },
              },
            ],
          },
        ],
      }),
    });

    const responseText = await response.text();
    let payload: any = null;
    try {
      payload = JSON.parse(responseText);
    } catch (error: any) {
      if (!response.ok) {
        return {
          statusCode: response.status,
          body: {
            error: {
              code: 'OPENAI_REQUEST_FAILED',
              message: 'OpenAI request failed',
              details: `status=${response.status}`,
            },
          },
        };
      }
      return {
        statusCode: 502,
        body: {
          error: {
            code: 'OPENAI_RESPONSE_PARSE_FAILED',
            message: 'OpenAI 응답을 해석하지 못했습니다.',
            details: error?.message ?? String(error),
          },
        },
      };
    }
    if (!response.ok) {
      return {
        statusCode: response.status,
        body: {
          error: {
            code: 'OPENAI_REQUEST_FAILED',
            message: 'OpenAI request failed',
            details: `status=${response.status}`,
          },
        },
      };
    }

    const content = payload?.choices?.[0]?.message?.content;
    if (typeof content !== 'string' || content.trim().length === 0) {
      return {
        statusCode: 502,
        body: {
          error: {
            code: 'AI_RESPONSE_EMPTY',
            message: 'AI 분석 결과가 비어 있습니다.',
          },
        },
      };
    }

    let parsed: any;
    try {
      parsed = JSON.parse(content);
    } catch (error: any) {
      return {
        statusCode: 502,
        body: {
          error: {
            code: 'AI_JSON_PARSE_FAILED',
            message: 'AI 응답 JSON을 해석하지 못했습니다.',
            details: error?.message ?? String(error),
          },
        },
      };
    }
    const foods = normalizeAnalysisFoods(parsed.foods);
    console.log(`[API_PARSE_OK] foods=${foods.length}`);
    return {
      statusCode: 200,
      body: {
        foods,
        warning: '사진 기반 분석은 참고용이며 실제 섭취량 확인이 필요합니다.',
        cached: false,
        model,
        detail,
      },
    };
  } catch (error: any) {
    return {
      statusCode: error?.name === 'AbortError' ? 504 : 502,
      body: {
        error: {
          code:
            error?.name === 'AbortError'
              ? 'AI_TIMEOUT'
              : 'OPENAI_REQUEST_FAILED',
          message:
            error?.name === 'AbortError'
              ? 'AI 분석 요청 시간이 초과되었습니다.'
              : 'OpenAI request failed',
          details:
            error?.name === 'AbortError'
              ? `timeoutMs=${OPENAI_TIMEOUT_MS}`
              : error?.message ?? String(error),
        },
      },
    };
  } finally {
    clearTimeout(timeout);
  }
}

export default async function handler(req: any, res: any) {
  if (req.method === 'OPTIONS') {
    setJsonHeaders(res, 204);
    res.end();
    return;
  }
  if (req.method !== 'POST') {
    sendError(res, 405, 'METHOD_NOT_ALLOWED', 'POST 요청만 지원합니다.');
    return;
  }

  try {
    const body = parseBody(req.body);
    const imageBase64 = String(body.imageBase64 ?? '').trim();
    const mimeType = String(body.mimeType ?? '').trim() || 'image/jpeg';
    const imageHash = normalizeImageHash(body.imageHash, imageBase64);
    const forceRefresh = body.forceRefresh === true;
    const clientId = clientIdFromRequest(req);
    const provider = (process.env.AI_PROVIDER || 'openai').toLowerCase();
    const model = process.env.AI_MODEL?.trim() || 'gpt-4o-mini';
    const detail = normalizeImageDetail(process.env.AI_IMAGE_DETAIL || 'low');

    console.log('[API_ANALYZE_START]');
    console.log(
      `[API_ENV] provider=${provider} model=${model} detail=${detail} hasOpenAIKey=${Boolean(
        process.env.OPENAI_API_KEY,
      )}`,
    );
    console.log(
      `[API_BODY] imageBase64Length=${imageBase64.length} promptFoods=0 imageHash=${shortHash(
        imageHash,
      )} client=${shortHash(hashText(clientId))} forceRefresh=${forceRefresh}`,
    );

    if (!imageBase64) {
      sendError(res, 400, 'IMAGE_REQUIRED', 'imageBase64가 필요합니다.');
      return;
    }
    if (!/^image\/(jpeg|jpg|png|webp)$/i.test(mimeType)) {
      sendError(res, 400, 'UNSUPPORTED_IMAGE_TYPE', '지원하지 않는 이미지 형식입니다.');
      return;
    }
    if (imageBase64.length > MAX_IMAGE_BASE64_LENGTH) {
      sendError(res, 413, 'IMAGE_TOO_LARGE', '이미지 용량이 너무 큽니다.');
      return;
    }

    if (provider !== 'openai') {
      sendError(
        res,
        400,
        'UNSUPPORTED_PROVIDER',
        '현재 AI_PROVIDER=openai만 지원합니다.',
      );
      return;
    }

    const cacheKey = [provider, model, detail, imageHash].join(':');
    const cached = forceRefresh ? null : getCachedAnalysis(cacheKey);
    if (cached) {
      console.log(`[API_CACHE_HIT] imageHash=${shortHash(imageHash)}`);
      sendJson(res, 200, {...cached, cached: true});
      return;
    }
    if (forceRefresh) {
      console.log(`[API_CACHE_BYPASS] imageHash=${shortHash(imageHash)}`);
    }

    const limitResult = consumeDailyLimit(clientId);
    console.log(
      `[API_RATE_LIMIT] client=${shortHash(hashText(clientId))} count=${limitResult.count} limit=${limitResult.limit}`,
    );
    if (!limitResult.allowed) {
      sendError(
        res,
        429,
        'DAILY_LIMIT_EXCEEDED',
        '오늘 AI 분석 가능 횟수를 모두 사용했습니다. 직접 검색으로 식단을 기록해 주세요.',
      );
      return;
    }

    const result = await callOpenAi({
      imageBase64,
      mimeType,
      model,
      detail,
    });
    if (result.statusCode === 200 && 'foods' in result.body) {
      const body = result.body as AnalysisBody;
      setCachedAnalysis(cacheKey, {
        foods: body.foods,
        warning: body.warning,
        model: body.model,
        detail: body.detail,
      });
      sendJson(res, 200, {...body, cached: false});
      return;
    }
    sendJson(res, result.statusCode, result.body);
  } catch (error: any) {
    sendError(
      res,
      400,
      'INVALID_JSON',
      '요청 body를 JSON으로 해석하지 못했습니다.',
      error?.message ?? String(error),
    );
  }
}
