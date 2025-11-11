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
Tal como indica la descripcion , se implementa un backend basico, que sera el cerebro de nuestra aplicacion,
manejara la logica interna y la comunicacion entre servicios.<br>
En backend/main.tf se DECLARA a docker como proveedor indicando la fuente desde donde obtener la imagen y la version 
luego se declara ademas , que se usara docker y que nos conectemos al daemon local de Docker, el que corre en
nuestro maquina , con una configuracion por defecto en este caso nos conectamos a unix://var/run/docker.sock
```bash
provider "docker" {}
```
![daemon docker](imagenes/daemon_docker.png)
Seguidamente se construye la imagen a partir de una obtenida via ${path.module}/Dockerfile, como se ve los comandos de expansion similares a bash o makefile.Nombrando la imagen con su respectiva etiqueta **backend-api-loca:v1.0**, procediendo en el bloque  build a su construccion, para ello indicamos donde terraform a de buscar **context** y se declara el Dockerfile en cuestion.
```bash
resource "docker_image" "imagen_backend" {
    name = "backend-api-local:v1.0"
    build{
        context = 
        dockerfile =  
    }
}
```
Un detalle a destacar es que "backend-im" es el nombre local que se proporciona a terraform , de modo que **docker_image.imagen_backend.image_id** hace referencia a backend-api-local:v1.0

Ademas es necesario tener docker instalado, el instalador de windows se consigue en la pagina de docker y una vez instalado , ejecutamos **local$ sudo usermod -aG docker $USER**  de modo que podamos acceder al socket antes mencionado

El bloque anterior construye la imagen, una vez hecho esto se construye el contenedor, las primera lineas definen el nombre y la imagen, el bloque port define donde escucha la app(internal) y el puerto expuesto en el host(external), esto es equivalente a **docker run -p internal:external contenedor**.
```bash
ports {
  internal = 
  external = 
}
```
Mientras tanto el bloque env define las variables de entorno
```bash
env = [
  "APP_ENV=local",
  "CACHE_BYPASS=false"
]
```
Lo cual es equivalente a **docker run -e APP_ENV=local -e CACHE_BYPASS=false mi-backend**
Sin embargo  iyectamos variables en lugar de hardcodearlos en main , en tal sentido usamos variables.tf,donde el mismo codigo sirve como documentacion
En tal sentido se define la variable  "docker_context" que especifica el lugar donde se halla el codigo ejecutable del backend , esto es main.py

Tambien var.env_vars.Ademas se asignan valores de configuracion recomendadas 
```bash
  restart        = "no"
  remove_volumes = true
  must_run       = true
  start          = true
}
```

Ahora bien , se requier de un Dockerfile que obtenga la imagen(FROM) , dentro de la imagen cree a carpeta de trabajo (WORKDIR) , copie los archivos app al directorio creado dentro de la imagen (COPY), ejecute el comando de instalacion de las dependencias(RUN comandos), exponga el puerto y ejecute el comando que lanza el backend(CMD)

