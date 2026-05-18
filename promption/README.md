# 🚀 CryptoLive — Promotion Automation

**Zero-cost promotion scripts** that generate ready-to-post content with **live crypto prices** pulled from the CoinGecko API.

## Quick Start

```bash
# 1. Configure your site
nano config.sh          # Set your SITE_URL, Twitter handle, etc.

# 2. Generate a tweet with the current Bitcoin price
bash promote.sh tweet

# 3. Generate everything at once
bash promote.sh all

# 4. See what to post today
bash promote.sh schedule

# 5. View your posting history
bash promote.sh log
```

## Commands

| Command | What it does |
|---------|-------------|
| `bash promote.sh tweet` | Generates a tweet with BTC price + chart arrows |
| `bash promote.sh reddit` | Reddit post with price table + backstory |
| `bash promote.sh linkedin` | Professional LinkedIn post |
| `bash promote.sh indie` | IndieHackers / IndieMakers post |
| `bash promote.sh share` | Quick WhatsApp/DM text |
| `bash promote.sh all` | Generates ALL content types at once |
| `bash promote.sh schedule` | Shows today's daily promotion plan |
| `bash promote.sh log` | Shows your posting history |
| `bash promote.sh install-cron` | Instructions for daily reminders |

## How It Works

1. **Fetches live prices** from CoinGecko's free API (BTC, ETH, SOL)
2. **Generates platform-specific content** with those prices baked in
3. **Saves to `generated_posts/`** as text files — you copy & paste manually
4. **Logs every action** so you know what you generated and when

> ⚠️ **No auto-posting.** API-based posting has been removed due to issues with social platform APIs.
> All content is saved to plain text files for manual copy-paste.

## Daily Routine (~5 min/day)

```
Monday:    Tweet + check Google Search Console
Tuesday:   Share on WhatsApp + reply to 2 tweets
Wednesday: Tweet + post on IndieMakers
Thursday:  Share + reply to tweets
Friday:    LinkedIn + check GA4 traffic
Saturday:  Catch-up / review log
Sunday:    Rest
```

## $0 Cost Breakdown

| Item | Cost |
|------|------|
| Hosting (GitHub Pages) | Free |
| CoinGecko API | Free |
| Content generation | Free |
| Manual posting (your time) | Free |
| **Total** | **$0** |
