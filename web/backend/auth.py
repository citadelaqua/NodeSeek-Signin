"""JWT-based auth helpers."""

import logging
import os
import secrets
from datetime import datetime, timedelta, timezone

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt

logger = logging.getLogger(__name__)

_JWT_ALGORITHM = "HS256"
_TOKEN_EXPIRE_HOURS = 24

# ── Secret / password resolution ─────────────────────────────────────────────


def _get_jwt_secret() -> str:
    secret = os.environ.get("JWT_SECRET", "")
    if not secret:
        secret = secrets.token_hex(32)
        logger.warning(
            "JWT_SECRET is not set — using a randomly generated secret. "
            "All existing tokens will be invalidated on restart. "
            "Set JWT_SECRET in your environment for persistent sessions."
        )
    return secret


def _get_web_password() -> str:
    pwd = os.environ.get("WEB_PASSWORD", "admin")
    if pwd == "admin":
        logger.warning(
            "WEB_PASSWORD is not set — using default password 'admin'. Please set WEB_PASSWORD in your environment."
        )
    return pwd


JWT_SECRET: str = _get_jwt_secret()
WEB_PASSWORD: str = _get_web_password()

# ── Token helpers ─────────────────────────────────────────────────────────────


def create_access_token() -> str:
    expire = datetime.now(timezone.utc) + timedelta(hours=_TOKEN_EXPIRE_HOURS)
    payload = {"sub": "admin", "exp": expire}
    return jwt.encode(payload, JWT_SECRET, algorithm=_JWT_ALGORITHM)


def verify_token(token: str) -> bool:
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[_JWT_ALGORITHM])
        return payload.get("sub") == "admin"
    except JWTError:
        return False


# ── FastAPI dependency ────────────────────────────────────────────────────────

_bearer_scheme = HTTPBearer(auto_error=True)


def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(_bearer_scheme)) -> str:
    if not verify_token(credentials.credentials):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return "admin"
