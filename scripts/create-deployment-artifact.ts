import { ethers, network } from "hardhat";
import fs from "fs";
import path from "path";

async function main() {
  const contractAddress = "0x6169f44197500b94adf98A42CA6b783B6e6ae72A";
  const contractName = "GelatoRelay1Balance_Proxy";

  console.log(`Fetching deployment info for ${contractName} at ${contractAddress} on ${network.name}...\n`);

  // Check if contract exists at address
  const code = await ethers.provider.getCode(contractAddress);
  if (code === "0x") {
    console.error(`❌ No contract found at ${contractAddress}`);
    process.exit(1);
  }
  console.log(`✅ Contract exists (${code.length} bytes)`);

  // Get the ABI from a reference deployment (alephzero)
  const referenceArtifactPath = path.join(
    __dirname,
    "../deployments/alephzero/GelatoRelay1Balance_Proxy.json"
  );

  if (!fs.existsSync(referenceArtifactPath)) {
    console.error(`❌ Reference artifact not found at ${referenceArtifactPath}`);
    process.exit(1);
  }

  const referenceArtifact = JSON.parse(fs.readFileSync(referenceArtifactPath, "utf8"));
  console.log(`✅ Loaded reference ABI from alephzero deployment`);

  // Create the artifact
  const artifact = {
    address: contractAddress,
    abi: referenceArtifact.abi,
    transactionHash: null, // We don't have this from on-chain
    receipt: null, // We don't have this from on-chain
    args: referenceArtifact.args, // Assuming same constructor args
    numDeployments: 1,
    solcInputHash: referenceArtifact.solcInputHash,
    metadata: referenceArtifact.metadata,
    bytecode: referenceArtifact.bytecode,
    deployedBytecode: referenceArtifact.deployedBytecode,
    libraries: referenceArtifact.libraries,
    facets: referenceArtifact.facets,
    execute: referenceArtifact.execute,
    history: referenceArtifact.history,
    implementation: referenceArtifact.implementation,
    devdoc: referenceArtifact.devdoc,
    userdoc: referenceArtifact.userdoc,
    storageLayout: referenceArtifact.storageLayout,
    methodIdentifiers: referenceArtifact.methodIdentifiers,
  };

  // Save to deployments folder
  const deploymentsDir = path.join(__dirname, `../deployments/${network.name}`);
  if (!fs.existsSync(deploymentsDir)) {
    fs.mkdirSync(deploymentsDir, { recursive: true });
  }

  const artifactPath = path.join(deploymentsDir, `${contractName}.json`);
  fs.writeFileSync(artifactPath, JSON.stringify(artifact, null, 2));

  console.log(`\n✅ Created deployment artifact at: ${artifactPath}`);
  console.log(`\nYou can now run: npx hardhat deploy --network dynamic --tags GelatoRelay`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
