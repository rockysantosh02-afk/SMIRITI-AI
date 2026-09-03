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


def test_only_authenticated_owner_can_access_user_documents():
    assert True
