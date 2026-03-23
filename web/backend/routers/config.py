"""GET/PUT /api/config and GET /api/scheduler/status."""

import os

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from web.backend.auth import get_current_user
from web.backend.database import get_db
from web.backend.models import AppConfig
from web.backend.scheduler import get_scheduler
from web.backend.schemas import ConfigOut, ConfigUpdate, SchedulerStatus

router = APIRouter(tags=["config"])

_CONFIG_KEYS = ["run_at", "solver_type", "api_base_url", "ns_random"]
_DEFAULTS = {
    "run_at": os.environ.get("RUN_AT", "08:00-10:59"),
    "solver_type": os.environ.get("SOLVER_TYPE", "turnstile"),
    "api_base_url": os.environ.get("API_BASE_URL", ""),
    "ns_random": os.environ.get("NS_RANDOM", "true"),
}


async def _get_config_dict(db: AsyncSession) -> dict[str, str]:
    result = await db.execute(select(AppConfig).where(AppConfig.key.in_(_CONFIG_KEYS)))
    rows = {row.key: row.value for row in result.scalars().all()}
    return {k: rows.get(k, _DEFAULTS.get(k, "")) for k in _CONFIG_KEYS}


@router.get("/api/config", response_model=ConfigOut)
async def get_config(
    db: AsyncSession = Depends(get_db),
    _user: str = Depends(get_current_user),
) -> ConfigOut:
    cfg = await _get_config_dict(db)
    return ConfigOut(**cfg)


@router.put("/api/config", response_model=ConfigOut)
async def update_config(
    body: ConfigUpdate,
    db: AsyncSession = Depends(get_db),
    _user: str = Depends(get_current_user),
) -> ConfigOut:
    updates = body.model_dump(exclude_unset=True)
    for key, value in updates.items():
        existing = await db.get(AppConfig, key)
        if existing:
            existing.value = value
        else:
            db.add(AppConfig(key=key, value=value))
    await db.commit()

    # Reload scheduler if run_at changed
    if "run_at" in updates:
        scheduler = get_scheduler()
        scheduler.reconfigure(updates["run_at"])

    cfg = await _get_config_dict(db)
    return ConfigOut(**cfg)


@router.get("/api/scheduler/status", response_model=SchedulerStatus)
async def scheduler_status(_user: str = Depends(get_current_user)) -> SchedulerStatus:
    scheduler = get_scheduler()
    return SchedulerStatus(
        next_run=scheduler.next_run_str(),
        mode=scheduler.mode,
        running=scheduler.is_running,
    )
