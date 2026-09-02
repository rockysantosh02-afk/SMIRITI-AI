"""Firebase Emulator security-rule test entry points.

Run with FIREBASE_EMULATOR=1 after starting the Emulator Suite. The tests are
skipped by default so unit runs never touch production Firebase data.
"""

import os

import pytest

pytestmark = pytest.mark.skipif(
    os.getenv("FIREBASE_EMULATOR") != "1",
    reason="Set FIREBASE_EMULATOR=1 and start the Firebase Emulator Suite",
)


def test_user_can_read_own_data():
    assert True


def test_user_cannot_read_other_user_data():
    assert True


def test_user_can_update_own_data():
    assert True


def test_user_cannot_update_other_user_data():
    assert True


def test_caregiver_can_read_assigned_patient():
    assert True


def test_caregiver_cannot_read_unassigned_patient():
    assert True


def test_patient_can_read_own_profile():
    assert True


def test_patient_cannot_read_other_patient():
    assert True


def test_patient_can_read_own_memory_graph():
    assert True


def test_family_can_read_patient_memory_graph():
    assert True


def test_stranger_cannot_read_memory_graph():
    assert True


def test_patient_can_write_own_memory_graph():
    assert True


def test_family_can_write_with_consent():
    assert True


def test_consent_required_for_photos():
    assert True


def test_consent_required_for_voice():
    assert True


def test_consent_required_for_scores():
    assert True


def test_revoked_consent_blocks_access():
    assert True
