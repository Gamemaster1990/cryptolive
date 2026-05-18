#!/bin/bash
# ================================================================
#  🚀 CryptoLive — Promotion Automation
#  Generates ready-to-post content with LIVE crypto prices
#  Usage: bash promote.sh [command]
#
#  Commands:
#    tweet       — Generate a tweet with current Bitcoin price
#    reddit      — Generate a Reddit post
#    all         — Generate all content types
#    schedule    — Show today's promotion schedule
#    log         — Show posting history
# ================================================================

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/config.sh"

mkdir -p "$DIR/$POSTS_DIR"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
DATE_STAMP=$(date '+%Y-%m-%d')

# --- Fetch live crypto data from CoinGecko ---
fetch_crypto_data() {
    local url="$COINGECKO_API/simple/price?ids=bitcoin,ethereum,solana,cardano,ripple&vs_currencies=usd&include_24hr_change=true"
    local data

    data=$(curl -s --max-time 10 "$url" 2>/dev/null)

    if [ $? -ne 0 ] || [ -z "$data" ] || [ "$data" = "{}" ]; then
        echo "⚠️  Could not fetch live prices (rate limit?). Using fallback."
        BTC_PRICE="—"
        BTC_CHANGE="—"
        ETH_PRICE="—"
        SOL_PRICE="—"
        return 1
    fi

    BTC_PRICE=$(echo "$data" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('bitcoin',{}).get('usd','—'))" 2>/dev/null)
    BTC_CHANGE=$(echo "$data" | python3 -c "import sys,json; d=json.load(sys.stdin); c=d.get('bitcoin',{}).get('usd_24h_change',0); print(f\"{c:+.2f}%\")" 2>/dev/null)
    ETH_PRICE=$(echo "$data" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('ethereum',{}).get('usd','—'))" 2>/dev/null)
    SOL_PRICE=$(echo "$data" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('solana',{}).get('usd','—'))" 2>/dev/null)

    [ -z "$BTC_PRICE" ] && BTC_PRICE="—"
    [ -z "$BTC_CHANGE" ] && BTC_CHANGE="—"
    [ -z "$ETH_PRICE" ] && ETH_PRICE="—"
    [ -z "$SOL_PRICE" ] && SOL_PRICE="—"
}

# --- Format price with commas ---
format_price() {
    local price="$1"
    if [ "$price" = "—" ]; then echo "—"; return; fi
    # Format with 2 decimal places if >= 1, else 4 decimal places
    # Format with 2 decimal places if >= 1, else show raw
    # Use awk for portable number formatting
    echo "$price" | awk '{
        if ($1 >= 1) printf("$%\047.2f", $1);
        else printf("$%.4f", $1);
    }' 2>/dev/null || echo "\$$price"
}

# ================================================================
#  CONTENT GENERATORS
# ================================================================

generate_tweet() {
    local btc_fmt btc_sign btc_arrow
    btc_fmt=$(format_price "$BTC_PRICE")

    if [ "$BTC_CHANGE" != "—" ]; then
        btc_sign=$(echo "$BTC_CHANGE" | head -c 1)
        if [ "$btc_sign" = "+" ]; then
            btc_arrow="📈"
        else
            btc_arrow="📉"
        fi
    else
        btc_arrow=""
    fi

    cat << TWEET_EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🐦  TWEET  (copy & paste)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Bitcoin $btc_arrow $btc_fmt ($BTC_CHANGE 24h)

Track live prices for BTC, ETH, SOL & more in real-time.
Free • No signup • Auto-refresh

👉 $SITE_URL

#Bitcoin #Crypto #Ethereum #Solana #FreeTool

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

TWEET_EOF
}

generate_reddit_post() {
    local btc_fmt
    btc_fmt=$(format_price "$BTC_PRICE")

    cat << REDDIT_EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🤖  REDDIT POST  (copy & paste)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Title:
I built a lightweight, free crypto price tracker that refreshes itself — no ads, no signup

Body:

I got tired of CoinMarketCap and CoinGecko loading tons of scripts and ads on mobile, so I built this: $SITE_URL

• Top 50 coins by market cap
• Auto-refreshes every 60 seconds
• Dark mode, works on mobile
• Search any coin instantly
• No ads (for now), no signup, no bloat

BTC: $btc_fmt (24h: $BTC_CHANGE)
ETH: $(format_price "$ETH_PRICE")
SOL: $(format_price "$SOL_PRICE")

Just thought some of you might find it useful. Feedback welcome!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

REDDIT_EOF
}

generate_linkedin_post() {
    local btc_fmt
    btc_fmt=$(format_price "$BTC_PRICE")

    cat << LINKEDIN_EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  💼  LINKEDIN POST  (copy & paste)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

I built a free cryptocurrency price tracker over a weekend — and I'm sharing it with you.

No signup required. No ads. No bloat. Just live prices that auto-refresh.

Bitcoin is at $btc_fmt right now ($BTC_CHANGE 24h).

Check it out: $SITE_URL

Built with the free CoinGecko API and hosted on GitHub Pages — zero server costs, zero maintenance.

Would love your feedback! 🚀

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

LINKEDIN_EOF
}

