import requests

# Base URL for your Node.js API server
FABRIC_API_URL = "http://localhost:3000/api/landrequests"

def get_all_land_requests():
    """Call the Node API endpoint to get all land requests."""
    try:
        response = requests.get(FABRIC_API_URL)
        response.raise_for_status()
        return response.json()
    except requests.RequestException as e:
        return {"error": str(e)}

def create_land_request(receipt_number, data):
    """
    Call the Node API endpoint to create a new land request.
    `data` is a dictionary containing all required fields.
    """
    payload = {
        "receiptNumber": receipt_number,
        "data": data
    }
    try:
        response = requests.post(f"{FABRIC_API_URL}/create", json=payload)
        response.raise_for_status()
        return response.json()
    except requests.RequestException as e:
        return {"error": str(e)}

def update_land_status(receipt_number, new_status, assigned_to, remarks, from_user, timestamp):
    """
    Call the Node API endpoint to update a land request's status.
    """
    payload = {
        "receiptNumber": receipt_number,
        "newStatus": new_status,
        "assignedTo": assigned_to,
        "remarks": remarks,
        "fromUser": from_user,
        "timestamp": timestamp
    }
    try:
        response = requests.post(f"{FABRIC_API_URL}/update", json=payload)
        response.raise_for_status()
        return response.json()
    except requests.RequestException as e:
        return {"error": str(e)}
