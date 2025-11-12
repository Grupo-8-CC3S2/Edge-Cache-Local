# Edge-Cache-Local

CDN casera con Nginx + pruebas de performance.
El proyecto consiste en montar un reverse proxy con caché (Nginx) delante de un servicio backend, con políticas de cacheo, invalidación y observabilidad de hit/miss. Ademas en la orquestación local con Terraform (docker provider/localexec, evitando imports manuales).

## Uso de la Infraestructura

Configuramos nuestras variables de entorno. Ejemplo de `infra/stacks/local-dev/terraform.tfvars`:

```
# Variables para el stack de desarrollo local

# General
app_version    = "1.0.0"
network_name   = "edge-cache-network"
restart_policy = "unless-stopped"

# Backend
backend_container_name = "edge-backend"
backend_image          = "edge-cache-backend:latest"
backend_build_context  = "../../../" # Path relativo al root del proyecto
backend_internal_port  = 8080
backend_external_port  = 8080

backend_environment = {
  HOST = "0.0.0.0"
  PORT = 8080
}

# Proxy
proxy_container_name = "edge-cache-proxy"
nginx_image          = "nginx:alpine"
nginx_config_path    = "/home/jquispe/Escritorio/cursos/Actividades/Edge-Cache-Local/proxy/nginx.conf"  # Ruta al nginx.conf que usaremos
proxy_external_port  = 80
```

Creamos la infraestructura:

```sh
make plan
make apply
```

Verificamos:

```sh
# La respuesta debe ser {"status":"ok"}
curl http://localhost:8080/api/v1/health 
curl http://localhost:80/api/v1/health
curl http://localhost/api/v1/health
```

Ademas al ejecutar `docker ps` deberiamos tener de salida algo como:

```
CONTAINER ID   IMAGE          COMMAND                  CREATED              STATUS              PORTS                              NAMES
1edc286df1c3   d4918ca78576   "/docker-entrypoint.…"   About a minute ago   Up About a minute   0.0.0.0:80->80/tcp                 edge-cache-proxy
0669781d5cef   1ffb655cd9f9   "/bin/sh -c 'uvicorn…"   About a minute ago   Up About a minute   8000/tcp, 0.0.0.0:8080->8080/tcp   edge-backend
```

Para destruir la infraestructura desplegada usamos `make destroy`.

## Uso del Backend

Esta sección explica cómo levantar el backend usando diferentes métodos: local sin Docker, con Docker directamente y usando Makefile.

### Sin Docker ni Makefile

```sh
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn src.app.main:app --reload --host 0.0.0.0 --port 8001
```

### Con Docker (sin Makefile)

```sh
docker compose up --build # es posible definir variables PORT y HOST
```

### Con Makefile y Docker

```sh
make build-backend-docker
make run-backend-docker # es posible definir variable PORT
```

## Primer issue : Inicializar estructura IaC en Terraform 
La estructura de archivos tentativa
```bash
infra 
    modules
        backckend
        proxy
    stacks
        local-dev
            main.tf
            variables.tf
            outputs.tf
```
A continuacion la configuracion base de terraform
```bash
terraform{
    required_providers {
        docker = {
            source = "kreuzwerker/docker"
        }
    }
}
provider "docker" {}
```
Declaramos que el proveedor es docker , indicando a su vez que se obtendra (source) desde el proveedor oficial de Docker. Instanciando  al motor Docker ya descargado en la ultima linea

Tambien se agregan variables,  en este caso el **variable "name"** del proyecto en variables.tf  

Se hace uso del principio de composabilidad de IaC (terraform) para  agregar dos "modulo"  en main.tf que hacen referencia a backend y proxy
```bash
module "backend" {
    source = "../../modules/backend"
}

module "proxy" {
    source = "../../modules/proxy"
}
```

