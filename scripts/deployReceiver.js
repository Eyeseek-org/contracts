async function main() {
  const Receiver = await ethers.getContractFactory("MessageReceiver");

  /// Polygon deployment
  const Deploy = await Receiver.deploy("0xBF62ef1486468a6bd26Dd669C06db43dEd5B849B");
  console.log("Axelar contract deployed to address:", Deploy.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });