#!/bin/bash
# ================================================================
#  🚀 CryptoLive — Promotion Automation
#  Generates unique marketing content with LIVE crypto prices,
#  trending coins, global market data, and latest news.
#  Usage: bash promote.sh [command]
#
#  Commands:
#    tweet       — Generate a tweet
#    reddit      — Generate a Reddit post
#    linkedin    — Generate a LinkedIn post
#    indie       — Generate an IndieHackers post
#    share       — Generate share text (WhatsApp/DM)
#    all         — Generate all content types
#    schedule    — Show today's promotion schedule
#    log         — Show posting history
# ================================================================

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/config.sh"

mkdir -p "$DIR/$POSTS_DIR"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
DATE_STAMP=$(date '+%Y-%m-%d')

# Globals for fetched data
BTC_PRICE="—"
BTC_CHANGE="—"
ETH_PRICE="—"
SOL_PRICE="—"
XRP_PRICE="—"
ADA_PRICE="—"
GLOBAL_MCAP="—"
GLOBAL_VOLUME="—"
BTC_DOM="—"
MCAP_CHANGE="—"
TRENDING_COIN="—"
TRENDING_SYMBOL="—"
TOP_GAINER="—"
TOP_GAINER_CHANGE="—"
TOP_LOSER="—"
TOP_LOSER_CHANGE="—"
NEWS_HEADLINE=""
NEWS_SOURCE=""

# ================================================================
#  VARIANT PICKER — picks 1..N based on date for daily consistency
# ================================================================
pick_variant() {
    local max="$1"
    # Portable: use date directly as a number, no md5 dependency
    echo $(( ($(date '+%Y%m%d') % max) + 1 ))
}

# ================================================================
#  DATA FETCHING
# ================================================================

fetch_prices() {
    local url="$COINGECKO_API/simple/price?ids=bitcoin,ethereum,solana,cardano,ripple&vs_currencies=usd&include_24hr_change=true"
    local data
    data=$(curl -s --max-time 10 "$url" 2>/dev/null)

    if [ $? -ne 0 ] || [ -z "$data" ] || [ "$data" = "{}" ]; then
        echo "⚠️  Could not fetch live prices (rate limit?). Using fallback."
        return 1
    fi

    BTC_PRICE=$(echo "$data" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('bitcoin',{}).get('usd','—'))" 2>/dev/null)
    BTC_CHANGE=$(echo "$data" | python3 -c "import sys,json; d=json.load(sys.stdin); c=d.get('bitcoin',{}).get('usd_24h_change',0); print(f\"{c:+.2f}%\")" 2>/dev/null)
    ETH_PRICE=$(echo "$data" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('ethereum',{}).get('usd','—'))" 2>/dev/null)
    SOL_PRICE=$(echo "$data" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('solana',{}).get('usd','—'))" 2>/dev/null)
    XRP_PRICE=$(echo "$data" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('ripple',{}).get('usd','—'))" 2>/dev/null)
    ADA_PRICE=$(echo "$data" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('cardano',{}).get('usd','—'))" 2>/dev/null)

    [ -z "$BTC_PRICE" ] && BTC_PRICE="—"
    [ -z "$BTC_CHANGE" ] && BTC_CHANGE="—"
    [ -z "$ETH_PRICE" ] && ETH_PRICE="—"
    [ -z "$SOL_PRICE" ] && SOL_PRICE="—"
    [ -z "$XRP_PRICE" ] && XRP_PRICE="—"
    [ -z "$ADA_PRICE" ] && ADA_PRICE="—"
}

fetch_global_data() {
    local data
    data=$(curl -s --max-time 10 "$COINGECKO_API/global" 2>/dev/null)

    if [ $? -eq 0 ] && [ -n "$data" ] && [ "$data" != "{}" ]; then
        GLOBAL_MCAP=$(echo "$data" | python3 -c "import sys,json; d=json.load(sys.stdin).get('data',{}); print(d.get('total_market_cap',{}).get('usd','—'))" 2>/dev/null)
        GLOBAL_VOLUME=$(echo "$data" | python3 -c "import sys,json; d=json.load(sys.stdin).get('data',{}); print(d.get('total_volume',{}).get('usd','—'))" 2>/dev/null)
        BTC_DOM=$(echo "$data" | python3 -c "import sys,json; d=json.load(sys.stdin).get('data',{}); print(f\"{d.get('market_cap_percentage',{}).get('btc',0):.1f}%\")" 2>/dev/null)
        MCAP_CHANGE=$(echo "$data" | python3 -c "import sys,json; d=json.load(sys.stdin).get('data',{}); print(f\"{d.get('market_cap_change_percentage_24h_usd',0):+.2f}%\")" 2>/dev/null)
    fi
    [ -z "$GLOBAL_MCAP" ] && GLOBAL_MCAP="—"
    [ -z "$GLOBAL_VOLUME" ] && GLOBAL_VOLUME="—"
    [ -z "$BTC_DOM" ] && BTC_DOM="—"
    [ -z "$MCAP_CHANGE" ] && MCAP_CHANGE="—"
}

fetch_trending() {
    local data
    data=$(curl -s --max-time 10 "$COINGECKO_API/search/trending" 2>/dev/null)

    if [ $? -eq 0 ] && [ -n "$data" ] && [ "$data" != "{}" ]; then
        TRENDING_COIN=$(echo "$data" | python3 -c "
import sys,json
d=json.load(sys.stdin).get('coins',[])
if d:
    c=d[0].get('item',{})
    print(c.get('name','—'))
else:
    print('—')
" 2>/dev/null)
        TRENDING_SYMBOL=$(echo "$data" | python3 -c "
import sys,json
d=json.load(sys.stdin).get('coins',[])
if d:
    c=d[0].get('item',{})
    print(c.get('symbol','—').upper())
else:
    print('—')
" 2>/dev/null)
    fi
    [ -z "$TRENDING_COIN" ] && TRENDING_COIN="—"
    [ -z "$TRENDING_SYMBOL" ] && TRENDING_SYMBOL="—"
}

fetch_movers() {
    local data
    data=$(curl -s --max-time 10 "$COINGECKO_API/coins/markets?vs_currency=usd&order=volume_desc&per_page=30&page=1&price_change_percentage_24h" 2>/dev/null)

    if [ $? -eq 0 ] && [ -n "$data" ] && [ "$data" != "{}" ]; then
        # Top gainer and loser
        local gainers
        gainers=$(echo "$data" | python3 -c "
import sys,json
d=json.load(sys.stdin)
sorted_coins=sorted(d, key=lambda x: x.get('price_change_percentage_24h',0) or 0, reverse=True)
g=sorted_coins[0]
l=sorted_coins[-1]
print(f\"{g['name']}|{g['price_change_percentage_24h']:+.2f}%|{l['name']}|{l['price_change_percentage_24h']:+.2f}%\")
" 2>/dev/null)

        if [ -n "$gainers" ] && [ "$gainers" != "—" ]; then
            TOP_GAINER=$(echo "$gainers" | cut -d'|' -f1)
            TOP_GAINER_CHANGE=$(echo "$gainers" | cut -d'|' -f2)
            TOP_LOSER=$(echo "$gainers" | cut -d'|' -f3)
            TOP_LOSER_CHANGE=$(echo "$gainers" | cut -d'|' -f4)
        fi
    fi
    [ -z "$TOP_GAINER" ] && TOP_GAINER="—"
    [ -z "$TOP_GAINER_CHANGE" ] && TOP_GAINER_CHANGE="—"
    [ -z "$TOP_LOSER" ] && TOP_LOSER="—"
    [ -z "$TOP_LOSER_CHANGE" ] && TOP_LOSER_CHANGE="—"
}

fetch_news() {
    local data
    data=$(curl -s --max-time 8 "https://news.google.com/rss/search?q=cryptocurrency+bitcoin&hl=en-US&gl=US&ceid=US:en" 2>/dev/null)

    if [ $? -eq 0 ] && [ -n "$data" ]; then
        local results
        results=$(echo "$data" | python3 -c "
import sys, html
from xml.etree import ElementTree as ET
try:
    r=ET.fromstring(sys.stdin.read())
    items=r.findall('.//item')
    for i in items[:5]:
        title = html.unescape(i.find('title').text or '')
        source = html.unescape(i.find('source').text or '') if i.find('source') is not None else ''
        print(f'{title}|{source}')
except:
    pass
" 2>/dev/null)
        if [ -n "$results" ]; then
            NEWS_HEADLINE=$(echo "$results" | head -1 | cut -d'|' -f1)
            NEWS_SOURCE=$(echo "$results" | head -1 | cut -d'|' -f2)
        fi
    fi
    [ -z "$NEWS_HEADLINE" ] && NEWS_HEADLINE=""
    [ -z "$NEWS_SOURCE" ] && NEWS_SOURCE=""
}

fetch_all_data() {
    echo -e "${CYAN}📡 Fetching live crypto prices...${NC}"
    fetch_prices
    echo -e "${CYAN}📡 Fetching global market data...${NC}"
    fetch_global_data
    echo -e "${CYAN}📡 Fetching trending coins...${NC}"
    fetch_trending
    echo -e "${CYAN}📡 Fetching top movers...${NC}"
    fetch_movers
    echo -e "${CYAN}📡 Fetching latest news...${NC}"
    fetch_news
    echo -e "${GREEN}✅  All data loaded!${NC}"
    echo "    BTC: \$$BTC_PRICE ($BTC_CHANGE) | ETH: \$$ETH_PRICE | SOL: \$$SOL_PRICE"
    echo "    Trending: $TRENDING_COIN ($TRENDING_SYMBOL)"
    echo "    Top gainer: $TOP_GAINER ($TOP_GAINER_CHANGE)"
    if [ -n "$NEWS_HEADLINE" ]; then
        echo "    📰 $NEWS_HEADLINE"
    fi
}

# === Format helpers ===
format_price() {
    local price="$1"
    if [ "$price" = "—" ]; then echo "—"; return; fi
    echo "$price" | awk '{
        if ($1 >= 1) printf("$%\047.2f", $1);
        else printf("$%.4f", $1);
    }' 2>/dev/null || echo "$$price"
}

format_large() {
    local n="$1"
    if [ "$n" = "—" ]; then echo "—"; return; fi
    echo "$n" | awk '{
        if ($1 >= 1e12) printf("$%.2fT", $1/1e12);
        else if ($1 >= 1e9) printf("$%.2fB", $1/1e9);
        else if ($1 >= 1e6) printf("$%.2fM", $1/1e6);
        else printf("$%.0f", $1);
    }' 2>/dev/null || echo "$$n"
}

btc_arrow() {
    if [ "$BTC_CHANGE" = "—" ]; then echo ""; return; fi
    local sign
    sign=$(echo "$BTC_CHANGE" | head -c 1)
    if [ "$sign" = "+" ]; then echo "📈"; else echo "📉"; fi
}

btc_sign() {
    if [ "$BTC_CHANGE" = "—" ]; then echo ""; return; fi
    local sign
    sign=$(echo "$BTC_CHANGE" | head -c 1)
    if [ "$sign" = "+" ]; then echo "🟢"; else echo "🔴"; fi
}

# ================================================================
#  CONTENT GENERATORS — each has 3 variants for unique content
# ================================================================

generate_tweet() {
    local v
    v=$(pick_variant 3)

    local btc_fmt eth_fmt
    btc_fmt=$(format_price "$BTC_PRICE")
    eth_fmt=$(format_price "$ETH_PRICE")
    local arrow
    arrow=$(btc_arrow)
    local sign
    sign=$(btc_sign)
    local mcap_fmt
    mcap_fmt=$(format_large "$GLOBAL_MCAP")

    case $v in
        1)
            # Hook: News + Live Price
            cat << TWEET_EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🐦  TWEET (copy & paste)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📰 ${NEWS_HEADLINE:-Crypto market is moving}

Bitcoin $arrow $btc_fmt ($BTC_CHANGE 24h)
Market cap: $mcap_fmt | BTC dominance: $BTC_DOM

Track all 50 coins live → $SITE_URL
Free • No signup • Auto-refresh

#Bitcoin #CryptoNews #Ethereum #Solana

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

TWEET_EOF
            ;;
        2)
            # Hook: Trending coin spotlight
            cat << TWEET_EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🐦  TWEET (copy & paste)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔥 Trending on CoinGecko: $TRENDING_COIN ($TRENDING_SYMBOL)

Bitcoin $arrow $btc_fmt ($BTC_CHANGE 24h)
Ethereum: $eth_fmt

See what's moving → $SITE_URL
Live prices • No bloat • No signup

#Bitcoin #Crypto #Altcoins #Trending

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

TWEET_EOF
            ;;
        3)
            # Hook: Top mover
            cat << TWEET_EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🐦  TWEET (copy & paste)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Today's biggest movers:
🟢 $TOP_GAINER $TOP_GAINER_CHANGE
🔴 $TOP_LOSER $TOP_LOSER_CHANGE

Bitcoin $arrow $btc_fmt ($BTC_CHANGE 24h)

Track every coin in real-time → $SITE_URL
Auto-refresh • Free • No signup

#Bitcoin #Crypto #Altcoins #Trading

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

TWEET_EOF
            ;;
    esac
}

