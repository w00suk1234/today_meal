function setJsonHeaders(res: any, statusCode: number) {
  res.statusCode = statusCode;
  res.setHeader('Content-Type', 'application/json; charset=utf-8');
  // TODO: Restrict this to the deployed Flutter Web domain before production.
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
    model: process.env.AI_MODEL?.trim() || 'gpt-4o-mini',
    hasOpenAIKey: Boolean(process.env.OPENAI_API_KEY),
  });
}
