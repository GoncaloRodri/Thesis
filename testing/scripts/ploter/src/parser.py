def parse_detailed(data):
    records = []
    for name, entry in data.items():
        scheduler = entry["tor_params"]["scheduler"]
        is_control = not scheduler.startswith("PRIV")

        # Assign dummy values for control
        epsilon = entry["tor_params"].get("dp_epsilon", "-1.0")

        clients = int(entry["client_params"]["bulk_clients"]) + int(
            entry["client_params"]["web_clients"]
        )

        record = {
            "name": name,
            "scheduler": scheduler,
            "epsilon": epsilon,
            "distribution": (
                "CONTROL"
                if scheduler in ["KIST", "Vanilla"]
                else entry["tor_params"].get("dp_distribution")
            ),
            "clients": clients,
            "is_control": is_control,
            "dummy": entry["tor_params"].get("dummy"),
            "filesize": entry["file_size"],
            "total_cells": entry["total_cells"]["mean"],
            "total_packets": entry["total_packets"]["mean"],
            "total_dummies": entry["total_dummies"]["mean"],
            # LATENCY
            "latency": entry["latency"]["mean"],
            "latency_std_dev": entry["latency"]["stddev"],
            "latency_50": entry["latency_p"]["50th"],
            "latency_90": entry["latency_p"]["90th"],
            "latency_10": entry["latency_p"]["10th"],
            # THROUGHPUT
            "throughput": entry["throughput"]["mean"],
            "throughput_std_dev": entry["throughput"]["stddev"],
            "throughput_50": entry["throughput_p"]["50th"],
            "throughput_10": entry["throughput_p"]["10th"],
            "throughput_90": entry["throughput_p"]["90th"],
            # TOTAL TIME
            "total_time": entry["total_time"]["mean"],
            "total_time_std_dev": entry["total_time"]["stddev"],
            "total_time_50": entry["total_time_p"]["50th"],
            "total_time_10": entry["total_time_p"]["10th"],
            "total_time_90": entry["total_time_p"]["90th"],
            # JITTER
            "jitter": entry["jitter"]["mean"],
            "jitter_std_dev": entry["jitter"]["stddev"],
            "jitter_min": entry["jitter"]["min"],
            "jitter_max": entry["jitter"]["max"],
            "jitter_var": entry["jitter"]["variance"],
        }
        if record["filesize"] in ["51200", "1048576", "5242880"]:
            records.append(record)
        else:
            print(record["filesize"])

    # Convert to DataFrame
    return records
