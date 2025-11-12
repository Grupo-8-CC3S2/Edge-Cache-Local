## Configuracion de Nginx edge Cache 
- Nginx configurado con proxy_cache_path, keys_zone, max_size e inactive 
- `proxy_cache_key` definido para endpoints `/api/v1/item` y `/api/v1/health` 
- Nginx syntax verificada (`nginx -t`) y configuración recargada (`nginx -s reload`) 
- Verificación de cache con `curl` exitosa, archivos hash/id creados 