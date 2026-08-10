const config = require('../config');

const TAVILY_URL = 'https://api.tavily.com/search';

async function search(query, options = {}) {
  if (!config.tavilyApiKey) throw new Error('TAVILY_API_KEY is not configured');

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 10000);
  try {
    const response = await fetch(TAVILY_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${config.tavilyApiKey}`,
      },
      body: JSON.stringify({
        query,
        search_depth: options.searchDepth === 'advanced' ? 'advanced' : 'basic',
        max_results: Math.min(Math.max(options.maxResults || 5, 1), 10),
        include_answer: true,
        include_raw_content: false,
      }),
      signal: controller.signal,
    });

    if (!response.ok) {
      const error = new Error(`Tavily request failed with status ${response.status}`);
      error.statusCode = response.status === 429 ? 503 : 502;
      throw error;
    }

    const data = await response.json();
    return {
      answer: data.answer || null,
      results: (data.results || []).map(({ title, url, content, score }) => ({
        title,
        url,
        content,
        score,
      })),
    };
  } finally {
    clearTimeout(timeout);
  }
}

module.exports = { search };
