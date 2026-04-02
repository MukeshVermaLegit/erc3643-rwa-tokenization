import { useState, useEffect, useCallback } from "react";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { ethers } from "ethers";
import { CHAIN_ID } from "./config";
import { useContracts } from "./hooks/useContracts";
import Navbar from "./components/Navbar";
import AdminDashboard from "./pages/AdminDashboard";
import InvestorPortal from "./pages/InvestorPortal";
import ComplianceMonitor from "./pages/ComplianceMonitor";
import "./styles/app.css";

export default function App() {
  const [account, setAccount] = useState(null);
  const [signer, setSigner] = useState(null);
  const [role, setRole] = useState("viewer");

  const contracts = useContracts(signer);

  const detectRole = useCallback(
    async (address) => {
      if (!address || !contracts) {
        setRole("viewer");
        return;
      }
      try {
        const [owner, isAgent, isInvestor] = await Promise.all([
          contracts.RealEstateToken.owner(),
          contracts.RealEstateToken.isAgent(address),
          contracts.IdentityRegistry.contains(address),
        ]);
        if (owner.toLowerCase() === address.toLowerCase() || isAgent) {
          setRole("admin");
        } else if (isInvestor) {
          setRole("investor");
        } else {
          setRole("viewer");
        }
      } catch (err) {
        console.error("Role detection failed:", err);
        setRole("viewer");
      }
    },
    [contracts]
  );

  useEffect(() => {
    detectRole(account);
  }, [account, detectRole]);

  const handleConnect = useCallback(async (address) => {
    const provider = new ethers.BrowserProvider(window.ethereum);
    const s = await provider.getSigner();
    setAccount(address.toLowerCase());
    setSigner(s);
  }, []);

  const handleDisconnect = useCallback(() => {
    setAccount(null);
    setSigner(null);
    setRole("viewer");
  }, []);

  // Listen for account/chain changes
  useEffect(() => {
    if (!window.ethereum) return;

    const onAccountsChanged = (accounts) => {
      if (accounts.length === 0) {
        handleDisconnect();
      } else {
        handleConnect(accounts[0]);
      }
    };

    const onChainChanged = (chainId) => {
      if (parseInt(chainId, 16) !== CHAIN_ID) {
        handleDisconnect();
      }
    };

    window.ethereum.on("accountsChanged", onAccountsChanged);
    window.ethereum.on("chainChanged", onChainChanged);

    return () => {
      window.ethereum.removeListener("accountsChanged", onAccountsChanged);
      window.ethereum.removeListener("chainChanged", onChainChanged);
    };
  }, [handleConnect, handleDisconnect]);

  const defaultRoute = role === "admin" ? "/" : role === "investor" ? "/investor" : "/compliance";

  return (
    <BrowserRouter>
      <Navbar
        account={account}
        role={role}
        onConnect={handleConnect}
        onDisconnect={handleDisconnect}
      />
      <main className="container">
        <Routes>
          {role === "admin" && (
            <Route path="/" element={<AdminDashboard contracts={contracts} />} />
          )}
          {role === "investor" && (
            <Route path="/investor" element={<InvestorPortal contracts={contracts} account={account} />} />
          )}
          <Route path="/compliance" element={<ComplianceMonitor />} />
          <Route path="*" element={<Navigate to={defaultRoute} replace />} />
        </Routes>
      </main>
    </BrowserRouter>
  );
}
