/* eslint-disable @typescript-eslint/naming-convention */
export interface Addresses {
  GELATO: string;
}

export const getAddresses = (network: string): Addresses => {
  switch (network) {
    case "hardhat":
      return {
        GELATO: "0x683913B3A32ada4F8100458A3E1675425BdAa7DF",
      };
    case "alfajores":
      return {
        GELATO: "0x53889b861f6cd5F93A419296b540aAD0BedE41Bd",
      };
    case "fuji":
      return {
        GELATO: "0x53889b861f6cd5F93A419296b540aAD0BedE41Bd",
      };
    case "goerli":
      return {
        GELATO: "0x53889b861f6cd5F93A419296b540aAD0BedE41Bd",
      };
    case "arbitrumGoerli":
      return {
        GELATO: "0x53889b861f6cd5F93A419296b540aAD0BedE41Bd",
      };
    case "mumbai":
      return {
        GELATO: "0x53889b861f6cd5F93A419296b540aAD0BedE41Bd",
      };
    case "optimisticGoerli":
      return {
        GELATO: "0x53889b861f6cd5F93A419296b540aAD0BedE41Bd",
      };
    default:
      throw new Error(`No addresses for Network: ${network}`);
  }
};