generate_reddit_post() {
    local v
    v=$(pick_variant 3)

    local btc_fmt eth_fmt sol_fmt ada_fmt
    btc_fmt=$(format_price "$BTC_PRICE")
    eth_fmt=$(format_price "$ETH_PRICE")
    sol_fmt=$(format_price "$SOL_PRICE")
    ada_fmt=$(format_price "$ADA_PRICE")
    local arrow
    arrow=$(btc_arrow)
    local mcap_fmt vol_fmt
    mcap_fmt=$(format_large "$GLOBAL_MCAP")
    vol_fmt=$(format_large "$GLOBAL_VOLUME")

    case $v in
        1)
            # Story: News-driven
            cat << REDDIT_EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🤖  REDDIT POST  (copy & paste)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Title:
Crypto market update: ${NEWS_HEADLINE:-crypto is heating up} — plus a free tool to track it live

Body:

Saw this headline earlier and wanted to share my thoughts:

📰 "${NEWS_HEADLINE:-Crypto market update}"

Meanwhile here's where the market stands as of now:

• BTC: $btc_fmt ($BTC_CHANGE 24h) $arrow
• ETH: $eth_fmt
• SOL: $sol_fmt
• ADA: $ada_fmt

Global crypto market cap: $mcap_fmt
24h volume: $vol_fmt
BTC dominance: $BTC_DOM

I've been using $SITE_URL to track prices in real-time. It auto-refreshes every 60s, shows the top 50 coins, and has no ads or signup — just clean data. Click any coin for detailed stats (market cap, volume, 24h high/low, ATH).

Not selling anything, just sharing a tool I built and use daily. Would love your thoughts!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

REDDIT_EOF
            ;;
        2)
            # Story: Trending coin spotlight
            cat << REDDIT_EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🤖  REDDIT POST  (copy & paste)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Title:
$TRENDING_COIN ($TRENDING_SYMBOL) is trending on CoinGecko right now — here's what the rest of the market looks like

Body:

Noticed that $TRENDING_COIN is trending on CoinGecko at the moment. Here's a quick snapshot of the broader market:

• BTC: $btc_fmt ($BTC_CHANGE 24h)
• ETH: $eth_fmt
• SOL: $sol_fmt
• XRP: $(format_price "$XRP_PRICE")

📊 Market stats:
• Total market cap: $mcap_fmt
• 24h volume: $vol_fmt
• BTC dominance: $BTC_DOM
• Market cap change (24h): $MCAP_CHANGE

I built $SITE_URL to track all of this without the bloat of other sites. It loads instantly, updates every 60 seconds, and works great on mobile. No signup required, no affiliate nonsense.

Check it out if you want a cleaner way to watch the market. Feedback always welcome!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

REDDIT_EOF
            ;;
        3)
            # Story: Market movers + pain point
            cat << REDDIT_EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🤖  REDDIT POST  (copy & paste)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Title:
Today's top movers: $TOP_GAINER (+$TOP_GAINER_CHANGE) and $TOP_LOSER ($TOP_LOSER_CHANGE) — plus a quick market overview

Body:

Checking the crypto market and here's what's happening right now:

📈 Top gainer: $TOP_GAINER ($TOP_GAINER_CHANGE)
📉 Top loser: $TOP_LOSER ($TOP_LOSER_CHANGE)

Bitcoin: $btc_fmt ($BTC_CHANGE 24h)
Ethereum: $eth_fmt
Solana: $sol_fmt

Global market cap: $mcap_fmt (${MCAP_CHANGE} 24h)
BTC dominance: $BTC_DOM

I got tired of sites loading tons of ads and scripts just to show prices, so I built $SITE_URL — a lightweight tracker that shows top 50 coins with auto-refresh, search, sparkline charts, and detailed stats for each coin.

Free, no signup, no BS. Just a tool I actually use every day.

