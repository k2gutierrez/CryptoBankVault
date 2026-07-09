'use client';

import { useState } from 'react';
import { useAtomValue } from 'jotai';
import { useReadContract, useWriteContract, useAccount } from 'wagmi';
import { formatEther, parseEther } from 'viem';
import { motion, AnimatePresence } from 'framer-motion';
import { selectedAccountIdAtom } from '../../store';
import { BANK_CONTRACT_ADDRESS, BANK_ABI } from '../../constants';

export function AccountDetails() {
  const { address } = useAccount();
  const selectedAccountId = useAtomValue(selectedAccountIdAtom);
  const [depositAmount, setDepositAmount] = useState('');
  const [withdrawAmount, setWithdrawAmount] = useState('');

  const { writeContract } = useWriteContract();

  // Fetch Account Data
  const { data: account, isLoading: isLoadingAccount } = useReadContract({
    address: BANK_CONTRACT_ADDRESS,
    abi: BANK_ABI,
    functionName: 'getAccount',
    args: selectedAccountId ? [selectedAccountId] : undefined,
    query: { enabled: !!selectedAccountId }
  });

  // Fetch Pending Withdrawal Request
  const { data: withdrawalRequest } = useReadContract({
    address: BANK_CONTRACT_ADDRESS,
    abi: BANK_ABI,
    functionName: 'getWithdrawalRequest',
    args: selectedAccountId ? [selectedAccountId] : undefined,
    query: { enabled: !!selectedAccountId }
  });

  if (!selectedAccountId) {
    return (
      <div className="bg-gray-800/50 backdrop-blur-sm p-8 rounded-2xl text-center border border-gray-700/50 h-full flex items-center justify-center text-gray-400">
        <p className="animate-pulse">Select a vault from the list to manage your funds and yield.</p>
      </div>
    );
  }

  if (isLoadingAccount) return <div className="text-gray-400 animate-pulse">Loading vault data...</div>;
  if (!account) return <div className="text-red-400">Vault data not found.</div>;
  
  // Destructure withdrawal request if it exists
  const hasPendingRequest = withdrawalRequest && withdrawalRequest.amount > BigInt(0) && !withdrawalRequest.isExecuted;
  const reqAmount = hasPendingRequest ? withdrawalRequest.amount : BigInt(0);
  const reqRequester = hasPendingRequest ? withdrawalRequest.requester : '';

  // Handlers
  const handleDeposit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!depositAmount || !account.isActive) return;
    writeContract({
      address: BANK_CONTRACT_ADDRESS,
      abi: BANK_ABI,
      functionName: 'deposit',
      args: [account.id],
      value: parseEther(depositAmount),
    });
    setDepositAmount('');
  };

  const handleWithdrawRequest = (e: React.FormEvent) => {
    e.preventDefault();
    if (!withdrawAmount || !account.isActive) return;
    writeContract({
      address: BANK_CONTRACT_ADDRESS,
      abi: BANK_ABI,
      functionName: 'requestWithdrawal',
      args: [account.id, parseEther(withdrawAmount)],
    });
    setWithdrawAmount('');
  };

  const handleTogglePause = () => {
    writeContract({
      address: BANK_CONTRACT_ADDRESS,
      abi: BANK_ABI,
      functionName: 'pauseUnpauseAccount',
      args: [account.id],
    });
  };

  const handleApproveWithdrawal = () => {
    writeContract({
      address: BANK_CONTRACT_ADDRESS,
      abi: BANK_ABI,
      functionName: 'approveWithdrawal',
      args: [account.id],
    });
  };

  return (
    <motion.div 
      key={account.id.toString()} 
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4, ease: "easeOut" }}
      className="bg-gray-800 p-8 rounded-2xl shadow-2xl border border-gray-700 flex flex-col gap-8 relative overflow-hidden"
    >
      <div className="absolute -top-24 -right-24 w-48 h-48 bg-blue-500 rounded-full mix-blend-multiply filter blur-3xl opacity-10"></div>

      {/* Vault Header (Same as before) */}
      <div className="border-b border-gray-700/50 pb-6 relative z-10">
        <div className="flex justify-between items-start mb-4">
          <div>
            <h2 className="text-3xl font-extrabold text-white tracking-tight">Vault #{account.id.toString()}</h2>
            <div className="flex gap-2 mt-2">
              <span className={`px-3 py-1 rounded-full text-xs font-semibold shadow-sm ${account.accType === 0 ? 'bg-indigo-500/20 text-indigo-300 border border-indigo-500/30' : 'bg-purple-500/20 text-purple-300 border border-purple-500/30'}`}>
                {account.accType === 0 ? 'Individual' : 'Joint (Multi-sig)'}
              </span>
              <span className={`px-3 py-1 rounded-full text-xs font-semibold shadow-sm border ${account.isActive ? 'bg-emerald-500/20 text-emerald-300 border-emerald-500/30' : 'bg-red-500/20 text-red-300 border-red-500/30'}`}>
                {account.isActive ? 'Active' : 'Paused'}
              </span>
            </div>
          </div>
          <button onClick={handleTogglePause} className="text-sm px-4 py-2 rounded-lg bg-gray-700 hover:bg-gray-600 border border-gray-600 text-gray-200 transition-colors">
            {account.isActive ? 'Pause Vault' : 'Unpause Vault'}
          </button>
        </div>
        <div className="mt-6">
          <p className="text-sm text-gray-400 font-medium uppercase tracking-wider mb-1">Total Balance</p>
          <p className="text-5xl font-black text-transparent bg-clip-text bg-gradient-to-r from-emerald-400 to-cyan-400">
            {formatEther(account.balance)} <span className="text-2xl text-emerald-500/50">ETH</span>
          </p>
        </div>
      </div>

      {/* Pending Withdrawal Notification (Multi-sig logic) */}
      <AnimatePresence>
        {account.accType === 1 && hasPendingRequest && (
          <motion.div 
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            className="relative z-10 bg-amber-500/10 border border-amber-500/30 rounded-xl p-5 flex flex-col md:flex-row items-center justify-between gap-4"
          >
            <div>
              <h4 className="text-amber-400 font-bold flex items-center gap-2">
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path></svg>
                Pending Approval
              </h4>
              <p className="text-sm text-gray-300 mt-1">
                A withdrawal of <span className="font-bold text-white">{formatEther(reqAmount)} ETH</span> has been requested by <span className="font-mono text-xs">{reqRequester.slice(0, 6)}...{reqRequester.slice(-4)}</span>.
              </p>
            </div>
            
            {/* Logic: the requester cannot approve their own request */}
            {address?.toLowerCase() === reqRequester.toLowerCase() ? (
              <span className="text-xs text-amber-500/70 bg-amber-900/20 px-3 py-2 rounded-lg text-center">
                Waiting for co-owner
              </span>
            ) : (
              <button 
                onClick={handleApproveWithdrawal}
                disabled={!account.isActive}
                className="whitespace-nowrap bg-amber-500 hover:bg-amber-400 disabled:bg-gray-600 text-amber-950 font-bold py-2 px-6 rounded-lg transition-colors shadow-lg"
              >
                Approve & Execute
              </button>
            )}
          </motion.div>
        )}
      </AnimatePresence>

      {/* Transaction Forms */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 relative z-10">
        <motion.form whileHover={{ scale: 1.02 }} onSubmit={handleDeposit} className={`p-5 rounded-xl flex flex-col gap-4 border ${account.isActive ? 'bg-gray-700/40 border-gray-600/50' : 'bg-gray-800/40 border-red-900/30 opacity-50'}`}>
          <h3 className="font-semibold text-gray-200">Deposit Funds</h3>
          <div className="relative">
            <input type="number" step="any" disabled={!account.isActive} placeholder="0.00" value={depositAmount} onChange={(e) => setDepositAmount(e.target.value)} className="w-full p-3 pl-4 pr-12 bg-gray-900/80 rounded-lg border border-gray-600 text-white focus:ring-2 focus:ring-blue-500 focus:outline-none transition-all"/>
            <span className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 font-bold">ETH</span>
          </div>
          <button type="submit" disabled={!account.isActive} className="w-full bg-blue-600 hover:bg-blue-500 disabled:bg-gray-600 text-white font-bold py-3 rounded-lg transition-colors">Deposit</button>
        </motion.form>

        <motion.form whileHover={{ scale: 1.02 }} onSubmit={handleWithdrawRequest} className={`p-5 rounded-xl flex flex-col gap-4 border ${account.isActive ? 'bg-gray-700/40 border-gray-600/50' : 'bg-gray-800/40 border-red-900/30 opacity-50'}`}>
          <h3 className="font-semibold text-gray-200">{account.accType === 0 ? 'Withdraw Funds' : 'Request Withdrawal'}</h3>
          <div className="relative">
            <input type="number" step="any" disabled={!account.isActive} placeholder="0.00" value={withdrawAmount} onChange={(e) => setWithdrawAmount(e.target.value)} className="w-full p-3 pl-4 pr-12 bg-gray-900/80 rounded-lg border border-gray-600 text-white focus:ring-2 focus:ring-red-500 focus:outline-none transition-all"/>
            <span className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 font-bold">ETH</span>
          </div>
          <button type="submit" disabled={!account.isActive} className="w-full bg-red-500/90 hover:bg-red-400 disabled:bg-gray-600 text-white font-bold py-3 rounded-lg transition-colors">{account.accType === 0 ? 'Withdraw' : 'Send Request'}</button>
        </motion.form>
      </div>
    </motion.div>
  );
}