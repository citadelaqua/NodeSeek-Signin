"""Statistics endpoints."""

from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, Query
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from web.backend.auth import get_current_user
from web.backend.database import get_db
from web.backend.models import Account, SigninLog
from web.backend.scheduler import get_scheduler
from web.backend.schemas import AccountStatsOut, DailyChickens, GlobalStatsOut

router = APIRouter(prefix="/api/stats", tags=["stats"])


@router.get("", response_model=GlobalStatsOut)
async def global_stats(
    db: AsyncSession = Depends(get_db),
    _user: str = Depends(get_current_user),
) -> GlobalStatsOut:
    # Total accounts
    total_result = await db.execute(select(func.count()).select_from(Account).where(Account.enabled == True))  # noqa: E712
    total_accounts: int = total_result.scalar() or 0

    # Signed today
    today_start = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)
    signed_result = await db.execute(
        select(func.count(func.distinct(SigninLog.account_id))).where(
            SigninLog.created_at >= today_start,
            SigninLog.result.in_(["success", "already"]),
        )
    )
    signed_today: int = signed_result.scalar() or 0

    # Total chickens today
    chickens_result = await db.execute(
        select(func.coalesce(func.sum(SigninLog.chickens), 0)).where(
            SigninLog.created_at >= today_start,
            SigninLog.result == "success",
        )
    )
    total_chickens_today: int = chickens_result.scalar() or 0

    # Next run from scheduler
    scheduler = get_scheduler()
    next_run = scheduler.next_run_str()

    return GlobalStatsOut(
        total_accounts=total_accounts,
        signed_today=signed_today,
        total_chickens_today=total_chickens_today,
        next_run=next_run,
    )


@router.get("/{account_id}", response_model=AccountStatsOut)
async def account_stats(
    account_id: int,
    days: int = Query(30, ge=1, le=365),
    db: AsyncSession = Depends(get_db),
    _user: str = Depends(get_current_user),
) -> AccountStatsOut:
    since = datetime.now(timezone.utc) - timedelta(days=days)

    logs_result = await db.execute(
        select(SigninLog).where(
            SigninLog.account_id == account_id,
            SigninLog.created_at >= since,
            SigninLog.result == "success",
        )
    )
    logs = logs_result.scalars().all()

    # Aggregate by day
    daily_map: dict[str, int] = {}
    for log in logs:
        day_key = log.created_at.strftime("%Y-%m-%d")
        daily_map[day_key] = daily_map.get(day_key, 0) + (log.chickens or 0)

    daily = [DailyChickens(date=k, chickens=v) for k, v in sorted(daily_map.items())]
    total_chickens = sum(d.chickens for d in daily)

    return AccountStatsOut(
        account_id=account_id,
        total_chickens=total_chickens,
        signin_count=len(logs),
        daily=daily,
    )
