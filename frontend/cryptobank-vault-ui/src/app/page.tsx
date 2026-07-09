'use client';

import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useAccount, useReadContract } from 'wagmi';
import { useAtom } from 'jotai';
import { BANK_CONTRACT_ADDRESS, BANK_ABI } from '../../constants';
import { CreateAccount } from '../components/CreateAccount';
import { AccountDetails } from '../components/AccountDetails';
import { YieldPortfolio } from '../components/YieldPortfolio';
import { selectedAccountIdAtom } from '../../store';
import { VaultListItem } from '../components/VaultListItem';

export default function Home() {
  const { address, isConnected } = useAccount();
  
  const [selectedAccountId, setSelectedAccountId] = useAtom(selectedAccountIdAtom);

  const { data: userAccounts, isLoading, isError, refetch } = useReadContract({
    address: BANK_CONTRACT_ADDRESS,
    abi: BANK_ABI,
    functionName: 'getUserAccounts',
    args: address ? [address] : undefined,
    query: {
      enabled: isConnected && !!address,
    }
  });

  return (
    <main className="flex min-h-screen flex-col items-center p-8 md:p-12 bg-gray-900 text-white">
      
      {/* HEADER */}
      <div className="z-10 max-w-6xl w-full items-center justify-between font-mono text-sm flex mb-12 border-b border-gray-800 pb-6">
        <h1 className="text-3xl font-bold tracking-tight bg-gradient-to-r from-blue-400 to-indigo-500 bg-clip-text text-transparent">
          CryptoBank Vault
        </h1>
        <ConnectButton />
      </div>

      {!isConnected ? (
        <div className="mt-24 text-center">
          <p className="text-xl text-gray-400">Connect your wallet to access your security vault.</p>
        </div>
      ) : (
        <div className="w-full max-w-6xl flex flex-col gap-8">
          
          {/* YIELD PORTFOLIO SECTION */}
          <YieldPortfolio />

          {/* MAIN GRID */}
          <div className="w-full grid grid-cols-1 md:grid-cols-3 gap-8">
            
            {/* LEFT COLUMN: Vault List & Create Form */}
            <div className="md:col-span-1 flex flex-col gap-6">
              
              <div className="bg-gray-800 p-6 rounded-xl shadow-lg border border-gray-700">
                <h2 className="text-xl font-semibold mb-4 text-gray-200">Your Active Vaults</h2>
                
                {isLoading && <p className="text-sm text-gray-400">Loading blockchain data...</p>}
                {isError && <p className="text-sm text-red-400">Error fetching contract data.</p>}
                
                {userAccounts && userAccounts.length === 0 && (
                  <p className="text-gray-400 text-sm">No vaults associated with this wallet.</p>
                )}

                {userAccounts && userAccounts.length > 0 && (
                  <ul className="flex flex-col gap-2">
                    {userAccounts.map((accountId) => (
                      <VaultListItem 
                        key={accountId.toString()} 
                        accountId={accountId} 
                      />
                    ))}
                  </ul>
                )}
              </div>

              <CreateAccount onAccountCreated={() => refetch()} />
            </div>

            {/* RIGHT COLUMN: Vault Details & Actions */}
            <div className="md:col-span-2">
              <AccountDetails />
            </div>

          </div>
        </div>
      )}
    </main>
  );
}