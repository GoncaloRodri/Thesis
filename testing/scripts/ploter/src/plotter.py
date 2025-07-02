import matplotlib.pyplot as plt
import os


def plot_dummy(metric, filesize, data, show=False):
    print(data)
    for (sched, eps, file_size, dist), group in data.groupby(
        ["scheduler", "epsilon", "filesize", "distribution"]
    ):
        if file_size != filesize:
            continue
        group_sorted = group.sort_values("dummy")
        label = (
            f"{sched} | εS={eps} | {dist.capitalize()}"
            if sched not in ["KIST", "Vanilla"]
            else f"{sched} (control)"
        )
        print(f"Plotting {metric} for {label} with file size {file_size}")
        print("Group sorted:")
        print(group_sorted)

        plt.plot(
            group_sorted["dummy"],
            group_sorted[metric],
            marker="o",
            label=label,
            linestyle=get_line_style(sched),
        )
        if metric in ["latency_95", "throughput_95", "total_time_95"]:
            metric_25 = metric.replace("95", "25")
            metric_75 = metric.replace("95", "75")
            plt.fill_between(
                group_sorted["dummy"],
                group_sorted[metric_25],
                group_sorted[metric_75],
                alpha=0.2,
            )

        elif metric in ["latency_50", "throughput_50", "total_time_50"]:
            metric_25 = metric.replace("50", "25")
            metric_75 = metric.replace("50", "75")
            plt.fill_between(
                group_sorted["dummy"],
                group_sorted[metric_25],
                group_sorted[metric_75],
                alpha=0.2,
            )

        elif metric in [
            "latency",
            "throughput",
            "total_time",
        ]:
            plt.fill_between(
                group_sorted["dummy"],
                group_sorted[f"{metric}_25"],
                group_sorted[f"{metric}_75"],
                alpha=0.2,
            )

    plt.title(f"{metric.capitalize()} vs Epsilon ({get_file_sizes(filesize)})")
    plt.xlabel("Packet Generation Epsilon")
    plt.ylabel(get_units(metric))
    plt.legend(bbox_to_anchor=(1.05, 1), loc="upper left")
    plt.grid(True)
    plt.tight_layout()
    plt.savefig(
        f"{abs_path()}/dummy/{metric}_vs_clients_{get_file_sizes(filesize).lower().replace(" ", "_")}.png"
    )
    if show:
        plt.show()
    plt.clf()


def plot_jitter_by_distribution(metric, dist, filesize, data, show=False):
    for (sched, dummy, file_size, distribution), group in data.groupby(
        ["scheduler", "dummy", "filesize", "distribution"]
    ):
        if file_size != filesize or distribution != dist != "CONTROL":
            continue
        group_sorted = group.sort_values("epsilon")
        label = (
            f"{sched} | εD={dummy} | {dist.capitalize()}"
            if sched not in ["KIST", "Vanilla"]
            else f"{sched} (control)"
        )
        plt.plot(
            group_sorted["epsilon"],
            group_sorted[metric],
            marker="o",
            label=label,
            linestyle=get_line_style(sched),
        )
    plt.title(
        f"{metric.capitalize()} on {dist.capitalize()} Distribution ({get_file_sizes(filesize)})"
    )
    plt.xlabel("Jitter Induction Epsilon")
    plt.ylabel(get_units(metric))
    plt.legend(bbox_to_anchor=(1.05, 1), loc="upper left")
    plt.grid(True)
    plt.tight_layout()
    plt.savefig(
        f"{abs_path()}/jitter/{metric}_vs_clients_{get_file_sizes(filesize).lower().replace(' ', '_')}_{dist}.png"
    )
    if show:
        plt.show()
    plt.clf()