Would love to hear what you think! 🫡

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

REDDIT_EOF
            ;;
    esac
}

generate_linkedin_post() {
    local v
    v=$(pick_variant 3)

    local btc_fmt eth_fmt
    btc_fmt=$(format_price "$BTC_PRICE")
    eth_fmt=$(format_price "$ETH_PRICE")
    local arrow mcap_fmt
    arrow=$(btc_arrow)
    mcap_fmt=$(format_large "$GLOBAL_MCAP")

    case $v in
        1)
            # Angle: News + Market insight
            cat << LINKEDIN_EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  💼  LINKEDIN POST  (copy & paste)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📰 ${NEWS_HEADLINE:-Interesting development in crypto today}

Meanwhile, the numbers:
• Bitcoin $arrow $btc_fmt ($BTC_CHANGE 24h)
• Global crypto market cap: $mcap_fmt
• BTC dominance: $BTC_DOM

I track all this (and 50+ coins) in real-time using a lightweight tool I built: $SITE_URL

It auto-refreshes every 60 seconds, works on mobile, and requires zero signup. No bloat, no premium tier — just live data.

If you follow the crypto space, give it a shot. Would love your feedback! 🚀

#Crypto #Bitcoin #Blockchain #FinTech #WebDev

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

LINKEDIN_EOF
            ;;
        2)
            # Angle: Trending + builder story
            cat << LINKEDIN_EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  💼  LINKEDIN POST  (copy & paste)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔥 $TRENDING_COIN ($TRENDING_SYMBOL) is trending in crypto right now.

Here's the market at a glance:
• Bitcoin $arrow $btc_fmt ($BTC_CHANGE 24h)
• Ethereum: $eth_fmt
• Market cap: $mcap_fmt

I built $SITE_URL over a weekend to track these numbers without signing up for anything or waiting for ads to load. It's been getting steady organic traffic ever since.

Stack: CoinGecko API + vanilla JS + GitHub Pages = $0 server cost.

If you're curious about the crypto space or just want a cleaner way to check prices, try it out. Completely free, no catch.

#Bitcoin #Crypto #SideProject #IndieDev #JavaScript

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

LINKEDIN_EOF
            ;;
        3)
            # Angle: Market movers + value prop
            cat << LINKEDIN_EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  💼  LINKEDIN POST  (copy & paste)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Today's crypto market snapshot:

🟢 Top gainer: $TOP_GAINER ($TOP_GAINER_CHANGE)
🔴 Top loser: $TOP_LOSER ($TOP_LOSER_CHANGE)
• Bitcoin $arrow $btc_fmt ($BTC_CHANGE 24h)
• Market cap: $mcap_fmt

I've been tracking crypto for years, and the biggest problem is that most price trackers are bloated with ads, popups, and signup walls.

So I built $SITE_URL — a fast, free tracker that shows you what matters: live prices, charts, and market data. No account needed, refreshes automatically, works on any device.

If you trade or just follow crypto, check it out. Built it for myself, sharing it with anyone who finds it useful.

#Crypto #Bitcoin #Trading #Technology #Productivity

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

LINKEDIN_EOF
            ;;
    esac
}

generate_indiehackers_post() {
    local v
    v=$(pick_variant 3)

    local btc_fmt
    btc_fmt=$(format_price "$BTC_PRICE")
    local mcap_fmt
    mcap_fmt=$(format_large "$GLOBAL_MCAP")

    case $v in
        1)
            # Angle: Tech stack + traffic
            cat << IH_EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🏗️  INDIEMAKERS / INDIEHACKERS POST
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Title: My free crypto tracker gets daily traffic — $0 server cost using CoinGecko + GitHub Pages

Body:

Launched $SITE_URL as a weekend project and it's been getting consistent organic traffic ever since.

The stack:
→ CoinGecko API (free, no key needed)
→ Vanilla JS (no framework, single HTML file)
→ GitHub Pages (free hosting, custom domain)
→ Google AdSense (auto-ads integrated)

Current market snapshot:
• BTC: $btc_fmt
• Global market cap: $mcap_fmt
• Trending: $TRENDING_COIN ($TRENDING_SYMBOL)
• 📰 "${NEWS_HEADLINE:-Crypto market update}"

Features users engage with most:
• Auto-refresh every 60s — keeps them coming back
• Search by name/ticker — utility
• Sparkline charts — visual appeal
• Expandable detail panels — depth
• Favorites system — builds habit

