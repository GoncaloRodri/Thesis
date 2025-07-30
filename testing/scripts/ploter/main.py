import json
import src.parser as parser
import src.plotter as plotter
import pandas as pd
import os

SHOW = False

# Load the JSON file
with open(f"{os.getcwd()}/testing/results/detailed_results.json") as f:
    data = json.load(f)

# Unique DP distributions
data = parser.parse_detailed(data)
# Generate plots for each metric, for each DP distribution
df = pd.DataFrame(data)
df["clients"] = pd.to_numeric(df["clients"], errors="coerce")
df["epsilon"] = pd.to_numeric(df["epsilon"])  # keeps NaN for "control"
df["dummy"] = pd.to_numeric(df["dummy"], errors="coerce")
df["jitter"] = pd.to_numeric(df["jitter"], errors="coerce")
df["latency"] = pd.to_numeric(df["latency"], errors="coerce")
df["throughput"] = pd.to_numeric(df["throughput"], errors="coerce")
df["total_time"] = pd.to_numeric(df["total_time"], errors="coerce")
df["jitter_std_dev"] = pd.to_numeric(df["jitter_std_dev"], errors="coerce")
df["latency_std_dev"] = pd.to_numeric(df["latency_std_dev"], errors="coerce")
df["throughput_std_dev"] = pd.to_numeric(df["throughput_std_dev"], errors="coerce")
df["total_time_std_dev"] = pd.to_numeric(df["total_time_std_dev"], errors="coerce")
df["latency_10"] = pd.to_numeric(df["latency_10"], errors="coerce")
df["throughput_10"] = pd.to_numeric(df["throughput_10"], errors="coerce")
df["total_time_10"] = pd.to_numeric(df["total_time_10"], errors="coerce")
df["latency_50"] = pd.to_numeric(df["latency_50"], errors="coerce")
df["throughput_50"] = pd.to_numeric(df["throughput_50"], errors="coerce")
df["total_time_50"] = pd.to_numeric(df["total_time_50"], errors="coerce")
df["latency_90"] = pd.to_numeric(df["latency_90"], errors="coerce")
df["throughput_90"] = pd.to_numeric(df["throughput_90"], errors="coerce")
df["total_time_90"] = pd.to_numeric(df["total_time_90"], errors="coerce")

filesizes = df["filesize"].unique()
metrics = [
    "jitter",
    "latency_50",
    "throughput",
    "total_time",
]

# metrics = ["total_packets", "jitter", "jitter_variance", "jitter_stddev"]
distributions = df["distribution"].unique()
schedulers = df["scheduler"].unique()

plotter.plot_dummy_count(df, SHOW)
plotter.plot_dummy_ratio(df, SHOW)
plotter.plot_packet_count(df, SHOW)

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
