from flask import Flask, request, Response
import requests, json
from datetime import datetime

def ts():
    return datetime.now().strftime("%Y%m%d_%H%M%S")

UPSTREAM = "http://localhost:8081"
app = Flask(__name__)

@app.route("/<path:path>", methods=["GET", "POST"])
def proxy(path):
    body = request.get_data()
    # ---- INPUT ----
    print(f"\n[{ts()}] ===== REQUEST", request.method, "/" + path, "=====")
    try:
        print(json.dumps(json.loads(body), indent=2, ensure_ascii=False))
    except Exception:
        print(body.decode("utf-8", "replace"))

    r = requests.request(request.method, f"{UPSTREAM}/{path}",
                         data=body, headers={k: v for k, v in request.headers
                         if k.lower() != "host"})
    # ---- OUTPUT ----
    print(f"[{ts()}] ----- RESPONSE", r.status_code, "-----")
    try:
        data = r.json()
        print(data["choices"][0]["message"]["content"])
    except Exception:
        print(r.text[:2000])
    return Response(r.content, r.status_code,
                    content_type=r.headers.get("content-type"))

app.run(port=8080)