#!/bin/bash
# ================================================================
#  Promotion Automation — Configuration
#  Edit these values to match your site and social profiles
# ================================================================

# --- Your Site ---
SITE_NAME="CryptoLive"
SITE_URL="https://cryptolive.space"
SITE_DESC="Free real-time cryptocurrency price tracker — no ads, no signup"

# --- Social Handles (without @) ---
TWITTER_HANDLE="newkidspoem"
REDDIT_USERNAME="Gamemaster1990"

# --- CoinGecko API (no key needed) ---
COINGECKO_API="https://api.coingecko.com/api/v3"

# --- Output ---
LOG_FILE="promotion_log.txt"
POSTS_DIR="generated_posts"

# --- API Credentials (for auto-posting with --post flag) ---
# ⚠️ Get these from developer.twitter.com (requires approved dev account)
# Fill these in config.sh, then run: bash promote.sh tweet --post
TWITTER_API_KEY=""
TWITTER_API_SECRET=""
TWITTER_ACCESS_TOKEN=""
TWITTER_ACCESS_SECRET=""

# ⚠️ Get from https://www.reddit.com/prefs/apps → create a "script" app
REDDIT_CLIENT_ID=""
REDDIT_CLIENT_SECRET=""

# ⚠️ Get from https://www.linkedin.com/developers/ (requires approved app)
LINKEDIN_ACCESS_TOKEN=""
LINKEDIN_PERSON_URN=""

# -- Colors --
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
