export default function TransactionStatus({ status }) {
  if (!status) return null;

  const classMap = {
    pending: "tx-pending",
    success: "tx-success",
    error: "tx-error",
  };

  return (
    <div className={`tx-status ${classMap[status.type] || ""}`}>
      {status.type === "pending" && <span className="spinner" />}
      <span>{status.message}</span>
      {status.hash && (
        <a
          href={`https://sepolia.etherscan.io/tx/${status.hash}`}
          target="_blank"
          rel="noopener noreferrer"
        >
          View on Etherscan
        </a>
      )}
    </div>
  );
}
