const { ethers, network } = require("hardhat")
const {expect} = require("chai")

let user, donationToken, donation, fund


beforeEach(async function () {
    // environment preparation, deploy token & staking contracts
    const accounts = await ethers.getSigners()
    user = await accounts[3] // Donor account
    fund = await accounts[4] // Fund account
    
    const Token = await ethers.getContractFactory("Token")
    donationToken = await Token.deploy()

    const Donation = await ethers.getContractFactory("Funding")
    donation = await Donation.deploy(donationToken.address, "0xc21223249CA28397B4B6541dfFaEcC539BfF0c59")
    stakeAmount = ethers.utils.parseUnits("1000000", 1)
    donationToken.transfer(user.address, stakeAmount)


    // eslint-disable-next-line no-unused-vars
    [user, donationToken.address, donation.address, fund] = await ethers.getSigners()


    return {Token, donationToken, donation, user, fund}
})

describe("Chain donation testing", async function () {
    it("Check funds + microfunds multiplication", async function () {

        const [user, fund] = await ethers.getSigners()

        const mainfund = 50000 
        const microfund1 = 500
        const microfund2 = 500
        const microfund3 = 500
        const microfund4 = 500
        const microfund5 = 50

        const secondFund = 1500 

        const initial1 = 20
        const initial2 = 20
        const initial3 = 20

        const allowance = microfund1 + microfund2 + microfund3 + microfund4 + microfund5 + initial1 + initial2 + initial3
        console.log(allowance)

        await donation.connect(fund).createFund(mainfund, mainfund, mainfund, mainfund,mainfund)
        await donation.connect(fund).createFund(secondFund, secondFund, secondFund, secondFund, secondFund)
        await donationToken.approve(donation.address, allowance, {from: user.address})
         // 3 Inverstors created microfund with initial donation of 20, 1 investor with 0
        await donation.contribute(microfund1,initial1,0, {from: user.address})
        await donation.contribute(microfund2,initial2,0, {from: user.address})
        await donation.contribute(microfund3,initial3,0, {from: user.address})
        await donation.contribute(microfund4,0,0, {from: user.address})
        // This microfund won't be calcuated due to lack of fund
        await donation.contribute(microfund5,0,0, {from: user.address})
        // Calculate donation impact
        const prediction = await donation.calcOutcome(0,100)
        expect(prediction).to.equal(500)
        console.log("Prediction: " + prediction)

        // Verify current balance after initial donations
        const info = await donation.getFundInfo(0)
        console.log("Initial fund balance is", info.balance)
        expect(info.balance).to.equal(120)

        // Check multiplier, 4x multiplier from microfunds + donation
        await donationToken.approve(donation.address, 100, {from: user.address})
        await donation.contribute(0,100, 0, {from: user.address})
        const info2 = await donation.getFundInfo(0)
        expect(info2.balance).to.equal(620)
        console.log("Total fund balance is", info2.balance)



        // Validate view functions
        const microfunds = await donation.getConnectedMicroFunds(0)
        expect(microfunds).to.equal(5)
        console.log("Total Microfunds: " + microfunds)


        // Test distribution after completion
        // Closing microfunds, closing funds 
        await donation.distribute(0);
        const fundBalance = await donationToken.balanceOf(fund.address)
        console.log("Fund balance after "+fundBalance)


    })
    it("Distributes donation, closing funds", async function () {

    })
    it("Cancel microfund", async function () {
            /// BeforeEach - Create test data, split between multiple scenarios
    })

})


