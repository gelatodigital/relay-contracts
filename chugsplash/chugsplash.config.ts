import { getAddresses } from "../src/addresses";
import { UserChugSplashConfig } from "@chugsplash/core";
import hre from "hardhat";

/**
 * Deploy with:
 * npx hardhat chugsplash-deploy --network <target network> --config-path ./chugsplash/chugsplash.config.ts
 *
 * When testing, ChugSplash automatically deploys all configs found in the chugsplash/ directory. You can fetch
 * the deployed contracts using "await hre.chugsplash.getContract(projectName, contractName)".
 *
 * For example:
 * import "@chugsplash/plugins"
 * const gelatoRelay = await hre.chugsplash.getContract("Gelato Relay", "GelatoRelay");
 */

const { GELATO } = getAddresses(hre.network.name);
const config: UserChugSplashConfig = {
  options: {
    projectName: "Gelato Relay",
  },
  contracts: {
    GelatoRelay: {
      contract: "GelatoRelay",
      constructorArgs: {
        // eslint-disable-next-line @typescript-eslint/naming-convention
        _gelato: GELATO,
      },
      variables: {},
    },
    GelatoRelayERC2771: {
      contract: "GelatoRelayERC2771",
      constructorArgs: {
        // eslint-disable-next-line @typescript-eslint/naming-convention
        _gelato: GELATO,
      },
      variables: {
        userNonce: {},
      },
    },
  },
};

export default config;
