import hre, { ethers } from "hardhat";
import {
  IGelato,
  GelatoRelayPayerContextMemory,
  ICounter,
  ISafe,
} from "../typechain";
import { expect } from "chai";
import {
  MessageRelayContextStruct,
  ExecWithSigsRelayContextStruct,
} from "../typechain/contracts/interfaces/IGelato";
import { utils } from "ethers";
import { generateDigestRelayContext } from "../src/utils/EIP712Signatures";
import {
  setBalance,
  impersonateAccount,
} from "@nomicfoundation/hardhat-network-helpers";
import { OperationType, SafeHelper } from "./utils/safeHelper";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

const EXEC_SIGNER_PK =
  "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d";
const CHECKER_SIGNER_PK =
  "0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a";
const FEE_COLLECTOR = "0x3AC05161b76a35c1c28dC99Aa01BEd7B24cEA3bf";

const SIMPLE_COUNTER_ETHEREUM = "0xA050b50869582F834f20bbc86f5C39658DeE1c41";

const correlationId = utils.formatBytes32String("CORRELATION_ID");

describe("Test GelatoRelayPayerContextMemory Smart Contract", function () {
  let executorSigner: SignerWithAddress;
  let checkerSigner: SignerWithAddress;
  let eoa: SignerWithAddress;

  let executorSignerAddress: string;
  let checkerSignerAddress: string;

  let gelatoRelayPayerContextMemory: GelatoRelayPayerContextMemory;
  let counter: ICounter;
  let safeProxy: ISafe;

  let gelatoDiamond: IGelato;
  let salt: number;
  let deadline: number;
  let feeToken: string;

  let targetData: string;

  let safeHelper: SafeHelper;

  beforeEach("tests", async function () {
    if (hre.network.name !== "hardhat") {
      console.error("Test Suite is meant to be run on hardhat only");
      process.exit(1);
    }

    await hre.deployments.fixture();

    [, executorSigner, checkerSigner, eoa] = await hre.ethers.getSigners();
    executorSignerAddress = await executorSigner.getAddress();
    checkerSignerAddress = await checkerSigner.getAddress();

    const { gelatoDiamond: gelatoDiamondAddress } =
      await hre.getNamedAccounts();

    gelatoRelayPayerContextMemory = (await hre.ethers.getContractAt(
      "GelatoRelayPayerContextMemory",
      (
        await hre.deployments.get("GelatoRelayPayerContextMemory")
      ).address
    )) as GelatoRelayPayerContextMemory;

    salt = 42069;
    deadline = 2664381086;
    feeToken = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";

    gelatoDiamond = (await ethers.getContractAt(
      "IGelato",
      gelatoDiamondAddress
    )) as IGelato;

    counter = (await hre.ethers.getContractAt(
      "ICounter",
      SIMPLE_COUNTER_ETHEREUM
    )) as ICounter;
    targetData = counter.interface.encodeFunctionData("increment");

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

    safeHelper = new SafeHelper(eoa);
    await safeHelper.init();
    await safeHelper.deploy();
    safeProxy = safeHelper.getSafeProxy();
  });

  it("#1: successful relay with maxFee", async () => {
    //Setup
    const initialBalance = hre.ethers.utils.parseEther("1");
    const relayerFee = 200;
    const maxFee = initialBalance;
    await setBalance(safeProxy.address, initialBalance);

    const counterBefore = await counter.counter();

    //Transaction
    const safePayload = await safeHelper.encodeExecTransactionData([
      {
        to: gelatoRelayPayerContextMemory.address,
        data: gelatoRelayPayerContextMemory.interface.encodeFunctionData(
          "transferFeeCappedDelegateCall",
          [safeProxy.address, maxFee]
        ),
        value: "0",
        operation: OperationType.DelegateCall,
      },
      {
        to: SIMPLE_COUNTER_ETHEREUM,
        data: targetData,
        value: "0",
        operation: OperationType.Call,
      },
    ]);

    const relayPayload =
      gelatoRelayPayerContextMemory.interface.encodeFunctionData(
        "callWithSyncFeeStoreContext",
        [safeProxy.address, safePayload, correlationId]
      );

    const msg: MessageRelayContextStruct = {
      service: gelatoRelayPayerContextMemory.address,
      data: relayPayload,
      salt,
      deadline,
      feeToken,
      fee: relayerFee,
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

    await expect(
      gelatoDiamond.execWithSigsRelayContext(call),
      "execWithSigsRelayContext"
    )
      .to.changeEtherBalances(
        [safeProxy.address, FEE_COLLECTOR],
        [-relayerFee, relayerFee]
      )
      .and.to.emit(
        gelatoRelayPayerContextMemory,
        "LogCallWithSyncFeeStoreContext"
      )
      .withArgs(safeProxy.address, correlationId);

    // Counter should be incremented by 1
    const counterAfter = await counter.counter();
    expect(counterAfter).to.equal(counterBefore.add(1));

    // Relay Context should be removed
    const relayContext =
      await gelatoRelayPayerContextMemory.getRelayContextByTarget(
        safeProxy.address
      );
    expect(relayContext.fee).to.equal(0);
    expect(relayContext.feeToken).to.equal(ethers.constants.AddressZero);
  });

  it("#2: successful relay without maxFee", async () => {
    //Setup
    const initialBalance = hre.ethers.utils.parseEther("1");
    const relayerFee = 100;

    await setBalance(safeProxy.address, initialBalance);
    const counterBefore = await counter.counter();

    //Transaction
    const safePayload = await safeHelper.encodeExecTransactionData([
      {
        to: gelatoRelayPayerContextMemory.address,
        data: gelatoRelayPayerContextMemory.interface.encodeFunctionData(
          "transferFeeDelegateCall",
          [safeProxy.address]
        ),
        value: "0",
        operation: OperationType.DelegateCall,
      },
      {
        to: SIMPLE_COUNTER_ETHEREUM,
        data: targetData,
        value: "0",
        operation: OperationType.Call,
      },
    ]);

    const relayPayload =
      gelatoRelayPayerContextMemory.interface.encodeFunctionData(
        "callWithSyncFeeStoreContext",
        [safeProxy.address, safePayload, correlationId]
      );

    const msg: MessageRelayContextStruct = {
      service: gelatoRelayPayerContextMemory.address,
      data: relayPayload,
      salt,
      deadline,
      feeToken,
      fee: relayerFee,
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

    await expect(
      gelatoDiamond.execWithSigsRelayContext(call),
      "execWithSigsRelayContext"
    )
      .to.changeEtherBalances(
        [safeProxy.address, FEE_COLLECTOR],
        [-relayerFee, relayerFee]
      )
      .and.to.emit(
        gelatoRelayPayerContextMemory,
        "LogCallWithSyncFeeStoreContext"
      )
      .withArgs(safeProxy.address, correlationId);

    // Counter should be incremented by 1
    const counterAfter = await counter.counter();
    expect(counterAfter).to.equal(counterBefore.add(1));

    // Relay Context should be removed
    const relayContext =
      await gelatoRelayPayerContextMemory.getRelayContextByTarget(
        safeProxy.address
      );
    expect(relayContext.fee).to.equal(0);
    expect(relayContext.feeToken).to.equal(ethers.constants.AddressZero);
  });

  it("#3: reverts if maxFee is exceeded", async () => {
    //Setup
    const initialBalance = hre.ethers.utils.parseEther("1");
    const relayerFee = ethers.utils.parseEther("0.2");
    const maxFee = ethers.utils.parseEther("0.1");
    await setBalance(safeProxy.address, initialBalance);

    //Transaction
    const safePayload = await safeHelper.encodeExecTransactionData([
      {
        to: gelatoRelayPayerContextMemory.address,
        data: gelatoRelayPayerContextMemory.interface.encodeFunctionData(
          "transferFeeCappedDelegateCall",
          [safeProxy.address, maxFee]
        ),
        value: "0",
        operation: OperationType.DelegateCall,
      },
      {
        to: SIMPLE_COUNTER_ETHEREUM,
        data: targetData,
        value: "0",
        operation: OperationType.Call,
      },
    ]);

    const relayPayload =
      gelatoRelayPayerContextMemory.interface.encodeFunctionData(
        "callWithSyncFeeStoreContext",
        [safeProxy.address, safePayload, correlationId]
      );

    const msg: MessageRelayContextStruct = {
      service: gelatoRelayPayerContextMemory.address,
      data: relayPayload,
      salt,
      deadline,
      feeToken,
      fee: relayerFee,
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

    await expect(
      gelatoDiamond.execWithSigsRelayContext(call)
    ).to.be.revertedWith(
      "ExecWithSigsFacet.execWithSigsRelayContext:GelatoRelayPayerContextMemory.callWithSyncFeeStoreContext:GS013"
    );
  });

  it("#4: reverts if transferFee is not called via delegate call", async () => {
    //Setup
    const initialBalance = hre.ethers.utils.parseEther("1");
    const relayerFee = ethers.utils.parseEther("0.2");
    await setBalance(safeProxy.address, initialBalance);

    //Transaction
    const safePayload = await safeHelper.encodeExecTransactionData([
      {
        to: gelatoRelayPayerContextMemory.address,
        data: gelatoRelayPayerContextMemory.interface.encodeFunctionData(
          "transferFeeDelegateCall",
          [safeProxy.address]
        ),
        value: "0",
        operation: OperationType.Call,
      },
      {
        to: SIMPLE_COUNTER_ETHEREUM,
        data: targetData,
        value: "0",
        operation: OperationType.Call,
      },
    ]);

    const relayPayload =
      gelatoRelayPayerContextMemory.interface.encodeFunctionData(
        "callWithSyncFeeStoreContext",
        [safeProxy.address, safePayload, correlationId]
      );

    const msg: MessageRelayContextStruct = {
      service: gelatoRelayPayerContextMemory.address,
      data: relayPayload,
      salt,
      deadline,
      feeToken,
      fee: relayerFee,
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

    await expect(
      gelatoDiamond.execWithSigsRelayContext(call)
    ).to.be.revertedWith(
      "ExecWithSigsFacet.execWithSigsRelayContext:GelatoRelayPayerContextMemory.callWithSyncFeeStoreContext:GS013"
    );
  });

  it("#5: reverts if fee collector is zero address", async () => {
    //Setup
    const initialBalance = hre.ethers.utils.parseEther("1");
    const relayerFee = ethers.utils.parseEther("0.2");
    await setBalance(safeProxy.address, initialBalance);

    //Transaction
    const safePayload = await safeHelper.encodeExecTransactionData([
      {
        to: gelatoRelayPayerContextMemory.address,
        data: gelatoRelayPayerContextMemory.interface.encodeFunctionData(
          "transferFeeDelegateCall",
          [safeProxy.address]
        ),
        value: "0",
        operation: OperationType.DelegateCall,
      },
      {
        to: SIMPLE_COUNTER_ETHEREUM,
        data: targetData,
        value: "0",
        operation: OperationType.Call,
      },
    ]);

    const relayPayload =
      gelatoRelayPayerContextMemory.interface.encodeFunctionData(
        "callWithSyncFeeStoreContext",
        [safeProxy.address, safePayload, correlationId]
      );

    const msg: MessageRelayContextStruct = {
      service: gelatoRelayPayerContextMemory.address,
      data: relayPayload,
      salt,
      deadline,
      feeToken: ethers.constants.AddressZero,
      fee: relayerFee,
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

    await expect(
      gelatoDiamond.execWithSigsRelayContext(call)
    ).to.be.revertedWith(
      "ExecWithSigsFacet.execWithSigsRelayContext:GelatoRelayPayerContextMemory.callWithSyncFeeStoreContext:GS013"
    );
  });
});
