"""Signin trigger and log endpoints."""

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from web.backend.auth import get_current_user
from web.backend.database import get_db
from web.backend.models import Account, SigninLog
from web.backend.scheduler import get_scheduler
from web.backend.schemas import SigninLogOut

router = APIRouter(prefix="/api/signin", tags=["signin"])


@router.post("/trigger")
async def trigger_all(
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
    _user: str = Depends(get_current_user),
) -> dict:
    result = await db.execute(select(Account).where(Account.enabled == True))  # noqa: E712
    enabled_accounts = result.scalars().all()
    if not enabled_accounts:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="没有可签到的账号，请先添加并启用账号",
        )
    scheduler = get_scheduler()
    background_tasks.add_task(scheduler.run_signin_all, triggered_by="manual")
    return {"message": f"Sign-in triggered for {len(enabled_accounts)} enabled account(s)"}


@router.post("/trigger/{account_id}")
async def trigger_one(
    account_id: int,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
    _user: str = Depends(get_current_user),
) -> dict:
    account = await db.get(Account, account_id)
    if not account:
        from fastapi import HTTPException, status

        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Account not found")
    scheduler = get_scheduler()
    background_tasks.add_task(scheduler.run_signin_one, account_id=account_id, triggered_by="manual")
    return {"message": f"Sign-in triggered for account {account_id}"}


@router.get("/logs", response_model=list[SigninLogOut])
async def get_logs(
    limit: int = Query(50, ge=1, le=500),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    _user: str = Depends(get_current_user),
) -> list[SigninLogOut]:
    result = await db.execute(select(SigninLog).order_by(SigninLog.created_at.desc()).offset(offset).limit(limit))
    logs = result.scalars().all()
    return [SigninLogOut.model_validate(log) for log in logs]


@router.get("/logs/{account_id}", response_model=list[SigninLogOut])
async def get_account_logs(
    account_id: int,
    limit: int = Query(50, ge=1, le=500),
    db: AsyncSession = Depends(get_db),
    _user: str = Depends(get_current_user),
) -> list[SigninLogOut]:
    result = await db.execute(
        select(SigninLog).where(SigninLog.account_id == account_id).order_by(SigninLog.created_at.desc()).limit(limit)
    )
    logs = result.scalars().all()
    return [SigninLogOut.model_validate(log) for log in logs]
