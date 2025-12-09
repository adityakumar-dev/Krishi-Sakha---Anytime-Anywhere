import requests
import json
import pandas as pd
import time
import math
import datetime

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

# --- 2. Setup ---
PAGE_SIZE = 100
all_schemes_list = []

# Create a single timestamp for this entire batch
# This is the 'upload_date' you wanted for Supabase
upload_timestamp = datetime.datetime.now().isoformat()

# Use sets to store unique filter options (no duplicates)
unique_states = set()
unique_levels = set()
unique_categories = set()
unique_tags = set()
unique_ministries = set()
unique_schemeFor = set()

# Helper function to extract filter data from a batch of schemes
def extract_filters(schemes_batch):
    print(f"Extracting filters from {len(schemes_batch)} schemes...")
    for scheme in schemes_batch:
        fields = scheme.get('fields', {})
        
        # Add level (single string)
        level = fields.get('level')
        if level:
            unique_levels.add(level)
        schemeFor = fields.get('schemeFor')
        if schemeFor :
            unique_schemeFor.add(schemeFor)
        # Add Ministry (single string, handle None)
        ministry = fields.get('nodalMinistryName')
        if ministry and pd.notna(ministry):
            unique_ministries.add(ministry)
            
        # Add beneficiaryState (list of strings)
        states = fields.get('beneficiaryState', [])
        if states:
            unique_states.update(states)
            
        # Add schemeCategory (list of strings)
        categories = fields.get('schemeCategory', [])
        if categories:
            unique_categories.update(categories)
            
        # Add tags (list of strings)
        tags = fields.get('tags', [])
        if tags:
            unique_tags.update(tags)

# --- 3. Pagination and Scraping ---
try:
    # First, make one call to get the total count (Page 1 / offset 0)
    print("Fetching page 1 to get total count...")
    params = {
        "lang": "en",
        "q": json.dumps([{"identifier": "schemeCategory", "value": CATEGORY}]),
        "keyword": "",
        "sort": "",
        "from": 0,
        "size": PAGE_SIZE
    }
    
    response = requests.get(API_URL, headers=HEADERS, params=params)
    response.raise_for_status()
    data = response.json()
    
    # Get the total number of schemes from the first response
    total_schemes = data.get('data', {}).get('summary', {}).get('total', 0)
    if total_schemes == 0:
        raise Exception("Could not fetch total scheme count. Check API key or parameters.")
        
    print(f"Total schemes to fetch: {total_schemes}")
    
    # Add the first page of schemes to our list
    schemes_page_1 = data.get('data', {}).get('hits', {}).get('items', [])
    all_schemes_list.extend(schemes_page_1)
    
    # --- Extract filters from Page 1 ---
    extract_filters(schemes_page_1)
    
    # Calculate total pages needed
    total_pages = math.ceil(total_schemes / PAGE_SIZE)
    print(f"Total pages: {total_pages}")

    # Loop through the rest of the pages
    # We start from page 2 (page_num = 1) since we already fetched page 1
    for page_num in range(1, total_pages):
        offset = page_num * PAGE_SIZE
        params['from'] = offset
        
        print(f"Fetching page {page_num + 1}/{total_pages} (offset {offset})...")
        
        response = requests.get(API_URL, headers=HEADERS, params=params)
        response.raise_for_status()
        data = response.json()
        
        new_schemes = data.get('data', {}).get('hits', {}).get('items', [])
        all_schemes_list.extend(new_schemes)
        
        # --- Extract filters from this page ---
        extract_filters(new_schemes)
        
        # Be polite to the server, wait a moment between requests
        time.sleep(0.5)

    print(f"\nSuccessfully fetched all {len(all_schemes_list)} schemes.")

except requests.exceptions.RequestException as e:
    print(f"Error during API request: {e}")
    if not all_schemes_list:
        print("No schemes were downloaded. Exiting.")
        exit()


# --- 4. Process and Flatten Main Scheme Data ---
if all_schemes_list:
    print("Processing all schemes into a DataFrame...")
    
    df_schemes = pd.DataFrame(all_schemes_list)

    # Flatten the 'fields' column
    df_schemes_flat = pd.concat(
        [df_schemes.drop('fields', axis=1).reset_index(drop=True), 
         df_schemes['fields'].apply(pd.Series).reset_index(drop=True)],
        axis=1
    )
    
    # --- ADD THIS LINE TO FIX THE ERROR ---
    print(f"Total rows before deduplication: {len(df_schemes_flat)}")
    df_schemes_flat = df_schemes_flat.drop_duplicates(subset=['id'], keep='first')
    print(f"Total rows after deduplication: {len(df_schemes_flat)}")
    # --- END OF FIX ---
    # --- ADD THE UPLOAD_DATE COLUMN ---
    df_schemes_flat['upload_date'] = upload_timestamp
    
    # Clean up columns that might be objects
    df_schemes_flat['beneficiaryState'] = df_schemes_flat['beneficiaryState'].astype(str)
    df_schemes_flat['schemeCategory'] = df_schemes_flat['schemeCategory'].astype(str)
    df_schemes_flat['tags'] = df_schemes_flat['tags'].astype(str)
    # --- NEW: CONVERT HEADERS TO LOWERCASE ---
    print("Converting column headers to lowercase...")
    df_schemes_flat.columns = df_schemes_flat.columns.str.lower()
    print(f"New columns: {df_schemes_flat.columns.tolist()}")
    # --- END OF NEW CODE ---
    # --- Save Main CSV ---
    OUTPUT_FILE = "ALL_Schemes_Agriculture_Rural_Environment.csv"
    df_schemes_flat.to_csv(OUTPUT_FILE, index=False)
    
    print(f"\n--- Success! ---")
    print(f"All {len(df_schemes_flat)} schemes saved to '{OUTPUT_FILE}'.")
    
    
    # --- 5. Create and Save Tidy Filter CSV (for Supabase) ---
    print("\n--- 5. Processing Filter Data for Supabase ---")

    filter_rows = []
    
    # Add all unique states
    for item in sorted(list(unique_states)):
        filter_rows.append({"filter_type": "state", "filter_value": item})
        
    # Add all unique categories
    for item in sorted(list(unique_categories)):
        filter_rows.append({"filter_type": "category", "filter_value": item})
        
    # Add all unique levels
    for item in sorted(list(unique_levels)):
        filter_rows.append({"filter_type": "level", "filter_value": item})
        
    # Add all unique ministries
    for item in sorted(list(unique_ministries)):
        filter_rows.append({"filter_type": "ministry", "filter_value": item})
        
    # Add all unique tags
    for item in sorted(list(unique_tags)):
        filter_rows.append({"filter_type": "tag", "filter_value": item})

    # add all unique schmeFor
    for item in sorted(list(unique_schemeFor)):
        filter_rows.append({"filter_type" : "schemeFor", "filter_value" : item})
        
    # Create the DataFrame
    df_filters = pd.DataFrame(filter_rows)
    
    FILTER_FILE = "scheme_filters.csv"
    df_filters.to_csv(FILTER_FILE, index=False)
    
    print(f"Successfully saved all unique filter options to '{FILTER_FILE}'.")
    print("\n--- Filter CSV Sample ---")
    print(df_filters.head())
    print("...")
    print(df_filters.tail())

else:
    print("No schemes were found or processed.")