def plot_jitter(metric, filesize, data, accepted_eps, show=False):
    for (sched, dummy, file_size, dist), group in data.groupby(
        ["scheduler", "dummy", "filesize", "distribution"]
    ):
        if file_size != filesize:
            continue
        group_sorted = group.sort_values("epsilon")
        label = (
            f"{sched} | εD={dummy} | {dist.capitalize()}"
            if sched not in ["KIST", "Vanilla"]
            else f"{sched} (control)"
        )

        plt.plot(
            group_sorted["epsilon"],
            group_sorted[metric],
            marker="o",
            label=label,
            linestyle=get_line_style(sched),
        )
    plt.title(f"{metric.capitalize()} vs Epsilon ({get_file_sizes(filesize)})")
    plt.xlabel("Jitter Induction Epsilon")
    plt.ylabel(get_units(metric))
    plt.legend(bbox_to_anchor=(1.05, 1), loc="upper left")
    plt.grid(True)
    plt.tight_layout()
    plt.savefig(
        f"{abs_path()}/jitter/{metric}_vs_clients_{get_file_sizes(filesize).lower().replace(' ', '_')}.png"
    )
    if show:
        plt.show()
    plt.clf()


def plot_jitter_dummy(metric, filesize, data, accepted_dummy, accepted_eps, show=False):
    for (sched, file_size, dist), group in data.groupby(
        ["scheduler", "filesize", "distribution"]
    ):
        if file_size != filesize:
            continue
        group_sorted = group.sort_values("dummy")
        label = (
            f"{sched} | {dist.capitalize()}"
            if sched not in ["KIST", "Vanilla"]
            else f"{sched} (control)"
        )

        plt.plot(
            group_sorted["dummy"],
            group_sorted["epsilon"],
            marker="o",
            label=label,
            linestyle=get_line_style(sched),
        )
    plt.title(f"{metric.capitalize()} vs Epsilon ({get_file_sizes(filesize)})")
    plt.xlabel("Dummy Epsilon")
    plt.ylabel("Jitter Induction Epsilon")
    plt.legend(bbox_to_anchor=(1.05, 1), loc="upper left")
    plt.grid(True)
    plt.tight_layout()
    plt.savefig(
        f"{abs_path()}/jitter_dummy/{metric}_vs_clients_{get_file_sizes(filesize).lower().replace(' ', '_')}.png"
    )
    if show:
        plt.show()
    plt.clf()


def plot_dummy_count(data, show=False):
    for (sched, eps, file_size, dist), group in data.groupby(
        ["scheduler", "epsilon", "filesize", "distribution"]
    ):
        group_sorted = group.sort_values("dummy")
        label = (
            f"{sched} | εS={eps} | {dist.capitalize()}"
            if sched not in ["KIST", "Vanilla"]
            else f"{sched} (control)"
        )
        plt.plot(
            group_sorted["dummy"],
            group_sorted["total_dummies"],
            marker="o",
            label=f"{label} (Total Dummies)",
            linestyle=get_line_style(sched),
        )
        plt.plot(
            group_sorted["dummy"],
            group_sorted["total_cells"],
            marker="x",
            label=f"{label} (Total Cells)",
            linestyle=get_line_style(sched),
        )
        plt.plot(
            group_sorted["dummy"],
            [
                d / cell
                for d, cell in zip(
                    group_sorted["total_dummies"], group_sorted["total_cells"]
                )
            ],
            marker="s",
            label=f"{label} (Dummies/Cells Ratio)",
            linestyle=get_line_style(sched),
        )
    plt.title(f"Total Cells vs Cell Generation Epsilon ({get_file_sizes(file_size)})")
    plt.xlabel("Packet Generation Epsilon")
    plt.ylabel("Total Cells")
    plt.legend(bbox_to_anchor=(1.05, 1), loc="upper left")
    plt.grid(True)
    plt.tight_layout()
    plt.savefig(
        f"{abs_path()}/dummy_count/dummies_vs_cells_{get_file_sizes(file_size).lower().replace(' ', '_')}.png"
    )
    if show:
        plt.show()
    plt.clf()


########################################
# Helpers
########################################


def get_line_style(scheduler):
    return (
        "--"
        if scheduler in ["PRIV_KIST", "DP_KIST"]
        else "-" if scheduler in ["PRIV_Vanilla", "DP_Vanilla"] else ":"
    )


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
        return "10 MiB"
    else:
        return size


def abs_path():
    """
    Get the absolute path of the current working directory.

    Returns:
        str: Absolute path of the current working directory.
    """
    return f"{os.getcwd()}/testing/results/figures"
