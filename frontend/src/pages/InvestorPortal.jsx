import { useState, useEffect, useCallback } from "react";
import TransactionStatus from "../components/TransactionStatus";

export default function InvestorPortal({ contracts, account }) {
  const [balance, setBalance] = useState(null);
  const [frozen, setFrozen] = useState(null);
  const [isVerified, setIsVerified] = useState(null);
  const [country, setCountry] = useState(null);
  const [txStatus, setTxStatus] = useState(null);

  const loadData = useCallback(async () => {
    if (!contracts || !account) return;
    try {
      const [bal, frz, verified, ctry] = await Promise.all([
        contracts.RealEstateToken.balanceOf(account),
        contracts.RealEstateToken.getFrozenTokens(account),
        contracts.IdentityRegistry.isVerified(account),
        contracts.IdentityRegistry.investorCountry(account).catch(() => 0),
      ]);
      setBalance(bal.toString());
      setFrozen(frz.toString());
      setIsVerified(verified);
      setCountry(Number(ctry));
    } catch (err) {
      console.error("Failed to load investor data:", err);
    }
  }, [contracts, account]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  return (
    <div className="page">
      <h1>Investor Portal</h1>
      <TransactionStatus status={txStatus} />

      <div className="grid">
        <BalanceCard balance={balance} frozen={frozen} />
        <IdentityCard isVerified={isVerified} country={country} account={account} />
        <TransferCard contracts={contracts} account={account} setTxStatus={setTxStatus} onSuccess={loadData} />
      </div>
    </div>
  );
}

function BalanceCard({ balance, frozen }) {
  const free = balance !== null && frozen !== null ? (Number(balance) - Number(frozen)).toString() : "--";

  return (
    <div className="card">
      <h2>Token Balance</h2>
      <div className="stat-grid">
        <div className="stat">
          <span className="stat-label">Total Balance</span>
          <span className="stat-value">{balance ?? "--"}</span>
        </div>
        <div className="stat">
          <span className="stat-label">Frozen</span>
          <span className="stat-value frozen">{frozen ?? "--"}</span>
        </div>
        <div className="stat">
          <span className="stat-label">Transferable</span>
          <span className="stat-value success">{free}</span>
        </div>
      </div>
    </div>
  );
}

function IdentityCard({ isVerified, country, account }) {
  const COUNTRY_NAMES = { 1: "USA", 44: "UK", 91: "India", 86: "China", 81: "Japan" };

  return (
    <div className="card">
      <h2>Identity Status</h2>
      <div className="stat-grid">
        <div className="stat">
          <span className="stat-label">Wallet</span>
          <span className="stat-value mono">{account ? `${account.slice(0, 10)}...${account.slice(-8)}` : "--"}</span>
        </div>
        <div className="stat">
          <span className="stat-label">KYC Verified</span>
          <span className={`stat-value ${isVerified ? "success" : "frozen"}`}>
            {isVerified === null ? "--" : isVerified ? "Yes" : "No"}
          </span>
        </div>
        <div className="stat">
          <span className="stat-label">Country</span>
          <span className="stat-value">{country ? `${COUNTRY_NAMES[country] || "Code " + country} (${country})` : "--"}</span>
        </div>
      </div>
    </div>
  );
}

function TransferCard({ contracts, account, setTxStatus, onSuccess }) {
  const [to, setTo] = useState("");
  const [amount, setAmount] = useState("");
  const [preCheck, setPreCheck] = useState(null);

  const checkTransfer = async () => {
    if (!to || !amount) return;
    setPreCheck(null);
    try {
      const verified = await contracts.IdentityRegistry.isVerified(to);
      if (!verified) {
        setPreCheck({ ok: false, reason: "Recipient is not verified in Identity Registry." });
        return;
      }
      const canTransfer = await contracts.ModularCompliance.canTransfer(account, to, amount);
      if (!canTransfer) {
        setPreCheck({ ok: false, reason: "Transfer blocked by compliance module (country restriction, max holders, or max balance)." });
        return;
      }
      setPreCheck({ ok: true, reason: "Transfer pre-check passed." });
    } catch (err) {
      setPreCheck({ ok: false, reason: err.reason || err.message });
    }
  };

  const handleTransfer = async (e) => {
    e.preventDefault();
    setTxStatus({ type: "pending", message: "Sending transfer..." });
    try {
      const tx = await contracts.RealEstateToken.transfer(to, amount);
      setTxStatus({ type: "pending", message: "Waiting for confirmation...", hash: tx.hash });
      await tx.wait();
      setTxStatus({ type: "success", message: "Transfer completed!", hash: tx.hash });
      setTo("");
      setAmount("");
      setPreCheck(null);
      onSuccess();
    } catch (err) {
      const reason = err.reason || err.message || "Transfer failed";
      setTxStatus({ type: "error", message: reason });
    }
  };

  return (
    <div className="card">
      <h2>Transfer Tokens</h2>
      <form onSubmit={handleTransfer}>
        <input placeholder="Recipient address" value={to} onChange={(e) => { setTo(e.target.value); setPreCheck(null); }} required />
        <input placeholder="Amount" type="number" value={amount} onChange={(e) => { setAmount(e.target.value); setPreCheck(null); }} required />

        <button type="button" className="btn btn-secondary" onClick={checkTransfer}>
          Pre-flight Check
        </button>

        {preCheck && (
          <div className={`pre-check ${preCheck.ok ? "pre-check-ok" : "pre-check-fail"}`}>
            {preCheck.ok ? "\u2713" : "\u2717"} {preCheck.reason}
          </div>
        )}

        <button className="btn btn-primary" type="submit" disabled={preCheck && !preCheck.ok}>
          Transfer
        </button>
      </form>
    </div>
  );
}