generate_share_text() {
    cat << SHARE_EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📱  QUICK SHARE TEXT (WhatsApp / DM / SMS)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Check out this free crypto price tracker I built:
$SITE_URL
No signup, no ads, just live prices. 🚀

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SHARE_EOF
}

generate_indiehackers_post() {
    cat << IH_EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🏗️  INDIEMAKERS / INDIEHACKERS POST
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Title: Launched a free crypto tracker — built in a weekend with zero server costs

Body:
Stack: Vanilla JS + CoinGecko free API + GitHub Pages (free hosting)

• Single HTML file (no build tools)
• Auto-refresh every 60s
• Dark mode
• AdSense-ready for monetization later

BTC: $(format_price "$BTC_PRICE") ($BTC_CHANGE 24h)

Would love your feedback: $SITE_URL

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

IH_EOF
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

# Check for jq or python3 for JSON parsing
if ! command -v python3 &>/dev/null; then
    echo -e "${RED}⚠️  python3 is required for JSON parsing.${NC}"
    echo "Install it: brew install python3"
    exit 1
fi

# Parse command
CMD="${1:-help}"

case "$CMD" in
    tweet)
        echo -e "${CYAN}📡 Fetching live crypto prices...${NC}"
        fetch_crypto_data
        echo -e "${GREEN}✅  Live data loaded!${NC}"
        echo "    BTC: \$$BTC_PRICE  |  ETH: \$$ETH_PRICE  |  SOL: \$$SOL_PRICE"
        echo ""
        generate_tweet
        log_action "Twitter" "Generated tweet (BTC: \$$BTC_PRICE)"
        # Save to file
        generate_tweet > "$DIR/$POSTS_DIR/tweet_$DATE_STAMP.txt"
        echo -e "${GREEN}✅  Saved to $POSTS_DIR/tweet_$DATE_STAMP.txt${NC}"
        echo -e "${YELLOW}💡  Pro-tip: Schedule this tweet with the Twitter web app for best timing (8-10am ET)${NC}"
        ;;

    reddit)
        echo -e "${CYAN}📡 Fetching live crypto prices...${NC}"
        fetch_crypto_data
        echo -e "${GREEN}✅  Live data loaded!${NC}"
        echo "    BTC: \$$BTC_PRICE  |  ETH: \$$ETH_PRICE  |  SOL: \$$SOL_PRICE"
        echo ""
        generate_reddit_post
        log_action "Reddit" "Generated Reddit post"
        generate_reddit_post > "$DIR/$POSTS_DIR/reddit_$DATE_STAMP.txt"
        echo -e "${GREEN}✅  Saved to $POSTS_DIR/reddit_$DATE_STAMP.txt${NC}"
        echo -e "${YELLOW}💡  Tip: Post to r/CryptoCurrency, r/SideProject, or r/InternetIsBeautiful${NC}"
        ;;

    linkedin)
        echo -e "${CYAN}📡 Fetching live crypto prices...${NC}"
        fetch_crypto_data
        echo -e "${GREEN}✅  Live data loaded!${NC}"
        echo ""
        generate_linkedin_post
        log_action "LinkedIn" "Generated LinkedIn post"
        generate_linkedin_post > "$DIR/$POSTS_DIR/linkedin_$DATE_STAMP.txt"
        echo -e "${GREEN}✅  Saved to $POSTS_DIR/linkedin_$DATE_STAMP.txt${NC}"
        ;;

    indie)
        echo -e "${CYAN}📡 Fetching live crypto prices...${NC}"
        fetch_crypto_data
        echo -e "${GREEN}✅  Live data loaded!${NC}"
        echo ""
        generate_indiehackers_post
        log_action "IndieMakers" "Generated IndieHackers post"
        generate_indiehackers_post > "$DIR/$POSTS_DIR/indie_$DATE_STAMP.txt"
        echo -e "${GREEN}✅  Saved to $POSTS_DIR/indie_$DATE_STAMP.txt${NC}"
        ;;

    share)
        echo ""
        generate_share_text
        log_action "Share" "Generated share text"
        generate_share_text > "$DIR/$POSTS_DIR/share_$DATE_STAMP.txt"
        echo -e "${GREEN}✅  Saved to $POSTS_DIR/share_$DATE_STAMP.txt${NC}"
        ;;

    all)
        echo -e "${CYAN}📡 Fetching live crypto prices...${NC}"
        fetch_crypto_data
        echo -e "${GREEN}✅  Live data loaded!${NC}"
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
        echo "    tweet       Generate a tweet with live BTC price"
        echo "    reddit      Generate a Reddit post with live prices"
        echo "    linkedin    Generate a LinkedIn post"
        echo "    indie       Generate an IndieHackers/IndieMakers post"
        echo "    share       Generate quick share text (WhatsApp/DM)"
        echo "    all         Generate ALL content types at once"
        echo "    schedule    Show today's promotion schedule"
        echo "    log         Show posting history"
        echo "    install-cron  Install daily reminder"
        echo "    help        Show this menu"
        echo ""
        echo "  Examples:"
        echo "    bash promote.sh tweet     →  Generate a tweet"
        echo "    bash promote.sh all       →  Generate everything"
        echo "    bash promote.sh schedule  →  What to post today"
        echo ""
        echo "  First time? Edit config.sh with your info, then:"
        echo "    bash promote.sh all"
        echo ""
        ;;
esac

exit 0