What I'd do differently:
• Add push notifications for price alerts
• Add a portfolio tracker (but that needs a backend)
• More social sharing features

Would love feedback from this community! 🔗 $SITE_URL

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

IH_EOF
            ;;
        2)
            # Angle: Growth/monetization
            cat << IH_EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🏗️  INDIEMAKERS / INDIEHACKERS POST
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Title: Building a free AdSense-supported crypto tracker — the numbers so far

Body:

Here's my progress with $SITE_URL, a zero-cost crypto price tracker monetized through AdSense:

Stack:
• CoinGecko API (free)
• Vanilla JS (no framework)
• GitHub Pages (free hosting)
• AdSense auto-ads

Market right now:
• BTC: $btc_fmt ($BTC_CHANGE 24h)
• BTC dominance: $BTC_DOM
• Top gainer: $TOP_GAINER ($TOP_GAINER_CHANGE)
• Global market cap: $mcap_fmt

What's working:
• Auto-refresh creates repeat visits
• No signup = lower bounce rate
• Dark mode = better retention
• Mobile-first design = more page views

Key lesson: You don't need VC funding or a complex backend to build something useful. One HTML file, one free API, zero server costs.

What tools are you using to keep your projects at $0? 👇

🔗 $SITE_URL

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

IH_EOF
            ;;
        3)
            # Angle: Build story + learnings
            cat << IH_EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🏗️  INDIEMAKERS / INDIEHACKERS POST
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Title: I spent a weekend building a crypto tracker and learned more about SEO than coding

Body:

$SITE_URL started as a simple project: a page that shows live crypto prices. What surprised me was how much I learned about growth, not just dev.

The product:
• Single HTML file
• CoinGecko free API
• GitHub Pages hosting
• $0 operating cost

Current stats: organic traffic from search, steady growth, AdSense applied.

Market check:
• BTC: $btc_fmt ($BTC_CHANGE 24h)
• Trending: $TRENDING_COIN
• 📰 ${NEWS_HEADLINE:-Crypto market update}

Biggest learnings:
1. SEO matters more than features — clean meta tags and fast load times drove most traffic
2. Auto-refresh is a retention hack — people leave the tab open
3. No signup = better conversion — zero friction wins
4. GitHub Pages + Cloudflare = bulletproof for $0
5. AdSense approval is achievable with original content

What weekend project surprised you with unexpected traffic?

🔗 $SITE_URL

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

IH_EOF
            ;;
    esac
}

generate_share_text() {
    local v
    v=$(pick_variant 3)

    local btc_fmt
    btc_fmt=$(format_price "$BTC_PRICE")
    local arrow
    arrow=$(btc_arrow)

    case $v in
        1)
            cat << SHARE_EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📱  QUICK SHARE TEXT (WhatsApp / DM / SMS)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Hey! Check out this free crypto price tracker I built 👇
$SITE_URL

📰 ${NEWS_HEADLINE:-Check this free crypto tracker out}
BTC $arrow $btc_fmt ($BTC_CHANGE 24h)

Tracks 50+ coins, auto-refreshes, no signup. Just works! 🚀

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SHARE_EOF
            ;;
        2)
            cat << SHARE_EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📱  QUICK SHARE TEXT (WhatsApp / DM / SMS)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Hey! This crypto tracker I built is completely free and shows live prices for 50+ coins:

$SITE_URL

🔥 $TRENDING_COIN is trending right now
BTC $arrow $btc_fmt ($BTC_CHANGE 24h)

No signup needed, just open and watch 🚀

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SHARE_EOF
            ;;
        3)
            cat << SHARE_EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📱  QUICK SHARE TEXT (WhatsApp / DM / SMS)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Hey! If you're into crypto, you'll like this free tracker I made:

$SITE_URL

📈 $TOP_GAINER is up $TOP_GAINER_CHANGE today
BTC $arrow $btc_fmt ($BTC_CHANGE 24h)

Live prices, auto-refresh, zero ads. Bookmark it! 🚀

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SHARE_EOF
            ;;
    esac
}

# ================================================================
#  SCHEDULER
# ================================================================

