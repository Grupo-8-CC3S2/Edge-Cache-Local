# Sprint 1 - Checklist Operativo

## 1. Terraform - IaC local
Se ejecutó el comando `terraform apply` para levantar la infraestructura local:

```bash
docker_container.proxy: Creating...
docker_container.proxy: Creation complete after 1s [id=bee4f106f4a5f7f21ea80d7467e6451891af17b13591f2bfafae69bf1500e7a7]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```
## tests
tests/
 PYTHONPATH=. pytest tests/ -vv
==================================== test session starts =====================================
platform linux -- Python 3.12.3, pytest-7.4.4, pluggy-1.4.0 -- /usr/bin/python3
cachedir: .pytest_cache
rootdir: /home/esau/Edge-Cache-Local
plugins: anyio-4.2.0
collected 4 items                                                                            

tests/unit/test_app.py::test_health_ok PASSED                                          [ 25%]
tests/unit/test_app.py::test_get_item_cache_header[1-store0-alpha] PASSED              [ 50%] 
tests/unit/test_app.py::test_get_item_cache_header[2-store1-beta] PASSED               [ 75%] 
tests/unit/test_app.py::test_get_item_cache_header[9-store2-] PASSED                   [100%]
===================================== 4 passed in 0.05s  

