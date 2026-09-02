# Load tests

Install Locust with `python -m pip install locust`, then run:

```powershell
python load_test/run_load_test.py
```

Override `USERS` and `DURATION` for local smoke runs. Production targets are
success rate above 99%, P95 below 500 ms, P99 below 1000 ms, and zero 500s.