show_schedule() {
    local day_of_week
    day_of_week=$(LC_ALL=C date '+%A')

    echo ""
    echo "╔══════════════════════════════════════════════╗"
    echo "║     📅  TODAY'S PROMOTION SCHEDULE           ║"
    echo "║     $DATE_STAMP ($day_of_week)                  ║"
    echo "╚══════════════════════════════════════════════╝"
    echo ""

    case $day_of_week in
        Monday)
            echo "  🐦  Post a Tweet with current prices"
            echo "  📋  Check Google Search Console for new keywords"
            echo "  📝  Log your weekly traffic in the tracker"
            ;;
        Tuesday)
            echo "  📱  Share on WhatsApp / DM to 3 friends"
            echo "  🔍  Find 2 crypto-related tweets to reply to"
            ;;
        Wednesday)
            echo "  🐦  Post a Tweet (different angle than Monday)"
            echo "  🏗️  Post on IndieMakers / IndieHackers"
            ;;
        Thursday)
            echo "  📱  Quick share text — send to 1 group chat"
            echo "  🔍  Find 2 more tweets to reply to"
            ;;
        Friday)
            echo "  💼  Post on LinkedIn"
            echo "  📋  Check GA4 traffic for the week"
            echo "  📝  Plan next week's content"
            ;;
        Saturday)
            echo "  🎯  Day off — or cross-post to any platform you missed"
            echo "  📊  Review weekly promotion log"
            ;;
        Sunday)
            echo "  🧘  Day off — let your SEO work"
            echo "  ✍️  Optional: draft ideas for next week"
            ;;
    esac

    echo ""
    echo "  ⏰  Total time today: ~5-10 minutes"
    echo ""
}

# ================================================================
#  LOGGING
# ================================================================

log_action() {
    local platform="$1"
    local type="$2"
    echo "[$TIMESTAMP] $platform — $type" >> "$DIR/$LOG_FILE"
    echo -e "${GREEN}✓${NC} Logged: $platform — $type"
}

show_log() {
    if [ ! -f "$DIR/$LOG_FILE" ]; then
        echo "📭  No promotion activity logged yet."
        echo "    Run 'bash promote.sh tweet' to get started!"
        return
    fi
    echo ""
    echo "╔══════════════════════════════════════════════╗"
    echo "║     📋  PROMOTION LOG                        ║"
    echo "╚══════════════════════════════════════════════╝"
    echo ""
    tail -20 "$DIR/$LOG_FILE"
    echo ""
    echo "Total posts logged: $(wc -l < "$DIR/$LOG_FILE")"
    echo ""
}

# ================================================================
#  MAIN
# ================================================================

# Check for python3
if ! command -v python3 &>/dev/null; then
    echo -e "${RED}⚠️  python3 is required for JSON parsing.${NC}"
    echo "Install it: brew install python3"
    exit 1
fi

CMD="${1:-help}"

