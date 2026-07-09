'use client';

import { useReadContract } from 'wagmi';
import { useAtom } from 'jotai';
import { selectedAccountIdAtom } from '../../store';
import { BANK_CONTRACT_ADDRESS, BANK_ABI } from '../../constants';

interface VaultListItemProps {
  accountId: bigint;
}

export function VaultListItem({ accountId }: VaultListItemProps) {
  const [selectedAccountId, setSelectedAccountId] = useAtom(selectedAccountIdAtom);
  const isSelected = selectedAccountId === accountId;

  // Consultamos los detalles específicos de esta bóveda
  const { data: account } = useReadContract({
    address: BANK_CONTRACT_ADDRESS,
    abi: BANK_ABI,
    functionName: 'getAccount',
    args: [accountId],
  });

  // Desestructuramos el estado isActive (es el índice 5 en tu tupla)
  // Si 'account' aún no carga, asumimos true para no parpadear en rojo
  const isActive = account?.isActive == true ? true : false;

  return (
    <li>
      <button
        onClick={() => setSelectedAccountId(accountId)}
        className={`w-full flex justify-between items-center text-left p-3 rounded-lg font-medium transition duration-200 ${
          isSelected 
            ? 'bg-blue-600 text-white shadow-md' 
            : 'bg-gray-700 hover:bg-gray-600 text-gray-300'
        }`}
      >
        <span>Vault #{accountId.toString()}</span>
        
        {/* Si la cuenta NO está activa, mostramos el badge (etiqueta) rojo */}
        {!isActive && (
          <span className="bg-red-500/20 text-red-300 border border-red-500/30 text-[10px] font-bold px-2 py-0.5 rounded-full uppercase tracking-wider">
            Paused
          </span>
        )}
      </button>
    </li>
  );
}