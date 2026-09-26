#!/usr/bin/env python3
"""Run every sdk_language test in its own process via the compiled run_one
binary. Robust to per-test OOMs/segfaults/hangs that kill shared-isolate
sweeps. Appends to /tmp/sdk_results.tsv as results arrive:
relpath<TAB>outcome<TAB>detail

Usage: python3 tool/sweep_sdk.py [dirFilter...]
"""
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHA = os.listdir(os.path.join(REPO, ".dart_tool", "sdk_language"))[0]
LANG = os.path.join(REPO, ".dart_tool", "sdk_language", SHA, "tests", "language")
RUN_ONE = "/tmp/run_one"
TIMEOUT = 60
WORKERS = 16


def tests():
    out = []
    for root, _, files in os.walk(LANG):
        for f in files:
            if f.endswith("_test.dart"):
                rel = os.path.relpath(os.path.join(root, f), LANG)
                out.append(rel.replace(os.sep, "/"))
    out.sort()
    return out


def run(rel):
    try:
        p = subprocess.run(
            [RUN_ONE, rel],
            capture_output=True,
            text=True,
            timeout=TIMEOUT,
            cwd=REPO,
        )
        kind = ""
        for line in p.stderr.splitlines():
            if line.startswith("kind:"):
                kind = line[5:].strip()
                break
        out = p.stdout
        if p.returncode != 0 and not out:
            return (rel, "crash", f"exit={p.returncode} {kind}")
        if "PASSED" in out:
            return (rel, "passed", kind)
        detail = next(
            (l[7:] for l in out.splitlines() if l.startswith("ERROR:")), ""
        )
        return (rel, "failed", f"{detail} [{kind}]")
    except subprocess.TimeoutExpired:
        return (rel, "timeout", "")
    except Exception as e:  # noqa: BLE001
        return (rel, "crash", str(e))


def main():
    filters = sys.argv[1:]
    ts = tests()
    if filters:
        ts = [t for t in ts if any(t.startswith(f) for f in filters)]
    done_set = set()
    try:
        with open("/tmp/sdk_results.tsv") as fh:
            for line in fh:
                done_set.add(line.split("\t", 1)[0])
    except FileNotFoundError:
        pass
    todo = [t for t in ts if t not in done_set]
    print(f"{len(todo)} to run ({len(done_set)} already done)", flush=True)
    done = 0
    with open("/tmp/sdk_results.tsv", "a", buffering=1) as out:
        with ThreadPoolExecutor(max_workers=WORKERS) as ex:
            futs = {ex.submit(run, t): t for t in todo}
            for fut in as_completed(futs):
                rel, outcome, detail = fut.result()
                out.write(f"{rel}\t{outcome}\t{detail}\n")
                done += 1
                if done % 100 == 0:
                    print(f"[{done}/{len(todo)}]", flush=True)


if __name__ == "__main__":
    main()
