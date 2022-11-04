const { ethers, network } = require("hardhat")
const {expect} = require("chai")

let user, donationToken, donation, fund, cancelUser, receiver


beforeEach(async function () {
    // environment preparation, deploy token & staking contracts
    const accounts = await ethers.getSigners()
    user = await accounts[3] // Donor account
    fund = await accounts[4] // Fund account
    cancelUser = await accounts[5] // Cancel account	
    receiver = await accounts[6] // Receiver account
    
    const Token = await ethers.getContractFactory("Token")
    donationToken = await Token.deploy()

    const Usdc = await ethers.getContractFactory("Token")
    usdcToken = await Usdc.deploy()
    usdcToken.transfer(user.address, 3 * 5000000000)
    usdcToken.transfer(fund.address, 5000000000)

    const Usdt = await ethers.getContractFactory("Token")
    usdtToken = await Usdt.deploy()
    usdtToken.transfer(user.address, 5000000000)
    usdtToken.transfer(fund.address, 5000000000)

    const Dai = await ethers.getContractFactory("Token")
    daiToken = await Dai.deploy()
    daiToken.transfer(user.address, 5000000000)
    daiToken.transfer(user.address, 5000000000)

    const Donation = await ethers.getContractFactory("Funding")
    donation = await Donation.deploy( donationToken.address, usdtToken.address, daiToken.address)
    stakeAmount = ethers.utils.parseUnits("1000000", 1)
    donationToken.transfer(user.address, stakeAmount)
    donationToken.transfer(cancelUser.address, 50000)
    donationToken.transfer(receiver.address, 50000)
    donationToken.transfer(fund.address, 50000)


    return {Token, donationToken, donation, user, fund, cancelUser, receiver}
})

describe("Chain donation testing", async function () {
    // it("Check funds + microfunds multiplication", async function () {

    //     const [user, fund] = await ethers.getSigners()

    //     const mainfund = 50000 
    //     const microfund1 = 500
    //     const microfund2 = 500
    //     const microfund3 = 500
    //     const microfund4 = 500
    //     const microfund5 = 50

    //     const secondFund = 1500 

    //     const initial1 = 20
    //     const initial2 = 20
    //     const initial3 = 20

    //     const allowance = microfund1 + microfund2 + microfund3 + microfund4 + microfund5 + initial1 + initial2 + initial3
    //     console.log(allowance)

    //     await donation.connect(fund).createFund(mainfund, '0x2107B0F3bB0ccc1CcCA94d641c0E2AB61D5b8F3E', 0)
    //     await donation.connect(fund).createFund(secondFund, '0x2107B0F3bB0ccc1CcCA94d641c0E2AB61D5b8F3E', 0)
    //     await donationToken.approve(donation.address, allowance, {from: user.address})
    //      // 3 Inverstors created microfund with initial donation of 20, 1 investor with 0
    //     await donation.contribute(microfund1,initial1,0,1, {from: user.address})
    //     await donation.contribute(microfund2,initial2,0,1, {from: user.address})
    //     await donation.contribute(microfund3,initial3,0,1, {from: user.address})
    //     await donation.contribute(microfund4,0,0, {from: user.address})
    //     // This microfund won't be calcuated due to lack of fund
    //     await donation.contribute(microfund5,0,0,1, {from: user.address})
    //     // Calculate donation impact
    //     const prediction = await donation.calcOutcome(0,100)
    //     expect(prediction).to.equal(500)
    //     console.log("Prediction: " + prediction)

    //     // Verify current balance after initial donations
    //     const info = await donation.getFundInfo(0)
    //     console.log("Initial fund balance is", info.balance)
    //     expect(info.balance).to.equal(120)

    //     // Check multiplier, 4x multiplier from microfunds + donation
    //     await donationToken.approve(donation.address, 100, {from: user.address})
    //     await donation.contribute(0,100, 0,1, {from: user.address})
    //     const info2 = await donation.getFundInfo(0)
    //     expect(info2.balance).to.equal(620)
    //     console.log("Total fund balance is", info2.balance)



    //     // Validate view functions
    //     const microfunds = await donation.getConnectedMicroFunds(0)
    //     expect(microfunds).to.equal(5)
    //     console.log("Total Microfunds: " + microfunds)


    //     // Test distribution after completion
    //     // Closing microfunds, closing funds 
    //     await donation.distribute(0);
    //     const fundBalance = await donationToken.balanceOf(fund.address)
    //     console.log("Fund balance after "+fundBalance)

    // })
    it("Cancel fund - Distributes resources back", async function () {
        const [user, fund] = await ethers.getSigners()
        const fundAmount = 500000000 
        const tokenAmount = 150
        await donationToken.approve(donation.address, tokenAmount, {from: user.address})
        await donation.connect(fund).createFund(fundAmount, '0x2107B0F3bB0ccc1CcCA94d641c0E2AB61D5b8F3E', 0)
        const balanceBefore = await donationToken.balanceOf(user.address)
        await donationToken.approve(donation.address, 1 * fundAmount, {from: user.address})
        await usdtToken.approve(donation.address, 2 * fundAmount, {from: user.address})
        await donation.contribute(0,fundAmount,0,1, {from: user.address})
        await donation.contribute(fundAmount,fundAmount,0,2, {from: user.address})

        const balance = await donationToken.balanceOf(donation.address)
        const balanceUsdt = await usdtToken.balanceOf(donation.address)

        console.log(balance)
        console.log(balanceUsdt)

        await donation.connect(fund).cancelFund(0);
        const balanceAfter = await donationToken.balanceOf(user.address)
        expect(balanceBefore).to.equal(balanceAfter)
        const contractBalance = await donationToken.balanceOf(donation.address)
        expect(contractBalance).to.equal(0)

    })
    it("Fund distribution", async function () {
        const [user, fund] = await ethers.getSigners()
        const fundAmount = 500000000
        await donation.connect(fund).createFund(fundAmount, '0x2107B0F3bB0ccc1CcCA94d641c0E2AB61D5b8F3E', 0)
        const fundBalBefore = await donationToken.balanceOf(fund.address)
        console.log(fundBalBefore)
        const balanceBefore = await donationToken.balanceOf(user.address)
        await donationToken.approve(donation.address, fundAmount, {from: user.address})
        await donation.contribute(0,fundAmount,0,1, {from: user.address})
        await donation.connect(fund).distribute(0, "0x2107B0F3bB0ccc1CcCA94d641c0E2AB61D5b8F3E");
        const balanceAfter = await donationToken.balanceOf(user.address)
        expect(balanceBefore).not.to.equal(balanceAfter)
        const fundAfter = await donationToken.balanceOf(fund.address)
        expect(fundBalBefore).not.to.equal(fundAfter)
        const contractBalance = await donationToken.balanceOf(donation.address)
        expect(contractBalance).to.equal(0)
    })
})


