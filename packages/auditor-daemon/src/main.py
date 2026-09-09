
import asyncio
from loguru import logger
from services.event_listener import EventListener
from services.task_recovery import TaskRecoveryService
from services.sla_monitor import SLAMonitor

async def main():
    logger.info("Starting A2A Auditor Daemon...")
    event_listener = EventListener()
    task_recovery = TaskRecoveryService()
    sla_monitor = SLAMonitor()
    tasks = [event_listener.start(), task_recovery.start(), sla_monitor.start()]
    try:
        await asyncio.gather(*tasks)
    except KeyboardInterrupt:
        logger.info("Shutting down...")

if __name__ == "__main__":
    asyncio.run(main())
