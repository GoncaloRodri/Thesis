import pandas as pd


def parse_detailed(data):
    records = []
    for name, entry in data.items():
        scheduler = entry["tor_params"]["scheduler"]
        is_control = not scheduler.startswith("PRIV")

        # Assign dummy values for control
        epsilon = entry["tor_params"].get("dp_epsilon", "-1.0")

        clients = int(entry["client_params"]["bulk_clients"]) + int(entry["client_params"]["web_clients"])

        record = {
            "name": name,
            "scheduler": scheduler,
            "epsilon": epsilon,
            "distribution": entry["tor_params"].get("dp_distribution", "CONTROL"),
            "clients": clients,
            "latency": entry["latency"]["mean"],
            "latency_95": entry["latency_p"]["95th"],
            "latency_50": entry["latency_p"]["50th"],
            "latency_75": entry["latency_p"]["75th"],
            "latency_25": entry["latency_p"]["25th"],
            "throughput": entry["throughput"]["mean"],
            "throughput_95": entry["throughput_p"]["95th"],
            "throughput_50": entry["throughput_p"]["50th"],
            "throughput_75": entry["throughput_p"]["75th"],
            "throughput_25": entry["throughput_p"]["25th"],
            "jitter": entry["jitter"]["mean"],
            "total_time": entry["total_time"]["mean"],
            "total_time_95": entry["total_time_p"]["95th"],
            "total_time_50": entry["total_time_p"]["50th"],
            "total_time_75": entry["total_time_p"]["75th"],
            "total_time_25": entry["total_time_p"]["25th"],
            "is_control": is_control,
            "dummy": entry["tor_params"].get("dummy", False),
            "filesize": entry["file_size"],
            "total_cells": entry["total_cells"]["mean"],
            "total_packets": entry["total_packets"]["mean"],
            "total_dummies": entry["total_dummies"]["mean"],
        }
        if record["filesize"] != "5120":
            records.append(record)

    # Convert to DataFrame
    return records
