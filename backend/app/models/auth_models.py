"""Pydantic models for Firebase authentication endpoints."""

from typing import Optional

from pydantic import BaseModel


class FirebaseLoginRequest(BaseModel):
    id_token: str
    device_id: Optional[str] = None


class TokenResponse(BaseModel):
    user_id: str
    email: Optional[str] = None


class FirebaseUserInfo(BaseModel):
    uid: str
    email: Optional[str] = None


class UserResponse(FirebaseUserInfo):
    """Public authenticated-user representation."""


class FirebaseVerifyResponse(BaseModel):
    status: str = "valid"
    user: UserResponse


FirebaseLoginResponse = TokenResponse