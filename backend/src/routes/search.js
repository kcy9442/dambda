const express = require('express');
const authenticate = require('../middleware/authenticate');
const asyncHandler = require('../middleware/asyncHandler');
const tavily = require('../services/tavily');

const router = express.Router();

router.post('/', authenticate, asyncHandler(async (req, res) => {
  const query = String(req.body.query || '').trim();
  if (query.length < 2 || query.length > 400) {
    return res.status(400).json({ error: 'query must be between 2 and 400 characters' });
  }

  try {
    const result = await tavily.search(query, {
      searchDepth: req.body.searchDepth,
      maxResults: Number(req.body.maxResults) || 5,
    });
    res.set('Cache-Control', 'private, no-store');
    return res.status(200).json(result);
  } catch (err) {
    if (err.name === 'AbortError') return res.status(504).json({ error: 'search_timeout' });
    if (err.message === 'TAVILY_API_KEY is not configured') {
      return res.status(503).json({ error: 'search_not_configured' });
    }
    return res.status(err.statusCode || 502).json({ error: 'search_unavailable' });
  }
}));

module.exports = router;
