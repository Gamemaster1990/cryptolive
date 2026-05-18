# CryptoLive — Real-Time Cryptocurrency Price Tracker

A single-page, zero-maintenance cryptocurrency price tracker powered by the **free CoinGecko API** (no API key needed).

## ✨ Features

- **Live prices** — top 50 cryptocurrencies by market cap, updated every 60 seconds
- **Auto-refresh** — pauses when tab is hidden, resumes when visible
- **Search/filter** — filter by name or symbol instantly
- **Responsive** — works on mobile, tablet, desktop
- **Dark theme** — easy on the eyes, crypto-standard aesthetic
- **AdSense ready** — placeholders for AdSense auto-ads included
- **SEO optimized** — meta tags, Open Graph, Twitter cards, sitemap
- **$0 hosting** — works on GitHub Pages, Vercel, Netlify, Cloudflare Pages

## 🚀 Deployment (GitHub Pages — Free)

1. **Push to GitHub:**
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
   git push -u origin main
   ```

2. **Enable GitHub Pages:**
   - Go to repo → Settings → Pages
   - Source: Deploy from a branch
   - Branch: `main`, folder: `/ (root)`
   - Save → your site is live at `https://YOUR_USERNAME.github.io/YOUR_REPO/`

## 🛠️ Customization

### AdSense
Open `index.html` and replace:
- `ca-pub-YOUR_PUBLISHER_ID` with your actual AdSense publisher ID
- The placeholder text inside the ad containers with real AdSense ad units

### Domain
- Update `https://yourdomain.com/` in `index.html` (canonical URL) and `sitemap.xml`
- For GitHub Pages, you can use your `.github.io` URL or set up a custom domain

### CoinGecko API
The free API is rate-limited (10-30 calls/min). The site refreshes every 60 seconds, well within limits. No API key required.

## 📄 Files

| File | Purpose |
|------|---------|
| `index.html` | Main page (all CSS + JS embedded) |
| `sitemap.xml` | SEO sitemap for search engines |
| `README.md` | This file |

## 📈 Monetization Tips

1. **Apply for Google AdSense** once you have some traffic
2. **Submit to Google Search Console** for indexing
3. **Promote free** on Reddit (r/CryptoCurrency, r/CryptoMarkets), Twitter/X, and crypto forums
4. **Add Google Analytics** to track traffic

## ⚠️ Disclaimer

Cryptocurrency data is provided by CoinGecko's public API. Prices may be delayed. Not financial advice.

---

Built with ❤️ using the free CoinGecko API. Zero server costs, zero maintenance.
