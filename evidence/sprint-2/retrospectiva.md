# sprint 2 - Retrospectiva
## Que se consiguió
**Reglas de cache**<br>

Mediante la configuracion de nginx , de modo que agregamos politicas de cache.
Mediante proxy_cache_key logramos que se identifique un recurso y guarde en cache, de modo que si el query se dirige al mismo recurso , banckend no sea sobrecargado y sea nginx quien responda via su cache local.
Esto para los endpoints existentes en main.py
Todo ello comprende las reglas de cache.

**Invalidacion selectiva**<br>

Mediante el bypass , se ignora peticiones con contenido sensible

## Lo que no se consiguió 
**Validación purga manual**

## Deuda tecnica
No hay dashboard de metricas

No se realizaron pruebas de expiración (`max-age`) prolongadas, por lo que el ciclo de vida completo de la caché no se validó aún
## Pendientes
..
