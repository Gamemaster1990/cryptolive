#!/usr/bin/env python3
"""
Post to LinkedIn using the LinkedIn API v2.

Usage:
    python3 poster_linkedin.py "Post text"
    python3 poster_linkedin.py "Post text" --dry-run

Requires: requests
Config: set LINKEDIN_ACCESS_TOKEN, LINKEDIN_PERSON_URN in config.sh

To get credentials:
  1. Go to https://www.linkedin.com/developers/
  2. Create an app and request the "Share on LinkedIn" product
  3. Generate an access token with w_member_social scope
  4. Find your Person URN via GET https://api.linkedin.com/v2/me
"""
import sys
import os
import json

try:
    import requests
except ImportError:
    print("Error: 'requests' module not found. Install it: pip install requests")
    sys.exit(1)


def post_to_linkedin(text, dry_run=False):
    """Post a text update to LinkedIn."""
    access_token = os.environ.get('LINKEDIN_ACCESS_TOKEN', '')
    person_urn = os.environ.get('LINKEDIN_PERSON_URN', '')

    if dry_run:
        print("\nDRY RUN — would post to LinkedIn:\n")
        print("  " + text)
        print("\n  POST https://api.linkedin.com/v2/ugcPosts")
        return True

    missing = []
    if not access_token: missing.append('LINKEDIN_ACCESS_TOKEN')
    if not person_urn: missing.append('LINKEDIN_PERSON_URN')

    if missing:
        print("Missing LinkedIn credentials in config.sh:", ', '.join(missing))
        print("Get them from https://www.linkedin.com/developers/")
        return False

    # Ensure URN has the urn:li:person: prefix
    if not person_urn.startswith('urn:li:person:'):
        person_urn = 'urn:li:person:' + person_urn

    url = 'https://api.linkedin.com/v2/ugcPosts'
    body = {
        'author': person_urn,
        'lifecycleState': 'PUBLISHED',
        'specificContent': {
            'com.linkedin.ugc.ShareContent': {
                'shareCommentary': {
                    'text': text,
                },
                'shareMediaCategory': 'NONE',
            },
        },
        'visibility': {
            'com.linkedin.ugc.MemberNetworkVisibility': 'PUBLIC',
        },
    }

    headers = {
        'Authorization': 'Bearer ' + access_token,
        'Content-Type': 'application/json',
        'X-Restli-Protocol-Version': '2.0.0',
    }

    try:
        resp = requests.post(url, json=body, headers=headers, timeout=15)
        if resp.status_code in (200, 201):
            print("Posted to LinkedIn!")
            return True
        else:
            print("LinkedIn API error (" + str(resp.status_code) + "):")
            try:
                print(json.dumps(resp.json(), indent=2))
            except Exception:
                print(resp.text)
            return False
    except requests.exceptions.RequestException as e:
        print("Network error:", e)
        return False


if __name__ == '__main__':
    is_dry_run = '--dry-run' in sys.argv
    text_parts = [a for a in sys.argv[1:] if a != '--dry-run']
    text = ' '.join(text_parts)

    if not text:
        print(__doc__)
        sys.exit(1)

    success = post_to_linkedin(text, dry_run=is_dry_run)
    sys.exit(0 if success else 1)
