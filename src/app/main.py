from fastapi import FastAPI, Depends, Response, Request
from typing import Dict
import hashlib, json, time

app = FastAPI()
API_PREFIX = "/api/v1"

def get_store() -> Dict[str, str]:
    # Fuente de datos mínima para Sprint 1 (mockeable en tests)
    return {"1": "alpha", "2": "beta"}

@app.get(f"{API_PREFIX}/health")
def health() -> Dict[str, str]:
    return {"status": "ok"}

@app.get(f"{API_PREFIX}/item/{{item_id}}")
def get_item(
    item_id: str,
    response: Response,
    store: Dict[str, str] = Depends(get_store),
) -> Dict[str, str]:
    value = store.get(item_id, "")
    response.headers["Cache-Control"] = "public, max-age=60"
    return {"id": item_id, "value": value}

@app.get(f"{API_PREFIX}/stable")
def stable(id: str, response: Response):
    payload = {"id": id, "value": f"stable-{id}"}
    response.headers["Cache-Control"] = "public, max-age=60"
    return payload

@app.get(f"{API_PREFIX}/volatile")
def volatile(response: Response):
    payload = {"now": int(time.time())}
    response.headers["Cache-Control"] = "no-store"
    return payload

@app.get(f"{API_PREFIX}/revalidate")
def revalidate(id: str, request: Request, response: Response):
    body = json.dumps({"id": id, "value": f"reval-{id}"})
    etag = hashlib.md5(body.encode()).hexdigest()
    if request.headers.get("if-none-match") == etag:
        response.status_code = 304
        return
    response.headers["ETag"] = etag
    response.headers["Cache-Control"] = "public, max-age=0, must-revalidate"
    return json.loads(body)