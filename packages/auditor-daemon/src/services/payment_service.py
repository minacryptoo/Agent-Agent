from loguru import logger
from web3 import Web3
from config.settings import settings

class PaymentService:
    def __init__(self):
        self.web3 = Web3(Web3.HTTPProvider(settings.RPC_URL))
        self.escrow_contract = self.web3.eth.contract(
            address=settings.ESCROW_ADDRESS,
            abi=ESCROW_ABI
        )
    
    async def execute_fallback_payout(self, task_id):
        try:
            tx = self.escrow_contract.functions.executeFallbackPayout(task_id).build_transaction({
                'from': settings.AUDITOR_WALLET,
                'nonce': self.web3.eth.get_transaction_count(settings.AUDITOR_WALLET),
                'gas': 200000,
                'gasPrice': self.web3.eth.gas_price
            })
            signed_tx = self.web3.eth.account.sign_transaction(tx, private_key=settings.AUDITOR_PRIVATE_KEY)
            tx_hash = self.web3.eth.send_raw_transaction(signed_tx.rawTransaction)
            logger.info(f"Fallback payout executed: {tx_hash.hex()}")
            return tx_hash.hex()
        except Exception as e:
            logger.error(f"Error executing fallback payout: {e}")
            return None

ESCROW_ABI = [
    {
        "inputs": [{"name": "taskId", "type": "bytes32"}],
        "name": "executeFallbackPayout",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    }
]
