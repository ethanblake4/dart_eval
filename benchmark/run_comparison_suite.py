import subprocess
import os
import re
import json
import sys

BENCHMARKS = [
    'access_policy',
    'event_bus',
    'http_headers',
    'int_fields',
    'interval_overlap',
    'particles',
    'telemetry_window',
    'template_render',
]

def parse_output(output_text):
    data = {}
    for line in output_text.strip().splitlines():
        line = line.strip()
        if 'median_ms=' in line:
            parts = line.split()
            data['name'] = parts[0]
            for part in parts[1:]:
                if '=' in part:
                    k, v = part.split('=', 1)
                    if k.startswith('ns/'):
                        data['unit'] = k[3:]
                        data['ns_per_unit'] = float(v)
                    elif k in ('median_ms', 'min_ms', 'max_ms'):
                        data[k] = float(v)
                    elif k == 'raw_ms':
                        data['raw_ms'] = [float(x) for x in v.split(',') if x]
        elif line.startswith('checksum='):
            data['checksum'] = line.split('=', 1)[1].strip()
    return data

def main():
    root_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    dart_tool = os.path.join(root_dir, '.dart_tool')
    os.makedirs(dart_tool, exist_ok=True)

    print("=== Step 1: Compiling missing Dart benchmarks to native AOT exe ===")
    for bench in BENCHMARKS:
        exe_path = os.path.join(dart_tool, f"{bench}.exe")
        dart_path = os.path.join(root_dir, 'benchmark', f"{bench}.dart")
        if not os.path.exists(exe_path):
            print(f"Compiling {bench}.dart -> {bench}.exe...")
            cmd = ['dart', 'compile', 'exe', dart_path, '-o', exe_path]
            res = subprocess.run(cmd, cwd=root_dir, capture_output=True, text=True)
            if res.returncode != 0:
                print(f"Error compiling {bench}: {res.stderr}")
                sys.exit(1)
            print(f"Compiled {bench}.exe successfully.")
        else:
            print(f"Existing {bench}.exe found.")

    results = []

    print("\n=== Step 2: Running Benchmarks (dart_eval AOT vs Python 3.12) ===")
    for bench in BENCHMARKS:
        print(f"\n--- Benchmarking: {bench} ---")
        exe_path = os.path.join(dart_tool, f"{bench}.exe")
        py_path = os.path.join(root_dir, 'benchmark', f"{bench}.py")

        # Run Dart
        print(f"Running dart_eval ({bench}.exe)...")
        dart_res = subprocess.run([exe_path], cwd=root_dir, capture_output=True, text=True)
        if dart_res.returncode != 0:
            print(f"Dart run failed: {dart_res.stderr}")
            continue
        dart_data = parse_output(dart_res.stdout)

        # Run Python
        print(f"Running Python ({bench}.py)...")
        py_res = subprocess.run(['python', py_path], cwd=root_dir, capture_output=True, text=True)
        if py_res.returncode != 0:
            print(f"Python run failed: {py_res.stderr}")
            continue
        py_data = parse_output(py_res.stdout)

        checksum_match = dart_data.get('checksum') == py_data.get('checksum')
        dart_med = dart_data.get('median_ms', 0)
        py_med = py_data.get('median_ms', 0)
        # speedup: python_ms / dart_ms (e.g. >1 means dart_eval is faster, <1 means python is faster)
        ratio = (py_med / dart_med) if dart_med > 0 else 0
        diff_pct = ((py_med - dart_med) / py_med * 100) if py_med > 0 else 0

        bench_item = {
            'benchmark': bench,
            'unit': dart_data.get('unit', 'op'),
            'dart_eval': dart_data,
            'python': py_data,
            'checksum_match': checksum_match,
            'speedup_vs_python': round(ratio, 2),
            'diff_percent': round(diff_pct, 1),
        }
        results.append(bench_item)
        print(f"Result for {bench}:")
        print(f"  dart_eval: {dart_med:.2f} ms")
        print(f"  Python:    {py_med:.2f} ms")
        print(f"  Ratio:     {ratio:.2f}x ({'dart_eval faster' if ratio > 1 else 'Python faster'})")
        print(f"  Checksums match: {checksum_match} ({dart_data.get('checksum')})")

    out_file = os.path.join(root_dir, 'benchmark', 'results.json')
    with open(out_file, 'w', encoding='utf-8') as f:
        json.dump(results, f, indent=2)
    print(f"\nAll benchmark results saved to {out_file}")

if __name__ == '__main__':
    main()
