// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
/// @title Chain donation contract
/// @author Michal Kazdan


import "hardhat/console.sol";

contract Funding is Ownable, ReentrancyGuard {
    IERC20 public token;
    IERC20 public usdc;

    address public feeAddress = 0xc21223249CA28397B4B6541dfFaEcC539BfF0c59;
    uint256 public minAmount = 1;
    uint256 public platformFee = 1;

    /// @notice Use modifiers to check when deadline is passed
    modifier isDeadlinePassed(uint256 _id) {
        require(
            block.timestamp < funds[_id].deadline,
            "Deadline for crowdfunding has passed."
        );
        _;
    }

    /// @notice Main crowdfunding fund
    struct Fund {
        uint256 id;
        address owner;
        uint256 balance;
        uint256 deadline; // Timespan for crowdfunding to be active
        uint256 state; ///@dev 0=Cancelled, 1=Active, 2=Finished
        uint256 currency; /// 0=Eye, 1=USDC
        uint256 level1;
        uint256 level2;
        uint256 level3;
        uint256 level4;
        uint256 level5;
    }

    /// @notice Unlimited amount of microfunds could be connect with a main fund
    struct MicroFund {
        uint256 microId;
        address owner;
        uint256 cap;
        uint256 microBalance;
        uint256 fundId;
        uint256 state; ///@dev 0=Cancelled, 1=Active, 2=Finished
    }

    /// @dev Struct for direct donations
    struct Donate {
        uint256 id;
        uint256 fundId;
        address backer;
        uint256 amount;
        uint256 state; ///@dev 0=Donated, 1=Distributed, 2=Refunded
    }

    /// @dev Struct for token funds
    struct TokenFund {
        uint256 id;
        address owner;
        uint256 balance;
        uint256 deadline; // Timespan for crowdfunding to be active
        uint256 state; ///@dev 0=Cancelled, 1=Active, 2=Finished
        address tokenAddress;
        uint256 reward;
        uint256 level1;
    }
    
    TokenFund[] public tokenFunds;
    Fund[] public funds;
    MicroFund[] public microFunds;
    Donate[] public donations;

    /// @notice Custom token for value exchange in the project
    constructor(address tokenAddress, address usdcAddress) {
        token = IERC20(tokenAddress);
        usdc = IERC20(usdcAddress);
    }

    /// @dev temporarily set only 1 level and fixed deadline, to make integration more simple
    function createFund(
        uint256 _level1
    ) public {
        /// @notice Create a new project to be funded
        /// @param _currency - token address, fund could be created in any token, this will be also required for payments // For now always 0
        /// @param _level1 - 1st (minimum) level of donation accomplishment, same works for all levels.
        /// @dev Frontend should handle parameters if no levels required. Level 1-5 have to be filled to max.
        uint256 _deadline = block.timestamp + 30 days; 
        require(msg.sender != address(0), "Invalid address");
        require(_level1 > 0, "Invalid amount");
        require(_level1 >= minAmount, "Value is lower than minimum possible amount");
        /// @dev Only one active fund per address should be allowed (for now disabled)
        // for (uint256 i = 0; i < funds.length; i++) {
        //    require(funds[i].owner == msg.sender && funds[i].state == 0, "You already have a fund");
        // }
        funds.push(
            Fund({
                owner: msg.sender,
                balance: 0,
                id: funds.length,
                state: 1,
                currency: 0,
                deadline: _deadline,
                level1: _level1,
                level2: _level1,
                level3: _level1,
                level4: _level1,
                level5: _level1
            })
        );
        emit FundCreated(
            msg.sender,
            _level1,
            funds.length
        );
    }


    /// Simple ICO function, experimenting in the contract
    /// TBD docs, tests, distribute functions, view functions 
    function createTokenFund (
        uint256 _level1,
        uint256 _address,
        uint256 _amount
    ) public {
        uint256 _deadline = block.timestamp + 30 days; 
        require(_level1 > 0, "Invalid amount");
        require(_level1 >= minAmount, "Value is lower than minimum possible amount");
        _address.transferFrom(msg.sender, address(this), _amount);
        tokenFunds.push(
            TokenFund({
                owner: msg.sender,
                balance: 0,
                id: tokenFunds.length,
                state: 1,
                deadline: _deadline,
                level1: _level1,
                tokenAddress: _address,
                reward: _amount
            })
        );
        emit TokenFundCreated(
            msg.sender,
            _level1,
            tokenFunds.length
        );
    }
    

    function contribute(
        uint256 _amountM,
        uint256 _amountD,
        uint256 _id
    ) public isDeadlinePassed(_id) {
        /// @param _amountM - amount of tokens to be sent to microfund
        /// @param _amountD - amount of tokens to be direcly donated
        /// @notice User can create microfund and donate at the same time
        /// @notice If he donates
        require(msg.sender != address(0), "Invalid address");
        require(_amountM >= 0, "Invalid amount");
        require(_amountD >= 0, "Invalid amount");
        require(funds[_id].state == 1, "Fund is not active");
        /// @notice Transfer function stores amount into this contract, both initial donation and microfund
        /// @dev User approval needed before the donation for _amount (FE part)
        /// @dev Currency recognition
        if (funds[_id].currency == 0) {
            token.transferFrom(msg.sender, address(this), _amountD + _amountM);
        } else if (funds[_id].currency == 1) {
            usdc.transferFrom(msg.sender, address(this), _amountD + _amountM);
        } else {
            revert("Invalid currency");
        }
        /// @notice If donated, fund adds balance and related microfunds are involed
        ///@dev 0=Donated, 1=Distributed, 2=Refunded
        if (_amountD > 0) {
            funds[_id].balance += _amountD;
            // Updated the direct donations
            donations.push(
                Donate({
                    id: donations.length,
                    fundId: _id,
                    backer: msg.sender,
                    amount: _amountD,
                    state: 0
                })
            );
            emit Donated(msg.sender, _amountD, _id);
            drainMicro(_id, _amountD);
        }
        /// @notice If microfund created, it is added to the list
        if (_amountM > 0) {
            microFunds.push(
                MicroFund({
                    owner: msg.sender,
                    cap: _amountM,
                    microBalance: 0,
                    microId: microFunds.length,
                    fundId: _id,
                    state: 1
                })
            );
            emit MicroCreated(msg.sender, _amountM, _id);
        }
    }

    function drainMicro(uint256 _id, uint256 _amount) internal {
        /// @notice Find all active microfunds related to the main fund and join the chain donation
        for (uint256 i = 0; i < microFunds.length; i++) {
            if (
                microFunds[i].cap - microFunds[i].microBalance >= _amount &&
                microFunds[i].fundId == _id &&
                microFunds[i].state == 1
            ) {
                microFunds[i].microBalance += _amount;
                funds[_id].balance += _amount;
                /// @notice Close microfund if it reaches its cap
                if (microFunds[i].cap == microFunds[i].microBalance) {
                    microFunds[i].state = 2;
                    emit MicroClosed(
                        microFunds[i].owner,
                        microFunds[i].cap,
                        microFunds[i].fundId
                    );
                }
                emit MicroDrained(microFunds[i].owner, _amount, _id);
            }
        }
    }

    function batchDistribute() public onlyOwner nonReentrant {
        for (uint256 i = 0; i < funds.length; i++) {
            /// @notice - Only active funds with achieved minimum are eligible for distribution
            if (block.timestamp < funds[i].deadline) {
                continue;
            }

            if (
                funds[i].state == 1 &&
                funds[i].balance >= funds[i].level1 &&
                block.timestamp > funds[i].deadline
            ) {
                distribute(i);
            }
        }
        // For each active fund check if cap is reached and if so
        // Call function "distributeRewards" pro každý font
    }

    /// @notice Only admin can distribute rewards
    /// @notice All microfunds, and fund are closed
    function distribute(uint256 _id) public onlyOwner nonReentrant {
        require(funds[_id].state == 1, "Fund is not active");
        if (funds[_id].currency == 0) {
            require(
                token.balanceOf(address(this)) >= funds[_id].balance,
                "Not enough tokens in the contract"
            );
            token.approve(address(this), funds[_id].balance);
            /// @notice Take 1% fee to Eyeseek treasury
            uint256 fee = (funds[_id].balance * 1) / 100;
            uint256 fundGain = funds[_id].balance - fee;
            token.transferFrom(address(this), feeAddress, fee);
            emit FundingFee(funds[_id].owner, fee);
            /// @notice Distribute rewards to fund owner
            token.transferFrom(address(this), funds[_id].owner, fundGain);
            funds[_id].state = 2;
            emit Distributed(funds[_id].owner, funds[_id].balance);
            /// @notice Close microfund - Send back the remaining amount to the microfund owner
            for (uint256 i = 0; i < microFunds.length; i++) {
                if (microFunds[i].fundId == _id && microFunds[i].state == 1) {
                    if (microFunds[i].cap > microFunds[i].microBalance) {
                        uint256 difference = microFunds[i].cap -
                            microFunds[i].microBalance;
                        token.approve(address(this), difference);
                        token.transferFrom(
                            address(this),
                            microFunds[_id].owner,
                            difference
                        );
                        emit Returned(
                            microFunds[i].owner,
                            difference,
                            funds[_id].owner
                        );
                    }
                    microFunds[i].state = 2;
                }
            }
        } else if (funds[_id].currency == 1) {
            require(
                usdc.balanceOf(address(this)) >= funds[_id].balance,
                "Not enough tokens in the contract"
            );
            /// @notice Take 1% fee to Eyeseek treasury
            uint256 fee = (funds[_id].balance * 1) / 100;
            uint256 fundGain = funds[_id].balance - fee;
            usdc.transferFrom(address(this), feeAddress, fee);
            emit FundingFee(funds[_id].owner, fee);
            /// @notice Distribute rewards to fund owner
            usdc.transferFrom(address(this), funds[_id].owner, fundGain);
            funds[_id].state = 2;
            emit Distributed(funds[_id].owner, funds[_id].balance);
            /// @notice Close microfund - Send back the remaining amount to the microfund owner
            for (uint256 i = 0; i < microFunds.length; i++) {
                if (microFunds[i].fundId == _id && microFunds[i].state == 1) {
                    if (microFunds[i].cap > microFunds[i].microBalance) {
                        uint256 difference = microFunds[i].cap -
                            microFunds[i].microBalance;
                        usdc.approve(address(this), difference);
                        usdc.transferFrom(
                            address(this),
                            microFunds[_id].owner,
                            difference
                        );
                        emit Returned(
                            microFunds[i].owner,
                            difference,
                            funds[_id].owner
                        );
                    }
                    microFunds[i].state = 2;
                }
            }
        } else {
            revert("Invalid currency");
        }
    }

    ///@dev 0=Cancelled, 1=Active, 2=Finished
    function cancelFund(uint256 _id) public nonReentrant {
        require(funds[_id].state == 1, "Fund is not active");
        require(
            token.balanceOf(address(this)) >= funds[_id].balance,
            "Not enough tokens in the contract"
        );
        if (
            msg.sender == microFunds[_id].owner || msg.sender == address(this)
        ) {
            for (uint256 i = 0; i < microFunds.length; i++) {
                if (microFunds[i].fundId == _id && microFunds[i].state == 1) {
                    /// @notice Close microfund
                    /// @notice Optional piece of code - Send back the remaining amount to the microfund owner
                    if (microFunds[i].cap > microFunds[i].microBalance) {
                        token.approve(address(this), microFunds[_id].cap);
                        token.transferFrom(
                            address(this),
                            microFunds[_id].owner,
                            microFunds[_id].cap
                        );
                        emit Returned(
                            microFunds[i].owner,
                            microFunds[_id].cap,
                            funds[_id].owner
                        );
                    }
                    microFunds[i].state = 2;
                }
            }
            ///@dev Fund states - 0=Donated, 1=Distributed, 2=Refunded
            for (uint256 i = 0; i < donations.length; i++) {
                if (donations[i].fundId == _id && donations[i].state == 0) {
                    ///@notice refund the backers of the EYE token
                    if (funds[_id].currency == 0) {
                        token.approve(address(this), donations[i].amount);
                        token.transferFrom(
                            address(this),
                            donations[_id].backer,
                            donations[_id].amount
                        );
                        donations[i].state = 2;
                        emit Refunded(
                            donations[_id].backer,
                            donations[_id].amount,
                            _id
                        );
                    } else if (funds[_id].currency == 1) {
                    ///@notice refund the backers of USDC
                        usdc.approve(address(this), donations[i].amount);
                        usdc.transferFrom(
                            address(this),
                            donations[_id].backer,
                            donations[_id].amount
                        );
                        donations[i].state = 2;
                        emit Refunded(
                            donations[_id].backer,
                            donations[_id].amount,
                            _id
                        );
                    }
                }
            }

            /// @notice - Ideally project fund should be empty and can be closed
            if (funds[_id].balance == 0) {
                funds[_id].state = 2;
                emit Cancelled(funds[_id].owner, funds[_id]);
            } else {
                revert("Problem with calculation");
            }
        }
    }

    // ------ ADMIN FUNCTIONS ----------
    /// @notice Allow admin to change minimum amount for new projects
    /// @param _min - Minimum amount to create fund with
    function setMinimum(uint256 _min) public onlyOwner {
        minAmount = _min;
    }

    /// @notice Ability to change platform fee without need for contract redeployment
    function changeFee(uint256 _fee) public onlyOwner {
        platformFee = _fee;
    }


    // ------ VIEW FUNCTIONS ----------

    /// @notice - Get total number of microfunds connected to the ID of fund
    /// @param _index - ID of the fund
    function getConnectedMicroFunds(uint256 _index)
        public
        view
        returns (uint256)
    {
        uint256 count = 0;
        for (uint256 i = 0; i < microFunds.length; i++) {
            if (microFunds[i].fundId == _index) {
                count++;
            }
        }
        return count;
    }

    /// @notice - Calculate amounts of all involved microfunds in the donation
    /// @param _index - ID of the fund
    /// @param _amount - Amount of the donation
    function calcOutcome(uint256 _index, uint256 _amount)
        public
        view
        returns (uint256)
    {
        uint256 total = 0;
        total += _amount;
        for (uint256 i = 0; i < microFunds.length; i++) {
            if (
                microFunds[i].fundId == _index &&
                microFunds[i].state == 1 &&
                microFunds[i].cap - microFunds[i].microBalance >= _amount
            ) {
                total += _amount;
            }
        }
        return total;
    }

    /// @notice - Calculate number of involved microfunds for specific donation amount
    /// @param _index - ID of the fund
    /// @param _amount - Amount of the donation
    function calcInvolvedMicros(uint256 _index, uint256 _amount)
        public
        view
        returns (uint256)
    {
        uint256 microNumber = 0;
        for (uint256 i = 0; i < microFunds.length; i++) {
            if (
                microFunds[i].fundId == _index &&
                microFunds[i].state == 1 &&
                microFunds[i].cap - microFunds[i].microBalance >= _amount
            ) {
                microNumber++;
            }
        }
        return microNumber;
    }

    /// @notice - Calculate number of involved microfunds for specific donation amount
    /// @param _index - ID of the fund
    function calcTotalDonations(uint256 _index)
        public
        view
        returns (uint256)
    {
        uint256 backerNumber = 0;
        for (uint256 i = 0; i < donations.length; i++) {
            if (
                donations[i].fundId == _index
            ) {
                backerNumber++;
            }
        }
        return backerNumber;
    }

    /// @notice - Get project deadline
    function getFuddDeadline(uint256 _index) public view returns (uint256) {
        return funds[_index].deadline;
    }

    /// @notice - Get project minimal cap
    function getFundCap(uint256 _index) public view returns (uint256) {
        return funds[_index].level1;
    }

    /// @notice - Get project actual backing
    function getFundBalance(uint256 _index) public view returns (uint256) {
        return funds[_index].balance;
    }

    /// @notice - Get detail about a microfund
    function getMicroFundInfo(uint256 _index)
        public
        view
        returns (
            uint256 state,
            uint256 max,
            uint256 balance
        )
    {
        MicroFund storage microFund = microFunds[_index];
        return (microFund.state, microFund.microBalance, microFund.cap);
    }

    function getFundInfo(uint256 _index)
        public
        view
        returns (
            uint256 state,
            uint256 max,
            uint256 balance
        )
    {
        Fund storage fund = funds[_index];
        return (fund.state, fund.level5, fund.balance);
    }


    event TokenFundCreated(address owner, uint256 cap, uint256 id);
    event FundCreated(address owner, uint256 cap, uint256 id);
    event MicroCreated(address owner, uint256 cap, uint256 fundId);
    event Donated(address donator, uint256 amount, uint256 fundId);
    event MicroDrained(address owner, uint256 amount, uint256 fundId);
    event MicroClosed(address owner, uint256 cap, uint256 fundId);
    event Distributed(address owner, uint256 balance);
    event Refunded(address backer, uint256 amount, uint256 fundId);
    event Returned(address microOwner, uint256 balance, address fundOwner);
    event FundingFee(address project, uint256 fee);
    event Cancelled(address owner, uint256 fundId);
}
