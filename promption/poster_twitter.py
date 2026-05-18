#!/usr/bin/env python3
"""
Post a tweet to Twitter/X using API v2 with OAuth 1.0a User Context.

Usage:
    python3 poster_twitter.py "tweet text"
    python3 poster_twitter.py "tweet text" --dry-run

Requires: requests (pip install requests)
Config: set TWITTER_API_KEY, TWITTER_API_SECRET, TWITTER_ACCESS_TOKEN,
        TWITTER_ACCESS_SECRET in config.sh or as env vars.
"""
import sys
import os
import json
import hashlib
import hmac
import base64
import time
import random
import string
from urllib.parse import quote

try:
    import requests
except ImportError:
    print("❌ Error: 'requests' module not found. Install it: pip install requests")
    sys.exit(1)


# ── OAuth 1.0a helpers ──────────────────────────────────────────────

def oauth_escape(s):
    """Percent-encode a string per OAuth 1.0a spec."""
    return quote(s, safe='~')


def generate_nonce():
    """Generate a random nonce string."""
    return ''.join(random.choices(string.ascii_letters + string.digits, k=32))


def make_oauth_header(method, url, params, consumer_key, consumer_secret,
                      token, token_secret):
    """Build the OAuth 1.0a Authorization header for Twitter API v2."""
    oauth_params = {
        'oauth_consumer_key': consumer_key,
        'oauth_nonce': generate_nonce(),
        'oauth_signature_method': 'HMAC-SHA1',
        'oauth_timestamp': str(int(time.time())),
        'oauth_token': token,
        'oauth_version': '1.0',
    }

    # Combine OAuth params with request params
    all_params = {**oauth_params, **params}

    # Sort alphabetically and percent-encode
    sorted_params = sorted(all_params.items())
    param_string = '&'.join(
        f'{oauth_escape(k)}={oauth_escape(str(v))}' for k, v in sorted_params
    )

    # Signature base string
    base_string = '&'.join([
        oauth_escape(method.upper()),
        oauth_escape(url),
        oauth_escape(param_string),
    ])

    # Signing key
    signing_key = f'{oauth_escape(consumer_secret)}&{oauth_escape(token_secret)}'

    # Generate signature
    signature = base64.b64encode(
        hmac.new(signing_key.encode(), base_string.encode(), hashlib.sha1).digest()
    ).decode()

    oauth_params['oauth_signature'] = signature

    # Build Authorization header
    header_parts = sorted(oauth_params.items())
    auth_header = 'OAuth ' + ', '.join(
        f'{oauth_escape(k)}="{oauth_escape(str(v))}"' for k, v in header_parts
    )
    return auth_header


# ── Twitter Poster ───────────────────────────────────────────────────

def post_tweet(text, dry_run=False):
    """Post a tweet using Twitter API v2."""
    consumer_key = os.environ.get('TWITTER_API_KEY', '')
    consumer_secret = os.environ.get('TWITTER_API_SECRET', '')
    access_token = os.environ.get('TWITTER_ACCESS_TOKEN', '')
    access_secret = os.environ.get('TWITTER_ACCESS_SECRET', '')

    if dry_run:
        print(f"\n🔍 DRY RUN — would post this tweet:\n")
        print(f"   \"{text}\"")
        if consumer_key:
            print(f"   Credentials: found ({consumer_key[:8]}...)")
        else:
            print(f"   Credentials: none (dry-run without API keys)")
        print(f"   URL: https://api.twitter.com/2/tweets")
        print(f"   Length: {len(text)} chars")
        return True

    missing = []
    if not consumer_key: missing.append('TWITTER_API_KEY')
    if not consumer_secret: missing.append('TWITTER_API_SECRET')
    if not access_token: missing.append('TWITTER_ACCESS_TOKEN')
    if not access_secret: missing.append('TWITTER_ACCESS_SECRET')

    if missing:
        print(f"❌ Missing Twitter credentials in config.sh: {', '.join(missing)}")
        print("   Get them from https://developer.twitter.com/")
        return False

    if len(text) > 280:
        print(f"⚠️  Tweet is {len(text)} characters (max 280). Truncating.")
        text = text[:277] + '...'

    url = 'https://api.twitter.com/2/tweets'
    body = {'text': text}
    method = 'POST'

    auth_header = make_oauth_header(
        method, url, {}, consumer_key, consumer_secret,
        access_token, access_secret
    )

    headers = {
        'Authorization': auth_header,
        'Content-Type': 'application/json',
    }

    try:
        resp = requests.post(url, json=body, headers=headers, timeout=15)
        if resp.status_code in (200, 201):
            data = resp.json()
            tweet_id = data.get('data', {}).get('id', 'unknown')
            print(f"✅  Tweet posted! ID: {tweet_id}")
            return True
        else:
            print(f"❌  Twitter API error ({resp.status_code}):")
            try:
                err = resp.json()
                print(f"    {json.dumps(err, indent=4)}")
            except Exception:
                print(f"    {resp.text}")
            return False
    except requests.exceptions.RequestException as e:
        print(f"❌  Network error: {e}")
        return False


# ── Main ────────────────────────────────────────────────────────────

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    args = sys.argv[1:]
    dry_run = '--dry-run' in args
    text_args = [a for a in args if a != '--dry-run']
    text = ' '.join(text_args)

    if not text:
        print("❌ No tweet text provided.")
        sys.exit(1)

    success = post_tweet(text, dry_run=dry_run)
    sys.exit(0 if success else 1)
