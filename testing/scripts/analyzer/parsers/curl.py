import re
import numpy as np


def get_info(data) -> list[dict]:
    results = []
    if not data:
        raise FileNotFoundError("No curl log file found!")
    results = parse_curl_log(data)
    return compute_stats(results)


def compute_metrics(stats: dict) -> dict:
    return {
        "min": float(np.min(stats)),
        "max": float(np.max(stats)),
        "mean": float(np.mean(stats)),
        "std": float(np.std(stats)),
        "percentiles": {
            "10th": float(np.percentile(stats, 10)),
            "50th": float(np.percentile(stats, 50)),
            "90th": float(np.percentile(stats, 90)),
        },
    }


def compute_stats(curl_logs: list[dict]) -> dict | None:
    latencies = [entry["latency"] for entry in curl_logs]
    total_times = [entry["total_time"] for entry in curl_logs]
    throughputs = [entry["throughput"] for entry in curl_logs]

    if not latencies or not total_times or not throughputs:
        return None

    return {
        "latency": compute_metrics(latencies),
        "total_time": compute_metrics(total_times),
        "throughput": compute_metrics(throughputs),
    }


def parse_curl_log(lines):
    results = []
    i = 0
    non200curl = 0
    if not lines:
        return []
    while i < len(lines):
        if lines[i].startswith("URL:"):
            url = lines[i].strip().split("URL: ")[-1]
            code = lines[i + 1].strip().split("Code: ")[-1]
            latency = float(re.search(r"([\d.]+)", lines[i + 2])[1])
            total_time = float(re.search(r"([\d.]+)", lines[i + 3])[1])
            throughput = int(re.search(r"(\d+)", lines[i + 4])[1])

            if code == "200":
                results.append(
                    {
                        "url": url,
                        "latency": latency,
                        "total_time": total_time,
                        "throughput": throughput,
                    }
                )
            else:
                non200curl += 1

            i += 5
        else:
            i += 1  # Skip malformed lines if any

    print(f"Non-200 responses found in curl logs: {non200curl}")

    return results
