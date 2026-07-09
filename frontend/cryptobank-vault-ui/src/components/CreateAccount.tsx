'use client';

import { useState } from 'react';
import { useAccount, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { BANK_CONTRACT_ADDRESS, BANK_ABI } from '../../constants';

export function CreateAccount() {
  const { address } = useAccount();
  const [isJoint, setIsJoint] = useState(false);
  const [coOwner, setCoOwner] = useState('');

  // Wagmi v2 hook for writing to the contract
  const { data: hash, error, isPending, writeContract } = useWriteContract();

  // Wagmi v2 hook to wait for the transaction to be mined
  const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
    hash,
  });

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!address) return;

    // AccountType enum: 0 for Individual, 1 for Joint
    const accountType = isJoint ? 1 : 0;
    
    // Construct the owners array based on the selection
    const owners = isJoint && coOwner 
      ? [address, coOwner as `0x${string}`] 
      : [address];

    writeContract({
      address: BANK_CONTRACT_ADDRESS,
      abi: BANK_ABI,
      functionName: 'createAccount',
      args: [accountType, owners],
    });
  };

  return (
    <div className="bg-gray-800 p-6 rounded-lg shadow-lg max-w-md w-full mt-6">
      <h2 className="text-2xl font-semibold mb-4 text-white">Open New Vault</h2>
      
      <form onSubmit={handleCreate} className="flex flex-col gap-4">
        <div>
          <label className="text-gray-300 mr-4">Account Type:</label>
          <select 
            className="bg-gray-700 text-white p-2 rounded"
            value={isJoint ? 'joint' : 'individual'}
            onChange={(e) => setIsJoint(e.target.value === 'joint')}
          >
            <option value="individual">Individual</option>
            <option value="joint">Joint (Multi-sig)</option>
          </select>
        </div>

        {isJoint && (
          <div>
            <label className="text-gray-300 block mb-1">Co-Owner Address:</label>
            <input 
              type="text" 
              placeholder="0x..." 
              required
              className="bg-gray-700 text-white p-2 rounded w-full border border-gray-600"
              value={coOwner}
              onChange={(e) => setCoOwner(e.target.value)}
            />
          </div>
        )}

        <button 
          type="submit" 
          disabled={isPending || isConfirming}
          className="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded disabled:opacity-50"
        >
          {isPending ? 'Confirm in Wallet...' : isConfirming ? 'Mining...' : 'Create Account'}
        </button>
      </form>

      {/* Transaction Status Messages */}
      {isConfirmed && (
        <div className="mt-4 p-3 bg-green-800 text-green-100 rounded">
          Vault successfully created!
        </div>
      )}
      {error && (
        <div className="mt-4 p-3 bg-red-800 text-red-100 rounded overflow-hidden text-sm">
          Error: {error.message.slice(0, 100)}...
        </div>
      )}
    </div>
  );
}