'use client';

import { useAccount, useReadContract } from 'wagmi';
import { formatEther } from 'viem';
import { motion } from 'framer-motion';
import { BANK_CONTRACT_ADDRESS, BANK_ABI, YIELD_TOKEN_ABI } from '../../constants';

export function YieldPortfolio() {
  const { address, isConnected } = useAccount();

  // 1. Get the Yield Token ($BKT) address dynamically from the Bank contract
  const { data: yieldTokenAddress } = useReadContract({
    address: BANK_CONTRACT_ADDRESS,
    abi: BANK_ABI,
    functionName: 'getYeildTokenAddress', // Matches your contract's exact spelling
    query: { enabled: isConnected }
  });

  // 2. Fetch the user's $BKT ERC-20 token balance
  const { data: bktBalance, isLoading } = useReadContract({
    address: yieldTokenAddress,
    abi: YIELD_TOKEN_ABI,
    functionName: 'balanceOf',
    args: address ? [address] : undefined,
    query: { 
      enabled: isConnected && !!yieldTokenAddress && !!address,
      refetchInterval: 5000 // Automatically refresh every 5 seconds to show updates!
    }
  });

  if (!isConnected) return null;

  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.95 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ duration: 0.5 }}
      className="w-full bg-gradient-to-r from-purple-900/40 to-pink-900/30 backdrop-blur-md border border-purple-500/30 rounded-2xl p-6 shadow-xl relative overflow-hidden flex flex-col md:flex-row items-center justify-between gap-4"
    >
      {/* Visual background elements */}
      <div className="absolute -left-12 -bottom-12 w-32 h-32 bg-pink-500 rounded-full mix-blend-screen filter blur-3xl opacity-20 animate-pulse"></div>
      
      <div>
        <span className="text-xs font-bold uppercase tracking-widest text-purple-400 bg-purple-500/10 px-3 py-1 rounded-full border border-purple-500/20">
          Protocol Rewards
        </span>
        <h3 className="text-xl font-bold text-white mt-2">Accumulated Yield</h3>
        <p className="text-sm text-gray-400 mt-1">
          Tokens are automatically minted to your wallet whenever a deposit or withdrawal occurs.
        </p>
      </div>

      <div className="text-right flex flex-col items-center md:items-end">
        {isLoading ? (
          <div className="h-10 w-32 bg-gray-700 animate-pulse rounded-lg"></div>
        ) : (
          <motion.p 
            key={bktBalance?.toString()}
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            className="text-4xl font-black text-transparent bg-clip-text bg-gradient-to-r from-purple-400 to-pink-400 font-mono tracking-tight"
          >
            {bktBalance ? Number(formatEther(bktBalance)).toFixed(4) : '0.0000'}
            <span className="text-lg font-bold text-pink-400/70 ml-2">BKT</span>
          </motion.p>
        )}
        <span className="text-xs text-purple-300/50 font-mono mt-1">
          Rate: (Balance * Time) / 100,000
        </span>
      </div>
    </motion.div>
  );
}