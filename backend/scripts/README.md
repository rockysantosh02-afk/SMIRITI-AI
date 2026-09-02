# Debug tools

Run these commands from `backend` after configuring `.env`:

```powershell
python scripts\view_data.py patients --patient-id demo-patient
python scripts\generate_test_token.py demo-user
python scripts\load_test_data.py
python scripts\cleanup_test_data.py
python scripts\debug_tools.py jwt demo-user
```

Firebase-backed commands require the service-account key and never print its contents.
