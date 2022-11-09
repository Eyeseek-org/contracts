async function main() {
    const Multi = await ethers.getContractFactory("EyeseekMulti");
  
    /// Polygon deployment
    /// TBD comment constructor - Hardcoded EYE token (2nd position) as uSDC
    /// constructr: address _gateway, address usdcAddress, address usdtAddress, address daiAddress
    /// Gateway polygon - 0xBF62ef1486468a6bd26Dd669C06db43dEd5B849B
    const Deployed = await Multi.deploy();
    console.log("Donator contract deployed to address:", Deployed.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });