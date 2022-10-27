 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IAxelarExecutable} from "./interfaces/IAxelarExecutable.sol";
import {IAxelarGasService} from "./interfaces/IAxelarGasService.sol";
import {IAxelarGateway} from "./interfaces/IAxelarGateway.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FundingSource is IAxelarExecutable {
     IAxelarGasService gasReceiver;
     IAxelarGateway immutable gateway;

    constructor(address _gateway, address _gasReceiver) {
        gateway = IAxelarGateway(_gateway);
        gasReceiver = IAxelarGasService(_gasReceiver);
    }

    function callWithToken(
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata symbol,
        uint256 amount
    ) external payable {
        address tokenAddress = gateway.tokenAddresses(symbol);
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        IERC20(tokenAddress).approve(address(gateway), amount);
        // Encode number going to Direct Donation, amount to Microfund
        bytes memory payload = abi.encode(destinationAddresses); // TO REPLACE
        if (msg.value > 0) {
            gasReceiver.payNativeGasForContractCallWithToken{value: msg.value}(
                address(this),
                destinationChain,
                destinationAddress,
                payload,
                symbol,
                amount,
                msg.sender
            );
        }
        gateway.callContractWithToken(
            destinationChain,
            destinationAddress,
            payload,
            symbol,
            amount
        );
    }
}