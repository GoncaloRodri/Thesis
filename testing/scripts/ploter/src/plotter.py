import matplotlib.pyplot as plt
import seaborn as sns
import os


def plot_dummy(metric, filesize, data, show=False):
    fig, ax = plt.subplots()
    for (sched, eps, file_size, dist), group in data.groupby(
        ["scheduler", "epsilon", "filesize", "distribution"]
    ):
        if file_size != filesize or float(eps) >= 0:
            continue

        filtered_group = group[group["dummy"] >= 0]
        group_sorted = filtered_group.sort_values("dummy")

        # __plot(ax, group_sorted["dummy"], group_sorted[metric], sched)

        __fill_between(
            ax, "dummy", group_sorted, metric, sched, label=f"{sched}-{dist}"
        )

    if __draw_ax(
        ax,
        "Dummy Epsilon",
        get_title("PPC", metric, filesize),
        metric,
        filesize,
    ):
        return

    __save_fig(
        fig,
        metric,
        filesize,
        "dummy",
        show,
    )


def plot_jitter_by_distribution(metric, dist, filesize, data, show=False):
    fig, ax = plt.subplots()
    for (sched, dummy, file_size, distribution), group in data.groupby(
        ["scheduler", "dummy", "filesize", "distribution"]
    ):
        if (
            file_size != filesize
            or distribution != dist != "CONTROL"
            or float(dummy) >= 0
        ):
            continue

        filtered_group = group[group["epsilon"] >= 0]
        group_sorted = filtered_group.sort_values("epsilon")

        # __plot(ax, group_sorted["epsilon"], group_sorted[metric], sched)
        __fill_between(ax, "epsilon", group_sorted, metric, sched, label=sched)

    if __draw_ax(
        ax,
        "Jitter Induction Epsilon",
        get_title(f"{distribution.capitalize()} Jitter Schedulers", metric, filesize),
        metric,
        filesize,
    ):
        return

    __save_fig(
        fig,
        metric,
        filesize,
        f"jitter_{dist.capitalize()}",
        show,
    )


def plot_jitter(metric, filesize, data, show=False):
    fig, ax = plt.subplots()
    for (sched, dummy, file_size, dist), group in data.groupby(
        ["scheduler", "dummy", "filesize", "distribution"]
    ):
        if file_size != filesize or float(dummy) >= 0:
            continue
        filtered_group = group[group["epsilon"] >= 0]
        group_sorted = filtered_group.sort_values("epsilon")
        label = (
            f"{sched} | {dist.capitalize()}"
            if sched not in ["KIST", "Vanilla"]
            else f"{sched}"
        )

        # __plot(ax, group_sorted["epsilon"], group_sorted[metric], sched, label=label)

        __fill_between(ax, "epsilon", group_sorted, metric, sched, label=label)

    if __draw_ax(
        ax,
        "Jitter Induction Epsilon",
        get_title("Jitter Induction Schedulers", metric, filesize),
        metric,
        filesize,
    ):
        return

    __save_fig(
        fig,
        metric,
        filesize,
        "jitter",
        show,
    )


def plot_heatmap(metric, filesize, data, show=False):
    fig, ax = plt.subplots(figsize=(15, 10))
    filtered_data = data[
        (data["epsilon"] >= 0)
        & (data["dummy"] >= 0)
        & (data["filesize"] == filesize)
        & (data["scheduler"] == "PRIV_KIST")
        & (data["distribution"] == "LAPLACE")
    ]
    pivot_table = filtered_data.pivot(index="dummy", columns="epsilon", values=metric)
    ordered_table = pivot_table.sort_index().sort_index(axis=1)
    ax = sns.heatmap(
        ordered_table, annot=True, fmt=".3f", cmap="viridis", linewidths=0.5
    )
    ax.invert_yaxis()
    ax.set_xlabel("Jitter Induction Epsilon")
    ax.set_ylabel("PPC Epsilon")
    ax.set_title(get_title("Both Features", metric, filesize))
    __save_fig(
        plt.gcf(),
        metric,
        filesize,
        f"heatmap_{get_file_sizes(filesize).lower().replace(' ', '_')}",
        show,
    )


