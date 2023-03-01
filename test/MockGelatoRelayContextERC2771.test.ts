import hre, { ethers, deployments } from "hardhat";
import { expect } from "chai";
import {
  IGelato,
  GelatoRelayERC2771,
  MockGelatoRelayContextERC2771,
  MockERC20,
} from "../typechain";
import {
  MessageRelayContextStruct,
  ExecWithSigsRelayContextStruct,
} from "../typechain/contracts/interfaces/IGelato";
import { CallWithERC2771Struct } from "../typechain/contracts/GelatoRelayERC2771";
import { INIT_TOKEN_BALANCE as FEE } from "./constants";
import { utils, Signer } from "ethers";
import {
  generateDigestCallWithSyncFeeERC2771,
  generateDigestRelayContext,
} from "../src/utils/EIP712Signatures";
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

describe("Test MockGelatoRelayContextERC2771 Smart Contract", function () {
  let executorSigner: Signer;
  let checkerSigner: Signer;
  let msgSender: Signer;
  let executorSignerAddress: string;
  let checkerSignerAddress: string;
  let msgSenderAddress: string;

  let gelatoRelayERC2771: GelatoRelayERC2771;
  let mockGelatoRelayContextERC2771: MockGelatoRelayContextERC2771;
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

    const {
      gelatoRelayERC2771: gelatoRelayERC2771Address,
      gelatoDiamond: gelatoDiamondAddress,
    } = await hre.getNamedAccounts();

    // In the deploy script: setCode(gelatoRelayERC2771Address, localDeployedBytecode)
    gelatoRelayERC2771 = (await hre.ethers.getContractAt(
      "GelatoRelayERC2771",
      gelatoRelayERC2771Address
    )) as GelatoRelayERC2771;

    mockGelatoRelayContextERC2771 = (await hre.ethers.getContractAt(
      "MockGelatoRelayContextERC2771",
      (
        await deployments.get("MockGelatoRelayContextERC2771")
      ).address
    )) as MockGelatoRelayContextERC2771;

    mockERC20 = (await hre.ethers.getContractAt(
      "MockERC20",
      (
        await deployments.get("MockERC20")
      ).address
    )) as MockERC20;

    targetAddress = mockGelatoRelayContextERC2771.address;
    salt = 42069;
    deadline = 2664381086;
    feeToken = mockERC20.address;

    gelatoDiamond = (await ethers.getContractAt(
      "IGelato",
      gelatoDiamondAddress
    )) as IGelato;

    const gelatoDiamondOwnerAddress = await gelatoDiamond.owner();

    await impersonateAccount(gelatoDiamondOwnerAddress);
    await setBalance(gelatoDiamondOwnerAddress, ethers.utils.parseEther("1"));

    const gelatoDiamondOwner = await ethers.getSigner(
      gelatoDiamondOwnerAddress
    );

    await gelatoDiamond
      .connect(gelatoDiamondOwner)
      .addExecutorSigners([executorSignerAddress]);
    await gelatoDiamond
      .connect(gelatoDiamondOwner)
      .addCheckerSigners([checkerSignerAddress]);
  });

  it("#1: emitContext", async () => {
    const currentTime = await time.latest();

    const targetPayload =
      mockGelatoRelayContextERC2771.interface.encodeFunctionData("emitContext");

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

    const msg: MessageRelayContextStruct = {
      service: gelatoRelayERC2771.address,
      data: relayPayload,
      salt,
      deadline,
      feeToken,
      fee: FEE,
    };

    const diamondDomainSeparator = await gelatoDiamond.DOMAIN_SEPARATOR();

    const esKey = new utils.SigningKey(EXEC_SIGNER_PK);
    const csKey = new utils.SigningKey(CHECKER_SIGNER_PK);
    const digest = generateDigestRelayContext(msg, diamondDomainSeparator);
    const executorSignerSig = utils.joinSignature(esKey.signDigest(digest));
    const checkerSignerSig = utils.joinSignature(csKey.signDigest(digest));

    const call: ExecWithSigsRelayContextStruct = {
      correlationId,
      msg,
      executorSignerSig,
      checkerSignerSig,
    };

    await expect(gelatoDiamond.execWithSigsRelayContext(call))
      .to.emit(mockGelatoRelayContextERC2771, "LogMsgData")
      .withArgs(targetPayload)
      .and.to.emit(mockGelatoRelayContextERC2771, "LogContext")
      .withArgs(FEE_COLLECTOR, feeToken, FEE, msgSenderAddress);
  });

  it("#2: testTransferRelayFee", async () => {
    const currentTime = await time.latest();
    const targetPayload =
      mockGelatoRelayContextERC2771.interface.encodeFunctionData(
        "testTransferRelayFee"
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

    const msg: MessageRelayContextStruct = {
      service: gelatoRelayERC2771.address,
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

    await mockERC20.transfer(targetAddress, FEE);

    await gelatoDiamond.execWithSigsRelayContext(call);

    expect(await mockERC20.balanceOf(FEE_COLLECTOR)).to.be.eq(FEE);
  });

  it("#3: testTransferRelayFeeCapped: works if at maxFee", async () => {
    const maxFee = FEE;
    const currentTime = await time.latest();

    const targetPayload =
      mockGelatoRelayContextERC2771.interface.encodeFunctionData(
        "testTransferRelayFeeCapped",
        [maxFee]
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

    const msg: MessageRelayContextStruct = {
      service: gelatoRelayERC2771.address,
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

    await mockERC20.transfer(targetAddress, FEE);

    await gelatoDiamond.execWithSigsRelayContext(call);

    expect(await mockERC20.balanceOf(FEE_COLLECTOR)).to.be.eq(FEE);
  });

  it("#4: testTransferRelayFeeCapped: works if below maxFee", async () => {
    const currentTime = await time.latest();
    const maxFee = FEE.add(1);

    const targetPayload =
      mockGelatoRelayContextERC2771.interface.encodeFunctionData(
        "testTransferRelayFeeCapped",
        [maxFee]
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

    const msg: MessageRelayContextStruct = {
      service: gelatoRelayERC2771.address,
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

    await mockERC20.transfer(targetAddress, FEE);

    await gelatoDiamond.execWithSigsRelayContext(call);

    expect(await mockERC20.balanceOf(FEE_COLLECTOR)).to.be.eq(FEE);
  });

  it("#5: testTransferRelayFeeCapped: reverts if above maxFee", async () => {
    const currentTime = await time.latest();
    const maxFee = FEE.sub(1);

    const targetPayload =
      mockGelatoRelayContextERC2771.interface.encodeFunctionData(
        "testTransferRelayFeeCapped",
        [maxFee]
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

    const msg: MessageRelayContextStruct = {
      service: gelatoRelayERC2771.address,
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

    await mockERC20.transfer(targetAddress, FEE);

    await expect(
      gelatoDiamond.execWithSigsRelayContext(call)
    ).to.be.revertedWith(
      "ExecWithSigsFacet.execWithSigsRelayContext:GelatoRelayERC2771.callWithSyncFeeERC2771:GelatoRelayContextERC2771._transferRelayFeeCapped: maxFee"
    );
  });

  it("#6: testOnlyGelatoRelayERC2771 reverts if not gelatoRelayERC2771", async () => {
    await expect(
      mockGelatoRelayContextERC2771.testOnlyGelatoRelayERC2771()
    ).to.be.revertedWith("onlyGelatoRelayERC2771");
  });
});
