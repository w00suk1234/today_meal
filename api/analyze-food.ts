import { createHash } from 'node:crypto';

const MAX_IMAGE_BASE64_LENGTH = 4_000_000;
const MAX_AVAILABLE_FOODS = 200;
const MAX_OUTPUT_FOODS = 5;
const CACHE_TTL_MS = 10 * 60 * 1000;
const OPENAI_TIMEOUT_MS = 25_000;
const OPENAI_CHAT_COMPLETIONS_URL =
  'https://api.openai.com/v1/chat/completions';

type ApiFood = {
  id: string;
  name: string;
  category: string;
};

type AnalysisFood = {
  name: string;
  confidence: 'high' | 'medium' | 'low';
  description: string;
  estimatedPortionText: string;
  estimatedGram: number;
  matchedFoodItemId: string | null;
};

type ImageDetail = 'low' | 'auto' | 'high';

type AnalysisBody = {
  foods: AnalysisFood[];
  warning: string;
  cached: boolean;
};

type CacheEntry = {
  expiresAt: number;
  body: Omit<AnalysisBody, 'cached'>;
};

const analysisCache: Map<string, CacheEntry> =
  (globalThis as any).__todayMealAnalysisCache ??
  ((globalThis as any).__todayMealAnalysisCache = new Map());

function setJsonHeaders(res: any, statusCode: number) {
  res.statusCode = statusCode;
  res.setHeader('Content-Type', 'application/json; charset=utf-8');
  // TODO: Restrict this to the deployed Flutter Web domain before production.
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
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

function parseBody(body: unknown): any {
  if (typeof body === 'string') {
    return JSON.parse(body);
  }
  return body ?? {};
}

function normalizeFoods(value: unknown): ApiFood[] {
  if (!Array.isArray(value)) {
    return [];
  }
  return value
    .map((item) => ({
      id: String(item?.id ?? '').trim(),
      name: String(item?.name ?? '').trim(),
      category: String(item?.category ?? '').trim(),
    }))
    .filter((food) => food.id && food.name)
    .slice(0, MAX_AVAILABLE_FOODS);
}

function normalizeConfidence(value: unknown): 'high' | 'medium' | 'low' {
  if (value === 'high' || value === 'medium' || value === 'low') {
    return value;
  }
  return 'low';
}

function normalizeAnalysisFoods(value: unknown, availableFoods: ApiFood[]) {
  const allowedIds = new Set(availableFoods.map((food) => food.id));
  if (!Array.isArray(value)) {
    return [];
  }
  return value
    .map((item): AnalysisFood => {
      const matchedId =
        typeof item?.matchedFoodItemId === 'string' &&
        allowedIds.has(item.matchedFoodItemId)
          ? item.matchedFoodItemId
          : null;
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
        matchedFoodItemId: matchedId,
      };
    })
    .filter((food) => food.name)
    .slice(0, MAX_OUTPUT_FOODS);
}

function buildPrompt(availableFoods: ApiFood[]) {
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
    '8. Only return name, confidence, description, estimatedPortionText, estimatedGram, matchedFoodItemId.',
    '9. matchedFoodItemId must be selected only from availableFoods.',
    '10. If no availableFoods item is clearly matched, set matchedFoodItemId to null.',
    '11. If the image is not food or the food is impossible to identify, return an empty foods array.',
    '12. Return valid JSON only.',
    '',
    'Available foods are provided as id/name/category. Use them only for matching, not for forcing a result.',
    'Descriptions must be short Korean sentences.',
    '',
    'JSON schema:',
    '{"foods":[{"name":"고등어구이","confidence":"high","description":"구운 생선으로 보입니다.","estimatedPortionText":"약 1인분","estimatedGram":180,"matchedFoodItemId":"grilled_mackerel"}]}',
    '',
    `availableFoods: ${JSON.stringify(availableFoods)}`,
  ].join('\n');
}

async function callOpenAi({
  imageBase64,
  mimeType,
  availableFoods,
  model,
  detail,
}: {
  imageBase64: string;
  mimeType: string;
  availableFoods: ApiFood[];
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
    // TODO: Add per-user daily analysis limits before production launch.
    console.log(`[API_OPENAI_REQUEST] model=${model} detail=${detail}`);
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
              'You return strict JSON only. Never estimate calories or macros.',
          },
          {
            role: 'user',
            content: [
              { type: 'text', text: buildPrompt(availableFoods) },
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
    const foods = normalizeAnalysisFoods(parsed.foods, availableFoods);
    console.log(`[API_PARSE_OK] foods=${foods.length}`);
    return {
      statusCode: 200,
      body: {
        foods,
        warning: '사진 기반 분석은 참고용이며 실제 섭취량 확인이 필요합니다.',
        cached: false,
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
    const availableFoods = normalizeFoods(body.availableFoods);
    const imageHash = normalizeImageHash(body.imageHash, imageBase64);
    const forceRefresh = body.forceRefresh === true;
    const provider = (process.env.AI_PROVIDER || 'openai').toLowerCase();
    const model = process.env.AI_MODEL?.trim() || 'gpt-4o-mini';
    const detail = normalizeImageDetail(process.env.AI_IMAGE_DETAIL || 'low');
    const availableFoodsHash = hashText(JSON.stringify(availableFoods));

    console.log('[API_ANALYZE_START]');
    console.log(
      `[API_ENV] provider=${provider} model=${model} detail=${detail} hasOpenAIKey=${Boolean(
        process.env.OPENAI_API_KEY,
      )}`,
    );
    console.log(
      `[API_BODY] imageBase64Length=${imageBase64.length} foods=${availableFoods.length} imageHash=${shortHash(
        imageHash,
      )} forceRefresh=${forceRefresh}`,
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

    const cacheKey = [
      provider,
      model,
      detail,
      imageHash,
      availableFoodsHash,
    ].join(':');
    const cached = forceRefresh ? null : getCachedAnalysis(cacheKey);
    if (cached) {
      console.log(`[API_CACHE_HIT] imageHash=${shortHash(imageHash)}`);
      sendJson(res, 200, {...cached, cached: true});
      return;
    }
    if (forceRefresh) {
      console.log(`[API_CACHE_BYPASS] imageHash=${shortHash(imageHash)}`);
    }

    const result = await callOpenAi({
      imageBase64,
      mimeType,
      availableFoods,
      model,
      detail,
    });
    if (result.statusCode === 200 && 'foods' in result.body) {
      const body = result.body as AnalysisBody;
      setCachedAnalysis(cacheKey, {
        foods: body.foods,
        warning: body.warning,
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