Ahora que se tiene la estructura basica, se agrega el .conf,puesto que Nginx usa una estructura jerarquica de bloques delimitados por {..} , introducimos dos directivas 
```bash
events {} 
http {}
```
La primera directiva configura la gestion de conexiones, en este caso se usarán valores por defecto , en tanto que el segundo bloque configura el servidor http.Se agrega el bloque server dentro de http, este representa un servidor virtual dentro de Nginx 
```bash
events{}
http{
    server{
    }
}
```
Seguidamente se establece la redireccion de las solicitudes en el bloque location
```bash
events{}
http{
    server{
        location / {}
    }
}
```
## Costrucciones de contenedores
Tal como indica la descripcion , se implementa el backend , que sera el cerebro de nuestra aplicacion,
manejara la logica interna y la comunicacion entre servicios.<br>
En backend/main.tf se DECLARA a docker como proveedor indicando la fuente desde donde obtener la imagen y la version 
luego se declara ademas , que se usara docker y que nos conectemos al daemon local de Docker, el que corre en
nuestro maquina , con una configuracion por defecto en este caso nos conectamos a unix://var/run/docker.sock
```bash
provider "docker" {}
``` 
Seguidamente se definen dos recursos docker_imagen y docker_container respectivamente; la primera  declara la logica que se ejecutara en la imagen y la ruta donde buscar le Dockerfile ,esto dentro del bloque build. El segundo declara el contenedor , quien se valdra del recurso imagen previo. 
```bash
resource "docker_image" "imagen_backend" {
    name = "backend-api-local:v1.0"
    build{
        context = 
        dockerfile =  
    }
}
```
Un detalle a destacar es que "imagen_backend" es el nombre local que se proporciona a terraform , de modo que **docker_image.imagen_backend.image_id** hace referencia a backend-api-local:v1.0

Ademas es necesario tener docker instalado, el instalador de windows se consigue en la pagina de docker y una vez instalado , ejecutamos **local$ sudo usermod -aG docker $USER**  de modo que podamos acceder al socket antes mencionado

Como se menciona resource "docker_image" ..  construye la imagen, una vez hecho esto se construye el contenedor, las primera lineas definen el nombre y la imagen, el bloque port define donde escucha la app(internal) y el puerto expuesto en el host(external), esto es equivalente a **docker run -p internal:external contenedor**.
```bash
ports {
  internal = 
  external = 
}
```
Mientras tanto la linea env=  declara las variables de entorno
```bash
env = [
  "APP_ENV=local",
  "CACHE_BYPASS=false"
]
```
Lo cual es equivalente a **docker run -e APP_ENV=local -e CACHE_BYPASS=false mi-backend**
Sin embargo  inyectamos variables en lugar de hardcodearlos en main , en tal sentido usamos variables.tf,donde el mismo codigo sirve como documentacion
En tal sentido se define la variable  "docker_context" que especifica el lugar donde se halla el codigo ejecutable del backend , esto es main.py

Tambien var.env_vars.Ademas se asignan valores de configuracion recomendadas 
```bash
  restart        = "no"
  remove_volumes = true
  must_run       = true
  start          = true
}
```

Ahora bien , se requiere de un Dockerfile que obtenga la imagen(FROM) , dentro de la imagen cree a carpeta de trabajo (WORKDIR) , copie los archivos app al directorio creado dentro de la imagen (COPY), ejecute el comando de instalacion de las dependencias(RUN comandos), exponga el puerto y ejecute el comando que lanza el backend(CMD)

En **~/Edge-Cache-Local/infra/modules/backend$** se ejecutan init y apply , 
Se construyen imagen y contenedor , asi como la ejecucion de los comandos del Dockerfile, y desde luego CMD **"uvicorn","main:app","--host","0.0.0.0","--port","8080"]** , esto es que lanzamos el servicio dentro del contenedor creado y al consultar el endpoint de salud el resultado es sozegador.
```bash
http://localhost:8080/api/v1/health
{"status":"ok"}
```
Para hacer el codigo portable se usan rutas reativas  para el contexto de docker **default     = "../../../src/app"**  y para la ruta al docerfile  
**default   = "Dockerfile"**

