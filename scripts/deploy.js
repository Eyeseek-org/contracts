async function main() {
  const Token = await ethers.getContractFactory("Token");
  const Donator = await ethers.getContractFactory("Funding");

  // Start deployment, returning a promise that resolves to a contract object
//  const TokenDeploy = await Token.deploy();
//  console.log("Contract deployed to address:", TokenDeploy.address);

  const DonatorDeploy = await Donator.deploy("0x2107B0F3bB0ccc1CcCA94d641c0E2AB61D5b8F3E","0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174");
  console.log("Donator contract deployed to address:", DonatorDeploy.address);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });