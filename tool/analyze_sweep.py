#!/usr/bin/env python3
"""Compare /tmp/sdk_results.tsv against suite.yaml expect_fail to find:
- expect_fail entries that now PASS (stale entries)
- runnable tests failing that aren't in expect_fail (real failures)
- expect_fail entries still failing (clustered by error signature)
"""
import re
import sys

sys.path.insert(0, "/usr/lib/python3/dist-packages")
try:
    import yaml
except ImportError:
    yaml = None

SUITE = "test/sdk_language/suite.yaml"
TSV = "/tmp/sdk_results.tsv"


def load_expect_fail():
    if yaml:
        data = yaml.safe_load(open(SUITE))
        ef = data.get("expect_fail") or []
        return {e["path"]: e.get("reason", "") for e in ef}
    # fallback: parse the expect_fail block manually
    ef = {}
    in_ef = False
    for line in open(SUITE):
        if line.startswith("expect_fail:"):
            in_ef = True
            continue
        if in_ef and line and not line.startswith(" "):
            break
        m = re.match(r"\s*-\s*path:\s*'([^']+)'", line)
        if in_ef and m:
            ef[m.group(1)] = ""
    return ef


def matches(rel, pattern):
    if pattern.endswith("/"):
        return rel.startswith(pattern)
    if "*" in pattern:
        rx = "^" + re.escape(pattern).replace(r"\*", ".*") + "$"
        return re.match(rx, rel) is not None
    return rel == pattern


def main():
    ef = load_expect_fail()
    results = {}
    for line in open(TSV):
        parts = line.rstrip("\n").split("\t")
        if len(parts) >= 2:
            results[parts[0]] = (parts[1], parts[2] if len(parts) > 2 else "")

    def in_ef(rel):
        return any(matches(rel, p) for p in ef)

    stale = []  # expect_fail but passed
    new_fail = []  # failing, not in expect_fail, runnable
    still_fail = []  # expect_fail and still failing
    not_run = []  # expect_fail entries with no result row
    for rel, (outcome, detail) in sorted(results.items()):
        if in_ef(rel):
            if outcome == "passed":
                stale.append((rel, detail))
            else:
                still_fail.append((rel, outcome, detail))
        else:
            if outcome in ("failed", "crash", "timeout"):
                new_fail.append((rel, outcome, detail))
    for p in ef:
        if not any(matches(r, p) for r in results):
            not_run.append(p)

    print(f"=== STALE expect_fail entries now passing ({len(stale)}) ===")
    for r, d in stale:
        print(f"  {r}  [{d}]")
    print(f"\n=== FAILURES not in expect_fail ({len(new_fail)}) ===")
    for r, o, d in new_fail:
        print(f"  {r}\t{o}\t{d[:110]}")
    print(
        f"\n=== expect_fail still failing: {len(still_fail)}; "
        f"not yet run: {len(not_run)} ==="
    )
    if "--still" in sys.argv:
        for r, o, d in still_fail:
            print(f"  {r}\t{o}\t{d[:110]}")


if __name__ == "__main__":
    main()
