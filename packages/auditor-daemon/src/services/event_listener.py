
import asyncio
from loguru import logger
from web3 import Web3
from config.settings import settings

class EventListener:
    def __init__(self):
        self.web3 = Web3(Web3.HTTPProvider(settings.RPC_URL))
        self.escrow_contract = self.web3.eth.contract(
            address=settings.ESCROW_ADDRESS,
            abi=ESCROW_ABI
        )
    
    async def start(self):
        logger.info("Starting event listener...")
        while True:
            try:
                events = self.escrow_contract.events.PaymentReleased.get_logs(fromBlock='latest')
                for event in events:
                    await self.handle_event(event)
                await asyncio.sleep(5)
            except Exception as e:
                logger.error(f"Error in event listener: {e}")
                await asyncio.sleep(10)
    
    async def handle_event(self, event):
        task_id = event['args']['taskId']
        worker = event['args']['worker']
        amount = event['args']['workerAmount']
        logger.info(f"Payment released for task {task_id} to {worker}: {amount} USDC")
    
    async def update_task_status(self, task_id, status):
        pass

ESCROW_ABI = [
    {
        "anonymous": False,
        "inputs": [
            {"indexed": True, "name": "taskId", "type": "bytes32"},
            {"indexed": True, "name": "worker", "type": "address"},
            {"indexed": False, "name": "workerAmount", "type": "uint256"},
            {"indexed": False, "name": "fee", "type": "uint256"}
        ],
        "name": "PaymentReleased",
        "type": "event"
    }
]
