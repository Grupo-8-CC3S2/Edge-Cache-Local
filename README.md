# Edge-Cache-Local
CDN casera con Nginx + pruebas de performance
El proyecto consiste en montar un reverse proxy con caché (Nginx) delante de un servicio backend, con políticas de cacheo, invalidación y observabilidad de hit/miss. Ademas en la orquestación local con Terraform (docker provider/localexec, evitando imports manuales).
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
