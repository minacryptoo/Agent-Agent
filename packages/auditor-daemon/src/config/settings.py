
import os
from dotenv import load_dotenv
load_dotenv()

class Settings:
    RPC_URL = os.getenv('RPC_URL', 'https://mainnet.base.org')
    ESCROW_ADDRESS = os.getenv('ESCROW_ADDRESS', '')
    AUDITOR_PRIVATE_KEY = os.getenv('AUDITOR_PRIVATE_KEY', '')
    REDIS_URL = os.getenv('REDIS_URL', 'redis://localhost:6379')
    SLA_TIMEOUT_MINUTES = 30
    MAX_RETRIES = 3
    ALERT_WEBHOOK_URL = os.getenv('ALERT_WEBHOOK_URL', '')

settings = Settings()
