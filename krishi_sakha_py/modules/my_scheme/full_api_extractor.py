#!/usr/bin/env python3
"""
myscheme_scraper.py

Scrape https://www.myscheme.gov.in to discover X-Api-Key and API endpoints.
Automatically handles Next.js bundles and stops when the first valid data is found.

Usage:
    python myscheme_scraper.py "Agriculture,Rural & Environment"
"""

import requests, re, json, urllib.parse, sys
from bs4 import BeautifulSoup


class FullApiExtractor:
    ROOT = "https://www.myscheme.gov.in"
    HEADERS = {
        "User-Agent": "RescueAI-Bootstrap/1.0 (contact@example.com)"
    }

    # Regex patterns
    JS_BUNDLE_RE = re.compile(r'/_next/static/[^"\']+\.js')
    XAPI_RE = re.compile(r'X-Api-Key["\']?\s*[:=]\s*["\']([A-Za-z0-9_\-]{20,})["\']', re.I)
    XAPI_GENERIC_RE = re.compile(r'(?:x-?api-?key|X-Api-Key)["\']?\s*[:=]\s*["\']([A-Za-z0-9_\-]{8,})["\']', re.I)
    API_URL_RE = re.compile(r'https?://(?:api\.)?myscheme\.gov\.in[^\s"\'\\,]+', re.I)

    def __init__(self, root=None, headers=None):
        self.root = root or self.ROOT
        self.headers = headers or self.HEADERS

    def fetch(self, url):
        """GET request with headers + error handling"""
        r = requests.get(url, headers=self.headers, timeout=20)
        r.raise_for_status()
        return r.text

    def find_next_bundles(self, html):
        """Extract all _next/static bundle URLs from HTML"""
        soup = BeautifulSoup(html, "html.parser")
        scripts = soup.find_all("script", src=True)
        bundles = [urllib.parse.urljoin(self.root, s["src"]) for s in scripts if "/_next/static/" in s["src"]]
        # also search inline
        for m in self.JS_BUNDLE_RE.finditer(html):
            bundles.append(urllib.parse.urljoin(self.root, m.group(0)))
        return list(dict.fromkeys(bundles))

    def find_apis_and_key_in_html(self, html):
        """Check HTML itself for X-Api-Key and API URLs"""
        key = None
        m = self.XAPI_RE.search(html) or self.XAPI_GENERIC_RE.search(html)
        if m:
            key = m.group(1)
        apis = self.API_URL_RE.findall(html)
        return key, apis

    def search_bundles_for_key_and_apis(self, bundles):
        """Download bundles until key and/or apis found"""
        api_urls = set()
        found_key = None
        for b in bundles:
            print("Checking bundle:", b)
            try:
                txt = self.fetch(b)
            except Exception as e:
                print("  Failed:", e)
                continue

            if not found_key:
                m = self.XAPI_RE.search(txt) or self.XAPI_GENERIC_RE.search(txt)
                if m:
                    found_key = m.group(1)
                    print("  🎯 Found X-Api-Key:", found_key)

            for u in self.API_URL_RE.findall(txt):
                api_urls.add(u)

            if found_key and api_urls:  # stop early
                break

        return found_key, sorted(api_urls)

    def bootstrap_static(self, category):
        """Main scraper pipeline"""
        encoded_cat = urllib.parse.quote(category, safe='')
        url = f"{self.root}/search/category/{encoded_cat}"
        print("Fetching HTML:", url)
        html = self.fetch(url)

        # 1. scan HTML directly
        key, apis = self.find_apis_and_key_in_html(html)

        # 2. collect bundle URLs
        bundles = self.find_next_bundles(html)

        # 3. search bundles if needed
        if not key or not apis:
            key2, apis2 = self.search_bundles_for_key_and_apis(bundles)
            if not key:
                key = key2
            apis.extend(apis2)

        out = {
            "category": category,
            "x_api_key": key,
            "api_urls": sorted(set(apis)),
            "bundles_checked": bundles
        }
        print(json.dumps(out, indent=2))
        return out


if __name__ == "__main__":
    category = sys.argv[1] if len(sys.argv) > 1 else "Agriculture,Rural & Environment"
    extractor = FullApiExtractor()
    extractor.bootstrap_static(category)