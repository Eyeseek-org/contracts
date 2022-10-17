async function main() {
    const Donator = await ethers.getContractFactory("FundingAx");
  
    // Polygon Gateway -- 0xBF62ef1486468a6bd26Dd669C06db43dEd5B849B
    const DonatorDeploy = await Donator.deploy("0x2107B0F3bB0ccc1CcCA94d641c0E2AB61D5b8F3E","0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174", "0xBF62ef1486468a6bd26Dd669C06db43dEd5B849B");
    console.log("Donator contract deployed to address:", DonatorDeploy.address);
  
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });