import numpy as np
import json

def merge_latency(keys, data):
    latencies = []
    latencies.extend(
        data[key].get("latency")
        for key in keys
        if key in data and "latency" in data[key]
    )
    if not latencies:
        print("No latency data found for the provided keys.")
        return {"mean": 0, "min": 0, "max": 0, "stddev": 0}

    return {
        "mean": np.mean([d["mean"] for d in latencies]),
        "min": np.min([d["min"] for d in latencies]),
        "max": np.max([d["max"] for d in latencies]),
        "stddev": np.mean([d["std"] for d in latencies]),
        "median": np.mean([d["median"] for d in latencies])
    }


def merge_throughput(keys, data):
    throughputs = []
    throughputs.extend(data[key].get("throughput", {}) for key in keys if key in data)
    if not throughputs:
        print("No throughput data found for the provided keys.")
        return {"mean": 0, "min": 0, "max": 0, "stddev": 0}

    return {
        "mean": np.mean([d["mean"] for d in throughputs]),
        "min": np.min([d["min"] for d in throughputs]),
        "max": np.max([d["max"] for d in throughputs]),
        "stddev": np.mean([d["std"] for d in throughputs]),
        "median": np.mean([d["median"] for d in throughputs])
    }

def merge_jitter(keys, data):
    jitters = []
    jitters.extend(data[key].get("jitter", {}) for key in keys if key in data)
    if not jitters:
        print("No jitter data found for the provided keys.")
        return {"mean": 0, "min": 0, "max": 0, "stddev": 0}

    return {
        "mean": np.mean([d["mean"] for d in jitters]),
        "min": np.min([d["min"] for d in jitters]),
        "max": np.max([d["max"] for d in jitters]),
        "stddev": np.mean([d["deviation"] for d in jitters]),
        "variance": np.mean([d["variance"] for d in jitters])
    }

def merge_total_time(keys, data):
    total_times = []
    total_times.extend(data[key].get("total_time", {}) for key in keys if key in data)
    if not total_times:
        print("No total time data found for the provided keys.")
        return {"mean": 0, "min": 0, "max": 0, "stddev": 0}

    return {
        "mean": np.mean([d["mean"] for d in total_times]),
        "min": np.min([d["min"] for d in total_times]),
        "max": np.max([d["max"] for d in total_times]),
        "stddev": np.mean([d["std"] for d in total_times]),
        "median": np.mean([d["median"] for d in total_times])
    }


def merge_total_packets(keys, data):
    total_packets = []
    total_packets.extend(
        data[key].get("total_packets")
        for key in keys
        if key in data and "total_packets" in data[key]
    )
    print(f"Total packets: {total_packets}")

    if not total_packets:
        print("No total time data found for the provided keys.")
        return {"mean": 0, "min": 0, "max": 0}

    return {
        "mean": np.mean(total_packets),
        "min": np.min(total_packets) * 1.0,
        "max": np.max(total_packets) * 1.0,
    }


def merge_total_dummies(keys, data):
    total_dummies = []
    total_dummies.extend(
        data[key].get("total_dummies")
        for key in keys
        if key in data and "total_dummies" in data[key]
    )
    print(f"Total dummies: {total_dummies}")

    if not total_dummies:
        print("No total dummies data found for the provided keys.")
        return {"mean": 0, "min": 0, "max": 0}

    return {
        "mean": np.mean(total_dummies),
        "min": np.min(total_dummies) * 1.0,
        "max": np.max(total_dummies) * 1.0,
    }


def merge_total_cells(keys, data):
    total_cells = []
    total_cells.extend(
        data[key].get("total_cells")
        for key in keys
        if key in data and "total_cells" in data[key]
    )
    print(f"Total cells: {total_cells}")

    if not total_cells:
        print("No total cells data found for the provided keys.")
        return {"mean": 0, "min": 0, "max": 0}

    return {
        "mean": np.mean(total_cells),
        "min": np.min(total_cells) * 1.0,
        "max": np.max(total_cells) * 1.0,
    }
