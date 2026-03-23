"""Pydantic v2 schemas for request/response models."""

from datetime import datetime

from pydantic import BaseModel, ConfigDict

# ── Auth ─────────────────────────────────────────────────────────────────────


class TokenRequest(BaseModel):
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


# ── Accounts ──────────────────────────────────────────────────────────────────


class AccountCreate(BaseModel):
    label: str
    username: str | None = None
    password: str | None = None
    cookie: str | None = None
    enabled: bool = True


class AccountUpdate(BaseModel):
    label: str | None = None
    username: str | None = None
    password: str | None = None
    cookie: str | None = None
    enabled: bool | None = None


class AccountOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    label: str
    username: str | None
    cookie: str | None
    last_signin_at: datetime | None
    last_result: str | None
    last_message: str | None
    enabled: bool
    created_at: datetime


# ── Signin Logs ───────────────────────────────────────────────────────────────


class SigninLogOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    account_id: int
    result: str
    message: str | None
    chickens: int | None
    triggered_by: str
    created_at: datetime


# ── Stats ─────────────────────────────────────────────────────────────────────


class DailyChickens(BaseModel):
    date: str  # "YYYY-MM-DD"
    chickens: int


class AccountStatsOut(BaseModel):
    account_id: int
    total_chickens: int
    signin_count: int
    daily: list[DailyChickens]


class GlobalStatsOut(BaseModel):
    total_accounts: int
    signed_today: int
    total_chickens_today: int
    next_run: str | None


# ── Config ────────────────────────────────────────────────────────────────────


class ConfigOut(BaseModel):
    run_at: str
    solver_type: str
    api_base_url: str
    ns_random: str
    # extend as needed


class ConfigUpdate(BaseModel):
    run_at: str | None = None
    solver_type: str | None = None
    api_base_url: str | None = None
    ns_random: str | None = None


# ── Scheduler ─────────────────────────────────────────────────────────────────


class SchedulerStatus(BaseModel):
    next_run: str | None
    mode: str
    running: bool
