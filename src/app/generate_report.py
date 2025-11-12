#!/usr/bin/env python3
"""
Versión mínima de generate_report.py
Lee un JSON de métricas y genera un resumen legible en texto
"""

import sys
import json
from pathlib import Path

def main():
    if len(sys.argv) < 2:
        print("Uso: python3 generate_report.py metrics.json", file=sys.stderr)
        sys.exit(1)
    
    metrics_file = Path(sys.argv[1])
    if not metrics_file.exists():
        print(f"Error: {metrics_file} no existe", file=sys.stderr)
        sys.exit(1)

    data = json.load(metrics_file)
    metrics = data.get("metrics", {})

    total = metrics.get("total_requests", 0)
    hits = metrics.get("cache_hits", 0)
    misses = metrics.get("cache_misses", 0)
    hit_ratio = (hits / total) if total else 0

    print(f"Reporte de Performance - {data.get('timestamp', 'N/A')}")
    print("="*40)
    print(f"Total Requests: {total}")
    print(f"Cache Hits: {hits}")
    print(f"Cache Misses: {misses}")
    print(f"Hit Ratio: {hit_ratio:.2%}")
    print(f"Total Bytes: {metrics.get('total_bytes', 0)}")
    
    # Status codes simples
    status_codes = metrics.get("status_codes", {})
    if status_codes:
        print("\nStatus Codes:")
        for code, count in sorted(status_codes.items()):
            pct = (int(count)/total*100) if total else 0
            print(f"  {code}: {count} ({pct:.2f}%)")
    
    sys.exit(0)

if __name__ == "__main__":
    main()
