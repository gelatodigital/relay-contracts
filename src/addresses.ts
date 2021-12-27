/* eslint-disable @typescript-eslint/naming-convention */
export interface Addresses {
  Gelato: string;
  WETH: string;
  DAI: string;
}

export const getAddresses = (network: string): Addresses => {
  switch (network) {
    case "hardhat":
      return {
        Gelato: "0x3CACa7b48D0573D793d3b0279b5F0029180E83b6",
        WETH: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
        DAI: "0x6B175474E89094C44Da98b954EedeAC495271d0F",
      };
    case "arbitrum":
      return {
        Gelato: "0x4775aF8FEf4809fE10bf05867d2b038a4b5B2146",
        WETH: "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1",
        DAI: "0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1",
      };
    case "mainnet":
      return {
        Gelato: "0x3CACa7b48D0573D793d3b0279b5F0029180E83b6",
        WETH: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
        DAI: "0x6B175474E89094C44Da98b954EedeAC495271d0F",
      };
    case "goerli":
      return {
        Gelato: "0x683913B3A32ada4F8100458A3E1675425BdAa7DF",
        WETH: "0x60D4dB9b534EF9260a88b0BED6c486fe13E604Fc",
        DAI: "0x11fE4B6AE13d2a6055C8D9cF65c55bac32B5d844",
      };
    default:
      throw new Error(`No addresses for Network: ${network}`);
  }
};
