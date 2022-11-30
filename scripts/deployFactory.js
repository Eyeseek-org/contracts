async function main() {
    const Box = await ethers.getContractFactory("Box");
    const box = await Box.deploy();
    await box.deployed();
  
    const BoxFactory = await ethers.getContractFactory("BoxFactory");
    const bf = await BoxFactory.deploy(box.address);
    await bf.deployed();
  
    console.log(box.address, "Box contract address");
    console.log(bf.address, "Minimal Proxy Box Factory contract address");
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });