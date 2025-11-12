## Agrega modulo monitor

- Declaracion de modulo monitor quien correra dentro de una imagen en un contenedor python. 

- Ejecucion del loop para la metrica por logs

    'command = [
        "sh", "-c",
        "while true; do python3 /app/analyze_logs.py /logs/access.log --container edge-cache-proxy; sleep ${var.scrape_interval}; done"
    ]'

- Tratamiento del logs para la obtencion de info como   total_lines  , total_bytes , hits y misses

'Total requests: 3
Cache hits (200): 2
Cache misses (404): 0
Hit ratio: 66.67%
Total bytes: 297'

Esto para cada request que nginx va almacenando en nginx.access.log