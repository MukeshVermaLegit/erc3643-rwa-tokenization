export const CHAIN_ID = 11155111; // Sepolia
export const CHAIN_NAME = "Sepolia";
export const RPC_URL = "https://ethereum-sepolia-rpc.publicnode.com";

export const CONTRACTS = {
  RealEstateToken: "0x22CbE1A5A8af36D0f77e339E473dD468969434a4",
  IdentityRegistry: "0xd8583E1e2E5e14902A00B899E857258D2D318f39",
  ModularCompliance: "0xE0796AB044621259e565A85bE3066E95291b6983",
  CountryRestrictModule: "0x3702C213f15228a0e4d0097a7bF15719fe736ef3",
  MaxHoldersModule: "0x3769b7085cF45DB971aaF5a1f79e5c0DFb00fa4c",
  MaxBalanceModule: "0x5b2c7445dDA24e48E4B7172001696B5ec804E6a8",
  TrustedIssuersRegistry: "0xC48D61bbD621513F30f568a8194219f768d62aAF",
};

export const SEPOLIA_PARAMS = {
  chainId: "0x" + CHAIN_ID.toString(16),
  chainName: CHAIN_NAME,
  nativeCurrency: { name: "Ether", symbol: "ETH", decimals: 18 },
  rpcUrls: [RPC_URL],
  blockExplorerUrls: ["https://sepolia.etherscan.io"],
};
