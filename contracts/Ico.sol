// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
/// @title Ico contract for Eyeseek Funding hackathon project
/// @author Michal Kazdan

/// TBD temporary file. After working features will be merged to the Funding.sol

import "hardhat/console.sol";

contract Ico is Ownable, ReentrancyGuard {
        /// @dev Struct for token funds
    struct TokenFund {
        uint256 id;
        address owner;
        uint256 balance;
        uint256 deadline; // Timespan for crowdfunding to be active
        uint256 state; ///@dev 0=Cancelled, 1=Active, 2=Finished
        uint256 reward;
        uint256 level1;
    }
    
    TokenFund[] public tokenFunds;
    address token; 
        /// Simple ICO function, experimenting in the contract
    /// TBD docs, tests, distribute functions, view functions 
    function createTokenFund (
        uint256 _level1,
        uint256 _amount
    ) public {
        uint256 _deadline = block.timestamp + 30 days; 
        require(_level1 > 0, "Invalid amount");
        tokenFunds.push(
            TokenFund({
                owner: msg.sender,
                balance: 0,
                id: tokenFunds.length,
                state: 1,
                deadline: _deadline,
                level1: _level1,
                reward: _amount
            })
        );
        emit TokenFundCreated(
            msg.sender,
            _level1,
            tokenFunds.length
        );
    }
    event TokenFundCreated(address owner, uint256 cap, uint256 id);
}
