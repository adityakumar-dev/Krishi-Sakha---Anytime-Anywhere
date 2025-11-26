import requests, re, json


class SimpleApiExtractor:
    # regex to find X-Api-Key
    XAPI_RE = re.compile(r'X-Api-Key["\']?\s*[:=]\s*["\']([A-Za-z0-9_\-]{20,})["\']', re.I)

    def __init__(self, bundle_url="https://cdn.myscheme.in/_next/static/chunks/pages/_app-6697e4fd0c08b018.js"):
        self.bundle_url = bundle_url

    def fetch_bundle(self, url=None):
        if url is None:
            url = self.bundle_url
        r = requests.get(url)
        r.raise_for_status()
        return r.text

    def extract_x_api_key(self, js_text):
        m = self.XAPI_RE.search(js_text)
        if m:
            return m.group(1)
        return None

    def get_api_key(self, url=None):
        js_text = self.fetch_bundle(url)
        return self.extract_x_api_key(js_text)


if __name__ == "__main__":
    extractor = ApiExtractor()
    print("Downloading bundle:", extractor.bundle_url)
    api_key = extractor.get_api_key()
    if api_key:
        print("🎯 Found X-Api-Key:", api_key)
    else:
        print("❌ X-Api-Key not found")