import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import {
  BigNumber,
  BigNumberish,
  ContractReceipt,
  ContractTransaction,
} from "ethers";
import { arrayify, solidityPack } from "ethers/lib/utils";
import { ethers } from "hardhat";
import { IMultiSend, ISafe, ISafeProxyFactory } from "../../typechain";

// On Ethereum
const GNOSIS_SAFE_ADDRESS_BOOK = {
  fallbackHandler: "0xf48f2B2d2a534e402487b3ee7C18c33Aec0Fe5e4",
  gnosisSafe: "0xd9Db270c1B5E3Bd161E8c8503c55cEABeE709552",
  gnosisSafeProxyFactory: "0xa6B71E26C5e0845f74c812102Ca7114b6a896AB2",
};
const MULTI_SEND = "0xA238CBeb142c10Ef7Ad8442C6D1f9E89e07e7761";

const SALT = "631570";
const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

export enum OperationType {
  Call,
  DelegateCall,
}

type MetaTransactionData = {
  to: string;
  value: BigNumberish;
  data: string;
  operation: OperationType;
};

export class SafeHelper {
  // Interfaces
  #safeSingleton: ISafe | undefined;
  #safeProxy: ISafe | undefined;
  #safeProxyFactory: ISafeProxyFactory | undefined;
  #multiSend: IMultiSend | undefined;

  // Signer
  #signer: SignerWithAddress;

  constructor(signer: SignerWithAddress) {
    this.#signer = signer;
  }

