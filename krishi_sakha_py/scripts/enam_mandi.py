import requests
import datetime

all_states_mandi_details = [
    "Andaman & Nicobar Islands",
    "Andhra Pradesh",
    "Assam",
    "Bihar",
    "Chandigarh",
    "Chhattisgarh",
    "Goa",
    "Gujarat",
    "Haryana",
    "Himachal Pradesh",
    "Jammu & Kashmir",
    "Jharkhand",
    "Karnataka",
    "Kerala",
    "Madhya Pradesh",
    "Maharashtra",
    "Nagaland",
    "Odisha",
    "Puducherry",
    "Punjab",
    "Rajasthan",
    "Tamil Nadu",
    "Telangana",
    "Tripura",
    "Uttar Pradesh",
    "Uttarakhand",
    "West Bengal"
]


def request_districts(state_name):
    if state_name in all_states_mandi_details:
        url = "https://enam.gov.in/web/Ajax_ctrl/district_name_detail"
        headers = {
            'Accept-Language': 'en-US,en;q=0.9',
            'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
            'Host': 'enam.gov.in',
            'Origin': 'https://enam.gov.in',
            'Referer': 'https://enam.gov.in/web/apmc-contact-details',
        }
        data = {'state_id': state_name}
        response = requests.post(url, headers=headers, data=data)
        return response.json()
    else:
        return {"error": "Invalid state name"}

def mandi_list(state_code, district):
    if state_code in all_states_mandi_details:
        url = "https://enam.gov.in/web/Ajax_ctrl/mandi_namedetail"
        headers = {
            'Connection': 'keep-alive',
            'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
            'Origin': 'https://enam.gov.in',
            'Referer': 'https://enam.gov.in/web/apmc-contact-details',
            'Sec-Fetch-Dest': 'empty',
            
        }
        data = {'state_code': state_code, 'district': district}
        response = requests.post(url, headers=headers, data=data)
        return response.json()
    else:
        return {"error": "Invalid state code"}

def mandi_details(mandi_id, state_name, district_name):
    if state_name in all_states_mandi_details:
        url = "https://enam.gov.in/web/Ajax_ctrl/mandi_name"
        headers = {
            'Host': 'enam.gov.in',
            'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
            'Origin': 'https://enam.gov.in',
            'Referer': 'https://enam.gov.in/web/apmc-contact-details',
         
        }
      
        data = {'mandi_id': mandi_id, 'state_name': state_name, 'district_name': district_name}
        response = requests.post(url, headers=headers, data=data)
        return response.json()
    else:
        return {"error": "Invalid state name"}


