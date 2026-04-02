import { CHAIN_ID, SEPOLIA_PARAMS } from "../config";

export default function ConnectWallet({ account, onConnect, onDisconnect }) {
  async function connect() {
    if (!window.ethereum) {
      alert("Please install MetaMask to use this dApp.");
      return;
    }

    try {
      const chainId = await window.ethereum.request({ method: "eth_chainId" });
      if (parseInt(chainId, 16) !== CHAIN_ID) {
        try {
          await window.ethereum.request({
            method: "wallet_switchEthereumChain",
            params: [{ chainId: SEPOLIA_PARAMS.chainId }],
          });
        } catch (switchErr) {
          if (switchErr.code === 4902) {
            await window.ethereum.request({
              method: "wallet_addEthereumChain",
              params: [SEPOLIA_PARAMS],
            });
          } else {
            throw switchErr;
          }
        }
      }

      const accounts = await window.ethereum.request({
        method: "eth_requestAccounts",
      });
      onConnect(accounts[0]);
    } catch (err) {
      console.error("Failed to connect:", err);
    }
  }

  if (account) {
    return (
      <div className="wallet-info">
        <span className="wallet-address">
          {account.slice(0, 6)}...{account.slice(-4)}
        </span>
        <button className="btn btn-secondary" onClick={onDisconnect}>
          Disconnect
        </button>
      </div>
    );
  }

  return (
    <button className="btn btn-primary" onClick={connect}>
      Connect Wallet
    </button>
  );
}
