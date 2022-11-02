async function main() {
  const Donator = await ethers.getContractFactory("Funding");

  /// Polygon deployment
  /// TBD comment constructor - Hardcoded EYE token (2nd position) as uSDC
  /// constructr: address _gateway, address usdcAddress, address usdtAddress, address daiAddress
  const DonatorDeploy = await Donator.deploy("0x2107B0F3bB0ccc1CcCA94d641c0E2AB61D5b8F3E", "0xc2132D05D31c914a87C6611C10748AEb04B58e8F", "0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063");
  console.log("Donator contract deployed to address:", DonatorDeploy.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });