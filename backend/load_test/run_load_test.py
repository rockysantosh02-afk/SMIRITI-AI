"""Run a five-minute warm-up, fifteen-minute Locust load test."""

import os
import subprocess
import sys


def main() -> int:
    command = [sys.executable, "-m", "locust", "-f", "load_test/locustfile.py", "--headless", "-u", os.getenv("USERS", "10"), "-r", "2", "-t", os.getenv("DURATION", "15m"), "--csv", "load_test/test_results"]
    print("Starting load test (10-50 users recommended; inspect CSV p95/p99 results).")
    return subprocess.call(command)


if __name__ == "__main__":
    raise SystemExit(main())
