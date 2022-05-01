/* eslint-disable @typescript-eslint/naming-convention */
export interface Addresses {
  Gelato: string;
}

export const getAddresses = (network: string): Addresses => {
  switch (network) {
    case "hardhat":
      return {
        Gelato: "0x3CACa7b48D0573D793d3b0279b5F0029180E83b6",
      };
    case "arbitrum":
      return {
        Gelato: "0x4775aF8FEf4809fE10bf05867d2b038a4b5B2146",
      };
    case "mainnet":
      return {
        Gelato: "0x3CACa7b48D0573D793d3b0279b5F0029180E83b6",
      };
    case "kovan":
      return {
        Gelato: "0xDf592cB2d32445F8e831d211AB20D3233cA41bD8",
      };
    case "goerli":
      return {
        Gelato: "0x683913B3A32ada4F8100458A3E1675425BdAa7DF",
      };
    case "matic":
      return {
        Gelato: "0x7598e84B2E114AB62CAB288CE5f7d5f6bad35BbA",
      };
    case "mumbai":
      return {
        Gelato: "0x25aD59adbe00C2d80c86d01e2E05e1294DA84823",
      };
    default:
      throw new Error(`No addresses for Network: ${network}`);
  }
};
