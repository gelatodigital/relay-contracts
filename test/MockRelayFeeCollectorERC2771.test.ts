import hre = require("hardhat");
const { ethers } = hre;
import { expect } from "chai";
import {
  IGelato,
  GelatoRelayERC2771,
  MockGelatoRelayFeeCollectorERC2771,
  MockERC20,
} from "../typechain";
import {
  MessageFeeCollectorStruct,
  ExecWithSigsFeeCollectorStruct,
} from "../typechain/contracts/interfaces/IGelato";

import { generateDigestCallWithSyncFeeERC2771 } from "../src/utils/EIP712Signatures";

import { CallWithERC2771Struct } from "../typechain/contracts/GelatoRelayERC2771";

import { utils, Signer } from "ethers";
import { getAddresses } from "../src/addresses";
import { generateDigestFeeCollector } from "../src/utils/EIP712Signatures";
import {
  setBalance,
  impersonateAccount,
  time,
} from "@nomicfoundation/hardhat-network-helpers";

const EXEC_SIGNER_PK =
  "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d";
const CHECKER_SIGNER_PK =
  "0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a";
const MSG_SENDER_PK =
  "0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6";
const FEE_COLLECTOR = "0x3AC05161b76a35c1c28dC99Aa01BEd7B24cEA3bf";
const correlationId = utils.formatBytes32String("CORRELATION_ID");
const FUJI_DIAMOND_OWNER = "0x9386CdCcbf11335587F2C769BB88E6e30685945e";

describe("Test MockGelatoRelayFeeCollectorERC2771 Smart Contract", function () {
  let executorSigner: Signer;
  let checkerSigner: Signer;
  let msgSender: Signer;
  let executorSignerAddress: string;
  let checkerSignerAddress: string;
  let msgSenderAddress: string;

  let gelatoRelayERC2771: GelatoRelayERC2771;
  let mockRelayFeeCollectorERC2771: MockGelatoRelayFeeCollectorERC2771;
  let mockERC20: MockERC20;

  let gelatoDiamond: IGelato;
  let targetAddress: string;
  let salt: number;
  let deadline: number;
  let feeToken: string;

  beforeEach("tests", async function () {
    if (hre.network.name !== "hardhat") {
      console.error("Test Suite is meant to be run on hardhat only");
      process.exit(1);
    }

    await hre.deployments.fixture();

    [, executorSigner, checkerSigner, msgSender] =
      await hre.ethers.getSigners();
    executorSignerAddress = await executorSigner.getAddress();
    checkerSignerAddress = await checkerSigner.getAddress();
    msgSenderAddress = await msgSender.getAddress();

    gelatoRelayERC2771 = (await hre.ethers.getContract(
      "GelatoRelayERC2771"
    )) as GelatoRelayERC2771;
    mockRelayFeeCollectorERC2771 = (await hre.ethers.getContract(
      "MockGelatoRelayFeeCollectorERC2771"
    )) as MockGelatoRelayFeeCollectorERC2771;
    mockERC20 = (await hre.ethers.getContract("MockERC20")) as MockERC20;

    targetAddress = mockRelayFeeCollectorERC2771.address;
    salt = 42069;
    deadline = 2664381086;
    feeToken = mockERC20.address;

    gelatoDiamond = (await ethers.getContractAt(
      "IGelato",
      getAddresses("fuji").GELATO
    )) as IGelato;

    await impersonateAccount(FUJI_DIAMOND_OWNER); // Diamond Owner
    await setBalance(FUJI_DIAMOND_OWNER, ethers.utils.parseEther("1"));

    const fujiDiamondOwner = await ethers.getSigner(FUJI_DIAMOND_OWNER);
    await gelatoDiamond
      .connect(fujiDiamondOwner)
      .addExecutorSigners([executorSignerAddress]);
    await gelatoDiamond
      .connect(fujiDiamondOwner)
      .addCheckerSigners([checkerSignerAddress]);
  });

  it("#1: emitFeeCollector", async () => {
    const currentTime = await time.latest();
    const targetPayload =
      mockRelayFeeCollectorERC2771.interface.encodeFunctionData(
        "emitFeeCollector"
      );

    const callWithERC2771: CallWithERC2771Struct = {
      chainId: 31337, // HH network
      target: targetAddress,
      data: targetPayload,
      user: msgSenderAddress,
      userNonce: 0,
      userDeadline: currentTime + 1000,
    };

    // create _msgSender signature
    const msgSenderKey = new utils.SigningKey(MSG_SENDER_PK);
    const relayERC2771DomainSeparator =
      await gelatoRelayERC2771.DOMAIN_SEPARATOR();

    const callWithSyncFeeERC2771Digest = generateDigestCallWithSyncFeeERC2771(
      callWithERC2771,
      relayERC2771DomainSeparator
    );
    const userSignature = utils.joinSignature(
      msgSenderKey.signDigest(callWithSyncFeeERC2771Digest)
    );

    const relayPayload = gelatoRelayERC2771.interface.encodeFunctionData(
      "callWithSyncFeeERC2771",
      [callWithERC2771, feeToken, userSignature, true, correlationId]
    );

    const msg: MessageFeeCollectorStruct = {
      service: gelatoRelayERC2771.address,
      data: relayPayload,
      salt,
      deadline,
      feeToken,
    };

    const domainSeparator = await gelatoDiamond.DOMAIN_SEPARATOR();

    const esKey = new utils.SigningKey(EXEC_SIGNER_PK);
    const csKey = new utils.SigningKey(CHECKER_SIGNER_PK);
    const digest = generateDigestFeeCollector(msg, domainSeparator);
    const executorSignerSig = utils.joinSignature(esKey.signDigest(digest));
    const checkerSignerSig = utils.joinSignature(csKey.signDigest(digest));

    const call: ExecWithSigsFeeCollectorStruct = {
      correlationId,
      msg,
      executorSignerSig,
      checkerSignerSig,
    };

    await expect(gelatoDiamond.execWithSigsFeeCollector(call))
      .to.emit(mockRelayFeeCollectorERC2771, "LogMsgData")
      .withArgs(targetPayload)
      .and.to.emit(mockRelayFeeCollectorERC2771, "LogFeeCollector")
      .withArgs(FEE_COLLECTOR);
  });

  it("#2: testOnlyGelatoRelayERC2771 reverts if not GelatoRelayERC2771", async () => {
    await expect(
      mockRelayFeeCollectorERC2771.testOnlyGelatoRelayERC2771()
    ).to.be.revertedWith("onlyGelatoRelayERC2771");
  });
});
