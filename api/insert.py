import requests
from datetime import datetime

base_url = "http://localhost:8000/"
firebase_uid = "b97e2441-a66d-4710-af58-25d65e5c7fc3"

result = requests.post(f"{base_url}user/create", json={"username": "SysteM", "email": "guicostaantunes@gmail.com", "firebase_uid": firebase_uid})
user_id = result.json()["user_id"]

result = requests.post(f"{base_url}route/create", json={"route_name": "Route 1", "route_number": 1})
route_id = result.json()["route_id"]

result = requests.post(f"{base_url}stop/create", json={"stop_name": "Stop 1", "stop_location_lat": 0.0, "stop_location_long": 0.0})
stop_id1 = result.json()["stop_id"]

result = requests.post(f"{base_url}stop/create", json={"stop_name": "Stop 2", "stop_location_lat": 1.0, "stop_location_long": 0.0})
stop_id2 = result.json()["stop_id"]

result = requests.post(f"{base_url}bus/create", json={"bus_name": "Bus 1", "route_id": route_id})
bus_id = result.json()["bus_id"]

result = requests.post(f"{base_url}bus/add_stop", json={"bus_id": bus_id, "stop_id": stop_id1, "stop_time": "2021-06-06T00:00:00"})
bus_stop_id1 = result.json()["bus_stop_id"]

result = requests.post(f"{base_url}bus/add_stop", json={"bus_id": bus_id, "stop_id": stop_id2, "stop_time": "2021-06-06T00:01:00"})
bus_stop_id2 = result.json()["bus_stop_id"]

result = requests.post(f"{base_url}travel/register", json={"bus_id": bus_id, "user_id": user_id})
travel_id = result.json()["travel_id"]

result = requests.get(f"{base_url}user/{firebase_uid}")
print(result.json())

result = requests.get(f"{base_url}user/history/{user_id}")
print(result.json())

result = requests.get(f"{base_url}stop/schedule/{stop_id1}")
print(result.json())

result = requests.get(f"{base_url}stop/location/{stop_id2}")
print(result.json())

result = requests.get(f"{base_url}stop/all")
print(result.json())

result = requests.get(f"{base_url}stop/all_names")
print(result.json())

result = requests.get(f"{base_url}route/all")
print(result.json())

result = requests.get(f"{base_url}route/{route_id}")
print(result.json())

result = requests.get(f"{base_url}route/stops/{route_id}")

date = datetime.now()
result = requests.get(f"{base_url}system/is_updated/{date}")
print(result.json())

result = requests.get(f"{base_url}system/last_update")
print(result.json())
