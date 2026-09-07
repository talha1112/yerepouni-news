# Yerepouni News — RSS/API proxy

A small Node/Express backend that proxies Yerepouni's WordPress RSS feeds
and REST API for the Flutter app in `../yerepouni_news_flutter`. It exists
because browsers/apps can't fetch `yerepouni-news.com`'s feeds directly
(no CORS headers), and because the site's RSS excerpts are truncated.

## Run locally
1. Install Node.js 18+.
2. In this folder run:
   npm install
   npm start
3. Server listens on http://localhost:3000 (or `$PORT`)

Only `www.yerepouni-news.com` is allowed as an upstream host, to avoid
turning this into an open proxy.

## Endpoints
- `GET /api/feed?url=<rss-feed-url>` — parses an RSS feed into JSON items.
- `GET /api/article?url=<article-link>` — fetches the full article body
  (RSS only exposes a truncated excerpt).
- `GET /api/search?q=<query>` — searches Yerepouni via WordPress's REST
  API (results are cached briefly server-side; their search is slow).
- `GET /api/image?url=<image-url>` — streams an image with CORS headers,
  for platforms (Flutter web) that can't load it directly.
