/* eslint-disable @typescript-eslint/naming-convention */
import { UserChugSplashConfig } from "@chugsplash/core";
import { INIT_TOKEN_BALANCE } from "../test/constants";

/**
 * Deploy with:
 * npx hardhat chugsplash-deploy --network <target network> --config-path ./chugsplash/mocks.config.ts
 *
 * When testing, ChugSplash automatically deploys all configs found in the chugsplash/ directory. You can fetch
 * the deployed contracts using "await hre.chugsplash.getContract(projectName, contractName)".
 *
 * For example:
 * import "@chugsplash/plugins"
 * const mockERC20 = await hre.chugsplash.getContract("Gelato Relay Mocks", "MockERC20");
 */

const config: UserChugSplashConfig = {
  options: {
    projectName: "Gelato Relay Mocks",
  },
  contracts: {
    MockERC20: {
      contract: "MockERC20",
      constructorArgs: {},
      variables: {
        _name: "MockERC20",
        _symbol: "ME2",
        _initializing: false,
        _initialized: 255,
        __gap: [],
        _totalSupply: INIT_TOKEN_BALANCE.toString(),
        _balances: {
          "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266":
            INIT_TOKEN_BALANCE.toString(),
        },
        _allowances: {},
      },
    },
    MockGelatoRelayContext: {
      contract: "MockGelatoRelayContext",
      constructorArgs: {},
      variables: {},
    },
    MockGelatoRelayContextERC2771: {
      contract: "MockGelatoRelayContextERC2771",
      constructorArgs: {},
      variables: {},
    },
    MockGelatoRelayFeeCollector: {
      contract: "MockGelatoRelayFeeCollector",
      constructorArgs: {},
      variables: {},
    },
    MockGelatoRelayFeeCollectorERC2771: {
      contract: "MockGelatoRelayFeeCollectorERC2771",
      constructorArgs: {},
      variables: {},
    },
  },
};

export default config;
