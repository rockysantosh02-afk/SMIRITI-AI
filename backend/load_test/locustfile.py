"""Locust scenarios for patient, caregiver, and mixed API traffic."""

try:
    from locust import HttpUser, between, task
except ImportError:
    HttpUser = object
    def task(*args, **kwargs):
        return lambda function: function
    def between(*args):
        return None


class PatientUser(HttpUser):
    wait_time = between(1, 3)

    @task(3)
    def play_game_flow(self):
        self.client.get("/games")

    @task(1)
    def view_memory_vault(self):
        self.client.get("/memory/persons/test-patient")

    @task(1)
    def check_reminders(self):
        self.client.get("/reminders/test-patient")


class CaregiverUser(PatientUser):
    @task(2)
    def view_patient_data(self):
        self.client.get("/games/scores/test-patient")


class MixedUser(PatientUser):
    @task(1)
    def submit_attempt(self):
        self.client.post("/games/attempt", json={"session_id": "load-test", "selected_index": 0, "response_time_ms": 100})
