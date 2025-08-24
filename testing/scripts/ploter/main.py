import json
import src.parser as parser
import src.plotter as plotter
import src.tabler as tabler
import pandas as pd
import os

SHOW = False
LATENCY_UNIT_CONVERSION = 1000
THROUGHPUT_UNIT_CONVERSION = 0.008


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
df["latency"] = (
    pd.to_numeric(df["latency"], errors="coerce") * LATENCY_UNIT_CONVERSION
)  # (set seconds to miliseconds)
df["throughput"] = (
    pd.to_numeric(df["throughput"], errors="coerce") * THROUGHPUT_UNIT_CONVERSION
)
df["total_time"] = pd.to_numeric(df["total_time"], errors="coerce")
df["jitter_std_dev"] = pd.to_numeric(df["jitter_std_dev"], errors="coerce")
df["latency_std_dev"] = pd.to_numeric(df["latency_std_dev"], errors="coerce")
df["throughput_std_dev"] = pd.to_numeric(df["throughput_std_dev"], errors="coerce")
df["total_time_std_dev"] = pd.to_numeric(df["total_time_std_dev"], errors="coerce")
df["latency_10"] = (
    pd.to_numeric(df["latency_10"], errors="coerce") * LATENCY_UNIT_CONVERSION
)  # (set seconds to miliseconds)
df["throughput_10"] = (
    pd.to_numeric(df["throughput_10"], errors="coerce")
) * THROUGHPUT_UNIT_CONVERSION

df["total_time_10"] = pd.to_numeric(df["total_time_10"], errors="coerce")
df["latency_25"] = (
    pd.to_numeric(df["latency_25"], errors="coerce") * LATENCY_UNIT_CONVERSION
)  # (set seconds to miliseconds)
df["throughput_25"] = (
    pd.to_numeric(df["throughput_25"], errors="coerce")
) * THROUGHPUT_UNIT_CONVERSION

df["total_time_25"] = pd.to_numeric(df["total_time_25"], errors="coerce")
df["latency_50"] = (
    pd.to_numeric(df["latency_50"], errors="coerce") * LATENCY_UNIT_CONVERSION
)  # (set seconds to miliseconds)
df["throughput_50"] = (
    pd.to_numeric(df["throughput_50"], errors="coerce")
) * THROUGHPUT_UNIT_CONVERSION

df["total_time_50"] = pd.to_numeric(df["total_time_50"], errors="coerce")
df["latency_75"] = (
    pd.to_numeric(df["latency_75"], errors="coerce") * LATENCY_UNIT_CONVERSION
)  # (set seconds to miliseconds)
df["throughput_75"] = (
    pd.to_numeric(df["throughput_75"], errors="coerce")
) * THROUGHPUT_UNIT_CONVERSION

df["total_time_75"] = pd.to_numeric(df["total_time_75"], errors="coerce")
df["latency_90"] = (
    pd.to_numeric(df["latency_90"], errors="coerce") * LATENCY_UNIT_CONVERSION
)  # (set seconds to miliseconds)
df["throughput_90"] = (
    pd.to_numeric(df["throughput_90"], errors="coerce")
) * THROUGHPUT_UNIT_CONVERSION

df["total_time_90"] = pd.to_numeric(df["total_time_90"], errors="coerce")

filesizes = df["filesize"].unique()
metrics = [
    "jitter",
    "latency_50",
    "throughput_50",
    "total_time_50",
]

distributions = df["distribution"].unique()
schedulers = df["scheduler"].unique()


plotter.plot_dummy_count(df, SHOW)
plotter.plot_dummy_ratio(df, SHOW)
plotter.plot_packet_count(df, SHOW)

for metric in metrics:
    for filesize in filesizes:
        plotter.plot_heatmap(metric, filesize, df, SHOW)
        plotter.plot_jitter(metric, filesize, df, SHOW)
        plotter.plot_jitter_dummy(metric, filesize, df, SHOW)
        plotter.plot_dummy(metric, filesize, df, SHOW)
        for dist in distributions:
            if dist == "CONTROL":
                continue
            plotter.plot_jitter_by_distribution(metric, dist, filesize, df, SHOW)

        print(f"Overview Table for {metric} at filesize {filesize}")
        tab = tabler.table_dummy(metric, filesize, df)
        print(json.dumps(tab, indent=2))
        print(json.dump(tab, open(f"table_{metric}_{filesize}.json", "w"), indent=2))


print("Plots generated successfully.")
exit(0)
