from collections import defaultdict
import utils.utils as utils
import utils.math as math_utils
import math
import json


def get_info(tor_log_files):
    relays = []
    total_dummies = 0
    total_cells = 0
    for filepath in tor_log_files:
        if not filepath.endswith(".log"):
            raise ValueError(f"Invalid file format: {filepath}. Expected .log file.")
        data, dummies, cells = parse_log(filepath)
        total_dummies += dummies
        total_cells += cells
        relays.extend(extract_circuits_data(data, filepath))

    return compute_stats(relays, total_dummies, total_cells)


def compute_stats(relays, total_dummies, total_cells):
    total_packets = math_utils.get_sum(r["num_packets"] for r in relays)

    if total_packets == 0:
        raise ValueError("Total number of packets is zero. Cannot compute statistics.")

    overall_min = math_utils.get_min(r["min_jitter"] for r in relays)
    overall_max = math_utils.get_max(r["max_jitter"] for r in relays)
    overall_mean = math_utils.get_sum(r["mean_jitter"] * r["num_packets"] for r in relays) / total_packets
    overall_variance = math_utils.get_sum(
        (r["num_packets"] - 1) * r["variance_jitter"] + 
        r["num_packets"] * ((r["mean_jitter"] - overall_mean) ** 2)
        for r in relays
    ) / (total_packets - 1)
    overall_deviation = math.sqrt(overall_variance)
    connections = {r["filename"]: r["connections"] for r in relays}
    return {
        "jitter": {
            "min": overall_min,
            "max": overall_max,
            "mean": overall_mean,
            "variance": overall_variance,
            "deviation": overall_deviation,
        },
        "total_packets": total_packets,
        "connections": connections,
        "total_dummies": total_dummies,
        "total_cells": total_cells,
    }


def extract_circuits_data(data, fs):
    connections = {}
    connections[data[0][0].split(":")[0]] = connections.get(data[0][0].split(":")[0], 0) + 1
    deltas = []
    last_ts = float(data[0][1])
    for i, (sender, ts) in enumerate(data, 1):
        deltas.append(float(ts) - last_ts)
        last_ts = float(ts)
        connections[sender.split(":")[0]] = connections.get(sender.split(":")[0], 0) + 1

    return [
        {
            "filename": fs.split("/")[-1].replace(".tor.log", ""),
            "mean_jitter": math_utils.get_mean(deltas),
            "max_jitter": math_utils.get_max(deltas),
            "min_jitter": math_utils.get_min(deltas),
            "variance_jitter": math_utils.get_variance(deltas),
            "deviation_jitter": math_utils.get_std_deviation(deltas),
            "num_packets": len(data),
            "connections": connections,
        }
    ]


def parse_log(filepath):
    parsed_data, dummies, cells = parse_file(filepath)
    return sort_data(parsed_data), dummies, cells

def parse_file(file):
    parsed_data = []
    dummies = 0
    cells = 0
    with open(file) as f:
        for line in f:
            if info := parse_line(line):
                sender, ts = info
                parsed_data.append((sender, ts))
            if "[Packet Padding Cell] Dummy Cell added to queue sucessfully!" in line:
                dummies += 1
            if "[Cell] Added to circuit queue" in line:
                cells += 1

    print(f"Found {dummies} dummy cells and {cells} total cells in {file}.")
    return parsed_data, dummies, cells

def parse_line(line):
    if "TLS_RECEIVED:" not in line:
        return None
    ts = parse_info(line, "time=", ", ") if "time=" in line else None
    sender = parse_info(line, "from=", " ") if "from=" in line else None

    return (sender, ts) if sender and ts else None

def parse_info(line, description, regex):
    start = (
        line.find(description) + len(description)
    )
    end = line.find(regex, start)
    return (
        line[start:end].strip()
        if end != -1
        else line[start:].strip()
    )

def sort_data(parsed_data):
    return sorted(parsed_data, key=lambda x: float(x[1]))
