import requests
import json
import datetime

API_URL = "https://api.myscheme.gov.in/search/v5/schemes"

# Replace with the X-Api-Key you extracted from the bundle
X_API_KEY = "tYTy5eEhlu9rFjyxuCr7ra7ACp4dv1RH8gWuHTDc"

category = "Agriculture,Rural & Environment"

headers = {
    "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36",
    "X-Api-Key": X_API_KEY,
    "Accept": "application/json, text/plain, */*",
    "Origin": "https://www.myscheme.gov.in",
    "Sec-Fetch-Site": "same-site",
    "Sec-Fetch-Mode": "cors",
    "Sec-Fetch-Dest": "empty",
}

# The 'q' param is a JSON string
params = {
    "lang": "en",
    "q": json.dumps([{"identifier": "schemeCategory", "value": category}]),
    "keyword": "",
    "sort": "",
    "from": 9,
    "size": 100
}

response = requests.get(API_URL, headers=headers, params=params)
response.raise_for_status()  # will raise error if status != 200

data = response.json()
print(json.dumps(data, indent=2))

# Save the data to a JSON file
timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
filename = f"scheme_data_{timestamp}.json"
with open(filename, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print(f"Data saved to {filename}")