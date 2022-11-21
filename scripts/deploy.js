async function main() {
  const Donator = await ethers.getContractFactory("Funding");

  /// Polygon deployment
  /// TBD comment constructor - Hardcoded EYE token (2nd position) as uSDC
  /// constructor:  address usdcAddress, address usdtAddress, address daiAddress
  
  /// Polygon testnet deployment
  const DonatorDeploy = await Donator.deploy("0x2bc37217445C34d616b2e2E2118a4Db6eFCD6ec8", "0xa57aC6b03ed2A1A8e58c35C355b990dC72f252b9", "0x5D8B4C2554aeB7e86F387B4d6c00Ac33499Ed01f");

  /// BNB testnet deployment
  //const DonatorDeploy = await Donator.deploy("0x96c185dB81d32d5e7efa65234cECa1C0040068BD", "0xD43b86CD7ccD89cb127F028E47A1F9d51029Eba8", "0xEC5dCb5Dbf4B114C9d0F65BcCAb49EC54F6A0867");

  /// Fantom testnet deployment
  //  const DonatorDeploy = await Donator.deploy("0x7383cC34B3eC68C327F93f9607Ea54b3D3B76dEe", "0x49bC977a4c5428F798cc136FCB3f5C1117BE0b6f", "0x30a40BC648799a746947417c675E54d5915ACA38");

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