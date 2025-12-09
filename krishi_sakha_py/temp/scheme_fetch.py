import requests
import json
import datetime

# ✅ Use the same API key seen in browser
HEADERS = {
    "Accept": "application/json, text/plain, */*",
    "User-Agent": "Mozilla/5.0",
    "Origin": "https://www.myscheme.gov.in",
    "Referer": "https://www.myscheme.gov.in/",
    "X-Api-Key": "tYTy5eEhlu9rFjyxuCr7ra7ACp4dv1RH8gWuHTDc",
    "Accept-Encoding": "gzip, deflate, br"   # server may send compressed data
}

API_URLS = [
    ("scheme_basic", "https://api.myscheme.gov.in/schemes/v5/public/schemes?slug=pm-kisan&lang=en"),
    ("documents", "https://api.myscheme.gov.in/schemes/v5/public/schemes/62a70e86f038bd8499a6aa53/documents?lang=en"),
    ("faqs", "https://api.myscheme.gov.in/schemes/v5/public/schemes/62a70e86f038bd8499a6aa53/faqs/?lang=en"),
    ("applicationchannel", "https://api.myscheme.gov.in/schemes/v5/public/schemes/62a70e86f038bd8499a6aa53/applicationchannel"),
    ("news", "https://api.myscheme.gov.in/schemes/v5/public/schemes/62a70e86f038bd8499a6aa53/news"),
]

def fetch_and_save(tag, url):
    print(f"\n===== {tag.upper()} =====")
    try:
        response = requests.get(url, headers=HEADERS)
        response.raise_for_status()

        # ✅ Automatically decompresses gzip/br
        try:
            data = response.json()
            print(json.dumps(data, indent=2, ensure_ascii=False))

            # Save to JSON file
            timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"{tag}_{timestamp}.json"
            with open(filename, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=2, ensure_ascii=False)
            print(f"💾 Data saved to: {filename}")

        except ValueError:
            print("[!] Response is not JSON")
            print(response.text)

    except requests.exceptions.RequestException as e:
        print(f"[ERROR] {e}")

if __name__ == "__main__":
    for tag, url in API_URLS:
        fetch_and_save(tag, url)                         