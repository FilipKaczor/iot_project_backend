"""
Flow Test Script - Tests the complete flow:
1. API Health Check
2. Register/Login
3. Send test data via MQTT endpoint
4. Retrieve data from API
"""
import requests
import json
import sys

BASE_URL = "https://smart-brewery.wittyforest-43b9cebb.westeurope.azurecontainerapps.io"
RESULTS = []

def log(msg):
    print(msg)
    RESULTS.append(msg)

def test_flow():
    log("=" * 60)
    log("SMART BREWERY - FLOW TEST")
    log("=" * 60)
    
    # 1. Health Check
    log("\n[1] HEALTH CHECK")
    try:
        r = requests.get(f"{BASE_URL}/health", timeout=30)
        log(f"    Status: {r.status_code}")
        log(f"    Response: {r.text}")
        if r.status_code != 200:
            log("    FAILED - API not healthy")
            return False
    except Exception as e:
        log(f"    ERROR: {e}")
        return False
    
    # 2. Register User (may already exist)
    log("\n[2] REGISTER USER")
    try:
        user_data = {
            "email": "flow_test@brewery.com",
            "username": "flow_test_user",
            "password": "test123456",
            "full_name": "Flow Test User"
        }
        r = requests.post(f"{BASE_URL}/register", json=user_data, timeout=30)
        log(f"    Status: {r.status_code}")
        if r.status_code == 200:
            log("    User registered successfully")
        elif r.status_code == 400:
            log("    User already exists (OK)")
        else:
            log(f"    Response: {r.text}")
    except Exception as e:
        log(f"    ERROR: {e}")
    
    # 3. Login
    log("\n[3] LOGIN")
    token = None
    try:
        login_data = {"username": "flow_test_user", "password": "test123456"}
        r = requests.post(f"{BASE_URL}/login", json=login_data, timeout=30)
        log(f"    Status: {r.status_code}")
        if r.status_code == 200:
            token = r.json().get("access_token")
            log(f"    Token: {token[:30]}...")
        else:
            log(f"    FAILED: {r.text}")
            return False
    except Exception as e:
        log(f"    ERROR: {e}")
        return False
    
    # 4. Send Test Data via MQTT Endpoint
    log("\n[4] SEND SENSOR DATA (simulating IoT Hub)")
    headers = {"Authorization": f"Bearer {token}"}
    
    test_data = [
        {"type": "weight", "device_id": "flow-test-device", "weight_kg": 25.5},
        {"type": "temperature", "device_id": "flow-test-device", "temperature_celsius": 18.5},
        {"type": "ph", "device_id": "flow-test-device", "ph_value": 4.2},
        {"type": "environment", "device_id": "flow-test-device", "humidity_percent": 65.0, "temperature_celsius": 22.0, "pressure_hpa": 1013.25}
    ]
    
    for data in test_data:
        try:
            r = requests.post(f"{BASE_URL}/mqtt/test", json=data, timeout=30)
            log(f"    {data['type']}: {r.status_code} - {r.json().get('status', r.text)}")
        except Exception as e:
            log(f"    {data['type']}: ERROR - {e}")
    
    # 5. Retrieve Data
    log("\n[5] RETRIEVE SENSOR DATA")
    endpoints = [
        ("/readings/weight", "Weight"),
        ("/readings/temperature", "Temperature"),
        ("/readings/ph", "pH"),
        ("/readings/environment", "Environment")
    ]
    
    for endpoint, name in endpoints:
        try:
            r = requests.get(f"{BASE_URL}{endpoint}?days=1", headers=headers, timeout=30)
            count = len(r.json()) if r.status_code == 200 else 0
            log(f"    {name}: {r.status_code} - {count} records")
        except Exception as e:
            log(f"    {name}: ERROR - {e}")
    
    log("\n" + "=" * 60)
    log("FLOW TEST COMPLETE!")
    log("=" * 60)
    
    return True

if __name__ == "__main__":
    success = test_flow()
    
    # Save results to file
    with open("flow_test_results.txt", "w", encoding="utf-8") as f:
        f.write("\n".join(RESULTS))
    
    print("\nResults saved to flow_test_results.txt")
    sys.exit(0 if success else 1)

