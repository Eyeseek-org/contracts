// global variables are: ethers, $chains, $contracts, $getSigner, Chain
const destSigner = await $getSigner(Chain.FANTOM);
const destContractFactory = new ethers.ContractFactory(
  $contracts["MessageReceiver"].abi,
  $contracts["MessageReceiver"].bytecode,
  destSigner
);

const destProvider = new ethers.providers.JsonRpcProvider(
  $chains.fantom.rpcUrl
);
console.log("[[Step 1: Deploy]] Deploying MessageReceiver contract...");
const destContract = await destContractFactory
  .deploy($chains.fantom.gateway, $chains.fantom.gasReceiver)
  .then((contract) => contract.connect(destProvider));
await destContract.deployed();
console.log(
  "[[Step 1: Deploy]] MessageReceiver deployed at",
  destContract.address
);

const srcSigner = await $getSigner(Chain.POLYGON);

const srcContractFactory = new ethers.ContractFactory(
  $contracts["MessageSender"].abi,
  $contracts["MessageSender"].bytecode,
  srcSigner
);

console.log("[[Step 1: Deploy]] Deploying MessageSender contract...");
const srcContract = await srcContractFactory.deploy(
  $chains.polygon.gateway,
  $chains.polygon.gasReceiver
);
await srcContract.deployed();
console.log(
  "[[Step 1: Deploy]] MessageSender deployed at",
  srcContract.address
);

const receipt = await srcContract
  .connect(srcSigner)
  .setRemoteValue("polygon", destContract.address, "Hello World", {
    value: ethers.utils.parseEther("0.003"),
  })
  .then((tx) => tx.wait());

console.log(
  `[[Step 2: Sent Tx]] Sent "Hello World" from Polygon`,
  receipt.transactionHash
);

console.log(
  "[[Step 3: Relaying...]]Wait for relayer to process transaction..."
);

const waitForEvent = async (contract, eventName) => {
  return new Promise((resolve, _reject) => {
    contract.once(eventName, (...args) => {
      resolve(args);
    });
  });
};

// Wait for the receiver Execute event to be emitted
const args = await waitForEvent(destContract, "Executed");
console.log(
  "[[Step 4: Verify]]MessageReceiver value:",
  await destContract.value()
);
console.log(
  "[[Step 4: Verify]]MessageReceiver sourceChain:",
  await destContract.sourceChain()
);
console.log(
  "[[Step 4: Verify]]MessageReceiver sourceAddress:",
  await destContract.sourceAddress()
);

console.success("[[Step 5: Done]]Execution Complete!");
