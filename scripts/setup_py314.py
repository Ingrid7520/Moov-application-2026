"""
Helper script to ensure dependencies compatible with Python 3.14 are installed.
Run with the project's virtualenv activated or with the desired Python executable.

Usage:
    python scripts/setup_py314.py

This will run `pip install --upgrade` for a small set of packages known to
work with Python 3.14 in this project.
"""
import sys
import subprocess

REQUIRED = [
    "pydantic>=2.12.0",
    "pydantic-core==2.41.5",
    "pydantic-settings>=2.12.0",
    "fastapi>=0.124.4",
    "uvicorn[standard]>=0.38.0",
]


def run(cmd):
    print("Running:", " ".join(cmd))
    subprocess.check_call(cmd)


def main():
    if sys.version_info < (3, 14):
        print("Python < 3.14 detected — this script is intended for Python 3.14+.")
        return

    py = sys.executable
    print(f"Python: {sys.version}")

    try:
        run([py, "-m", "pip", "install", "--upgrade"] + REQUIRED)
        print("Dependencies upgraded for Python 3.14.")
    except subprocess.CalledProcessError as e:
        print("Failed to install packages:", e)
        print("You may need Rust toolchain to build pydantic-core from source if wheel is unavailable.")


if __name__ == "__main__":
    main()
