function setJsonHeaders(res: any, statusCode: number) {
  res.statusCode = statusCode;
  res.setHeader('Content-Type', 'application/json; charset=utf-8');
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
}

function sendJson(res: any, statusCode: number, body: unknown) {
  setJsonHeaders(res, statusCode);
  res.end(JSON.stringify(body));
}

export default function handler(req: any, res: any) {
  if (req.method === 'OPTIONS') {
    setJsonHeaders(res, 204);
    res.end();
    return;
  }
  if (req.method !== 'GET') {
    sendJson(res, 405, {
      error: {
        code: 'METHOD_NOT_ALLOWED',
        message: 'GET 요청만 지원합니다.',
      },
    });
    return;
  }

  sendJson(res, 200, {
    ok: true,
    provider: process.env.AI_PROVIDER || 'openai',
    model: process.env.AI_MODEL || 'gpt-4o-mini',
    detail: process.env.AI_IMAGE_DETAIL || 'low',
    dailyLimit: Number(process.env.AI_DAILY_LIMIT_PER_CLIENT || '20'),
    hasOpenAIKey: Boolean(process.env.OPENAI_API_KEY),
  });
}
