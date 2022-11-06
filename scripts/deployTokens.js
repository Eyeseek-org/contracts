async function main() {
    /// Creating test environment

    const Usdc = await ethers.getContractFactory("USDC");
    const Usdt = await ethers.getContractFactory("USDT");
    const FaucetUsdc = await ethers.getContractFactory("Faucet");
    const FaucetUsdt = await ethers.getContractFactory("Faucet");
  

    const DeployedUsdc = await Usdc.deploy();
    console.log("USDC deployed to address:", DeployedUsdc.address);

    const DeployedUsdt = await Usdt.deploy();
    console.log("USDT deployed to address:", DeployedUsdt.address);

    const DeployedFaucetUsdc = await FaucetUsdc.deploy(DeployedUsdc.address);
    console.log("Faucet USDC deployed to address:", DeployedFaucetUsdc.address);

    const DeployedFaucetUsdt = await FaucetUsdt.deploy(DeployedUsdt.address);
    console.log("Faucet USDT deployed to address:", DeployedFaucetUsdt.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });