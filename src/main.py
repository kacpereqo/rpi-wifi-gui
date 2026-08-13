from fastapi import FastAPI

import wifi

app = FastAPI()


@app.get("/ap")
def get_all_access_points():
    access_points = wifi.get_all_access_points()
    return {"access_points": [ap.__dict__ for ap in access_points]}

@app.post("/connect")
def wifi_connect(ssid: str, password: str, bssid: str):
    result = wifi.wifi_connect(ssid, password, bssid)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)