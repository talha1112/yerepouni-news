# Yerepouni News — live RSS app prototype

This version implements the mobile-first app shell and a small RSS proxy layer.

## Run locally
1. Install Node.js 18+.
2. In this folder run:
   npm install
   npm start
3. Open http://localhost:3000

The app uses the Yerepouni WordPress URLs in `config.json`, including:
- Western Armenian general: https://www.yerepouni-news.com/category/western-armenian/
- Featured: https://www.yerepouni-news.com/category/mobile-home/
- Category feeds derived from the supplied Excel file.

The proxy only permits `www.yerepouni-news.com` to avoid turning the endpoint into a general open proxy.

## Current behavior
- Western Armenian is the default edition.
- Menu: 3 languages, each expanding to its own Excel-provided categories.
- Featured News loads from mobile-home.
- Latest News loads from the current edition.
- AFHIL logo is inserted after every 5 latest articles.
- Article cards open the original WordPress article.
- Search and “ՊԱՏՄՈՒԹԵԱՆ ՄԷՋ ԱՅՍՕՐ” are placeholders for later integration.
