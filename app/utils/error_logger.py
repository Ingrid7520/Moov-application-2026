import logging
import asyncio
from typing import Optional

from app.database import mongodb
from app.services.chat_history_service import ChatHistoryService


class MongoChatLogHandler(logging.Handler):
    """Logging handler that persists warnings/errors into chat history.

    It schedules an async task to call ChatHistoryService.log_error.
    """

    def __init__(self, user_id: str = "system", session_id: str = "system_logs", level: int = logging.WARNING):
        super().__init__(level)
        self.user_id = user_id
        self.session_id = session_id

    def emit(self, record: logging.LogRecord) -> None:
        try:
            msg = self.format(record)
            severity = record.levelname.lower()

            # Use the global mongodb instance to get the async DB
            try:
                db = mongodb.get_database()
            except Exception:
                # If DB not ready, skip persisting
                return

            chat_service = ChatHistoryService(db)

            # Schedule async call to persist the error
            loop = None
            try:
                loop = asyncio.get_running_loop()
            except RuntimeError:
                loop = None

            if loop and loop.is_running():
                asyncio.create_task(self._send(chat_service, msg, severity))
            else:
                # If no loop, attempt to run the coroutine (best-effort)
                try:
                    asyncio.run(self._send(chat_service, msg, severity))
                except Exception:
                    pass

        except Exception:
            # Silently ignore logging handler failures
            pass

    async def _send(self, chat_service: ChatHistoryService, message: str, severity: str):
        try:
            await chat_service.log_error(
                user_id=self.user_id,
                session_id=self.session_id,
                error_message=message,
                severity=severity
            )
        except Exception:
            # do not raise from logging
            return
