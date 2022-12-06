const { bytecode } = require("../artifacts/contracts/Funding.sol/Funding.json");
const { encoder, create2Address } = require("../utils/utils.js")

// 1. Deploy Factory
// 2. Run this script
// npx hardhat unlocktimer --set 30 => Pass to unlockTime, pass factory address
// 3. Deploy Funding npx hardhat run scripts/vaultDeploy.js

const main = async () => {
  const factoryAddr = "0x3bdcbd275741bd33D4A3e3469793065b528F1A93";
  const unlockTime = "1657835239"
  const saltHex = ethers.utils.id("1234");
  const initCode = bytecode + encoder(["uint"], [unlockTime]);

  const create2Addr = create2Address(factoryAddr, saltHex, initCode);
  console.log("precomputed address:", create2Addr);

  const Factory = await ethers.getContractFactory("DeployFactory");
  const factory = await Factory.attach(factoryAddr);

  const lockDeploy = await factory.deploy(initCode, saltHex);
  const txReceipt = await lockDeploy.wait();
  console.log("Deployed to:", txReceipt.events[0].args[0]);
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });