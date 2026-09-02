"""Pydantic models for Firebase authentication endpoints."""

from typing import Optional

from pydantic import BaseModel


class FirebaseLoginRequest(BaseModel):
    id_token: str
    device_id: Optional[str] = None


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: str
    role: str
    firebase_uid: str


class FirebaseUserInfo(BaseModel):
    uid: str
    email: Optional[str] = None
    name: Optional[str] = None
    role: str = "patient"
    language: Optional[str] = None


class UserResponse(FirebaseUserInfo):
    """Public authenticated-user representation."""


class FirebaseVerifyResponse(BaseModel):
    status: str = "valid"
    user: UserResponse


FirebaseLoginResponse = TokenResponse