Respecto al proxy, tambien se crean las variables en variables.tf los cuales son :contenedor_proxy quien declara la info del contenedor para nginx, la imagen nginx:alpine que sera buscado por terraform en Dockerhub , el puerto , la ruta de nginx que define la logica a ejecutar dentro del contenedor(el servidor que se expondra a internet) y la info del contenedor donde corre el backend.

En tanto que en main.tf dentro del modulo/proxy declaramos bloques similares establecemos el proveedor, declaramos como construiremos  que tipo de imagen y contenedor queremos asi como los puertos que se expondran . Lo nuevo es el bloque volumes, donde se registra la configuracion del proxy pass dentro del contenedor nginx 
```bash

volumes {
    host_path = var.ruta_nginx
    container_path = "etc/nginx/nginx.conf"
    read_only = true
}
```
y finalmente un output

Ahora bien , en el .conf se abraca el corazon del proyecto Edge-Cache-Local, declaramos el bloque events {} definimos cuantas conexiones manejaremos de forma simultanea en este caso 1024 por worker.

Seguidamente usamos la palabra reservada http para definir al upstream backend y al server. El primero define un grupo de servidores , en este solo uno edge-backend : 8080 ; en cuanto al blqoue server es un tanto familiar, define el puerto nginx expondra asi como el servidor al que se redirigiran las solicitudes.

Entonces en infra/modules/proxy , se levanta la infraestructura, construyendo la imagen y el contenedor asi como estableciendo el proxy pass.

Ejecutamos terraformm apply 
```bash
docker_container.proxy: Creating...
docker_container.proxy: Creation complete after 1s [id=bee4f106f4a5f7f21ea80d7467e6451891af17b13591f2bfafae69bf1500e7a7]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:
```

sin embargo hace falta una red comun
entonces agregamos las variables 
```bash
variable "nombre_red" {
  description = "Nombre de la red Docker compartida"
  type        = string
  default     = "edge-cache-network"
}
``` 
y dentro del recurso 
```bash
 networks_advanced {
    name = data.docker_network.shared.name
  }

#terraform apply
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

proxy_endpoint = "http://localhost:80/api/v1/health"
{"status":"ok"}
```
## Configurar cache en nginx
Cabe mencionar que toda la infraestructura fue reformula logrando reproducibilidad, tanto los modulos como local-dev.
Con todo, ahora abarquemos la definición del cache primeramente.En nginx.conf quien contiene la configuracion de nginx,
dentro del bloque **http { }** creamos la cache, es decir lo declaramos agregando alguna directivas<br>
- **proxy_cache_path = /var/cache/nginx/app_cache** : De modo que se define el directorio donde se almacena la cache , app_cache es el que corresponde a nuestro proyecto.
- **keys_zone=app_cachee:10m**
Con la cual definos el tamaño de la cache en memoria.
- **max_size=100m** : tamaño que en disco .
- **inactive=30m**:Tambien el tiempo maximo que se almacena en memoria 
Entonces se procede a probar
```bash
docker ps  
#nuestros contenedores estan levantados
#ejecutamos el siguiente comando de modo que nginx lea /etc/nginx/nginx.conf y verifique la sintaxis y recargar nginx
docker exec -it edge-cache-proxy nginx -t
docker exec -it edge-cache-proxy nginx -s reload
```
Cabe destacar que este hot reload solo afecta al contenedor no a la infraestructura, ademas de ser interesante lo que realiza
```bash
-s reload → kill -HUP <pid_maestro_nginx>
el daemon nginx  usa  hang up signal como orden para leer nginx.conf →arranca nuevos workers con la nueva conf y termina los workers viejos.  
```

