import hre = require("hardhat");
const { ethers } = hre;
import { expect } from "chai";
import {
  IGelato,
  GelatoRelay,
  MockGelatoRelayContext,
  MockERC20,
} from "../typechain";

import {
  MessageRelayContextStruct,
  ExecWithSigsRelayContextStruct,
} from "../typechain/contracts/interfaces/IGelato";
import { INIT_TOKEN_BALANCE as FEE } from "./constants";
import { utils, Signer } from "ethers";
import { getAddresses } from "../src/addresses";
import { generateDigestRelayContext } from "../src/utils/EIP712Signatures";
import {
  setBalance,
  impersonateAccount,
} from "@nomicfoundation/hardhat-network-helpers";

const EXEC_SIGNER_PK =
  "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d";
const CHECKER_SIGNER_PK =
  "0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a";
const FEE_COLLECTOR = "0x3AC05161b76a35c1c28dC99Aa01BEd7B24cEA3bf";
const correlationId = utils.formatBytes32String("CORRELATION_ID");
const FUJI_DIAMOND_OWNER = "0x9386CdCcbf11335587F2C769BB88E6e30685945e";

describe("Test MockGelatoRelayContext Smart Contract", function () {
  let executorSigner: Signer;
  let checkerSigner: Signer;
  let executorSignerAddress: string;
  let checkerSignerAddress: string;

  let gelatoRelay: GelatoRelay;
  let mockRelayContext: MockGelatoRelayContext;
  let mockERC20: MockERC20;

  let gelatoDiamond: IGelato;
  let targetRelayContext: string;
  let salt: number;
  let deadline: number;
  let feeToken: string;

  beforeEach("tests", async function () {
    if (hre.network.name !== "hardhat") {
      console.error("Test Suite is meant to be run on hardhat only");
      process.exit(1);
    }

    await hre.deployments.fixture();

    [, executorSigner, checkerSigner] = await hre.ethers.getSigners();
    executorSignerAddress = await executorSigner.getAddress();
    checkerSignerAddress = await checkerSigner.getAddress();

    gelatoRelay = (await hre.ethers.getContract("GelatoRelay")) as GelatoRelay;
    mockRelayContext = (await hre.ethers.getContract(
      "MockGelatoRelayContext"
    )) as MockGelatoRelayContext;
    mockERC20 = (await hre.ethers.getContract("MockERC20")) as MockERC20;
    targetRelayContext = mockRelayContext.address;
    salt = 42069;
    deadline = 2664381086;
    feeToken = mockERC20.address;

    gelatoDiamond = (await ethers.getContractAt(
      "IGelato",
      getAddresses("goerli").GELATO
    )) as IGelato;

    await impersonateAccount(FUJI_DIAMOND_OWNER); // Diamond Owner
    await setBalance(FUJI_DIAMOND_OWNER, ethers.utils.parseEther("1"));

    const devMS = await ethers.getSigner(FUJI_DIAMOND_OWNER);
    await gelatoDiamond
      .connect(devMS)
      .addExecutorSigners([executorSignerAddress]);
    await gelatoDiamond
      .connect(devMS)
      .addCheckerSigners([checkerSignerAddress]);
  });

  it("#1: emitContext", async () => {
    const targetPayload =
      mockRelayContext.interface.encodeFunctionData("emitContext");
    const relayPayload = gelatoRelay.interface.encodeFunctionData(
      "callWithSyncFeeV2",
      [targetRelayContext, targetPayload, true, correlationId]
    );

    const msg: MessageRelayContextStruct = {
      service: gelatoRelay.address,
      data: relayPayload,
      salt,
      deadline,
      feeToken,
      fee: FEE,
    };

    const domainSeparator = await gelatoDiamond.DOMAIN_SEPARATOR();

    const esKey = new utils.SigningKey(EXEC_SIGNER_PK);
    const csKey = new utils.SigningKey(CHECKER_SIGNER_PK);
    const digest = generateDigestRelayContext(msg, domainSeparator);
    const executorSignerSig = utils.joinSignature(esKey.signDigest(digest));
    const checkerSignerSig = utils.joinSignature(csKey.signDigest(digest));

    const call: ExecWithSigsRelayContextStruct = {
      correlationId,
      msg,
      executorSignerSig,
      checkerSignerSig,
    };

    await expect(gelatoDiamond.execWithSigsRelayContext(call))
      .to.emit(mockRelayContext, "LogMsgData")
      .withArgs(targetPayload)
      .and.to.emit(mockRelayContext, "LogContext")
      .withArgs(FEE_COLLECTOR, feeToken, FEE);
  });

  it("#2: testTransferRelayFee", async () => {
    const targetPayload = mockRelayContext.interface.encodeFunctionData(
      "testTransferRelayFee"
    );
    const relayPayload = gelatoRelay.interface.encodeFunctionData(
      "callWithSyncFeeV2",
      [targetRelayContext, targetPayload, true, correlationId]
    );

    const msg: MessageRelayContextStruct = {
      service: gelatoRelay.address,
      data: relayPayload,
      salt,
      deadline,
      feeToken,
      fee: FEE,
    };

    const domainSeparator = await gelatoDiamond.DOMAIN_SEPARATOR();

    const esKey = new utils.SigningKey(EXEC_SIGNER_PK);
    const csKey = new utils.SigningKey(CHECKER_SIGNER_PK);
    const digest = generateDigestRelayContext(msg, domainSeparator);
    const executorSignerSig = utils.joinSignature(esKey.signDigest(digest));
    const checkerSignerSig = utils.joinSignature(csKey.signDigest(digest));

    const call: ExecWithSigsRelayContextStruct = {
      correlationId,
      msg,
      executorSignerSig,
      checkerSignerSig,
    };

    await mockERC20.transfer(targetRelayContext, FEE);

    await gelatoDiamond.execWithSigsRelayContext(call);

    expect(await mockERC20.balanceOf(FEE_COLLECTOR)).to.be.eq(FEE);
  });

  it("#3: testTransferRelayFeeCapped: works if at maxFee", async () => {
    const maxFee = FEE;
    const targetPayload = mockRelayContext.interface.encodeFunctionData(
      "testTransferRelayFeeCapped",
      [maxFee]
    );
    const relayPayload = gelatoRelay.interface.encodeFunctionData(
      "callWithSyncFeeV2",
      [targetRelayContext, targetPayload, true, correlationId]
    );

    const msg: MessageRelayContextStruct = {
      service: gelatoRelay.address,
      data: relayPayload,
      salt,
      deadline,
      feeToken,
      fee: FEE,
    };

    const domainSeparator = await gelatoDiamond.DOMAIN_SEPARATOR();

    const esKey = new utils.SigningKey(EXEC_SIGNER_PK);
    const csKey = new utils.SigningKey(CHECKER_SIGNER_PK);
    const digest = generateDigestRelayContext(msg, domainSeparator);
    const executorSignerSig = utils.joinSignature(esKey.signDigest(digest));
    const checkerSignerSig = utils.joinSignature(csKey.signDigest(digest));

    const call: ExecWithSigsRelayContextStruct = {
      correlationId,
      msg,
      executorSignerSig,
      checkerSignerSig,
    };

    await mockERC20.transfer(targetRelayContext, FEE);

    await gelatoDiamond.execWithSigsRelayContext(call);

    expect(await mockERC20.balanceOf(FEE_COLLECTOR)).to.be.eq(FEE);
  });

  it("#4: testTransferRelayFeeCapped: works if below maxFee", async () => {
    const maxFee = FEE.add(1);
    const targetPayload = mockRelayContext.interface.encodeFunctionData(
      "testTransferRelayFeeCapped",
      [maxFee]
    );
    const relayPayload = gelatoRelay.interface.encodeFunctionData(
      "callWithSyncFeeV2",
      [targetRelayContext, targetPayload, true, correlationId]
    );

    const msg: MessageRelayContextStruct = {
      service: gelatoRelay.address,
      data: relayPayload,
      salt,
      deadline,
      feeToken,
      fee: FEE,
    };

    const domainSeparator = await gelatoDiamond.DOMAIN_SEPARATOR();

    const esKey = new utils.SigningKey(EXEC_SIGNER_PK);
    const csKey = new utils.SigningKey(CHECKER_SIGNER_PK);
    const digest = generateDigestRelayContext(msg, domainSeparator);
    const executorSignerSig = utils.joinSignature(esKey.signDigest(digest));
    const checkerSignerSig = utils.joinSignature(csKey.signDigest(digest));

    const call: ExecWithSigsRelayContextStruct = {
      correlationId,
      msg,
      executorSignerSig,
      checkerSignerSig,
    };

    await mockERC20.transfer(targetRelayContext, FEE);

    await gelatoDiamond.execWithSigsRelayContext(call);

    expect(await mockERC20.balanceOf(FEE_COLLECTOR)).to.be.eq(FEE);
  });

  it("#5: testTransferRelayFeeCapped: reverts if above maxFee", async () => {
    const maxFee = FEE.sub(1);
    const targetPayload = mockRelayContext.interface.encodeFunctionData(
      "testTransferRelayFeeCapped",
      [maxFee]
    );
    const relayPayload = gelatoRelay.interface.encodeFunctionData(
      "callWithSyncFeeV2",
      [targetRelayContext, targetPayload, true, correlationId]
    );

    const msg: MessageRelayContextStruct = {
      service: gelatoRelay.address,
      data: relayPayload,
      salt,
      deadline,
      feeToken,
      fee: FEE,
    };

    const domainSeparator = await gelatoDiamond.DOMAIN_SEPARATOR();

    const esKey = new utils.SigningKey(EXEC_SIGNER_PK);
    const csKey = new utils.SigningKey(CHECKER_SIGNER_PK);
    const digest = generateDigestRelayContext(msg, domainSeparator);
    const executorSignerSig = utils.joinSignature(esKey.signDigest(digest));
    const checkerSignerSig = utils.joinSignature(csKey.signDigest(digest));

    const call: ExecWithSigsRelayContextStruct = {
      correlationId,
      msg,
      executorSignerSig,
      checkerSignerSig,
    };

    await mockERC20.transfer(targetRelayContext, FEE);

    await expect(
      gelatoDiamond.execWithSigsRelayContext(call)
    ).to.be.revertedWith(
      "ExecWithSigsFacet.execWithSigsRelayContext:GelatoRelay.callWithSyncFeeV2:GelatoRelayContext._transferRelayFeeCapped: maxFee"
    );
  });

  it("#6: testOnlyGelatoRelay reverts if not GelatoRelay", async () => {
    await expect(mockRelayContext.testOnlyGelatoRelay()).to.be.revertedWith(
      "GelatoRelayContext.onlyGelatoRelay"
    );
  });
});