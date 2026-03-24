"""Background scheduler thread that drives periodic sign-in."""

from __future__ import annotations

import asyncio
import logging
import os
import re
import sys
import threading
from datetime import datetime, timezone
from pathlib import Path

# Ensure src/ is importable when running from repo root
_SRC = Path(__file__).parent.parent.parent / "src"
if str(_SRC) not in sys.path:
    sys.path.insert(0, str(_SRC))

from nodeseek.scheduler import calculate_next_run_time, get_run_config  # noqa: E402
from nodeseek.sign import session_login, sign  # noqa: E402

logger = logging.getLogger(__name__)

_scheduler_instance: WebScheduler | None = None


def get_scheduler() -> WebScheduler:
    global _scheduler_instance
    if _scheduler_instance is None:
        _scheduler_instance = WebScheduler()
    return _scheduler_instance


def _parse_chickens(message: str) -> int | None:
    """Extract chicken count from a sign-in response message."""
    if not message:
        return None
    m = re.search(r"(\d+)\s*(?:个)?鸡腿", message)
    return int(m.group(1)) if m else None


class WebScheduler:
    """Daemon thread that waits until the calculated run time and triggers sign-in."""

    def __init__(self) -> None:
        self._thread: threading.Thread | None = None
        self._stop_event = threading.Event()
        self._running = False
        self._next_run: datetime | None = None
        mode, value = get_run_config()
        self._mode = mode
        self._value = value
        self._recalculate_next_run()

    # ── Public API ────────────────────────────────────────────────────────────

    @property
    def mode(self) -> str:
        return self._mode

    @property
    def is_running(self) -> bool:
        return self._running

    def next_run_str(self) -> str | None:
        if self._next_run is None:
            return None
        return self._next_run.strftime("%Y-%m-%d %H:%M:%S %Z")

    def start(self) -> None:
        self._stop_event.clear()
        self._thread = threading.Thread(target=self._run_loop, daemon=True, name="WebScheduler")
        self._thread.start()
        logger.info("WebScheduler started, next run: %s", self.next_run_str())

    def stop(self) -> None:
        self._stop_event.set()
        if self._thread:
            self._thread.join(timeout=5)

    def reconfigure(self, run_at: str) -> None:
        """Update RUN_AT value and recalculate next run."""
        os.environ["RUN_AT"] = run_at
        mode, value = get_run_config()
        self._mode = mode
        self._value = value
        self._recalculate_next_run()
        logger.info("Scheduler reconfigured: mode=%s value=%s next=%s", mode, value, self.next_run_str())

    # ── Background helpers ────────────────────────────────────────────────────

    def _recalculate_next_run(self) -> None:
        self._next_run = calculate_next_run_time(self._mode, self._value)

    def _run_loop(self) -> None:
        while not self._stop_event.is_set():
            if self._next_run is None:
                self._recalculate_next_run()

            now = datetime.now(self._next_run.tzinfo)
            wait_seconds = (self._next_run - now).total_seconds()

            if wait_seconds > 0:
                logger.info("Scheduler sleeping %.0f s until %s", wait_seconds, self.next_run_str())
                interrupted = self._stop_event.wait(timeout=wait_seconds)
                if interrupted:
                    break

            # Fire
            logger.info("Scheduler: firing sign-in task")
            self._running = True
            try:
                self.run_signin_all(triggered_by="scheduler")
            finally:
                self._running = False

            self._recalculate_next_run()

    # ── Sign-in execution ─────────────────────────────────────────────────────

    def run_signin_all(self, triggered_by: str = "scheduler") -> None:
        """Run sign-in for all enabled accounts (safe to call from thread or FastAPI background task)."""
        from sqlalchemy import select  # noqa: PLC0415

        from web.backend.database import AsyncSessionLocal
        from web.backend.models import Account

        async def _inner() -> None:
            async with AsyncSessionLocal() as db:
                result_q = await db.execute(select(Account).where(Account.enabled == True))  # noqa: E712
                accounts = result_q.scalars().all()
                for account in accounts:
                    await _do_sign(db, account, triggered_by)
                await db.commit()

        _run_async(_inner())

    def run_signin_one(self, account_id: int, triggered_by: str = "manual") -> None:
        """Run sign-in for a single account."""
        from web.backend.database import AsyncSessionLocal
        from web.backend.models import Account

        async def _inner() -> None:
            async with AsyncSessionLocal() as db:
                account = await db.get(Account, account_id)
                if account:
                    await _do_sign(db, account, triggered_by)
                    await db.commit()

        _run_async(_inner())


async def _do_sign(db, account, triggered_by: str) -> None:  # type: ignore[type-arg]
    """Execute one account's sign-in and persist the result."""
    from web.backend.models import SigninLog

    cookie = account.cookie or ""
    ns_random = os.environ.get("NS_RANDOM", "true")

    # If no cookie and we have credentials, try to login
    if not cookie and account.username and account.password:
        solver_type = os.environ.get("SOLVER_TYPE", "turnstile")
        api_base_url = os.environ.get("API_BASE_URL", "")
        clientt_key = os.environ.get("CLIENTT_KEY", "")
        loop = asyncio.get_running_loop()
        new_cookie = await loop.run_in_executor(
            None, session_login, account.username, account.password, solver_type, api_base_url, clientt_key
        )
        if new_cookie:
            account.cookie = new_cookie
            cookie = new_cookie

    if not cookie:
        result, message = "error", "No cookie available and login failed"
    else:
        loop = asyncio.get_running_loop()
        result, message = await loop.run_in_executor(None, sign, cookie, ns_random)

    chickens = _parse_chickens(message) if result == "success" else None

    now = datetime.now(timezone.utc)
    account.last_signin_at = now
    account.last_result = result
    account.last_message = message

    log = SigninLog(
        account_id=account.id,
        result=result,
        message=message,
        chickens=chickens,
        triggered_by=triggered_by,
        created_at=now,
    )
    db.add(log)

    _log_signin_result(account, result, message, chickens, triggered_by)


def _log_signin_result(account, result: str, message: str, chickens: int | None, triggered_by: str) -> None:
    """Emit a structured log line for a sign-in attempt."""
    tag = f"[{triggered_by}] 账号 {account.id}「{account.label}」"
    if result == "success":
        chicken_info = f"，获得 {chickens} 个鸡腿" if chickens is not None else ""
        logger.info("%s ✅ 签到成功%s — %s", tag, chicken_info, message)
    elif result == "already":
        logger.info("%s ✅ 已签到（重复） — %s", tag, message)
    elif result == "forbidden":
        logger.warning("%s 🚫 被 Cloudflare 拦截 — %s", tag, message)
    elif result == "fail":
        logger.warning("%s ❌ 签到失败 — %s", tag, message)
    elif result == "invalid":
        logger.warning("%s ⚠️  Cookie 无效 — %s", tag, message)
    else:
        logger.error("%s 🔥 签到出错 (result=%s) — %s", tag, result, message)


def _run_async(coro) -> None:  # type: ignore[type-arg]
    """Run an async coroutine from a sync context (thread or BackgroundTask)."""
    try:
        loop = asyncio.get_event_loop()
        if loop.is_running():
            # Called from an async context (FastAPI BackgroundTask) — schedule as a task
            asyncio.ensure_future(coro)
        else:
            loop.run_until_complete(coro)
    except RuntimeError:
        asyncio.run(coro)
