import json
import src.parser as parser
import src.plotter as plotter
import pandas as pd
import matplotlib as plt
import os

SHOW = True

# Load the JSON file
with open(f"{os.getcwd()}/testing/results/detailed_results.json") as f:
    data = json.load(f)

# Unique DP distributions
data = parser.parse_detailed(data)
# Generate plots for each metric, for each DP distribution
df = pd.DataFrame(data)
df["clients"] = pd.to_numeric(df["clients"], errors="coerce")
df["epsilon"] = pd.to_numeric(df["epsilon"])  # keeps NaN for "control"
df["jitter"] = pd.to_numeric(df["jitter"], errors="coerce")
df["dummy"] = pd.to_numeric(df["dummy"], errors="coerce")
df["latency"] = pd.to_numeric(df["latency"], errors="coerce")
df["throughput"] = pd.to_numeric(df["throughput"], errors="coerce")
df["total_time"] = pd.to_numeric(df["total_time"], errors="coerce")
df["latency_95"] = pd.to_numeric(df["latency_95"], errors="coerce")
df["throughput_95"] = pd.to_numeric(df["throughput_95"], errors="coerce")
df["total_time_95"] = pd.to_numeric(df["total_time_95"], errors="coerce")
df["latency_75"] = pd.to_numeric(df["latency_75"], errors="coerce")
df["throughput_75"] = pd.to_numeric(df["throughput_75"], errors="coerce")
df["total_time_75"] = pd.to_numeric(df["total_time_75"], errors="coerce")
df["latency_25"] = pd.to_numeric(df["latency_25"], errors="coerce")
df["throughput_25"] = pd.to_numeric(df["throughput_25"], errors="coerce")
df["total_time_25"] = pd.to_numeric(df["total_time_25"], errors="coerce")

filesizes = df["filesize"].unique()
metrics = [
    "jitter",
    "total_packets",
    "total_dummies",
    "latency_50",
    "throughput_50",
    "total_time_50",
    "latency_95",
    "throughput_95",
    "total_time_95",
    "latency",
    "throughput",
    "total_time",
]

# metrics = ["total_packets", "jitter", "jitter_variance", "jitter_stddev"]
distributions = df["distribution"].unique()
schedulers = df["scheduler"].unique()

plotter.plot_dummy_count(df, SHOW)

for metric in metrics:
    for filesize in filesizes:
        plotter.plot_jitter(metric, filesize, df, SHOW)
        plotter.plot_jitter_dummy(metric, filesize, df, SHOW)
        plotter.plot_dummy(metric, filesize, df, SHOW)
        for dist in distributions:
            if dist == "CONTROL":
                continue
            plotter.plot_jitter_by_distribution(metric, dist, filesize, df, SHOW)


print("Plots generated successfully.")
exit(0)