Nuestro servidor tiene varios tipos de contenido , entonces se requieren politicas de almacenamiento de acuerdo a esto.
Entonces dentro del bloque server agregamos 
- **location /api/v1/item { }** y **location/api/v1/health { }**<br> Se usa la directiva **proxy_cache_key** junto con la política **"$scheme$request_method$host$uri"**<br>
proxy_cache_key crea un identificador para el archivo en esa ruta y cada vez que llegue una solicitud a ese recurso se usa este id para obtenerlo de la cache, asi evitamos ir hasta el backend.En este caso la politica establecida representará : 
    - el protocolo
    - tipo de request
    - el dominio  
    - la ruta del recurso para el endpoint item
```bash
GET http://localhost/api/v1/item/file.js → httpGETlocalhost/api/v1/file.js
``` 
Ademas **proxy_cache_valid** permite mantener el tipo de respuesta un tiempo establecido en cache<br>
Procedemos a verificar la sintaxis y recargar nginx, verificando ademas que que la cache se haya creado
```bash
docker exec -it edge-cache-proxy ls -lh /var/cache/nginx/app_cache
```
```
Hacemos las peticiones:
```bash
curl http://localhost/api/v1/item/1
curl http://localhost/api/v1/item/2
#verificando la cache mediante querys sucesivos
docker exec -it edge-cache-proxy ls -lh /var/cache/nginx/app_cache
esau@DESKTOP-A3RPEKP:~/Edge-Cache-Local/proxy$ curl http://localhost/api/v1/item/2      
{"id":"2","value":"beta"}esau@DESKTOP-A3RPEKP:~/Edge-Cache-Local/proxy$ curl http://locadocker exec -it edge-cache-proxy ls -lh /var/cache/nginx/app_cache
total 8K     
drwx------    3 nginx    nginx       4.0K Nov 12 01:09 1
drwx------    3 nginx    nginx       4.0K Nov 12 01:06 f
esau@DESKTOP-A3RPEKP:~/Edge-Cache-Local/proxy$ curl http://localhost/api/v1/item/2      
{"id":"2","value":"beta"}esau@DESKTOP-A3RPEKP:~/Edge-Cache-Local/proxy$ curl http://locadocker exec -it edge-cache-proxy ls -lh /var/cache/nginx/app_cache
total 8K     
drwx------    3 nginx    nginx       4.0K Nov 12 01:09 1
drwx------    3 nginx    nginx       4.0K Nov 12 01:06 f

