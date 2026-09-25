#!/usr/bin/env python3
"""Cluster runnable-test failures in /tmp/sdk_results.tsv by error signature,
excluding tests listed in suite.yaml (exclude + expect_fail)."""
import re
from collections import defaultdict

TSV = "/tmp/sdk_results.tsv"


def load_lists():
    exclude, expect_fail = [], []
    cur = None
    for line in open("test/sdk_language/suite.yaml"):
        m = re.match(r"^(\w+):", line)
        if m:
            cur = m.group(1)
            continue
        m = re.match(r"\s*-\s*path:\s*'([^']+)'", line)
        if cur == "exclude" and m:
            exclude.append(m.group(1))
        elif cur == "expect_fail" and m:
            expect_fail.append(m.group(1))
    return exclude, expect_fail


def matches(rel, patterns):
    for p in patterns:
        if p.endswith("/"):
            if rel.startswith(p):
                return True
        elif "*" in p:
            if re.match("^" + re.escape(p).replace(r"\*", ".*") + "$", rel):
                return True
        elif rel == p:
            return True
    return False


def main():
    exclude, expect_fail = load_lists()
    clusters = defaultdict(list)
    counts = defaultdict(int)
    for line in open(TSV):
        parts = line.rstrip("\n").split("\t")
        if len(parts) < 2:
            continue
        rel, outcome = parts[0], parts[1]
        detail = parts[2] if len(parts) > 2 else ""
        if outcome == "passed":
            continue
        if "TestKind.runnable" not in detail:
            continue  # negative / unsupported — skipped by the real suite
        if matches(rel, exclude) or matches(rel, expect_fail):
            continue
        sig = re.sub(r"package:sdk_language/\S+", "<src>", detail)
        sig = re.sub(r"\[TestKind.*", "", sig).strip()
        sig = re.sub(r"\d+", "N", sig)
        sig = sig[:90]
        clusters[sig].append(rel)
        counts[outcome] += 1
    items = sorted(clusters.items(), key=lambda e: -len(e[1]))
    print(f"{dict(counts)}  ({sum(counts.values())} runnable failures)\n")
    for sig, rels in items:
        print(f"[{len(rels)}] {sig}")
        for r in rels[:6]:
            print(f"    {r}")
        if len(rels) > 6:
            print(f"    ... {len(rels)-6} more")


if __name__ == "__main__":
    main()
