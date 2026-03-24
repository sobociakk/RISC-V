import sys
import re
import os

if len(sys.argv) < 2:
    print("Error: Please provide the path to the simulation log file.")
    sys.exit(1)

log_file = sys.argv[1]

if not os.path.exists(log_file):
    print(f"Error: Log file not found at {log_file}")
    sys.exit(1)

error_pattern = re.compile(r'\b(error|fail|fatal)\b', re.IGNORECASE)
warning_pattern = re.compile(r'\bwarning\b', re.IGNORECASE)

ignore_pattern = re.compile(r'(0 errors|0 fail|0 fatal|without error|no error)', re.IGNORECASE)

errors = 0
warnings = 0

print(f"\n--- Simulation Log Analysis: {os.path.basename(log_file)} ---")

with open(log_file, "r") as f:
    for line in f:
        if ignore_pattern.search(line):
            continue
        if error_pattern.search(line):
            errors += 1
            print(f"[ERROR] {line.strip()}")
        elif warning_pattern.search(line):
            warnings += 1

print("-" * 45)
if errors == 0:
    print(f"[SUCCESS] Simulation passed with {warnings} warnings.\n")
    sys.exit(0)
else:
    print(f"[FAILURE] Simulation failed with {errors} errors.\n")
    sys.exit(1)