case "$CMD" in
    tweet)
        fetch_all_data
        echo ""
        generate_tweet
        log_action "Twitter" "Generated tweet (BTC: \$$BTC_PRICE)"
        generate_tweet > "$DIR/$POSTS_DIR/tweet_$DATE_STAMP.txt"
        echo -e "${GREEN}✅  Saved to $POSTS_DIR/tweet_$DATE_STAMP.txt${NC}"
        ;;

    reddit)
        fetch_all_data
        echo ""
        generate_reddit_post
        log_action "Reddit" "Generated Reddit post"
        generate_reddit_post > "$DIR/$POSTS_DIR/reddit_$DATE_STAMP.txt"
        echo -e "${GREEN}✅  Saved to $POSTS_DIR/reddit_$DATE_STAMP.txt${NC}"
        ;;

    linkedin)
        fetch_all_data
        echo ""
        generate_linkedin_post
        log_action "LinkedIn" "Generated LinkedIn post"
        generate_linkedin_post > "$DIR/$POSTS_DIR/linkedin_$DATE_STAMP.txt"
        echo -e "${GREEN}✅  Saved to $POSTS_DIR/linkedin_$DATE_STAMP.txt${NC}"
        ;;

    indie)
        fetch_all_data
        echo ""
        generate_indiehackers_post
        log_action "IndieMakers" "Generated IndieHackers post"
        generate_indiehackers_post > "$DIR/$POSTS_DIR/indie_$DATE_STAMP.txt"
        echo -e "${GREEN}✅  Saved to $POSTS_DIR/indie_$DATE_STAMP.txt${NC}"
        ;;

    share)
        fetch_all_data
        echo ""
        generate_share_text
        log_action "Share" "Generated share text"
        generate_share_text > "$DIR/$POSTS_DIR/share_$DATE_STAMP.txt"
        echo -e "${GREEN}✅  Saved to $POSTS_DIR/share_$DATE_STAMP.txt${NC}"
        ;;

    all)
        fetch_all_data
        echo ""
        echo "╔══════════════════════════════════════════════╗"
        echo "║     📢  GENERATING ALL CONTENT              ║"
        echo "╚══════════════════════════════════════════════╝"
        echo ""
        generate_tweet     > "$DIR/$POSTS_DIR/tweet_$DATE_STAMP.txt"
        echo "  ✅  Tweet saved"
        generate_reddit_post > "$DIR/$POSTS_DIR/reddit_$DATE_STAMP.txt"
        echo "  ✅  Reddit post saved"
        generate_linkedin_post > "$DIR/$POSTS_DIR/linkedin_$DATE_STAMP.txt"
        echo "  ✅  LinkedIn post saved"
        generate_indiehackers_post > "$DIR/$POSTS_DIR/indie_$DATE_STAMP.txt"
        echo "  ✅  IndieHackers post saved"
        generate_share_text > "$DIR/$POSTS_DIR/share_$DATE_STAMP.txt"
        echo "  ✅  Share text saved"
        echo ""
        log_action "All" "Generated all content types"
        echo -e "${GREEN}✅  All content saved to $POSTS_DIR/ for $DATE_STAMP${NC}"
        echo ""
        echo -e "${YELLOW}💡  Open the files in $POSTS_DIR/ and copy-paste each one manually.${NC}"
        ;;

    schedule)
        show_schedule
        ;;

    log)
        show_log
        ;;

    install-cron)
        echo ""
        echo "╔══════════════════════════════════════════════╗"
        echo "║     ⏰  INSTALL REMINDER CRON                ║"
        echo "╚══════════════════════════════════════════════╝"
        echo ""
        echo "To get a daily reminder to promote, add this to your crontab:"
        echo ""
        echo "  crontab -e"
        echo ""
        echo "Then paste this line (reminds you at 9am every day):"
        echo ""
        echo -e "  ${GREEN}0 9 * * * echo \"📢 Time to promote! Run: cd $(pwd) && bash promote.sh schedule\" | terminal-notifier -title \"CryptoLive Promotion\" -message \"Check your schedule\" 2>/dev/null || echo \"📢 Promote today! cd $(pwd) && bash promote.sh schedule\"${NC}"
        echo ""
        echo "  OR for a simpler reminder via terminal echo:"
        echo "  0 9 * * * echo \"🚀 CryptoLive Promotion — check promote.sh schedule\" > /dev/ttys000"
        echo ""
        echo "  To edit: crontab -e"
        echo "  To list: crontab -l"
        echo "  To remove: crontab -r"
        echo ""
        ;;

    help|*)
        echo ""
        echo "╔══════════════════════════════════════════════╗"
        echo "║     🚀  CryptoLive Promotion Automation     ║"
        echo "╚══════════════════════════════════════════════╝"
        echo ""
        echo "  Usage: bash promote.sh <command>"
        echo ""
        echo "  Commands:"
        echo "    tweet           Generate a tweet with live data"
        echo "    reddit          Generate a Reddit post"
        echo "    linkedin        Generate a LinkedIn post"
        echo "    indie           Generate an IndieHackers post"
        echo "    share           Generate share text (WhatsApp/DM)"
        echo "    all             Generate ALL content types at once"
        echo "    schedule        Show today's promotion schedule"
        echo "    log             Show posting history"
        echo "    install-cron    Install daily reminder"
        echo "    help            Show this menu"
        echo ""
        echo "  Each run fetches: latest crypto news, trending coins,"
        echo "  global market data, and live prices — completely unique"
        echo "  content generated fresh every day."
        echo ""
        echo "  Examples:"
        echo "    bash promote.sh tweet          →  Generate tweet"
        echo "    bash promote.sh all            →  Generate all content"
        echo "    bash promote.sh schedule       →  What to post today"
        echo ""
        echo "  First time? Edit config.sh with your site info, then:"
        echo "    bash promote.sh all    →  Open files in generated_posts/ and paste"
        echo ""
        ;;
esac

exit 0
