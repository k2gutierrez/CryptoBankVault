import { getDefaultConfig } from "@rainbow-me/rainbowkit";
import { foundry, curtis } from "wagmi/chains";

export const config = getDefaultConfig({
    appName: 'CryptoBank Vault',
    projectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID!,
    chains: [
    foundry, // Red local para tu desarrollo
        ...(process.env.NEXT_PUBLIC_ENABLE_TESTNETS === 'true' ? [curtis] : []),
    ],
    ssr: true,
});