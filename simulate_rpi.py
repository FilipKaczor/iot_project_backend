"""
Raspberry Pi Simulator - Generates realistic sensor data
Simulates multiple readings over time for demonstration
"""
import requests
import random
import time
from datetime import datetime

BASE_URL = "https://smart-brewery.wittyforest-43b9cebb.westeurope.azurecontainerapps.io"
DEVICE_ID = "raspberry-pi-brewery"

# Simulation parameters
NUM_READINGS = 20  # Number of readings to generate
DELAY_BETWEEN = 1  # Seconds between readings (for demo)

def generate_weight():
    """Simulate fermentation weight (starts ~28kg, decreases as CO2 escapes)"""
    base = 28.0
    variation = random.uniform(-0.5, 0.1)  # Slowly decreasing
    return round(base + variation, 2)

def generate_temperature():
    """Simulate fermentation temperature (ideal: 18-22°C)"""
    base = 20.0
    variation = random.uniform(-2.0, 2.0)
    return round(base + variation, 1)

def generate_ph():
    """Simulate pH during fermentation (starts ~5.2, drops to ~4.0)"""
    base = 4.5
    variation = random.uniform(-0.3, 0.3)
    return round(base + variation, 2)

def generate_environment():
    """Simulate room environment (BME280 sensor)"""
    return {
        "humidity_percent": round(random.uniform(55.0, 75.0), 1),
        "temperature_celsius": round(random.uniform(18.0, 24.0), 1),
        "pressure_hpa": round(random.uniform(1008.0, 1020.0), 2)
    }

def send_data(data):
    """Send data to API"""
    try:
        r = requests.post(f"{BASE_URL}/mqtt/test", json=data, timeout=10)
        return r.status_code == 200
    except:
        return False

def main():
    print("=" * 60)
    print("SMART BREWERY - Raspberry Pi Simulator")
    print("=" * 60)
    print(f"Device ID: {DEVICE_ID}")
    print(f"Generating {NUM_READINGS} readings...")
    print("-" * 60)
    
    success_count = 0
    
    for i in range(NUM_READINGS):
        timestamp = datetime.now().strftime("%H:%M:%S")
        print(f"\n[{i+1}/{NUM_READINGS}] {timestamp}")
        
        # Weight
        weight = generate_weight()
        if send_data({"type": "weight", "device_id": DEVICE_ID, "weight_kg": weight}):
            print(f" Weight: {weight} kg")
            success_count += 1
        else:
            print(f" Weight: FAILED")
        
        # Temperature
        temp = generate_temperature()
        if send_data({"type": "temperature", "device_id": DEVICE_ID, "temperature_celsius": temp}):
            print(f" Temperature: {temp} °C")
            success_count += 1
        else:
            print(f"   Temperature: FAILED")
        
        # pH
        ph = generate_ph()
        if send_data({"type": "ph", "device_id": DEVICE_ID, "ph_value": ph}):
            print(f"pH: {ph}")
            success_count += 1
        else:
            print(f"   pH: FAILED")
        
        # Environment
        env = generate_environment()
        env_data = {
            "type": "environment",
            "device_id": DEVICE_ID,
            **env
        }
        if send_data(env_data):
            print(f"   Environment: {env['humidity_percent']}% / {env['temperature_celsius']}°C / {env['pressure_hpa']} hPa")
            success_count += 1
        else:
            print(f"  Environment: FAILED")
        
        if i < NUM_READINGS - 1:
            time.sleep(DELAY_BETWEEN)
    
    total = NUM_READINGS * 4
    print("\n" + "=" * 60)
    print(" Complete! {success_count}/{total} readings sent successfully")
    print("=" * 60)
    
    # Show summary
    print("\n📊 Quick verification:")
    try:
        # Login
        r = requests.post(f"{BASE_URL}/login", json={"username": "flow_test_user", "password": "test123456"}, timeout=10)
        if r.status_code == 200:
            token = r.json()["access_token"]
            headers = {"Authorization": f"Bearer {token}"}
            
            for endpoint in ["weight", "temperature", "ph", "environment"]:
                r = requests.get(f"{BASE_URL}/readings/{endpoint}?days=1", headers=headers, timeout=10)
                count = len(r.json()) if r.status_code == 200 else 0
                print(f"  {endpoint.capitalize()}: {count} records in database")
    except Exception as e:
        print(f"  Verification error: {e}")

if __name__ == "__main__":
    main()

