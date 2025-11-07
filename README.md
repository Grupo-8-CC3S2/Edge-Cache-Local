# Edge-Cache-Local
CDN casera con Nginx + pruebas de performance
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
