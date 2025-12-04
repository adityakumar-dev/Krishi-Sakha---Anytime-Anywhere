import httpx
import asyncio
from datetime import datetime
from typing import Dict, List, Optional
all_states_mandi_price = [
    "ANDAMAN AND NICOBAR ISLANDS",
    "ANDHRA PRADESH",
    "ASSAM",
    "BIHAR",
    "CHANDIGARH",
    "CHHATTISGARH",
    "GOA",
    "GUJARAT",
    "HARYANA",
    "HIMACHAL PRADESH",
    "JAMMU AND KASHMIR",
    "JHARKHAND",
    "KARNATAKA",
    "KERALA",
    "MADHYA PRADESH",
    "MAHARASHTRA",
    "NAGALAND",
    "ODISHA",
    "PUDUCHERRY",
    "PUNJAB",
    "RAJASTHAN",
    "TAMIL NADU",
    "TELANGANA",
    "TRIPURA",
    "UTTAR PRADESH",
    "UTTARAKHAND",
    "WEST BENGAL"
]

# Your god-tier e-NAM Kerala price fetcher
async def get_mandi_prices(
    from_date: str = None,
    to_date: str = None,
    state_name: str = "KERALA",
    client: Optional[httpx.AsyncClient] = None
) -> Dict:
    """
    Fetch ALL Kerala mandi prices in ONE call.
    Returns empty dict if no trading that day (status 500 = no data)
    """
    close_client = client is None
    if client is None:
        # Mimic real browser headers (this is what makes it stable)
        client = httpx.AsyncClient(
            timeout=20.0,
            headers={
                "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36",
                "Accept": "application/json, text/javascript, */*",
                "Accept-Encoding": "gzip, deflate, br",
                "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
                "Origin": "https://enam.gov.in",
                "Referer": "https://enam.gov.in/web/dashboard/trade-data",
                "X-Requested-With": "XMLHttpRequest",
            },
            follow_redirects=True
        )

    # Default to last 7 days if not provided
    if not from_date:
        from_date = (datetime.now()).strftime("%Y-%m-%d")
    if not to_date:
        to_date = from_date

    payload = {
        "language": "en",
        "stateName": state_name,
        "apmcName": "-- Select APMCs --",
        "commodityName": "-- Select Commodity --",
        "fromDate": from_date,
        "toDate": to_date
    }

    try:
        response = await client.post(
            "https://enam.gov.in/web/Ajax_ctrl/trade_data_list",
            data=payload
        )

        # e-NAM returns 200 + {"status":500} when no data
        if response.status_code != 200:
            return {"error": f"HTTP {response.status_code}", "prices": []}

        data = response.json()

        if data.get("status") == 500 or not data.get("data"):
            return {"date_range": f"{from_date} to {to_date}", "prices": [], "note": "No trading data"}

       

        return data

    except Exception as e:
        return {"error": str(e), "prices": []}
    finally:
        if close_client:
            await client.aclose()


# Quick test function
async def test_today(state_name: str = "KERALA"):

    result = await get_mandi_prices("2025-11-29", "2025-11-30", state_name=state_name)
    print(result)

# Run it
if __name__ == "__main__":
    asyncio.run(test_today("KERALA"))