'use client';

import { useState, useEffect } from 'react';
import { useAccount, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { BANK_CONTRACT_ADDRESS, BANK_ABI } from '../../constants';

// 1. Definimos las props del componente
interface CreateAccountProps {
  onAccountCreated: () => void;
}

export function CreateAccount({ onAccountCreated }: CreateAccountProps) {
  const { address } = useAccount();
  const [isJoint, setIsJoint] = useState(false);
  const [coOwner, setCoOwner] = useState('');

  const { data: hash, error, isPending, writeContract } = useWriteContract();

  const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
    hash,
  });

  // 2. Escuchamos el estado "isConfirmed" para refrescar la lista
  useEffect(() => {
    if (isConfirmed) {
      onAccountCreated();
    }
  }, [isConfirmed, onAccountCreated]);

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!address) return;

    const accountType = isJoint ? 1 : 0;
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
    <div className="bg-gray-800 p-6 rounded-xl shadow-lg border border-gray-700">
      <h2 className="text-xl font-semibold mb-4 text-white">Open New Vault</h2>
      
      <form onSubmit={handleCreate} className="flex flex-col gap-4">
        <div>
          <label className="text-gray-300 mr-4 text-sm font-medium">Account Type:</label>
          <select 
            className="bg-gray-900 text-white p-2 rounded-lg border border-gray-600 focus:ring-2 focus:ring-blue-500 w-full mt-1"
            value={isJoint ? 'joint' : 'individual'}
            onChange={(e) => setIsJoint(e.target.value === 'joint')}
          >
            <option value="individual">Individual</option>
            <option value="joint">Joint (Multi-sig)</option>
          </select>
        </div>

        {isJoint && (
          <div>
            <label className="text-gray-300 block mb-1 text-sm font-medium">Co-Owner Address:</label>
            <input 
              type="text" 
              placeholder="0x..." 
              required
              className="bg-gray-900 text-white p-2 rounded-lg border border-gray-600 w-full focus:ring-2 focus:ring-blue-500"
              value={coOwner}
              onChange={(e) => setCoOwner(e.target.value)}
            />
          </div>
        )}

        <button 
          type="submit" 
          disabled={isPending || isConfirming}
          className="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded-lg disabled:opacity-50 transition-colors mt-2"
        >
          {isPending ? 'Confirm in Wallet...' : isConfirming ? 'Mining...' : 'Create Account'}
        </button>
      </form>

      {isConfirmed && (
        <div className="mt-4 p-3 bg-green-500/20 text-green-300 border border-green-500/30 rounded-lg text-sm text-center">
          Vault successfully created!
        </div>
      )}
      {error && (
        <div className="mt-4 p-3 bg-red-500/20 text-red-300 border border-red-500/30 rounded-lg text-sm overflow-hidden">
          Error: {error.message.slice(0, 100)}...
        </div>
      )}
    </div>
  );
}