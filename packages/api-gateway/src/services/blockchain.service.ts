import { ethers } from 'ethers';

export const blockchainService = {
  provider: new ethers.JsonRpcProvider(process.env.RPC_URL || 'https://mainnet.base.org'),
  async getEscrowContract() {
    const escrowAddress = process.env.ESCROW_ADDRESS;
    if (!escrowAddress) throw new Error('Escrow address not configured');
    const abi = [
      'function createTask(bytes32 taskId, uint256 amount) external',
      'function releasePayment(bytes32 taskId) external',
      'function executeFallbackPayout(bytes32 taskId) external',
    ];
    return new ethers.Contract(escrowAddress, abi, this.provider);
  },
  async getTransactionReceipt(txHash: string) {
    return this.provider.getTransactionReceipt(txHash);
  },
}