def plot_jitter_dummy(metric, filesize, data, show=False):
    fig, ax = plt.subplots()
    for (sched, file_size, dist), group in data.groupby(
        ["scheduler", "filesize", "distribution"]
    ):
        if file_size != filesize or dist != "LAPLACE":
            continue
        filtered_group = group[(group["epsilon"] >= 0) & (group["dummy"] >= 0)]
        group_sorted = filtered_group.sort_values("epsilon")
        label = (
            f"{sched} | {dist.capitalize()}"
            if sched not in ["KIST", "Vanilla"]
            else f"{sched}"
        )

        ax.scatter(
            group_sorted["dummy"],
            group_sorted["epsilon"],
            c=group_sorted[metric],
            cmap="coolwarm",
            alpha=0.7,
            marker="o",
            label=label,
            linestyle=get_line_style(sched),
        )

    if not ax.collections:
        plt.close(fig)
        return

    ax.set_title(get_title("Both Features", metric, filesize))
    ax.set_xlabel("PPC Epsilon")
    ax.set_ylabel("Jitter Induction Epsilon")
    ax.legend(bbox_to_anchor=(1.05, 1))
    ax.grid(True)
    __save_fig(
        fig,
        metric,
        filesize,
        f"jitter_dummy_{get_file_sizes(filesize).lower().replace(' ', '_')}",
        show,
    )


def plot_dummy_count(data, show=False):
    fig, ax = plt.subplots()
    for (sched, eps, file_size, dist), group in data.groupby(
        ["scheduler", "epsilon", "filesize", "distribution"]
    ):

        if float(eps) >= 0:
            continue

        filtered_group = group[group["dummy"] >= 0]
        group_sorted = filtered_group.sort_values("dummy")

        __plot(
            ax,
            group_sorted["dummy"],
            group_sorted["total_dummies"],
            sched,
            label=f"{sched} | {get_file_sizes(file_size)}",
        )

    if __draw_ax(
        ax,
        "PPC Epsilon",
        "Nº of False Cells Generated",
        "dummy_count",
        file_size,
    ):
        print(f"No data to plot for dummy count with file size {file_size}")
        return

    __save_fig(
        fig,
        "dummy_count",
        "",
        "dummy_count",
        show,
    )


def plot_dummy_ratio(data, show=False):
    fig, ax = plt.subplots()
    for (sched, eps, file_size, dist), group in data.groupby(
        ["scheduler", "epsilon", "filesize", "distribution"]
    ):

        if float(eps) >= 0:
            continue

        filtered_group = group[group["dummy"] >= 0]
        group_sorted = filtered_group.sort_values("dummy")

        __plot(
            ax,
            group_sorted["dummy"],
            [
                (d / (cell)) * 100
                for d, cell in zip(
                    group_sorted["total_dummies"], group_sorted["total_cells"]
                )
            ],
            sched,
            label=f"{sched} | {get_file_sizes(file_size)}",
        )

    if __draw_ax(
        ax,
        "PPC Epsilon",
        "PPC False Cells Ratio",
        "dummy_ratio",
        file_size,
    ):
        print(f"No data to plot for dummy count with file size {file_size}")
        return

    __save_fig(
        fig,
        "PPC Ratio",
        file_size,
        "dummy_ratio",
        show,
    )


def plot_packet_count(data, show=False):
    fig, ax = plt.subplots()
    for (sched, eps, file_size, dist), group in data.groupby(
        ["scheduler", "epsilon", "filesize", "distribution"]
    ):

        if float(eps) >= 0:
            continue

        # print(group)
        filtered_group = group[group["dummy"] >= 0]
        group_sorted = filtered_group.sort_values("dummy")

        __plot(
            ax,
            group_sorted["dummy"],
            group_sorted["total_packets"],
            sched,
            label=f"{sched} | {get_file_sizes(file_size)}",
        )

    if __draw_ax(
        ax,
        "PPC Epsilon",
        "PPC Total TLS Packets",
        "dummy_count",
        file_size,
    ):
        print(f"No data to plot for dummy count with file size {file_size}")
        return

    __save_fig(
        fig,
        "packet_count",
        file_size,
        "packet_count",
        show,
    )


########################################
# Helpers
########################################


def __plot(ax, x, y, sched, label=None):
    """
    Helper function to plot data with common settings.
    """
    ax.plot(
        x,
        y,
        marker="o",
        label=label if label else f"{sched}",
        linestyle=get_line_style(sched),
    )


def __draw_ax(ax, x_label, title, metric, file_size):
    """
    Helper function to finalize the plot with common settings.
    """
    if not ax.lines:
        plt.close("all")
        return True

    ax.set_title(title)
    ax.set_xlabel(x_label)
    ax.set_ylabel(get_axis_label(metric))
    ax.legend(loc="best", bbox_to_anchor=(1.05, 1))
    ax.grid(True)
    return False


