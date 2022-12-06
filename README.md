# Eyeseek funding contracts

This directory contains the contracts for the Eyeseek crowdfunding system. Created with Hardhat 

## Token contract
Eye token serves only as temporary token to faucet testnet behavior. Production version will work with stablecoins:
- USDC
- DAI
- USDT

Right now we are deployed on 3 testnet networks:
- Polygon Mumbai
- BNB testnet
- Fantom testnet

### Funding contract
Core contracts (`Funding.sol`) are changing in this stage of development very frequently (several times a week), there is a chance they might be outdated.

- 0x4B0cDe65426F66929c6a29B327F8E8Be13F29C3d - Mumbai
- 0x33A789a9B2aCF86693a270b428Fa001EE97f35AE - BNB
- 0xb03c283301E4af82c40Cd8e3744a7876B3C8276E - Fantom

#### Core contract responsibilities
- Funding contract is the main contract for the crowdfunding system. 
- It is responsible for creating and managing funding campaigns. 
- It also handles the funding process and the distribution of funds to the campaign creators.