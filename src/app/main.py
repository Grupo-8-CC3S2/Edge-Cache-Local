from fastapi import FastAPI, Depends, Response
from typing import Dict

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
