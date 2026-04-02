import { useMemo } from "react";
import { ethers } from "ethers";
import { CONTRACTS, RPC_URL } from "../config";

import RealEstateTokenABI from "../contracts/RealEstateToken.json";
import IdentityRegistryABI from "../contracts/IdentityRegistry.json";
import ModularComplianceABI from "../contracts/ModularCompliance.json";
import CountryRestrictModuleABI from "../contracts/CountryRestrictModule.json";
import MaxHoldersModuleABI from "../contracts/MaxHoldersModule.json";
import MaxBalanceModuleABI from "../contracts/MaxBalanceModule.json";
import TrustedIssuersRegistryABI from "../contracts/TrustedIssuersRegistry.json";

const ABI_MAP = {
  RealEstateToken: RealEstateTokenABI,
  IdentityRegistry: IdentityRegistryABI,
  ModularCompliance: ModularComplianceABI,
  CountryRestrictModule: CountryRestrictModuleABI,
  MaxHoldersModule: MaxHoldersModuleABI,
  MaxBalanceModule: MaxBalanceModuleABI,
  TrustedIssuersRegistry: TrustedIssuersRegistryABI,
};

export function getReadOnlyProvider() {
  return new ethers.JsonRpcProvider(RPC_URL);
}

export function getReadOnlyContracts() {
  const provider = getReadOnlyProvider();
  const contracts = {};
  for (const [name, address] of Object.entries(CONTRACTS)) {
    contracts[name] = new ethers.Contract(address, ABI_MAP[name], provider);
  }
  return contracts;
}

export function useContracts(signer) {
  return useMemo(() => {
    const providerOrSigner = signer || getReadOnlyProvider();
    const contracts = {};
    for (const [name, address] of Object.entries(CONTRACTS)) {
      contracts[name] = new ethers.Contract(address, ABI_MAP[name], providerOrSigner);
    }
    return contracts;
  }, [signer]);
}
