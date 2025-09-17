import json

TEST_ENV = "dist"


def table_dummy(metric, filesize, data):
    res = {
        "control": {
            "KIST": 0,
            "Vanilla": 0
        },
        "Dummy": {
            "max": 0,
            "min": float("inf")
        },
        "Jitter": {
            "max": 0,
            "min": float("inf")
        },
        "Both": {
            "max": 0,
            "min": float("inf")
        }
    }
    for (sched, eps, dummy, file_size, dist, metric_val), group in data.groupby(
        ["scheduler", "epsilon", "dummy", "filesize", "distribution", metric]
    ):
        if file_size != filesize:
            continue
        if float(eps) < 0.0 and float(dummy) < 0.0:
            # Control
            res["control"][sched] = float(metric_val)
        elif float(dummy) >= 0.0 and float(eps) < 0.0:
            # Dummy
            res["Dummy"]["max"] = float(max(res["Dummy"]["max"], metric_val))
            res["Dummy"]["min"] = float(min(res["Dummy"]["min"], metric_val))
        elif float(dummy) < 0.0 and float(eps) >= 0.0:
            # Jitter
            res["Jitter"]["max"] = float(max(res["Jitter"]["max"], metric_val))
            res["Jitter"]["min"] = float(min(res["Jitter"]["min"], metric_val))
        elif float(dummy) >= 0.0 and float(eps) >= 0.0:
            # Both
            res["Both"]["max"] = float(max(res["Both"]["max"], metric_val))
            res["Both"]["min"] = float(min(res["Both"]["min"], metric_val))
        else:
            print("Unknown combination")
            exit(1)

    json.dump(
        res,
        open(
            f"testing/results/tables/{TEST_ENV}_{metric}_{filesize}.json",
            "w",
        ),
        indent=2,
    )
