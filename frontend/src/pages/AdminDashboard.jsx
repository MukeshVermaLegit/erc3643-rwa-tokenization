import { useState, useCallback } from "react";
import { CONTRACTS } from "../config";
import TransactionStatus from "../components/TransactionStatus";

export default function AdminDashboard({ contracts }) {
  const [txStatus, setTxStatus] = useState(null);

  const execTx = useCallback(async (label, txPromise) => {
    setTxStatus({ type: "pending", message: `${label}...` });
    try {
      const tx = await txPromise;
      setTxStatus({ type: "pending", message: `${label} — waiting for confirmation...`, hash: tx.hash });
      await tx.wait();
      setTxStatus({ type: "success", message: `${label} succeeded.`, hash: tx.hash });
    } catch (err) {
      const reason = err.reason || err.message || "Transaction failed";
      setTxStatus({ type: "error", message: `${label} failed: ${reason}` });
    }
  }, []);

  return (
    <div className="page">
      <h1>Admin Dashboard</h1>
      <TransactionStatus status={txStatus} />

      <div className="grid">
        <MintSection contracts={contracts} execTx={execTx} />
        <FreezeSection contracts={contracts} execTx={execTx} />
        <PauseSection contracts={contracts} execTx={execTx} />
        <ForcedTransferSection contracts={contracts} execTx={execTx} />
        <ComplianceSettingsSection contracts={contracts} execTx={execTx} />
      </div>
    </div>
  );
}

function MintSection({ contracts, execTx }) {
  const [to, setTo] = useState("");
  const [amount, setAmount] = useState("");

  const handleMint = (e) => {
    e.preventDefault();
    execTx("Minting tokens", contracts.RealEstateToken.mint(to, amount));
  };

  return (
    <div className="card">
      <h2>Mint Tokens</h2>
      <form onSubmit={handleMint}>
        <input placeholder="Recipient address" value={to} onChange={(e) => setTo(e.target.value)} required />
        <input placeholder="Amount" type="number" value={amount} onChange={(e) => setAmount(e.target.value)} required />
        <button className="btn btn-primary" type="submit">Mint</button>
      </form>
    </div>
  );
}

function FreezeSection({ contracts, execTx }) {
  const [addr, setAddr] = useState("");
  const [amount, setAmount] = useState("");

  return (
    <div className="card">
      <h2>Freeze / Unfreeze</h2>
      <div className="form-group">
        <input placeholder="Wallet address" value={addr} onChange={(e) => setAddr(e.target.value)} />
        <input placeholder="Amount" type="number" value={amount} onChange={(e) => setAmount(e.target.value)} />
        <div className="btn-group">
          <button
            className="btn btn-danger"
            onClick={() => execTx("Freezing tokens", contracts.RealEstateToken.freezePartialTokens(addr, amount))}
          >
            Freeze
          </button>
          <button
            className="btn btn-success"
            onClick={() => execTx("Unfreezing tokens", contracts.RealEstateToken.unfreezePartialTokens(addr, amount))}
          >
            Unfreeze
          </button>
        </div>
      </div>
    </div>
  );
}

function PauseSection({ contracts, execTx }) {
  return (
    <div className="card">
      <h2>Pause / Unpause</h2>
      <p>Pause all token transfers globally.</p>
      <div className="btn-group">
        <button className="btn btn-danger" onClick={() => execTx("Pausing token", contracts.RealEstateToken.pause())}>
          Pause
        </button>
        <button className="btn btn-success" onClick={() => execTx("Unpausing token", contracts.RealEstateToken.unpause())}>
          Unpause
        </button>
      </div>
    </div>
  );
}

function ForcedTransferSection({ contracts, execTx }) {
  const [from, setFrom] = useState("");
  const [to, setTo] = useState("");
  const [amount, setAmount] = useState("");

  const handleForce = (e) => {
    e.preventDefault();
    execTx("Forced transfer", contracts.RealEstateToken.forcedTransfer(from, to, amount));
  };

  return (
    <div className="card">
      <h2>Forced Transfer</h2>
      <form onSubmit={handleForce}>
        <input placeholder="From address" value={from} onChange={(e) => setFrom(e.target.value)} required />
        <input placeholder="To address" value={to} onChange={(e) => setTo(e.target.value)} required />
        <input placeholder="Amount" type="number" value={amount} onChange={(e) => setAmount(e.target.value)} required />
        <button className="btn btn-danger" type="submit">Force Transfer</button>
      </form>
    </div>
  );
}

function ComplianceSettingsSection({ contracts, execTx }) {
  const [maxHolders, setMaxHolders] = useState("");
  const [maxBalance, setMaxBalance] = useState("");
  const [country, setCountry] = useState("");

  const complianceAddr = CONTRACTS.ModularCompliance;

  return (
    <div className="card">
      <h2>Compliance Settings</h2>

      <div className="form-group">
        <label>Max Holders</label>
        <div className="inline-form">
          <input placeholder="e.g. 100" type="number" value={maxHolders} onChange={(e) => setMaxHolders(e.target.value)} />
          <button className="btn btn-primary" onClick={() => execTx("Setting max holders", contracts.MaxHoldersModule.setMaxHolders(complianceAddr, maxHolders))}>
            Set
          </button>
        </div>
      </div>

      <div className="form-group">
        <label>Max Balance per Investor</label>
        <div className="inline-form">
          <input placeholder="e.g. 10000" type="number" value={maxBalance} onChange={(e) => setMaxBalance(e.target.value)} />
          <button className="btn btn-primary" onClick={() => execTx("Setting max balance", contracts.MaxBalanceModule.setMaxBalance(complianceAddr, maxBalance))}>
            Set
          </button>
        </div>
      </div>

      <div className="form-group">
        <label>Country Restriction</label>
        <div className="inline-form">
          <input placeholder="Country code (e.g. 999)" type="number" value={country} onChange={(e) => setCountry(e.target.value)} />
          <div className="btn-group">
            <button className="btn btn-danger" onClick={() => execTx("Adding restriction", contracts.CountryRestrictModule.addCountryRestriction(complianceAddr, country))}>
              Restrict
            </button>
            <button className="btn btn-success" onClick={() => execTx("Removing restriction", contracts.CountryRestrictModule.removeCountryRestriction(complianceAddr, country))}>
              Unrestrict
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
