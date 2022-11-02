async function main() {
    const Faucet = await ethers.getContractFactory("Faucet");
  
    /// Polygon deployment
    /// TBD comment constructor - Hardcoded EYE token (2nd position) as uSDC
    /// constructr: address _gateway, address usdcAddress, address usdtAddress, address daiAddress
    /// Gateway polygon - 0xBF62ef1486468a6bd26Dd669C06db43dEd5B849B
    const Deployed = await Faucet.deploy("0x2107B0F3bB0ccc1CcCA94d641c0E2AB61D5b8F3E");
    console.log("Donator contract deployed to address:", Deployed.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });