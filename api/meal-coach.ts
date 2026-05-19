import { createHash } from 'node:crypto';
import OpenAI from 'openai';

type CoachMode = 'today_plan' | 'improvement_report' | 'exercise_recommendation';

const OPENAI_TIMEOUT_MS = 30_000;
const MAX_BODY_LENGTH = 24_000;

type DailyLimitEntry = {
  dateKey: string;
  count: number;
};

const dailyLimitCounts: Map<string, DailyLimitEntry> =
  (globalThis as any).__todayMealCoachDailyLimitCounts ??
  ((globalThis as any).__todayMealCoachDailyLimitCounts = new Map());

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
  console.error(`[MEAL_COACH_ERROR] code=${code}`);
  sendJson(res, statusCode, {
    error: {
      code,
      message,
      ...(details ? { details } : {}),
    },
  });
}

function parseBody(body: unknown): any {
  if (typeof body === 'string') {
    return JSON.parse(body);
  }
  return body ?? {};
}

function hashText(value: string) {
  return createHash('sha256').update(value).digest('hex');
}

function shortHash(value: string) {
  return value.length > 12 ? value.slice(0, 12) : value;
}

function todayKey() {
  return new Date().toISOString().slice(0, 10);
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

function dailyLimit() {
  const parsed = Number(process.env.AI_MEAL_COACH_DAILY_LIMIT_PER_CLIENT ?? '10');
  if (!Number.isFinite(parsed) || parsed <= 0) {
    return 10;
  }
  return Math.floor(parsed);
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

function stringList(value: unknown, fallback: string[], limit = 4) {
  if (!Array.isArray(value)) {
    return fallback;
  }
  const items = value
    .map((item) => cleanText(String(item ?? '')))
    .filter((item) => item.length > 0)
    .slice(0, limit);
  return items.length > 0 ? items : fallback;
}

function numberOrFallback(value: unknown, fallback: number) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function textOrFallback(value: unknown, fallback: string, limit = 180) {
  const text = cleanText(String(value ?? ''));
  return (text || fallback).slice(0, limit);
}

function cleanText(value: string) {
  return value
    .replace(/\s*[\(\[\{（［｛][^\)\]\}）］｝]{1,160}[\)\]\}）］｝]/g, '')
    .replace(/\s{2,}/g, ' ')
    .replace(/\s+([,.!?。])/g, '$1')
    .trim();
}

function normalizeMode(value: unknown): CoachMode | null {
  return value === 'today_plan' ||
    value === 'improvement_report' ||
    value === 'exercise_recommendation'
    ? value
    : null;
}

function buildSystemPrompt(mode: CoachMode) {
  const task =
    mode === 'today_plan'
      ? 'Generate a concise AI today meal plan for the rest of today.'
      : mode === 'exercise_recommendation'
        ? 'Generate one concise AI exercise recommendation for today.'
        : 'Generate a concise AI improvement report from the recent 7-day summary.';
  const exerciseRules =
    mode === 'exercise_recommendation'
      ? [
          'The title field must be short and fit on one mobile line.',
          'The reason field must be around 80 Korean characters or less.',
          'The caution field should be short.',
          'Do not push exercise as mandatory.',
          'If skippedMealTypes exist or mealCount is low, prefer light walking, stretching, or rest instead of hard exercise.',
          'If activityContext already shows enough activity today, suggest light recovery or rest.',
        ]
      : [];
  return [
    'You are a Korean meal coaching assistant inside a local-first diet logging app.',
    task,
    'Respond in Korean only.',
    'Tone: supportive, practical, non-judgmental, and short enough for mobile cards.',
    'Do not imply the user must fill remaining calories.',
    'Do not subtract exercise calories from food intake calories.',
    'Use activityContext only as reference for today activity level and condition.',
    'Avoid strong wording such as "you exercised so you should eat more".',
    'For activity, keep advice to general lifestyle suggestions like light recovery, hydration, and protein support.',
    'Do not give medical, treatment, or rehabilitation advice based on activity.',
    ...exerciseRules,
    'Never use parentheses, brackets, or meta explanations in user-facing text.',
    'Do not write internal notes such as "think of this as a guide" inside the answer.',
    'Prefer direct menu names instead of alternatives in parentheses.',
    'Do not give medical diagnosis, treatment, or clinical advice.',
    'Treat BMI and weight as reference indicators only.',
    'Do not encourage extreme dieting, fasting, or rapid weight loss.',
    'Prefer realistic Korean meals and everyday actions.',
    'Do not modify or save any meal data. Only provide suggestions.',
    mode === 'exercise_recommendation'
      ? 'Always include a short caution that resting is okay when condition is not good.'
      : 'Always include the caution exactly as a reference-only food suggestion.',
  ].join('\n');
}

function buildUserPrompt(mode: CoachMode, body: any) {
  const payload = {
    mode,
    date: body.date,
    todaySummary: body.todaySummary,
    recentSummary: body.recentSummary,
    healthContext: body.healthContext,
  };
  return [
    '아래 JSON 요약 데이터만 보고 앱 카드용 응답을 만들어주세요.',
    '원본 식단 전체가 아니라 요약값만 제공됩니다.',
    '숫자가 비어 있거나 0이면 단정하지 말고 기록이 더 필요하다고 표현하세요.',
    'skippedMealTypes는 사용자가 의도적으로 건너뛴 식사이므로 기록 누락으로 판단하지 마세요.',
    'activityContext는 오늘 활동량 참고용입니다. 운동 칼로리를 섭취 칼로리에서 빼지 마세요.',
    '오늘 식사 기록이 적거나 굶은 식사가 있으면 강한 운동보다 걷기, 스트레칭, 휴식 위주로 제안하세요.',
    '이미 운동 기록이 충분하면 추가 운동을 강하게 권하지 말고 가벼운 회복이나 휴식을 제안하세요.',
    mode === 'exercise_recommendation'
      ? '운동 추천은 제목 한 줄, 이유 1~2문장, 짧은 주의 문구 정도로만 작성하세요.'
      : '식단 제안은 앱 카드에 맞게 짧게 작성하세요.',
    '사용자에게 그대로 보이는 문장이므로 괄호, 대괄호, 내부 설명 같은 메모를 쓰지 마세요.',
    '남은 칼로리를 채우라는 표현 대신 참고 목표와 현재 기록 흐름을 말해주세요.',
    JSON.stringify(payload),
  ].join('\n\n');
}

const nextMealSuggestionSchema = {
  type: 'object',
  properties: {
    mealType: { type: 'string' },
    title: { type: 'string' },
    reason: { type: 'string' },
    estimatedKcal: { type: 'integer' },
    proteinG: { type: 'integer' },
    carbsG: { type: 'integer' },
    fatG: { type: 'integer' },
  },
  required: [
    'mealType',
    'title',
    'reason',
    'estimatedKcal',
    'proteinG',
    'carbsG',
    'fatG',
  ],
  additionalProperties: false,
};

const exerciseRecommendationSchema = {
  type: 'object',
  properties: {
    title: { type: 'string' },
    reason: { type: 'string' },
    durationMinutes: { type: 'integer', minimum: 0, maximum: 240 },
    intensity: { type: 'string', enum: ['light', 'moderate', 'hard'] },
    type: {
      type: 'string',
      enum: ['walk', 'running', 'strength', 'cycling', 'stretching', 'rest', 'etc'],
    },
    caution: { type: 'string' },
  },
  required: ['title', 'reason', 'durationMinutes', 'intensity', 'type', 'caution'],
  additionalProperties: false,
};

const todayPlanSchema = {
  type: 'object',
  properties: {
    type: { type: 'string', enum: ['today_plan'] },
    title: { type: 'string' },
    summary: { type: 'string' },
    statusLabel: { type: 'string' },
    recommendedFocus: {
      type: 'array',
      items: { type: 'string' },
      minItems: 1,
      maxItems: 3,
    },
    nextMealSuggestion: nextMealSuggestionSchema,
    missions: {
      type: 'array',
      items: { type: 'string' },
      minItems: 1,
      maxItems: 3,
    },
    caution: { type: 'string' },
  },
  required: [
    'type',
    'title',
    'summary',
    'statusLabel',
    'recommendedFocus',
    'nextMealSuggestion',
    'missions',
    'caution',
  ],
  additionalProperties: false,
};

const improvementReportSchema = {
  type: 'object',
  properties: {
    type: { type: 'string', enum: ['improvement_report'] },
    title: { type: 'string' },
    score: { type: 'integer', minimum: 0, maximum: 100 },
    summary: { type: 'string' },
    goodPoints: {
      type: 'array',
      items: { type: 'string' },
      minItems: 1,
      maxItems: 3,
    },
    improvementPoints: {
      type: 'array',
      items: { type: 'string' },
      minItems: 1,
      maxItems: 3,
    },
    patterns: {
      type: 'array',
      items: { type: 'string' },
      minItems: 1,
      maxItems: 3,
    },
    nextActions: {
      type: 'array',
      items: { type: 'string' },
      minItems: 1,
      maxItems: 4,
    },
    caution: { type: 'string' },
  },
  required: [
    'type',
    'title',
    'score',
    'summary',
    'goodPoints',
    'improvementPoints',
    'patterns',
    'nextActions',
    'caution',
  ],
  additionalProperties: false,
};

function schemaForMode(mode: CoachMode) {
  if (mode === 'today_plan') {
    return todayPlanSchema;
  }
  if (mode === 'exercise_recommendation') {
    return exerciseRecommendationSchema;
  }
  return improvementReportSchema;
}

function collectOutputText(response: any) {
  if (typeof response.output_text === 'string' && response.output_text.trim()) {
    return response.output_text;
  }
  const chunks: string[] = [];
  for (const output of response.output ?? []) {
    for (const content of output.content ?? []) {
      if (content.type === 'output_text' && typeof content.text === 'string') {
        chunks.push(content.text);
      }
    }
  }
  return chunks.join('\n').trim();
}

function normalizeTodayPlan(value: any) {
  const suggestion = value?.nextMealSuggestion ?? {};
  return {
    type: 'today_plan',
    title: textOrFallback(value?.title, '오늘은 균형을 조금 보완해보세요.', 80),
    summary: textOrFallback(
      value?.summary,
      '현재 기록을 기준으로 무리하지 않고 단백질이 포함된 식사를 선택해보세요.',
      180,
    ),
    statusLabel: textOrFallback(value?.statusLabel, '균형 보완', 24),
    recommendedFocus: stringList(value?.recommendedFocus, ['단백질 보완'], 3),
    nextMealSuggestion: {
      mealType: textOrFallback(suggestion?.mealType, 'dinner', 20),
      title: textOrFallback(suggestion?.title, '단백질 포함 한식 메뉴', 80),
      reason: textOrFallback(
        suggestion?.reason,
        '부담 없이 균형을 보완하기 좋은 선택입니다.',
        160,
      ),
      estimatedKcal: Math.round(numberOrFallback(suggestion?.estimatedKcal, 520)),
      proteinG: Math.round(numberOrFallback(suggestion?.proteinG, 30)),
      carbsG: Math.round(numberOrFallback(suggestion?.carbsG, 55)),
      fatG: Math.round(numberOrFallback(suggestion?.fatG, 15)),
    },
    missions: stringList(
      value?.missions,
      ['다음 식사에 단백질 식품 하나 포함하기', '오늘 기록을 마무리하기'],
      3,
    ),
    caution: '참고용 식단 제안이며 의학적 조언이 아닙니다.',
  };
}

function normalizeExerciseRecommendation(value: any) {
  return {
    title: textOrFallback(value?.title, '가볍게 걷기 20분', 38),
    reason: textOrFallback(
      value?.reason,
      '오늘은 강한 운동보다 부담 없는 활동이 좋아요.',
      90,
    ),
    durationMinutes: Math.max(
      0,
      Math.min(240, Math.round(numberOrFallback(value?.durationMinutes, 20))),
    ),
    intensity: textOrFallback(value?.intensity, 'light', 20),
    type: textOrFallback(value?.type, 'walk', 24),
    caution: textOrFallback(
      value?.caution,
      '컨디션이 좋지 않으면 쉬어도 괜찮아요.',
      60,
    ),
  };
}

function normalizeImprovementReport(value: any) {
  return {
    type: 'improvement_report',
    title: textOrFallback(value?.title, '최근 기록을 바탕으로 식단 흐름을 점검했어요.', 90),
    score: Math.max(0, Math.min(100, Math.round(numberOrFallback(value?.score, 70)))),
    summary: textOrFallback(
      value?.summary,
      '최근 기록을 기준으로 식사 기록 습관과 단백질 섭취를 함께 확인해보세요.',
      220,
    ),
    goodPoints: stringList(value?.goodPoints, ['식단 기록을 남기고 있어요.'], 3),
    improvementPoints: stringList(
      value?.improvementPoints,
      ['단백질과 수분 섭취를 함께 확인해보세요.'],
      3,
    ),
    patterns: stringList(
      value?.patterns,
      ['기록이 더 쌓이면 반복 패턴을 더 정확히 볼 수 있어요.'],
      3,
    ),
    nextActions: stringList(
      value?.nextActions,
      ['다음 식사에 단백질 식품 하나를 추가해보세요.', '주 2회 이상 몸무게를 기록해보세요.'],
      4,
    ),
    caution: '참고용 식단 제안이며 의학적 조언이 아닙니다.',
  };
}

function normalizeResult(mode: CoachMode, parsed: any) {
  if (mode === 'today_plan') {
    return normalizeTodayPlan(parsed);
  }
  if (mode === 'exercise_recommendation') {
    return normalizeExerciseRecommendation(parsed);
  }
  return normalizeImprovementReport(parsed);
}

async function callOpenAi(mode: CoachMode, body: any) {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    return {
      statusCode: 503,
      body: {
        error: {
          code: 'OPENAI_API_KEY_MISSING',
          message:
            'OPENAI_API_KEY가 서버 환경변수에 없습니다. Vercel Environment Variables에 추가해 주세요.',
        },
      },
    };
  }

  const model = process.env.OPENAI_MEAL_COACH_MODEL?.trim() || 'gpt-5.4-nano';
  const client = new OpenAI({ apiKey });
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), OPENAI_TIMEOUT_MS);

  try {
    console.log(`[MEAL_COACH_OPENAI_REQUEST] mode=${mode} model=${model}`);
    const response = await client.responses.create(
      {
        model,
        input: [
          { role: 'system', content: buildSystemPrompt(mode) },
          { role: 'user', content: buildUserPrompt(mode, body) },
        ],
        text: {
          format: {
            type: 'json_schema',
            name:
              mode === 'today_plan'
                ? 'today_meal_ai_plan'
                : mode === 'exercise_recommendation'
                  ? 'today_meal_ai_exercise_recommendation'
                  : 'today_meal_ai_improvement_report',
            strict: true,
            schema: schemaForMode(mode),
          },
        },
        max_output_tokens:
          mode === 'exercise_recommendation'
            ? 450
            : mode === 'today_plan'
              ? 900
              : 1200,
        store: false,
      } as any,
      { signal: controller.signal } as any,
    );

    const outputText = collectOutputText(response);
    if (!outputText) {
      return {
        statusCode: 502,
        body: {
          error: {
            code: 'AI_RESPONSE_EMPTY',
            message: 'AI 응답이 비어 있습니다.',
          },
        },
      };
    }

    let parsed: any;
    try {
      parsed = JSON.parse(outputText);
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

    return {
      statusCode: 200,
      body: {
        result: normalizeResult(mode, parsed),
        cached: false,
        model,
      },
    };
  } catch (error: any) {
    return {
      statusCode: error?.name === 'AbortError' ? 504 : 502,
      body: {
        error: {
          code: error?.name === 'AbortError' ? 'AI_TIMEOUT' : 'OPENAI_REQUEST_FAILED',
          message:
            error?.name === 'AbortError'
              ? 'AI 코치 요청 시간이 초과되었습니다.'
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
    const rawBody =
      typeof req.body === 'string' ? req.body : JSON.stringify(req.body ?? {});
    if (rawBody.length > MAX_BODY_LENGTH) {
      sendError(res, 413, 'PAYLOAD_TOO_LARGE', '요청 데이터가 너무 큽니다.');
      return;
    }

    const body = parseBody(req.body);
    const mode = normalizeMode(body.mode);
    if (!mode) {
      sendError(
        res,
        400,
        'INVALID_MODE',
        'mode는 today_plan, improvement_report, exercise_recommendation만 지원합니다.',
      );
      return;
    }

    if (!body.todaySummary || !body.recentSummary || !body.healthContext) {
      sendError(res, 400, 'MISSING_CONTEXT', '요약 데이터와 건강 컨텍스트가 필요합니다.');
      return;
    }

    const clientId = clientIdFromRequest(req);
    const limitResult = consumeDailyLimit(clientId);
    console.log(
      `[MEAL_COACH_RATE_LIMIT] client=${shortHash(hashText(clientId))} count=${limitResult.count} limit=${limitResult.limit}`,
    );
    if (!limitResult.allowed) {
      sendError(
        res,
        429,
        'DAILY_LIMIT_EXCEEDED',
        '오늘 AI 코치 생성 가능 횟수를 모두 사용했습니다.',
      );
      return;
    }

    const result = await callOpenAi(mode, body);
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
