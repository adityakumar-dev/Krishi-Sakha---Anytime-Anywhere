import requests
import json
import pandas as pd
import time
import math

# --- 1. API Configuration ---
API_URL = "https://api.myscheme.gov.in/search/v5/schemes"
X_API_KEY = "tYTy5eEhlu9rFjyxuCr7ra7ACp4dv1RH8gWuHTDc"
CATEGORY = "Agriculture,Rural & Environment"

HEADERS = {
    "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36",
    "X-Api-Key": X_API_KEY,
    "Accept": "application/json, text/plain, */*",
    "Origin": "https://www.myscheme.gov.in",
    "Sec-Fetch-Site": "same-site",
    "Sec-Fetch-Mode": "cors",
    "Sec-Fetch-Dest": "empty",
}

# --- 2. Pagination and Scraping ---
PAGE_SIZE = 100
all_schemes_list = []
all_states = []
all_levels = []
all_tags = []
all_category = []
total_schemes = 0

# First, make one call to get the total count
print("Fetching page 1 to get total count...")
params = {
    "lang": "en",
    "q": json.dumps([{"identifier": "schemeCategory", "value": CATEGORY}]),
    "keyword": "",
    "sort": "",
    "from": 0,
    "size": PAGE_SIZE
}

try:
    response = requests.get(API_URL, headers=HEADERS, params=params)
    response.raise_for_status()
    data = response.json()
    
    # Get the total number of schemes from the first response
    total_schemes = data.get('data', {}).get('summary', {}).get('total', 0)
    if total_schemes == 0:
        raise Exception("Could not fetch total scheme count. Check API key or parameters.")
        
    print(f"Total schemes to fetch: {total_schemes}")
    
    # Add the first page of schemes to our list
    schemes = data.get('data', {}).get('hits', {}).get('items', [])
    all_schemes_list.extend(schemes)
    
    # Calculate total pages needed
    total_pages = math.ceil(total_schemes / PAGE_SIZE)
    print(f"Total pages: {total_pages}")

    # Loop through the rest of the pages
    # We start from page 0 (offset 100) 
    for page_num in range(0, total_pages):
        offset = page_num * PAGE_SIZE
        params['from'] = offset
        
        print(f"Fetching page {page_num + 1}/{total_pages} (offset {offset})...")
        
        response = requests.get(API_URL, headers=HEADERS, params=params)
        response.raise_for_status()
        data = response.json()
        
        schemes = data.get('data', {}).get('hits', {}).get('items', [])
        all_schemes_list.extend(schemes)
        
        # Be polite to the server, wait a moment between requests
        time.sleep(0.5)

    print(f"\nSuccessfully fetched all {len(all_schemes_list)} schemes.")

except requests.exceptions.RequestException as e:
    print(f"Error during API request: {e}")
    # If the script fails, still try to process what was downloaded
    if not all_schemes_list:
        print("No schemes were downloaded. Exiting.")
        exit()


# --- 3. Process and Flatten Data ---
if all_schemes_list:
    print("Processing all schemes into a DataFrame...")
    
    # Convert the combined list into a DataFrame
    df_schemes = pd.DataFrame(all_schemes_list)

    # Flatten the 'fields' column
    df_schemes_flat = pd.concat(
        [df_schemes.drop('fields', axis=1).reset_index(drop=True), 
         df_schemes['fields'].apply(pd.Series).reset_index(drop=True)],
        axis=1
    )
    
    # Clean up columns that might be objects
    df_schemes_flat['beneficiaryState'] = df_schemes_flat['beneficiaryState'].astype(str)
    df_schemes_flat['schemeCategory'] = df_schemes_flat['schemeCategory'].astype(str)
    df_schemes_flat['tags'] = df_schemes_flat['tags'].astype(str)

    # --- 4. Save to CSV ---
    OUTPUT_FILE = "ALL_Schemes_Agriculture_Rural_Environment.csv"
    df_schemes_flat.to_csv(OUTPUT_FILE, index=False)
    
    print(f"\n--- Success! ---")
    print(f"All {len(df_schemes_flat)} schemes saved to '{OUTPUT_FILE}'.")
    print("DataFrame sample:")
    print(df_schemes_flat.head())
else:
    print("No schemes were found or processed.")