/* eslint-disable @typescript-eslint/naming-convention */
export interface Addresses {
  GELATO: string;
}

export const getAddresses = (network: string): Addresses => {
  switch (network) {
    case "hardhat":
      return {
        GELATO: "0x3CACa7b48D0573D793d3b0279b5F0029180E83b6",
      };
    case "alfajores":
      return {
        GELATO: "0x91f2A140cA47DdF438B9c583b7E71987525019bB",
      };
    case "arbitrum":
      return {
        GELATO: "0x4775aF8FEf4809fE10bf05867d2b038a4b5B2146",
      };
    case "bsc":
      return {
        GELATO: "0x7C5c4Af1618220C090A6863175de47afb20fa9Df",
      };
    case "evmos":
      return {
        GELATO: "0x91f2A140cA47DdF438B9c583b7E71987525019bB",
      };
    case "mainnet":
      return {
        GELATO: "0x3CACa7b48D0573D793d3b0279b5F0029180E83b6",
      };
    case "kovan":
      return {
        GELATO: "0xDf592cB2d32445F8e831d211AB20D3233cA41bD8",
      };
    case "gnosis":
      return {
        GELATO: "0x29b6603D17B9D8f021EcB8845B6FD06E1Adf89DE",
      };
    case "goerli":
      return {
        GELATO: "0x683913B3A32ada4F8100458A3E1675425BdAa7DF",
      };
    case "matic":
      return {
        GELATO: "0x7598e84B2E114AB62CAB288CE5f7d5f6bad35BbA",
      };
    case "mumbai":
      return {
        GELATO: "0x25aD59adbe00C2d80c86d01e2E05e1294DA84823",
      };
    case "rinkeby":
      return {
        GELATO: "0x0630d1b8C2df3F0a68Df578D02075027a6397173",
      };
    case "moonriver":
      return {
        GELATO: "0x91f2A140cA47DdF438B9c583b7E71987525019bB",
      };
    case "moonbeam":
      return {
        GELATO: "0x91f2A140cA47DdF438B9c583b7E71987525019bB",
      };
    case "avalanche":
      return {
        GELATO: "0x7C5c4Af1618220C090A6863175de47afb20fa9Df",
      };
    default:
      throw new Error(`No addresses for Network: ${network}`);
  }
};