  async init() {
    this.#safeProxyFactory = (await ethers.getContractAt(
      "ISafeProxyFactory",
      GNOSIS_SAFE_ADDRESS_BOOK.gnosisSafeProxyFactory
    )) as ISafeProxyFactory;
    this.#safeSingleton = (await ethers.getContractAt(
      "ISafe",
      GNOSIS_SAFE_ADDRESS_BOOK.gnosisSafe
    )) as ISafe;
    this.#multiSend = (await ethers.getContractAt(
      "IMultiSend",
      MULTI_SEND
    )) as IMultiSend;
  }

  async deploy() {
    if (!this.#safeProxyFactory) {
      throw new Error("init function is not invoked");
    }
    const deploymentTx = await this.#safeProxyFactory
      .connect(this.#signer)
      .createProxyWithNonce(
        GNOSIS_SAFE_ADDRESS_BOOK.gnosisSafe,
        await this._getSafeInitializer(),
        BigNumber.from(SALT)
      );
    const contractReceipt = await deploymentTx.wait();
    this.#safeProxy = (await ethers.getContractAt(
      "ISafe",
      this._getSafeProxyFromReceipt(contractReceipt)
    )) as ISafe;
  }

  getSafeProxy(): ISafe {
    if (!this.#safeProxy) {
      throw new Error("deploy function is not invoked");
    }
    return this.#safeProxy;
  }

  async execTransaction(
    txs: MetaTransactionData[]
  ): Promise<ContractTransaction> {
    if (!txs.length) {
      throw new Error("No transaction is provided");
    }
    if (txs.length === 1) {
      if (!this.#safeProxy) {
        throw new Error("deploy function is not invoked");
      }
      const { to, data, value, operation } = txs[0];
      const signature = await this._getSignature(to, data, value, operation);
      return this.#safeProxy
        .connect(this.#signer)
        .execTransaction(
          to,
          value,
          data,
          operation,
          0,
          0,
          0,
          ZERO_ADDRESS,
          ZERO_ADDRESS,
          signature
        );
    }
    if (!this.#multiSend) {
      throw new Error("init function is not invoked");
    }
    const data = this._encodeMultiSendData(txs);
    return this.execTransaction([
      {
        to: MULTI_SEND,
        data: this.#multiSend.interface.encodeFunctionData("multiSend", [data]),
        value: 0,
        operation: OperationType.DelegateCall,
      },
    ]);
  }

  async encodeExecTransactionData(txs: MetaTransactionData[]): Promise<string> {
    if (!txs.length) {
      throw new Error("No transaction is provided");
    }
    if (txs.length === 1) {
      if (!this.#safeProxy) {
        throw new Error("deploy function is not invoked");
      }
      const { to, data, value, operation } = txs[0];
      const signature = await this._getSignature(to, data, value, operation);
      return this.#safeProxy.interface.encodeFunctionData("execTransaction", [
        to,
        value,
        data,
        operation,
        0,
        0,
        0,
        ZERO_ADDRESS,
        ZERO_ADDRESS,
        signature,
      ]);
    }
    if (!this.#multiSend || !this.#safeProxy) {
      throw new Error("init function is not invoked");
    }

    const encodedMultiSendData = this._encodeMultiSendData(txs);
    const data = this.#multiSend.interface.encodeFunctionData("multiSend", [
      encodedMultiSendData,
    ]);
    return this.encodeExecTransactionData([
      { to: MULTI_SEND, data, value: 0, operation: OperationType.DelegateCall },
    ]);
  }

  private _encodeMetaTransaction(tx: MetaTransactionData): string {
    const data = arrayify(tx.data);
    const encoded = solidityPack(
      ["uint8", "address", "uint256", "uint256", "bytes"],
      [tx.operation, tx.to, tx.value.toString(), data.length, data]
    );
    return encoded.slice(2);
  }

  private _encodeMultiSendData(txs: MetaTransactionData[]): string {
    return "0x" + txs.map((tx) => this._encodeMetaTransaction(tx)).join("");
  }

  private async _getSignature(
    to: string,
    data: string,
    value: BigNumberish,
    operation: OperationType
  ) {
    if (!this.#safeProxy) {
      throw new Error("deploy function is not invoked");
    }
    return this.#signer._signTypedData(
      {
        chainId: await this.#signer.getChainId(),
        verifyingContract: this.#safeProxy.address,
      },
      {
        SafeTx: [
          { type: "address", name: "to" },
          { type: "uint256", name: "value" },
          { type: "bytes", name: "data" },
          { type: "uint8", name: "operation" },
          { type: "uint256", name: "safeTxGas" },
          { type: "uint256", name: "baseGas" },
          { type: "uint256", name: "gasPrice" },
          { type: "address", name: "gasToken" },
          { type: "address", name: "refundReceiver" },
          { type: "uint256", name: "nonce" },
        ],
      },
      {
        to,
        value: BigNumber.from(value).toString(),
        data,
        operation,
        safeTxGas: BigNumber.from(0).toString(),
        baseGas: BigNumber.from(0).toString(),
        gasPrice: BigNumber.from(0).toString(),
        gasToken: ZERO_ADDRESS,
        refundReceiver: ZERO_ADDRESS,
        nonce: (await this._getNonce()).toString(),
      }
    );
  }

  private async _getNonce(): Promise<BigNumber> {
    if (!this.#safeProxy) {
      throw new Error("deploy function is not invoked");
    }
    const nonce = await this.#safeProxy.nonce();
    return nonce;
  }

  private _getSafeProxyFromReceipt(contractReceipt: ContractReceipt): string {
    if (!this.#safeProxyFactory) {
      throw new Error("init function is not invoked");
    }
    const proxyCreationTopic =
      this.#safeProxyFactory.interface.getEventTopic("ProxyCreation");
    const proxyCreationEvent = contractReceipt.events?.find(
      (event) => event.topics[0] === proxyCreationTopic
    );
    const proxy = proxyCreationEvent?.args?.at(0);
    if (!proxy) {
      throw new Error("Proxy address could not be fetched");
    }
    return proxy;
  }

  private async _getSafeInitializer(): Promise<string> {
    if (!this.#safeSingleton) {
      throw new Error("init function is not invoked");
    }
    const owner = await this.#signer.getAddress();
    return this.#safeSingleton.interface.encodeFunctionData("setup", [
      [owner],
      BigNumber.from(1),
      ZERO_ADDRESS,
      "0x",
      GNOSIS_SAFE_ADDRESS_BOOK.fallbackHandler,
      ZERO_ADDRESS,
      BigNumber.from(0),
      ZERO_ADDRESS,
    ]);
  }
}