def __save_fig(fig, metric, file_size, file_name, show=False):
    """
    Helper function to save the figure with common settings.
    """
    path = f"{abs_path()}/{metric}"
    os.makedirs(path, exist_ok=True)
    fig.savefig(
        f"{path}/{file_name}_{get_file_sizes(file_size).lower().replace(' ', '_')}.png",
        dpi=300,
        bbox_inches="tight",
    )
    if show:
        fig.show()
    plt.close("all")


def __fill_between(ax, variable, group_sorted, metric, sched, label=""):
    """
    Helper function to fill the area between two percentiles.
    """

    if metric not in [
        "latency",
        "throughput",
        "total_time",
        "jitter",
        "latency_50",
        "throughput_50",
        "total_time_50",
    ]:
        return

    if "_50" in metric:
        metric_10 = metric.replace("50", "25")
        metric_90 = metric.replace("50", "75")

        ax.plot(
            group_sorted[variable],
            group_sorted[metric],
            marker="o",
            label=label if label else f"{sched}",
            linestyle=get_line_style(sched),
        )

        ax.fill_between(
            group_sorted[variable],
            group_sorted[metric_10],
            group_sorted[metric_90],
            alpha=0.4,
        )
        return

    if "jitter" in metric:

        lower_b = group_sorted[metric] - group_sorted[f"{metric}_var"]
        upper_b = group_sorted[metric] + group_sorted[f"{metric}_var"]

        lower_clamped = lower_b.clip(lower=0)

        lower_error = group_sorted[metric] - lower_clamped
        upper_error = upper_b - group_sorted[metric]

        ax.errorbar(
            group_sorted[variable],
            group_sorted[metric],
            yerr=[lower_error, upper_error],
            fmt="-o",
            capsize=3,
            label=label,
        )
        return

    else:

        lower_b = group_sorted[metric] - group_sorted[f"{metric}_std_dev"]
        upper_b = group_sorted[metric] + group_sorted[f"{metric}_std_dev"]

        lower_clamped = lower_b.clip(lower=0)

        lower_error = group_sorted[metric] - lower_clamped
        upper_error = upper_b - group_sorted[metric]

        ax.errorbar(
            group_sorted[variable],
            group_sorted[metric],
            yerr=[lower_error, upper_error],
            fmt="-o",
            capsize=3,
            label=label,
        )
        return


def get_line_style(scheduler):
    return (
        "--"
        if scheduler in ["PRIV_KIST", "DP_KIST"]
        else "-" if scheduler in ["PRIV_Vanilla", "DP_Vanilla"] else ":"
    )


def get_title(feature, metric, filesize):
    if "PPC" not in feature:
        feature = f"{feature.capitalize()}"

    if "latency" in metric:
        return f"{feature} Latency ({get_file_sizes(filesize)})"
    elif "throughput" in metric:
        return f"{feature} Throughput ({get_file_sizes(filesize)})"
    elif "jitter" in metric:
        return f"{feature} Jitter ({get_file_sizes(filesize)})"
    elif "total_time" in metric:
        return f"{feature} Total Time ({get_file_sizes(filesize)})"
    elif "total_dummy" in metric:
        return f"{feature} False Cells ({get_file_sizes(filesize)})"
    elif "dummy_ratio" in metric:
        return f"{feature} False Cells Ratio ({get_file_sizes(filesize)})"
    elif "packet_count" in metric:
        return f"{feature} Total TLS Packet Count ({get_file_sizes(filesize)})"
    else:
        return metric


def get_axis_label(metric):
    if "latency" in metric:
        return "Latency (ms)"
    elif "throughput" in metric:
        return "Throughput (Kbps)"
    elif "jitter" in metric:
        return "Jitter"
    elif "total_time" in metric:
        return "Total Time Elapsed (s)"
    elif "total_dummy" in metric:
        return "Nº of False Cells"
    elif "dummy_ratio" in metric:
        return "False Cells Ratio (%)"
    elif "packet_count" in metric:
        return "Nº of TLS Packets"
    else:
        return metric


def get_units(metric):
    if metric == "latency":
        return "Latency (s)"
    elif metric == "throughput":
        return "Throughput (bytes/s)"
    elif metric == "jitter":
        return "Jitter (s)"
    elif metric == "total_time":
        return "Total time (s)"
    else:
        return metric


def get_file_sizes(size):
    if size == "51200":
        return "50 KiB"
    elif size == "1048576":
        return "1 MiB"
    elif size == "5242880":
        return "5 MiB"
    else:
        return size


def abs_path():
    """
    Get the absolute path of the current working directory.

    Returns:
        str: Absolute path of the current working directory.
    """
    return f"{os.getcwd()}/testing/results/figures"
