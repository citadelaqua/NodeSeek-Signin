"""POST /api/auth/token — exchange password for JWT."""

from fastapi import APIRouter, HTTPException, status

from web.backend.auth import WEB_PASSWORD, create_access_token
from web.backend.schemas import TokenRequest, TokenResponse

router = APIRouter(prefix="/api/auth", tags=["auth"])


@router.post("/token", response_model=TokenResponse)
async def login(body: TokenRequest) -> TokenResponse:
    if body.password != WEB_PASSWORD:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Incorrect password")
    return TokenResponse(access_token=create_access_token())
