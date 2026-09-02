"""Firebase token stubs for API tests."""


def valid_claims(uid="test-user", email="test@example.com"):
    return {"uid": uid, "email": email, "name": "Test User"}


def verify_firebase_token(token, check_revoked=False):
    if token == "valid-token":
        return valid_claims()
    return None