```
La memoria asignada corresponde a los id→hash creados , no se repiten

Ahora conviene agregar algunos campos headers para recolectar informacion del cliente y que nginx pueda reenviarlas al backend, las cabeceras usadas en el labo1 son precisas.
```bash
proxy_set_header X-Forwarded-Host $host;
proxy_set_header X-Forwarded-For $remote_addr;
proxy_set_header X-Forwarded-Proto https;
```
Las cabeceras el cliente envia su ip  el host desde donde se hace el query y el protocolo usado respectivamente.
Revisando la sintaxis y recargando nginx , realizamos la consulta incluyendo esas cabeceras se obtiene
```bash
curl -v   -H "X-Forwarded-For: localhost"   -H "X-Forwarded-Proto: https"   -H "X-Forwarded-Host: localhost"     http://loca
lhost/api/v1/item/2
HTTP/1.1 200 OK
< Server: nginx/1.29.3
< Date: Wed, 12 Nov 2025 02:20:27 GMT
< Content-Type: application/json
< Content-Length: 25
< Connection: keep-alive
< cache-control: public, max-age=60
<
* Connection #0 to host localhost left intact
{"id":"2","value":"beta"}
```
Seguidamente modificamos la politica para el endpoint item/ por **"$scheme$request_method$host$uri$is_args$args** pues los retornos no son valores estaticos, recargando nginx, haciendo la consulta y revisando la cache
```bash
curl -H "Host: localhost" http://localhost/api/v1/item/2?id=value
{"id":"2","value":"beta"}
drwx------    3 nginx    nginx       4.0K Nov 12 01:09 1
drwx------    3 nginx    nginx       4.0K Nov 12 02:48 7
drwx------    3 nginx    nginx       4.0K Nov 12 01:06 f
```
Ahora para la gestión de endpoints que no requieren usar cache ,como datos sensibles de usuario definimos  **location /api/no-cache {}** que maneja las peticiones al endpoint en cuestion . Entonces para las directivas usadas en este caso son : proxy_cache_bypass 1, proxy_no_cache 1. Asi evitamos almacenar el cache las respuestas para estas solicitudes de este tipo
```bash
add_header Cache-Control "no-store, no-cache, must-revalidate" always;
```
Con esto ultimo las respuestas no se guardan en disco.

Ahora bien , se agrega la directiva  **add_header X-Cache-Status $upstream_cache_status;** para la medicion del  hit ratio, con esta cabecera usando la variable de nginx usada para indicar el resultado de la operación en cache.


## Agregar modulo monitor (Terraform)
La nueva infraestructura otorga flexilibilidad y es el estilo que se usara para la creacion del nuevo modulo monitor, este simula (en un primer estadio) ejecutando comandos cada cierto tiempo.
Entonces se declara la infraestructura para dicho modulo, en variables.tf
Se tiene la informacion siguiente:  informacion de la imagen, del contenedor, de la red y la politica de reinicio, respesctivamente

Mientras que en main se declara como sera la creacion del contenedor en base a una imagen , cuyo valor se obtiene expandiendo (inyectando) desde variables.tf, el codigo es util como documentacion.Se sabe que  **default = "alpine:latest"** es suficiente para terraform, pues se comunicara con el daemmon docker para construir la imagen y el consiguiente contenedor.

Lo mas interesante es el bloque 
```bash
command = [ "sh","-c","while true; do echo 'monitor en marha: ....'; sleep 10; done"]

```
Dentro del resource "docker_container" "monitor" { }  , que es el monitor encargado de la creacion de los logs cada cierto tiempo

En local-dev, se realiza la composicion del modulo monitor, que se suma a los ya existentes backend  y proxy , este bloque es crucial
```bash
module "monitor" {
  source = "../../modules/monitor"
  nombre_contenedor = "edge-cache-monitor"
  nombre_red        = docker_network.edge_cache.name
  politica_reinicio = var.restart_policy

  depends_on = [docker_network.edge_cache]
}

```
De modo tal que le pasamos los valores de las variables a las variables en monitor.
Se ejecuta de la siguiente manera 
```bash
docker rm -f edge-cache-monitor # limpia el contenedor existente
terraform init
terraform apply
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```
Se ha levantado la infraestructura , construido el contenedor y lanzado el servicio dentro del contenedor , en una misma red ,  junto con los otros contenedores con servicios dentro de ellos.
Y luego 
```bash
docker logs -f edge-cache-monitor
monitor en marha: ....
monitor en marha: ....
monitor en marha: ....
```
Ahora lo que el mmonitor esta operativo debera ejecutar un script analize_logs.py que leera el access.log que nginx guarda, este contiene info de los requests mandados hacia nginx. Luego analize_logs calculara metricas como total de requests, ratio hit, total de bytes transferidos 

Posteriormente estas metricas seran usadas por generate_report.py

Para ello agregamos en main.tf del modulo monitor
```bash
# reemplazar por tu /home/usuario /home/esau/
 volumes {
  host_path      = "/home/esau/Edge-Cache-Local/src/app"
  container_path = "/app"
}

volumes {
  host_path      = "/home/esau/Edge-Cache-Local/logs/nginx.access.log"
  container_path = "/logs/access.log"
}

  # Comando de scraping continuo
  command = [
    "sh", "-c",
    "while true; do python3 /app/analyze_logs.py /logs/access.log --container edge-cache-proxy; sleep ${var.scrape_interval}; done"
  ]
```
la ejecucion habitual y luego 
```bash
docker exec -it edge-cache-monitor ls /app
docker logs edge-cache-monitor
```
