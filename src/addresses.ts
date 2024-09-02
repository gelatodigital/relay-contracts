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
    case "alephzero":
      return {
        GELATO: "0xb0cb899251086ed70e5d2c8d733D2896Fd989850",
      };
    case "alephzeroTestnet":
      return {
        GELATO: "0x30056FD86993624B72c7400bB4D7b29F05928E59",
      };
    case "amoy":
      return {
        GELATO: "0x30056FD86993624B72c7400bB4D7b29F05928E59",
      };
    case "amoyDev":
      return {
        GELATO: "0x963F2BeF2e6ac7764576bF449011eCcc759C0324",
      };
    case "anomalyAndromeda":
      return {
        GELATO: "0x30056FD86993624B72c7400bB4D7b29F05928E59",
      };
    case "arbitrum":
      return {
        GELATO: "0x4775aF8FEf4809fE10bf05867d2b038a4b5B2146",
      };
    case "arbitrumGoerli":
      return {
        GELATO: "0xF82D64357D9120a760e1E4C75f646C0618eFc2F3",
      };
    case "arbitrumSepolia":
      return {
        GELATO: "0xF82D64357D9120a760e1E4C75f646C0618eFc2F3",
      };
    case "astarzkevm":
      return {
        GELATO: "0xa2351354b39977ea35b1C28A035BD94e48F3ED7D",
      };
    case "astarzkyoto":
      return {
        GELATO: "0x683913B3A32ada4F8100458A3E1675425BdAa7DF",
      };
    case "avalanche":
      return {
        GELATO: "0x7C5c4Af1618220C090A6863175de47afb20fa9Df",
      };
    case "base":
      return {
        GELATO: "0x08EFb6D315c7e74C39620c9AAEA289730f43a429",
      };
    case "baseGoerli":
      return {
        GELATO: "0xbe77Cd403Be3F2C7EEBC3427360D3f9e5d528F43",
      };
    case "baseSepolia":
      return {
        GELATO: "0x683913B3A32ada4F8100458A3E1675425BdAa7DF",
      };
    case "baseGoerliDev":
      return {
        GELATO: "0xCf8EDB3333Fae73b23f689229F4De6Ac95d1f707",
      };
    case "berachainbartio":
      return {
        GELATO: "0x30056FD86993624B72c7400bB4D7b29F05928E59",
      };
    case "blast":
      return {
        GELATO: "0xFec1E33eBe899906Ff63546868A26E1028700b0e",
      };
    case "blastSepolia":
      return {
        GELATO: "0xF82D64357D9120a760e1E4C75f646C0618eFc2F3",
      };
    case "bnb":
      return {
        GELATO: "0x7C5c4Af1618220C090A6863175de47afb20fa9Df",
      };
    case "bonito":
      return {
        GELATO: "0x30056FD86993624B72c7400bB4D7b29F05928E59",
      };
    case "chiado":
      return {
        GELATO: "0xF82D64357D9120a760e1E4C75f646C0618eFc2F3",
      };
    case "connextSepolia":
      return {
        GELATO: "0x30056FD86993624B72c7400bB4D7b29F05928E59",
      };
    case "ethereum":
      return {
        GELATO: "0x3CACa7b48D0573D793d3b0279b5F0029180E83b6",
      };
    case "ethernityTestnet":
      return {
        GELATO: "0x30056FD86993624B72c7400bB4D7b29F05928E59",
      };
    case "gnosis":
      return {
        GELATO: "0x29b6603D17B9D8f021EcB8845B6FD06E1Adf89DE",
      };
    case "gelatoorbittestnet":
      return {
        GELATO: "0x683913B3A32ada4F8100458A3E1675425BdAa7DF",
      };
    case "gelatoorbittestnetDev":
      return {
        GELATO: "0xaB0A8DCb1590C4565C35cC785dc25A0590398054",
      };
    case "geloptestnet":
      return {
        GELATO: "0xF82D64357D9120a760e1E4C75f646C0618eFc2F3",
      };
    case "gelopcelestiatestnet":
      return {
        GELATO: "0x30056FD86993624B72c7400bB4D7b29F05928E59",
      };
    case "goerli":
      return {
        GELATO: "0x683913B3A32ada4F8100458A3E1675425BdAa7DF",
      };
    case "linea":
      return {
        GELATO: "0xc2a813699bF2353380c625e3D6b544dC42963941",
      };
    case "lineaGoerli":
      return {
        GELATO: "0xF82D64357D9120a760e1E4C75f646C0618eFc2F3",
      };
    case "lineaGoerliDev":
      return {
        GELATO: "0x1861708A1F55F433BaDE81895815c481e0c33448",
      };
    case "lisk":
      return {
        GELATO: "0xb0cb899251086ed70e5d2c8d733D2896Fd989850",
      };
    case "liskSepolia":
      return {
        GELATO: "0xF82D64357D9120a760e1E4C75f646C0618eFc2F3",
      };
    case "meldkanazawa":
      return {
        GELATO: "0xF82D64357D9120a760e1E4C75f646C0618eFc2F3",
      };
    case "meldkanazawaDev":
      return {
        GELATO: "0xEB9b4944EB937dEE6CC8d721dA982d6019A2Fb8a",
      };
    case "metis":
      return {
        GELATO: "0xFec1E33eBe899906Ff63546868A26E1028700b0e",
      };
    case "mode":
      return {
        GELATO: "0xFec1E33eBe899906Ff63546868A26E1028700b0e",
      };
    case "mumbai":
      return {
        GELATO: "0x25aD59adbe00C2d80c86d01e2E05e1294DA84823",
      };
    case "mumbaiDev":
      return {
        GELATO: "0x266E4AB6baD069aFc28d3C2CC129f6F8455b1dc2",
      };
    case "openCampusCodex":
      return {
        GELATO: "0x30056FD86993624B72c7400bB4D7b29F05928E59",
      };
    case "optimismGoerli":
      return {
        GELATO: "0xF82D64357D9120a760e1E4C75f646C0618eFc2F3",
      };
    case "optimismSepolia":
      return {
        GELATO: "0x2d4E9d6ac373d09033BF0b6579A881bF84B9Ee3A",
      };
    case "optimism":
      return {
        GELATO: "0x01051113D81D7d6DA508462F2ad6d7fD96cF42Ef",
      };
    case "playblock":
      return {
        GELATO: "0xb0cb899251086ed70e5d2c8d733D2896Fd989850",
      };
    case "playnanceTestnet":
      return {
        GELATO: "0x683913B3A32ada4F8100458A3E1675425BdAa7DF",
      };
    case "polygon":
      return {
        GELATO: "0x7598e84B2E114AB62CAB288CE5f7d5f6bad35BbA",
      };
    case "polygonBlackberry":
      return {
        GELATO: "0x30056FD86993624B72c7400bB4D7b29F05928E59",
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
    case "prism":
      return {
        GELATO: "0xb0cb899251086ed70e5d2c8d733D2896Fd989850",
      };
    case "rari":
      return {
        GELATO: "0xb0cb899251086ed70e5d2c8d733D2896Fd989850",
      };
    case "real":
      return {
        GELATO: "0xb0cb899251086ed70e5d2c8d733D2896Fd989850",
      };
    case "reya":
      return {
        GELATO: "0xb0cb899251086ed70e5d2c8d733D2896Fd989850",
      };
    case "reyaCronos":
      return {
        GELATO: "0x683913B3A32ada4F8100458A3E1675425BdAa7DF",
      };
    case "rootstock":
      return {
        GELATO: "0xb0cb899251086ed70e5d2c8d733D2896Fd989850",
      };
    case "sepolia":
      return {
        GELATO: "0xCf8EDB3333Fae73b23f689229F4De6Ac95d1f707",
      };
    case "shibarium":
      return {
        GELATO: "0xc2a813699bF2353380c625e3D6b544dC42963941",
      };
    case "unreal":
      return {
        GELATO: "0xF82D64357D9120a760e1E4C75f646C0618eFc2F3",
      };
    case "unrealOrbit":
      return {
        GELATO: "0x30056FD86993624B72c7400bB4D7b29F05928E59",
      };
    case "verifyTestnet":
      return {
        GELATO: "0x30056FD86993624B72c7400bB4D7b29F05928E59",
      };
    case "zkatana":
      return {
        GELATO: "0xF82D64357D9120a760e1E4C75f646C0618eFc2F3",
      };
    case "zksync":
      return {
        GELATO: "0x52cb9f60225aA830AE420126BC8e3d5B2fc5bCf4",
      };
    case "zksyncGoerli":
      return {
        GELATO: "0x296530a4224D5A5669a3f0C772EC7337ca3D3f1d",
      };
    case "zksyncGoerliDev":
      return {
        GELATO: "0x0730d466570f7413Df70298B019B3B775511E974",
      };
    case "zora":
      return {
        GELATO: "0xaF8447Ae9b68914E771b9C42e309CF76B98E2315",
      };
    default:
      throw new Error(`No addresses for Network: ${network}`);
  }
};
