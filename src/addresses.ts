/* eslint-disable @typescript-eslint/naming-convention */
export interface Addresses {
  GELATO: string;
}

export const getAddresses = (network: string): Addresses => {
  switch (network) {
    case "hardhat":
      return {
        // We fork ethereum for local testing
        GELATO: "0x3CACa7b48D0573D793d3b0279b5F0029180E83b6",
      };
    case "arbitrum":
      return {
        GELATO: "0x4775aF8FEf4809fE10bf05867d2b038a4b5B2146",
      };
    case "avalanche":
      return {
        GELATO: "0x7C5c4Af1618220C090A6863175de47afb20fa9Df",
      };
    case "baseGoerli":
      return {
        GELATO: "0xbe77Cd403Be3F2C7EEBC3427360D3f9e5d528F43",
      };
    case "baseGoerliDev":
      return {
        GELATO: "0xCf8EDB3333Fae73b23f689229F4De6Ac95d1f707",
      };
    case "bicocca":
      return {
        GELATO: "0xF82D64357D9120a760e1E4C75f646C0618eFc2F3",
      };
    case "bicoccaDev":
      return {
        GELATO: "0xEB9b4944EB937dEE6CC8d721dA982d6019A2Fb8a",
      };
    case "bnb":
      return {
        GELATO: "0x7C5c4Af1618220C090A6863175de47afb20fa9Df",
      };
    case "chiado":
      return {
        GELATO: "0xF82D64357D9120a760e1E4C75f646C0618eFc2F3",
      };
    case "ethereum":
      return {
        GELATO: "0x3CACa7b48D0573D793d3b0279b5F0029180E83b6",
      };
    case "gnosis":
      return {
        GELATO: "0x29b6603D17B9D8f021EcB8845B6FD06E1Adf89DE",
      };
    case "fuji":
      return {
        GELATO: "0xF82D64357D9120a760e1E4C75f646C0618eFc2F3",
      };
    case "goerli":
      return {
        GELATO: "0x683913B3A32ada4F8100458A3E1675425BdAa7DF",
      };
    case "arbitrumGoerli":
      return {
        GELATO: "0xF82D64357D9120a760e1E4C75f646C0618eFc2F3",
      };
    case "polygon":
      return {
        GELATO: "0x7598e84B2E114AB62CAB288CE5f7d5f6bad35BbA",
      };
    case "polygonZk":
      return {
        GELATO: "0x08EFb6D315c7e74C39620c9AAEA289730f43a429",
      };
    case "polygonZkGoerli":
      return {
        GELATO: "0xaB0A8DCb1590C4565C35cC785dc25A0590398054",
      };
    case "polygonZkGoerliDev":
      return {
        GELATO: "0x1861708A1F55F433BaDE81895815c481e0c33448",
      };
    case "mumbai":
      return {
        GELATO: "0x25aD59adbe00C2d80c86d01e2E05e1294DA84823",
      };
    case "mumbaiDev":
      return {
        GELATO: "0x266E4AB6baD069aFc28d3C2CC129f6F8455b1dc2",
      };
    case "moonriver":
      return {
        GELATO: "0x91f2A140cA47DdF438B9c583b7E71987525019bB",
      };
    case "moonbeam":
      return {
        GELATO: "0x91f2A140cA47DdF438B9c583b7E71987525019bB",
      };
    case "optimismGoerli":
      return {
        GELATO: "0xF82D64357D9120a760e1E4C75f646C0618eFc2F3",
      };
    case "optimism":
      return {
        GELATO: "0x01051113D81D7d6DA508462F2ad6d7fD96cF42Ef",
      };
    default:
      throw new Error(`No addresses for Network: ${network}`);
  }
};
