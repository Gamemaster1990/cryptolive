#!/usr/bin/env python3
"""
Post a text post to Reddit using the Reddit API.

Usage:
    python3 poster_reddit.py "Post Title" "Post body text"
    python3 poster_reddit.py "Title" "Body" --subreddit CryptoCurrency

Requires: requests
Config: set REDDIT_CLIENT_ID, REDDIT_CLIENT_SECRET, REDDIT_USERNAME, REDDIT_PASSWORD
"""
import sys
import os
import json

try:
    import requests
except ImportError:
    print("Error: 'requests' module not found. Install it: pip install requests")
    sys.exit(1)


def get_reddit_token(client_id, client_secret, username, password):
    """Obtain an OAuth 2.0 access token from Reddit."""
    auth = requests.auth.HTTPBasicAuth(client_id, client_secret)
    data = {
        'grant_type': 'password',
        'username': username,
        'password': password,
    }
    headers = {'User-Agent': 'CryptoLivePromotion/1.0 (by u/' + username + ')'}

    try:
        resp = requests.post(
            'https://www.reddit.com/api/v1/access_token',
            auth=auth, data=data, headers=headers, timeout=15
        )
        if resp.status_code != 200:
            print("Reddit auth error:", resp.status_code)
            try:
                print(json.dumps(resp.json(), indent=2))
            except Exception:
                print(resp.text)
            return None
        return resp.json().get('access_token')
    except requests.exceptions.RequestException as e:
        print("Network error during Reddit auth:", e)
        return None


def post_to_reddit(title, body, subreddit, dry_run=False):
    """Submit a self post to a subreddit."""
    client_id = os.environ.get('REDDIT_CLIENT_ID', '')
    client_secret = os.environ.get('REDDIT_CLIENT_SECRET', '')
    username = os.environ.get('REDDIT_USERNAME', '')
    password = os.environ.get('REDDIT_PASSWORD', '')

    if dry_run:
        print("\nDRY RUN — would post to Reddit:\n")
        print("  Subreddit: r/" + subreddit)
        print("  Title:     " + title)
        print("  Body:      " + body[:200] + ("..." if len(body) > 200 else ""))
        return True

    missing = []
    if not client_id: missing.append('REDDIT_CLIENT_ID')
    if not client_secret: missing.append('REDDIT_CLIENT_SECRET')
    if not username: missing.append('REDDIT_USERNAME')
    if not password: missing.append('REDDIT_PASSWORD')

    if missing:
        print("Missing Reddit credentials in config.sh:", ', '.join(missing))
        print("Get them from https://www.reddit.com/prefs/apps")
        return False

    token = get_reddit_token(client_id, client_secret, username, password)
    if not token:
        print("Failed to authenticate with Reddit.")
        return False

    headers = {
        'Authorization': 'Bearer ' + token,
        'User-Agent': 'CryptoLivePromotion/1.0 (by u/' + username + ')',
    }

    data = {
        'sr': subreddit,
        'title': title,
        'text': body,
        'kind': 'self',
    }

    try:
        resp = requests.post(
            'https://oauth.reddit.com/api/submit',
            headers=headers, data=data, timeout=15
        )
        if resp.status_code == 200:
            result = resp.json()
            if result.get('json', {}).get('errors'):
                errors = result['json']['errors']
                print("Reddit API errors:", errors)
                return False
            print("Posted to r/" + subreddit + "!")
            return True
        else:
            print("Reddit API error (" + str(resp.status_code) + "):")
            try:
                print(json.dumps(resp.json(), indent=2))
            except Exception:
                print(resp.text)
            return False
    except requests.exceptions.RequestException as e:
        print("Network error:", e)
        return False


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='Post to Reddit')
    parser.add_argument('title', help='Post title')
    parser.add_argument('body', help='Post body text')
    parser.add_argument('--subreddit', default='CryptoCurrency',
                        help='Subreddit to post to (default: CryptoCurrency)')
    parser.add_argument('--dry-run', action='store_true',
                        help='Preview without posting')
    args = parser.parse_args()
    success = post_to_reddit(args.title, args.body, args.subreddit, args.dry_run)
    sys.exit(0 if success else 1)
