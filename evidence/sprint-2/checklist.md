## Configuracion de Nginx edge Cache 

Nginx configurado con proxy_cache_path, keys_zone, max_size e inactive 

`proxy_cache_key` definido para endpoints `/api/v1/item` y `/api/v1/health` 

nginx syntax verificada (`nginx -t`) y configuración recargada (`nginx -s reload`) 

```bash
esau@DESKTOP-A3RPEKP:~/Edge-Cache-Local/proxy$ docker exec -it edge-cache-proxy nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
esau@DESKTOP-A3RPEKP:~/Edge-Cache-Local/proxy$
```

Verificación de cache con `curl` exitosa 
```bash
curl -H "Host: localhost" http://localhost/api/v1/item/2
{"id":"2","value":"beta"}
```

Una vez configurado el cache y agregado politicas correspondientes, se tiene certeza que la cache cachea respuestas de solicitudes de modo que al ejecutar los comandos siguientes el tiempo del segundo deberia ser menor
```bash
time curl -s http://localhost/api/v1/item/2 > /dev/null

real    0m0.153s
user    0m0.036s
sys     0m0.024s

time curl -s http://localhost/api/v1/item/2 > /dev/null

real    0m0.010s
user    0m0.000s
sys     0m0.008s
```
Debido a que ya esta en cache:
```bash
docker exec -it edge-cache-proxy ls -lh /var/cache/nginx/app_cache
total 4K     
drwx------    3 nginx    nginx       4.0K Nov 12 04:08 1
```
Uso de add_header X-Cache-Status $upstream_cache_status en los bloques location, permite la observabilidad del comportamiento de cache,el MISS del primer  request indica que la peticion llegó al backend, mientras que el HIT del segundo request muestra que la respuesta se obtuvo del cache local
```bash
esau@DESKTOP-A3RPEKP:~/Edge-Cache-Local/proxy$ curl -I http://localhost/api/v1/item/2
HTTP/1.1 200 OK
Server: nginx/1.29.3
Date: Wed, 12 Nov 2025 04:21:38 GMT
Content-Type: application/json
Content-Length: 25
Connection: keep-alive
cache-control: public, max-age=60
X-Cache-Status: MISS

esau@DESKTOP-A3RPEKP:~/Edge-Cache-Local/proxy$ curl -I http://localhost/api/v1/item/2
HTTP/1.1 200 OK
Server: nginx/1.29.3
Date: Wed, 12 Nov 2025 04:21:49 GMT
Content-Type: application/json
Content-Length: 25
Connection: keep-alive
cache-control: public, max-age=60
X-Cache-Status: HIT
```

