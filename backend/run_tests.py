"""Run backend tests and generate standard reports."""

import shutil
import subprocess
import sys
import time


def main() -> int:
    started = time.perf_counter()
    pytest = [sys.executable, "-m", "pytest"]
    if shutil.which("firebase"):
        print("Firebase CLI detected; security tests remain opt-in via FIREBASE_EMULATOR=1.")
    else:
        print("Firebase CLI not detected; emulator tests will be skipped.")
    command = pytest + ["tests", "--cov=core_logic", "--cov-report=html", "--cov-report=xml", "--junitxml=test-results.xml"]
    result = subprocess.run(command, check=False)
    print(f"Completed in {time.perf_counter() - started:.2f}s")
    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
