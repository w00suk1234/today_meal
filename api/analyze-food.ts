const MAX_IMAGE_BASE64_LENGTH = 4_000_000;
const MAX_AVAILABLE_FOODS = 200;
const MAX_OUTPUT_FOODS = 5;
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
  sendJson(res, statusCode, {
    error: {
      code,
      message,
      ...(details ? { details } : {}),
    },
  });
}

function preview(value: unknown) {
  const text =
    typeof value === 'string' ? value : JSON.stringify(value ?? null);
  const compact = text.replace(/\s+/g, ' ').trim();
  return compact.length > 500 ? `${compact.slice(0, 500)}...` : compact;
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
      return {
        name: String(item?.name ?? '').trim(),
        confidence: normalizeConfidence(item?.confidence),
        description: String(item?.description ?? '').trim(),
        estimatedPortionText:
          String(item?.estimatedPortionText ?? '').trim() || '확인 필요',
        estimatedGram:
          Number.isFinite(estimatedGram) && estimatedGram > 0
            ? Math.round(estimatedGram)
            : 100,
        matchedFoodItemId: matchedId,
      };
    })
    .filter((food) => food.name)
    .slice(0, MAX_OUTPUT_FOODS);
}

function buildPrompt(availableFoods: ApiFood[]) {
  return [
    '너는 한국 식단 기록 앱의 음식 사진 분석 도우미다.',
    '사진에 보이는 음식 후보를 최대 5개까지 찾는다.',
    '한국 음식명을 우선 사용한다.',
    '칼로리, 탄수화물, 단백질, 지방 값은 절대 생성하지 않는다.',
    '반환할 수 있는 값은 음식명, confidence, 설명, 예상 섭취량, availableFoods 기반 matchedFoodItemId뿐이다.',
    'confidence는 high, medium, low 중 하나만 사용한다.',
    'availableFoods와 명확히 매칭될 때만 matchedFoodItemId에 해당 id를 넣고, 애매하면 null을 넣는다.',
    '음식이 아니거나 판단이 어려우면 foods를 빈 배열로 반환한다.',
    '반드시 JSON만 반환한다. 마크다운과 설명 문장은 출력하지 않는다.',
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
}: {
  imageBase64: string;
  mimeType: string;
  availableFoods: ApiFood[];
}) {
  const apiKey = process.env.OPENAI_API_KEY;
  const model = process.env.AI_MODEL?.trim() || 'gpt-4o-mini';
  const provider = (process.env.AI_PROVIDER || 'openai').toLowerCase();
  console.log(
    `[API_ENV] provider=${provider} model=${model} hasOpenAIKey=${Boolean(
      apiKey,
    )}`,
  );
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
    // TODO: Cache repeated image hashes to avoid paying for duplicate analysis.
    // TODO: Add per-user daily analysis limits before production launch.
    console.log(
      `[API_OPENAI_REQUEST] model=${model} detail=low timeoutMs=${OPENAI_TIMEOUT_MS}`,
    );
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
                  detail: 'low',
                },
              },
            ],
          },
        ],
      }),
    });

    const responseText = await response.text();
    console.log(
      `[API_OPENAI_RESPONSE] status=${response.status} preview=${preview(
        responseText,
      )}`,
    );
    let payload: any = null;
    try {
      payload = JSON.parse(responseText);
    } catch (error: any) {
      console.error(`[API_OPENAI_PARSE_FAIL] error=${error?.message ?? error}`);
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
      console.error(`[API_PARSE_FAIL] error=${error?.message ?? error}`);
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
      },
    };
  } catch (error: any) {
    console.error(`[API_ERROR] error=${error?.message ?? error}`);
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
  const origin = String(req.headers?.origin ?? '');
  const contentType = String(req.headers?.['content-type'] ?? '');
  console.log(
    `[API_ANALYZE_START] method=${req.method} origin=${origin || '-'} contentType=${contentType || '-'}`,
  );

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
    console.log('[API_BODY_PARSE] ok=true');
    const imageBase64 = String(body.imageBase64 ?? '').trim();
    const mimeType = String(body.mimeType ?? '').trim() || 'image/jpeg';
    const availableFoods = normalizeFoods(body.availableFoods);
    console.log(
      `[API_BODY] imageBase64Length=${imageBase64.length} mime=${mimeType} foods=${availableFoods.length}`,
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

    const provider = (process.env.AI_PROVIDER || 'openai').toLowerCase();
    if (provider !== 'openai') {
      console.log(
        `[API_ENV] provider=${provider} model=${process.env.AI_MODEL?.trim() || 'gpt-4o-mini'} hasOpenAIKey=${Boolean(
          process.env.OPENAI_API_KEY,
        )}`,
      );
      sendError(
        res,
        400,
        'UNSUPPORTED_PROVIDER',
        '현재 AI_PROVIDER=openai만 지원합니다.',
      );
      return;
    }

    const result = await callOpenAi({ imageBase64, mimeType, availableFoods });
    sendJson(res, result.statusCode, result.body);
  } catch (error: any) {
    console.error(`[API_BODY_PARSE] ok=false error=${error?.message ?? error}`);
    sendError(
      res,
      400,
      'INVALID_JSON',
      '요청 body를 JSON으로 해석하지 못했습니다.',
      error?.message ?? String(error),
    );
  }
}
