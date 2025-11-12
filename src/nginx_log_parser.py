import re
from collections import Counter, defaultdict

LINE = re.compile(
    r'"\w+\s(?P<path>[^"\s?]+)(?:\?[^"]*)?\sHTTP/[^"]+"\s(?P<status>\d{3}).*\s(?P<reqtime>\d+\.\d+)$'
)

def parse_lines(lines):
    by_path = Counter()
    by_status = Counter()
    times = defaultdict(list)

    for ln in lines:
        m = LINE.search(ln)
        if not m:
            continue
        path = m.group("path")
        status = m.group("status")
        req_time = float(m.group("reqtime"))
        by_path[path] += 1
        by_status[status] += 1
        times[path].append(req_time)

    avg_time = {p: round(sum(v)/len(v), 4) for p, v in times.items()}
    return {"by_path": dict(by_path), "by_status": dict(by_status), "avg_time": avg_time}

if __name__ == "__main__":
    import sys, json
    data = sys.stdin.readlines()
    print(json.dumps(parse_lines(data), indent=2))
