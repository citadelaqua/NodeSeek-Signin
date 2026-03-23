"""FastAPI application entry point."""

import logging
from collections.abc import AsyncGenerator
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from web.backend.database import init_db
from web.backend.routers import accounts, auth, config, signin, stats
from web.backend.scheduler import get_scheduler

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger(__name__)

FRONTEND_DIST = Path(__file__).parent.parent / "frontend" / "dist"


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    # Startup
    await init_db()
    scheduler = get_scheduler()
    scheduler.start()
    logger.info("Application started. Scheduler next run: %s", scheduler.next_run_str())
    yield
    # Shutdown
    scheduler.stop()
    logger.info("Application shutting down.")


app = FastAPI(
    title="NodeSeek 签到面板",
    description="NodeSeek 论坛自动签到 Web 管理面板",
    version="1.1.0",
    lifespan=lifespan,
)

# CORS — allow all origins in dev; tighten in production via environment
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# API routers
app.include_router(auth.router)
app.include_router(accounts.router)
app.include_router(signin.router)
app.include_router(stats.router)
app.include_router(config.router)

# Serve the built Vue SPA (only when dist exists)
if FRONTEND_DIST.exists():
    app.mount("/", StaticFiles(directory=str(FRONTEND_DIST), html=True), name="frontend")
    logger.info("Serving frontend from %s", FRONTEND_DIST)
else:
    logger.warning(
        "Frontend dist not found at %s — API-only mode. Run 'cd web/frontend && npm run build' to build the frontend.",
        FRONTEND_DIST,
    )
