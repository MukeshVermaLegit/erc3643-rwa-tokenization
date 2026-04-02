import { Link, useLocation } from "react-router-dom";
import ConnectWallet from "./ConnectWallet";

const ROLE_LABELS = {
  admin: "Admin",
  investor: "Investor",
  viewer: "Viewer",
};

const ROLE_COLORS = {
  admin: "#e74c3c",
  investor: "#2ecc71",
  viewer: "#3498db",
};

export default function Navbar({ account, role, onConnect, onDisconnect }) {
  const location = useLocation();

  const navLinks = [
    { path: "/", label: "Dashboard", roles: ["admin"] },
    { path: "/investor", label: "Portfolio", roles: ["investor"] },
    { path: "/compliance", label: "Compliance", roles: ["admin", "investor", "viewer"] },
  ];

  const visibleLinks = navLinks.filter(
    (link) => link.roles.includes(role)
  );

  return (
    <nav className="navbar">
      <div className="navbar-brand">
        <Link to="/">RealEstate Token</Link>
      </div>
      <div className="navbar-links">
        {visibleLinks.map((link) => (
          <Link
            key={link.path}
            to={link.path}
            className={location.pathname === link.path ? "active" : ""}
          >
            {link.label}
          </Link>
        ))}
      </div>
      <div className="navbar-right">
        {account && (
          <span
            className="role-badge"
            style={{ backgroundColor: ROLE_COLORS[role] }}
          >
            {ROLE_LABELS[role]}
          </span>
        )}
        <ConnectWallet
          account={account}
          onConnect={onConnect}
          onDisconnect={onDisconnect}
        />
      </div>
    </nav>
  );
}
