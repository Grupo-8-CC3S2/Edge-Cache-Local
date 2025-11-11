# tests/unit/test_app.py
import pytest
from fastapi.testclient import TestClient

def test_health_ok(client: TestClient):
    r = client.get("/api/v1/health")
    assert r.status_code == 200
    assert r.json() == {"status": "ok"}

@pytest.mark.parametrize(
    "item_id,store,expected_value",
    [
        ("1", {"1": "alpha", "2": "beta"}, "alpha"),
        ("2", {"1": "alpha", "2": "beta"}, "beta"),
        ("9", {"1": "alpha", "2": "beta"}, ""),  # no existe → vacío
    ],
)
def test_get_item_cache_header(client: TestClient, monkeypatch, item_id, store, expected_value):
    # Parchea la dependencia get_store para controlar el dataset
    monkeypatch.setattr("src.app.main.get_store", lambda: store)
    r = client.get(f"/api/v1/item/{item_id}")
    assert r.status_code == 200
    assert r.json() == {"id": item_id, "value": expected_value}
    # Verifica header de caché (case-insensitive)
    assert any(k.lower() == "cache-control" for k in r.headers.keys())
    assert "max-age=60" in r.headers.get("Cache-Control", "") or \
           "max-age=60" in next((v for k, v in r.headers.items() if k.lower()=="cache-control"), "")
