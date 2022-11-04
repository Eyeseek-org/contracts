// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAxelarGasService} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";
import {AxelarExecutable} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/executables/AxelarExecutable.sol";

/// @title Chain donation contract
/// @author Michal Kazdan


contract MessageReceiver is AxelarExecutable {

    /// @dev Axelar - Lets start with hard Polygon gateway
    /// @dev In case of spreading core cotnract into multiple blockchain, put gateway address in constructor
    //address public gateway = 0xBF62ef1486468a6bd26Dd669C06db43dEd5B849B; 
    IAxelarGasService immutable gasReceiver = IAxelarGasService(0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6);
   

    constructor(address _gateway) 
         AxelarExecutable(_gateway)
     {
    }

    ///@dev Experimental with Axelar
    function _executeWithToken(
        string memory,
        string memory,
        bytes calldata payload,
        string memory tokenSymbol,
        uint256 amount 
    ) internal override {
        // get ERC-20 address from gateway
        address recipient = abi.decode(payload, (address));
        address tokenAddress = gateway.tokenAddresses(tokenSymbol);
        IERC20(tokenAddress).transfer(recipient, amount);
        emit AxelarExecutionComplete(amount, tokenSymbol);
    }

    event AxelarExecutionComplete(uint256 amount, string symbol);
}