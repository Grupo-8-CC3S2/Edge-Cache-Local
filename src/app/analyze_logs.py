#!/usr/bin/env python3
"""
Versión mínima de analyze_logs.py
Lee un archivo de log y muestra algunas métricas básicas
"""

import sys
from pathlib import Path

def main():
    log_path = sys.argv[1] if len(sys.argv) > 1 else "/logs/access.log"
    
    log_file = Path(log_path)
    if not log_file.exists():
        print(f"Error: {log_path} no existe")
        sys.exit(1)
    
    total_lines = 0
    total_bytes = 0
    hits = 0
    misses = 0

    with log_file.open("r") as f:
        for line in f:
            total_lines += 1
            total_bytes += len(line)
            # Suponiendo que las líneas con "200" son hits y "404" son misses
            if "200" in line:
                hits += 1
            elif "404" in line:
                misses += 1

    hit_ratio = (hits / total_lines) if total_lines else 0

    print(f"Total requests: {total_lines}")
    print(f"Cache hits (200): {hits}")
    print(f"Cache misses (404): {misses}")
    print(f"Hit ratio: {hit_ratio:.2%}")
    print(f"Total bytes: {total_bytes}")

if __name__ == "__main__":
    main()
