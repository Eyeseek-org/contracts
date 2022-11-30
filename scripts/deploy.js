async function main() {
  const Donator = await ethers.getContractFactory("Funding");

  /// Polygon deployment
  /// TBD comment constructor - Hardcoded EYE token (2nd position) as uSDC
  /// constructor:  address usdcAddress, address usdtAddress, address daiAddress
  
  /// Polygon testnet deployment
   //const DonatorDeploy = await Donator.deploy("0x027FC11f7cB537F180aD46186CDc382A353e6E15", "0xce754458108142F620d78604a1ea892212f3DC94", "0x5D8B4C2554aeB7e86F387B4d6c00Ac33499Ed01f");

  /// BNB testnet deployment
  // const DonatorDeploy = await Donator.deploy("0x1EB85995c4a81a61EA4Ff7F5F2e84C20C9F590Ec", "0xc4932a9D0dD42aB445d1801bCbae0E42B47F22a0", "0xEC5dCb5Dbf4B114C9d0F65BcCAb49EC54F6A0867");

  /// Fantom testnet deployment
  //  const DonatorDeploy = await Donator.deploy("0x7383cC34B3eC68C327F93f9607Ea54b3D3B76dEe", "0x49bC977a4c5428F798cc136FCB3f5C1117BE0b6f", "0x30a40BC648799a746947417c675E54d5915ACA38");

  /// Optimism testnet deployment
  const DonatorDeploy = await Donator.deploy("0x71994687371a3AaDc3FfD32366EF349cAb8306Af", "0x1fB4F306500CcCFbD92156c0790FE1d312a362E1", "0x5D8B4C2554aeB7e86F387B4d6c00Ac33499Ed01f")

  console.log("Donator contract deployed to address:", DonatorDeploy.address);
  await DonatorDeploy.createZeroData();
  console.log("Zero data created")

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });