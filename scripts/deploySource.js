async function main() {
    const Source = await ethers.getContractFactory("MessageSender");
  
    // Fantom Gateway, Gas receiver contract
    //const SourceDeploy = await Source.deploy("0x97837985Ec0494E7b9C71f5D3f9250188477ae14","0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6");

    const SourceDeploy = await Source.deploy("0x4D147dCb984e6affEEC47e44293DA442580A3Ec0","0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6");
    console.log("Source contract deployed to address:", SourceDeploy.address);
  
  
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });