import requests
import time
headers = {"X-API-Key": "373072a37541eb2a12ad3f4a4c1538b16d1f2a1f66c2c9a8c5e9027954cc03a8"}
start = time.time()
r = requests.get("https://api.openaq.org/v3/locations?limit=10", headers=headers)
locations = r.json().get("results", [])
print(f"Got {len(locations)} locations")
for loc in locations:
    r = requests.get(f"https://api.openaq.org/v3/locations/{loc['id']}/latest", headers=headers)
    print(loc['id'], r.status_code)
print(f"Time: {time.time()-start}")
