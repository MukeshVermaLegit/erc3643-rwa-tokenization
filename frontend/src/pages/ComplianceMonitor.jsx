import { useState, useEffect, useCallback } from "react";
import { CONTRACTS } from "../config";
import { getReadOnlyContracts } from "../hooks/useContracts";

export default function ComplianceMonitor() {
  const [data, setData] = useState(null);
  const [transfers, setTransfers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const loadData = useCallback(async () => {
    try {
      setError(null);
      const c = getReadOnlyContracts();
      const complianceAddr = CONTRACTS.ModularCompliance;

      // Batch calls in smaller groups to avoid Infura rate limits
      const [name, symbol, totalSupply] = await Promise.all([
        c.RealEstateToken.name(),
        c.RealEstateToken.symbol(),
        c.RealEstateToken.totalSupply(),
      ]);

      const [paused, maxHolders, holderCount, maxBalance] = await Promise.all([
        c.RealEstateToken.paused(),
        c.MaxHoldersModule.getMaxHolders(complianceAddr),
        c.MaxHoldersModule.getHolderCount(complianceAddr),
        c.MaxBalanceModule.getMaxBalance(complianceAddr),
      ]);

      // Check a few common country codes for restrictions
      const countriesToCheck = [1, 44, 86, 91, 999];
      const restrictions = [];
      for (const code of countriesToCheck) {
        const restricted = await c.CountryRestrictModule.isCountryRestricted(complianceAddr, code);
        if (restricted) restrictions.push(code);
      }

      setData({
        name,
        symbol,
        totalSupply: totalSupply.toString(),
        paused,
        maxHolders: maxHolders.toString(),
        holderCount: holderCount.toString(),
        maxBalance: maxBalance.toString(),
        restrictedCountries: restrictions,
      });

      // Fetch recent Transfer events (last 5000 blocks)
      try {
        const currentBlock = await c.RealEstateToken.runner.provider.getBlockNumber();
        const fromBlock = Math.max(0, currentBlock - 5000);
        const filter = c.RealEstateToken.filters.Transfer();
        const events = await c.RealEstateToken.queryFilter(filter, fromBlock, currentBlock);
        const parsed = events.map((e) => ({
          from: e.args[0],
          to: e.args[1],
          value: e.args[2].toString(),
          txHash: e.transactionHash,
          blockNumber: e.blockNumber,
        }));
        setTransfers(parsed.reverse());
      } catch (err) {
        console.error("Failed to fetch events:", err);
      }

      setLoading(false);
    } catch (err) {
      console.error("Failed to load compliance data:", err);
      setError(err.message || "Failed to load data from blockchain");
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadData();
  }, [loadData]);

  if (loading) {
    return (
      <div className="page">
        <h1>Compliance Monitor</h1>
        <p>Loading on-chain data...</p>
      </div>
    );
  }

  if (error || !data) {
    return (
      <div className="page">
        <h1>Compliance Monitor</h1>
        <div className="card">
          <p style={{ color: "#e74c3c" }}>
            {error || "Failed to load data. The RPC endpoint may be rate-limited or unavailable."}
          </p>
          <button className="btn btn-primary" onClick={() => { setLoading(true); loadData(); }}>
            Retry
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="page">
      <h1>Compliance Monitor</h1>

      <div className="grid">
        <div className="card">
          <h2>Token Overview</h2>
          <div className="stat-grid">
            <div className="stat">
              <span className="stat-label">Name</span>
              <span className="stat-value">{data.name}</span>
            </div>
            <div className="stat">
              <span className="stat-label">Symbol</span>
              <span className="stat-value">{data.symbol}</span>
            </div>
            <div className="stat">
              <span className="stat-label">Total Supply</span>
              <span className="stat-value">{data.totalSupply}</span>
            </div>
            <div className="stat">
              <span className="stat-label">Status</span>
              <span className={`stat-value ${data.paused ? "frozen" : "success"}`}>
                {data.paused ? "PAUSED" : "ACTIVE"}
              </span>
            </div>
          </div>
        </div>

        <div className="card">
          <h2>Compliance Settings</h2>
          <div className="stat-grid">
            <div className="stat">
              <span className="stat-label">Holders</span>
              <span className="stat-value">{data.holderCount} / {data.maxHolders}</span>
            </div>
            <div className="stat">
              <span className="stat-label">Max Balance / Investor</span>
              <span className="stat-value">{data.maxBalance}</span>
            </div>
            <div className="stat">
              <span className="stat-label">Restricted Countries</span>
              <span className="stat-value">
                {data.restrictedCountries.length > 0
                  ? data.restrictedCountries.join(", ")
                  : "None"}
              </span>
            </div>
          </div>
        </div>

        <div className="card full-width">
          <h2>Transfer History</h2>
          {transfers.length === 0 ? (
            <p className="muted">No transfers found in recent blocks.</p>
          ) : (
            <div className="table-wrapper">
              <table>
                <thead>
                  <tr>
                    <th>Block</th>
                    <th>From</th>
                    <th>To</th>
                    <th>Amount</th>
                    <th>Tx</th>
                  </tr>
                </thead>
                <tbody>
                  {transfers.map((t, i) => (
                    <tr key={i}>
                      <td>{t.blockNumber}</td>
                      <td className="mono">
                        {t.from === "0x0000000000000000000000000000000000000000"
                          ? "MINT"
                          : `${t.from.slice(0, 6)}...${t.from.slice(-4)}`}
                      </td>
                      <td className="mono">{`${t.to.slice(0, 6)}...${t.to.slice(-4)}`}</td>
                      <td>{t.value}</td>
                      <td>
                        <a
                          href={`https://sepolia.etherscan.io/tx/${t.txHash}`}
                          target="_blank"
                          rel="noopener noreferrer"
                        >
                          View
                        </a>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
