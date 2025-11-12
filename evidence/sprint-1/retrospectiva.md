# sprint 1 - Retrospectiva
## Que se consiguió
- Se declara y posteriormente se levanta la infraestructura de los modulos , esto se conigue en cada modulo propiamente, pero tambien dentro de proxy por ejemplo , cuando terraform utiliza la rutas declaradas en variables.tf

Se construyen las imagenes y contenedores, para el banckend y nginx, asi como una red donde se comunican, se consigue que nginx rediriga peticiones a nuestro banckend. Ademas el proxy contiene mas funcionalidades como los workeres , quienes gestionaran hilos para las solicitudes , un maximo de 1024.

## Lo que no se consiguió 
Si bien ejecutando terraform apply dentro de infra/modules/proxy se obtiene el cometido, desde local-dev la ejecucion no llega a "buen puerto".
Una configuracion no desea de las rutas , impidio usar composabilidad, terraform no logra encontrar las rutas de las imagenes.

## Deuda tecnica
En cuanto a la infraestructura , no se realiazo nigun xfail o algun skip

## Pendientes
Corregir lo mencionado la seccion "Lo que no se consiguio" 
